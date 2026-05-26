// Q6 — POST /v1/admin/assertions.
//
// Bearer-protected stamping endpoint used by the DIFCongress signup worker.
// On successful membership signup the worker calls this with the user's
// wallet address and assertion_type=difcongress_member, status=true.
//
// The handler is deliberately schema-agnostic over `assertion_type` so the
// same surface can be reused for future externally-stamped assertions
// (e.g. "diaspora_voter", "kyc_bank") without code churn. Whitelisting is
// done here to refuse arbitrary types — the worker should only stamp types
// sso-svc actually consumes.
//
// The endpoint MUST never accept `zk_verified` here — that assertion type
// has its own crypto-verified surface at POST /v1/assertions/zk and stamping
// it via shared admin token would collapse the M2.5 trust boundary.
package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/jomhoor/sso-svc/internal/data"
	"github.com/pkg/errors"
	"gitlab.com/distributed_lab/ape"
	"gitlab.com/distributed_lab/ape/problems"
)

// adminStampableAssertionTypes is the closed set of assertion_type values
// the admin endpoint will write. zk_verified is intentionally excluded —
// it has its own crypto-verified path.
var adminStampableAssertionTypes = map[string]struct{}{
	"difcongress_member": {},
}

// adminAssertionRequest accepts EITHER `wallet_address` (internal tools that
// know the raw address) OR `subject` + `client_id` (relying-party workers
// that only ever see the pairwise subject — the M2.5 privacy boundary keeps
// raw wallet addresses out of RP hands). Exactly one of the two forms must
// be supplied; the handler resolves both to a wallet_id before insert.
type adminAssertionRequest struct {
	WalletAddress string `json:"wallet_address,omitempty"`
	Subject       string `json:"subject,omitempty"`
	ClientID      string `json:"client_id,omitempty"`

	AssertionType string `json:"assertion_type"`
	Status        bool   `json:"status"`
	Source        string `json:"source"`
	// ExpiresAt is optional. When nil the assertion is persistent (no expiry).
	// RFC3339 string in JSON; omitted/empty fields are decoded as nil.
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
}

type adminAssertionResponse struct {
	ID            string     `json:"id"`
	WalletID      string     `json:"wallet_id"`
	AssertionType string     `json:"assertion_type"`
	Status        bool       `json:"status"`
	Source        string     `json:"source"`
	IssuedAt      time.Time  `json:"issued_at"`
	ExpiresAt     *time.Time `json:"expires_at,omitempty"`
}

// SubmitAdminAssertion handles POST /v1/admin/assertions.
//
// Responses:
//
//	200 — assertion inserted, body carries the persisted row.
//	400 — bad body, unknown wallet, or disallowed assertion_type.
//	401 — missing/wrong bearer token (handled by middleware).
//	503 — admin surface disabled (no token configured).
func SubmitAdminAssertion(w http.ResponseWriter, r *http.Request) {
	var req adminAssertionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		ape.RenderErr(w, problems.BadRequest(errors.Wrap(err, "decode body"))...)
		return
	}
	if req.AssertionType == "" || req.Source == "" {
		ape.RenderErr(w, problems.BadRequest(
			errors.New("assertion_type and source are required"))...)
		return
	}
	hasAddress := req.WalletAddress != ""
	hasSubject := req.Subject != "" && req.ClientID != ""
	if hasAddress == hasSubject {
		// Exclusive-or: caller must pick exactly one identification form.
		ape.RenderErr(w, problems.BadRequest(
			errors.New("supply exactly one of {wallet_address} or {subject, client_id}"))...)
		return
	}
	if _, ok := adminStampableAssertionTypes[req.AssertionType]; !ok {
		// Refuse arbitrary types — the admin surface is intentionally narrow.
		ape.RenderErr(w, problems.BadRequest(
			errors.Errorf("assertion_type %q is not admin-stampable", req.AssertionType))...)
		return
	}

	walletID, err := resolveAdminTargetWallet(r, req)
	if err != nil {
		Log(r).WithError(err).Error("admin: resolve target wallet")
		ape.RenderErr(w, problems.InternalError())
		return
	}
	if walletID == "" {
		// 400 rather than 404 — the caller supplied the identifier in the
		// body, not the URL, and "not found" is a payload problem.
		ape.RenderErr(w, problems.BadRequest(errors.New("unknown wallet identifier"))...)
		return
	}

	inserted, err := DB(r).Assertions().Insert(data.Assertion{
		WalletID:      walletID,
		AssertionType: req.AssertionType,
		Status:        req.Status,
		// NullifierHash is intentionally empty for admin-stamped assertions —
		// only crypto-verified types (zk_verified) carry one.
		Source:    req.Source,
		ExpiresAt: req.ExpiresAt,
	})
	if err != nil {
		Log(r).WithError(err).Error("admin: insert assertion")
		ape.RenderErr(w, problems.InternalError())
		return
	}

	Log(r).WithFields(map[string]interface{}{
		"wallet_id":      inserted.WalletID,
		"assertion_type": inserted.AssertionType,
		"status":         inserted.Status,
		"source":         inserted.Source,
	}).Info("admin: assertion stamped")

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(adminAssertionResponse{
		ID:            inserted.ID,
		WalletID:      inserted.WalletID,
		AssertionType: inserted.AssertionType,
		Status:        inserted.Status,
		Source:        inserted.Source,
		IssuedAt:      inserted.IssuedAt,
		ExpiresAt:     inserted.ExpiresAt,
	}); err != nil {
		Log(r).WithError(err).Error("admin: encode response")
	}
}

// resolveAdminTargetWallet returns the wallet_id for either input form, or
// the empty string when the identifier doesn't match a row. Errors are
// reserved for unexpected DB failures.
func resolveAdminTargetWallet(r *http.Request, req adminAssertionRequest) (string, error) {
	if req.WalletAddress != "" {
		wallet, err := DB(r).Wallets().GetByAddress(req.WalletAddress)
		if err != nil {
			return "", errors.Wrap(err, "lookup wallet by address")
		}
		if wallet == nil {
			return "", nil
		}
		return wallet.ID, nil
	}

	// Subject + client_id path. PairwiseSubjects rows are unique per pair,
	// so a single GetBySubject lookup is sufficient; we still verify the
	// client_id matches to catch typos / cross-client confusion.
	ps, err := DB(r).PairwiseSubjects().GetBySubject(req.Subject)
	if err != nil {
		return "", errors.Wrap(err, "lookup pairwise subject")
	}
	if ps == nil {
		return "", nil
	}
	if ps.ClientID != req.ClientID {
		// Caller asserted a (subject, client_id) pair that doesn't match
		// our records — refuse rather than silently stamping the wrong
		// wallet. Treated as "unknown" by the caller.
		Log(r).WithFields(map[string]interface{}{
			"asserted_client_id": req.ClientID,
			"actual_client_id":   ps.ClientID,
		}).Warn("admin: subject/client_id mismatch")
		return "", nil
	}
	return ps.WalletID, nil
}
