// Phase 1.6: OIDC UserInfo endpoint.
//
// /v1/userinfo is the OIDC Core 1.0 §5.3 endpoint. It accepts a valid access
// token (Bearer) and returns the same trust-bearing claim shape we put in the
// ID token, but read live from the DB at request time. This is the
// authoritative source for relying parties — the ID token is a momentary
// snapshot, UserInfo refreshes it.
//
// Invariants:
//   - `sub` is always the pairwise subject; never the wallet address.
//   - `zk_verified` is fetched live from the assertions table so revocations
//     are honoured immediately.
//   - We never include raw public keys or wallet metadata.
package handlers

import (
	"encoding/json"
	"net/http"

	"gitlab.com/distributed_lab/ape"
	"gitlab.com/distributed_lab/ape/problems"
)

// UserInfo handles GET /v1/userinfo.
//
// Auth: Bearer access token (validated by AuthMiddleware before reaching here).
// Response shape: { sub, iss, client_id, zk_verified?, matrix_localpart? }.
//
// Fields are intentionally omitted (not nulled) when absent so RPs can
// distinguish "unknown" from "known false" once we add explicitly-negative
// assertion states in the future.
func UserInfo(w http.ResponseWriter, r *http.Request) {
	claim := Claim(r)

	resp := map[string]any{
		"sub":       claim.Subject,
		"iss":       OIDC(r).IssuerURL(),
		"client_id": claim.ClientID,
	}

	// pairwise → wallet ID → assertions / matrix_localpart.
	ps, err := DB(r).PairwiseSubjects().GetBySubject(claim.Subject)
	if err != nil {
		Log(r).WithError(err).Error("userinfo: lookup pairwise subject")
		ape.RenderErr(w, problems.InternalError())
		return
	}
	if ps != nil {
		if ps.MatrixLocalpart != "" {
			resp["matrix_localpart"] = ps.MatrixLocalpart
		}
		assertion, err := DB(r).Assertions().GetByWalletAndType(ps.WalletID, "zk_verified")
		if err != nil {
			// Non-fatal: log + continue without the claim. We'd rather serve
			// the basic identity than 500 on a transient assertions lookup.
			Log(r).WithError(err).Warn("userinfo: lookup zk_verified assertion")
		} else if assertion != nil && assertion.Status {
			resp["zk_verified"] = true
		}
	}

	w.Header().Set("Content-Type", "application/json")
	// OIDC Core 1.0 §5.3.4 — UserInfo is per-user data; never cache.
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Pragma", "no-cache")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		Log(r).WithError(err).Error("userinfo: encode response")
	}
}
