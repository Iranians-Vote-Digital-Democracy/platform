// Phase 1.9 — Desktop cross-device QR flow.
//
// When /v1/authorize is invoked with display=qr (set by OIDC clients running
// in a desktop browser, e.g. Element Web → MAS → sso-svc), we cannot 302 the
// browser to the wallet's Universal Link — there is no wallet on this device.
// Instead we:
//
//   1. Create a `desktop_sessions` row keyed by a fresh sid.
//   2. Render a small HTML page (QRPage) that polls /v1/authorize/qr/poll and
//      displays a QR encoding the wallet Universal Link with the sid appended.
//   3. The user scans on their phone. The wallet runs the normal /authorize
//      flow, then POSTs to /v1/authorize/qr/complete with {session_id, code}.
//   4. The desktop's poll picks up the code, JS sets window.location to
//      `<redirect_uri>?code=&state=` — same hand-off as the same-device flow.
//
// The wallet still owns identity proof; sso-svc only owns the rendezvous.
package handlers

import (
	"encoding/base64"
	"encoding/json"
	"html/template"
	"net/http"
	"net/url"
	"time"

	"github.com/jomhoor/sso-svc/internal/data"
	"github.com/pkg/errors"
	qrcode "github.com/skip2/go-qrcode"
	"gitlab.com/distributed_lab/ape"
	"gitlab.com/distributed_lab/ape/problems"
)

// desktopSessionTTL bounds how long the desktop browser may keep polling
// before the user must restart the flow. 5 min matches the wallet challenge
// TTL — a wallet completing later than that would already have a dead nonce.
const desktopSessionTTL = 5 * time.Minute

// qrPollInterval is how often the desktop polls. Aggressive enough to feel
// instant, gentle enough to survive a few hundred concurrent desktop sessions.
const qrPollIntervalMs = 1500

// qrPageTemplate renders the QR page returned by /v1/authorize/qr. It is
// deliberately dependency-free (no CDN, no inline scripts loaded from
// elsewhere) so it complies with strict CSP and avoids a supply-chain
// surface. The QR itself is server-rendered as a base64-PNG data URI.
var qrPageTemplate = template.Must(template.New("qr").Parse(`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sign in with Jomhoor</title>
<style>
  body { font-family: system-ui, -apple-system, sans-serif; max-width: 480px;
         margin: 4rem auto; padding: 0 1rem; text-align: center; color: #111; }
  img.qr { width: 280px; height: 280px; image-rendering: pixelated;
           border: 1px solid #ddd; padding: 12px; background: #fff; }
  .hint { color: #666; font-size: 0.95rem; line-height: 1.5; }
  .status { margin-top: 1.5rem; font-size: 0.9rem; color: #888; }
  .err { color: #b00020; }
</style>
</head>
<body>
<h1>Sign in with Jomhoor</h1>
<p class="hint">Scan this code with the Jomhoor wallet on your phone to continue.</p>
<img class="qr" alt="QR code" src="data:image/png;base64,{{.QRDataB64}}">
<p class="status" id="status">Waiting for wallet…</p>
<noscript><p class="err">JavaScript is required to complete sign-in.</p></noscript>
<script>
(function () {
  var sid = {{.SessionID}};
  var pollURL = "/v1/authorize/qr/poll?sid=" + encodeURIComponent(sid);
  var statusEl = document.getElementById("status");
  var attempts = 0;
  // Hard cap on polling so a forgotten tab doesn't poll forever. ~5 min at 1.5s.
  var maxAttempts = {{.MaxAttempts}};
  function tick() {
    if (attempts++ > maxAttempts) {
      statusEl.textContent = "This sign-in attempt expired. Please refresh to try again.";
      statusEl.className = "status err";
      return;
    }
    fetch(pollURL, { credentials: "omit" }).then(function (res) {
      if (res.status === 204) { return setTimeout(tick, {{.PollIntervalMs}}); }
      if (res.status === 410) {
        statusEl.textContent = "This sign-in attempt expired. Please refresh to try again.";
        statusEl.className = "status err";
        return;
      }
      if (!res.ok) {
        statusEl.textContent = "Unexpected error (" + res.status + "). Please refresh.";
        statusEl.className = "status err";
        return;
      }
      return res.json().then(function (body) {
        if (!body || !body.redirect_url) {
          statusEl.textContent = "Wallet response was malformed. Please refresh.";
          statusEl.className = "status err";
          return;
        }
        statusEl.textContent = "Signed in. Redirecting…";
        window.location = body.redirect_url;
      });
    }).catch(function () {
      // Transient network errors — keep polling.
      setTimeout(tick, {{.PollIntervalMs}});
    });
  }
  tick();
})();
</script>
</body>
</html>`))

type qrPageData struct {
	SessionID      string
	QRDataB64      string
	PollIntervalMs int
	MaxAttempts    int
}

// renderQRPage is called from Authorize when display=qr. It allocates a
// desktop session, builds the wallet Universal Link (with desktop_session_id
// + the existing challenge + state), renders the QR + polling page, and
// writes it to w. Returns an error so the caller can decide how to fail
// (errors are non-recoverable — render 500).
func renderQRPage(
	w http.ResponseWriter,
	r *http.Request,
	challengeNonce, clientID, redirectURI, state string,
) error {
	sid, err := randomHex(32)
	if err != nil {
		return errors.Wrap(err, "generate desktop session id")
	}

	if err := DB(r).DesktopSessions().Insert(data.DesktopSession{
		ID:          sid,
		ClientID:    clientID,
		RedirectURI: redirectURI,
		State:       state,
		ChallengeNonce: challengeNonce,
		ExpiresAt:   time.Now().UTC().Add(desktopSessionTTL),
	}); err != nil {
		return errors.Wrap(err, "insert desktop session")
	}

	// Universal Link the wallet should open when the QR is scanned. Mirrors
	// the same params as the same-device redirect in Authorize(), plus the
	// desktop_session_id the wallet uses to call back to QRComplete.
	dl := Deeplink(r)
	deepLink, err := url.Parse(dl.UniversalLinkBase)
	if err != nil {
		return errors.Wrap(err, "parse deeplink base")
	}
	dq := deepLink.Query()
	dq.Set("challenge", challengeNonce)
	dq.Set("client_id", clientID)
	dq.Set("state", state)
	dq.Set("desktop_session_id", sid)
	// `desktop_origin` discriminates the rendezvous target so the wallet
	// knows where to POST the auth code once verify succeeds. Legacy Taraaz
	// QRs omit this and the wallet falls back to AGORA_ORIGIN; "sso" routes
	// the callback to /v1/authorize/qr/complete on sso-svc itself.
	dq.Set("desktop_origin", "sso")
	dq.Set("api_url", requestScheme(r)+"://"+r.Host)
	deepLink.RawQuery = dq.Encode()

	// Server-render the QR. Medium error correction is a good fit for screens;
	// the payload is small (~200 bytes) so the matrix stays scannable at 280px.
	png, err := qrcode.Encode(deepLink.String(), qrcode.Medium, 512)
	if err != nil {
		return errors.Wrap(err, "encode qr png")
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("Content-Security-Policy",
		"default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'self'")

	maxAttempts := int(desktopSessionTTL/time.Millisecond) / qrPollIntervalMs
	return qrPageTemplate.Execute(w, qrPageData{
		SessionID:      sid,
		QRDataB64:      base64.StdEncoding.EncodeToString(png),
		PollIntervalMs: qrPollIntervalMs,
		MaxAttempts:    maxAttempts,
	})
}

// QRPoll handles GET /v1/authorize/qr/poll?sid=<sid>.
//
// Responses:
//
//	204 No Content — wallet has not bound a code yet, keep polling.
//	200 {"redirect_url": "..."} — code bound; the desktop should navigate
//	    there. The session is atomically marked consumed (one-shot).
//	410 Gone — session expired, was never created, or already consumed.
//	400 — missing sid.
func QRPoll(w http.ResponseWriter, r *http.Request) {
	sid := r.URL.Query().Get("sid")
	if sid == "" {
		ape.RenderErr(w, problems.BadRequest(errors.New("sid is required"))...)
		return
	}

	// Try the atomic consume first — succeeds iff code is bound, not consumed,
	// not expired. We only fall back to GetByID to disambiguate 204 vs 410.
	sess, err := DB(r).DesktopSessions().ConsumePoll(sid)
	if err != nil {
		Log(r).WithError(err).Error("qr poll: consume desktop session")
		ape.RenderErr(w, problems.InternalError())
		return
	}
	if sess != nil && sess.Code != nil {
		redirect, err := url.Parse(sess.RedirectURI)
		if err != nil {
			Log(r).WithError(err).Error("qr poll: parse redirect_uri")
			ape.RenderErr(w, problems.InternalError())
			return
		}
		rq := redirect.Query()
		rq.Set("code", *sess.Code)
		rq.Set("state", sess.State)
		redirect.RawQuery = rq.Encode()

		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{"redirect_url": redirect.String()})
		return
	}

	// Disambiguate: 204 (pending) vs 410 (gone). A consumed/expired session
	// should not be confused with one that's still pending.
	existing, err := DB(r).DesktopSessions().GetByID(sid)
	if err != nil {
		Log(r).WithError(err).Error("qr poll: lookup desktop session")
		ape.RenderErr(w, problems.InternalError())
		return
	}
	if existing == nil || existing.Consumed || existing.ExpiresAt.Before(time.Now().UTC()) {
		w.Header().Set("Cache-Control", "no-store")
		http.Error(w, "session expired", http.StatusGone)
		return
	}

	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(http.StatusNoContent)
}

type qrCompleteRequest struct {
	SessionID string `json:"session_id"`
	Code      string `json:"code"`
}

// QRComplete handles POST /v1/authorize/qr/complete.
//
// Wallet posts {session_id, code} after a successful /v1/authorize/verify
// when the deep link carried a desktop_session_id. Binds the auth code to
// the session row so the desktop's next poll can pick it up.
//
// Responses:
//
//	200 {} — bound.
//	400 — bad body.
//	409 — session already bound, consumed, or expired.
func QRComplete(w http.ResponseWriter, r *http.Request) {
	var req qrCompleteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		ape.RenderErr(w, problems.BadRequest(errors.Wrap(err, "decode body"))...)
		return
	}
	if req.SessionID == "" || req.Code == "" {
		ape.RenderErr(w, problems.BadRequest(
			errors.New("session_id and code are required"))...)
		return
	}

	bound, err := DB(r).DesktopSessions().BindCode(req.SessionID, req.Code)
	if err != nil {
		Log(r).WithError(err).Error("qr complete: bind desktop session")
		ape.RenderErr(w, problems.InternalError())
		return
	}
	if bound == nil {
		// Idempotency: if the same code is already bound on an active session,
		// treat this as success so duplicate mobile submits don't surface errors.
		existing, lookupErr := DB(r).DesktopSessions().GetByID(req.SessionID)
		if lookupErr != nil {
			Log(r).WithError(lookupErr).Error("qr complete: lookup desktop session")
			ape.RenderErr(w, problems.InternalError())
			return
		}
		if existing != nil && !existing.Consumed && existing.ExpiresAt.After(time.Now().UTC()) &&
			existing.Code != nil && *existing.Code == req.Code {
			w.Header().Set("Cache-Control", "no-store")
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(struct{}{})
			return
		}

		// Row is either missing, already has a different code, already consumed,
		// or expired. We don't leak which — Conflict covers them all.
		http.Error(w, "session not bindable", http.StatusConflict)
		return
	}

	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(struct{}{})
}

// requestScheme returns the request's external scheme, honouring X-Forwarded-Proto.
func requestScheme(r *http.Request) string {
	if proto := r.Header.Get("X-Forwarded-Proto"); proto != "" {
		return proto
	}
	if r.TLS != nil {
		return "https"
	}
	return "http"
}
