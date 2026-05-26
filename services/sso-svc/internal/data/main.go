package data

import (
	"time"
)

// ─────────────────────────────────────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────────────────────────────────────

type Wallet struct {
	ID            string    `db:"id"`
	WalletAddress string    `db:"wallet_address"`
	PublicKeyX    string    `db:"public_key_x"`
	PublicKeyY    string    `db:"public_key_y"`
	RegisteredAt  time.Time `db:"registered_at"`
}

type AppCredential struct {
	ID                string    `db:"id"`
	WalletID          string    `db:"wallet_id"`
	Platform          string    `db:"platform"`
	CredentialID      string    `db:"credential_id"`
	AttestationKeyID  string    `db:"attestation_key_id"`
	AttestationStatus string    `db:"attestation_status"`
	AttestedAt        time.Time `db:"attested_at"`
	LastVerifiedAt    time.Time `db:"last_verified_at"`
}

type Assertion struct {
	ID            string     `db:"id"`
	WalletID      string     `db:"wallet_id"`
	AssertionType string     `db:"assertion_type"`
	Status        bool       `db:"status"`
	NullifierHash []byte     `db:"nullifier_hash"`
	Source        string     `db:"source"`
	IssuedAt      time.Time  `db:"issued_at"`
	ExpiresAt     *time.Time `db:"expires_at"`
}

type PairwiseSubject struct {
	ID        string    `db:"id"`
	WalletID  string    `db:"wallet_id"`
	ClientID  string    `db:"client_id"`
	Subject   string    `db:"subject"`
	// MatrixLocalpart is the optional Matrix Authentication Service localpart
	// claim — set lazily by MAS provisioning, never derived here. Empty for
	// non-Matrix clients.
	MatrixLocalpart string    `db:"matrix_localpart"`
	CreatedAt       time.Time `db:"created_at"`
}

type SSOClient struct {
	ID           string    `db:"id"`
	Name         string    `db:"name"`
	LogoURL      *string   `db:"logo_url"`
	RedirectURIs []string  `db:"redirect_uris"`
	ClientSecret string    `db:"client_secret"`
	ZKRequired   bool      `db:"zk_required"`
	// RequiresDifcongress gates /v1/authorize/verify on the wallet carrying a
	// live `difcongress_member` assertion. Stamped by the DIFCongress signup
	// worker via POST /v1/admin/assertions. Never embedded in tokens.
	RequiresDifcongress bool      `db:"requires_difcongress"`
	CreatedAt           time.Time `db:"created_at"`
}

type SSOChallenge struct {
	Nonce         string    `db:"nonce"`
	ClientID      string    `db:"client_id"`
	RedirectURI   string    `db:"redirect_uri"`
	State         string    `db:"state"`
	CodeChallenge string    `db:"code_challenge"`
	// OIDCNonce is the optional `nonce` parameter from OIDC Core 1.0 §3.1.2.1.
	// NOT to be confused with the row's `Nonce` primary key, which is an
	// internal session id.
	OIDCNonce string `db:"oidc_nonce"`
	// Scope is the raw space-separated `scope` request param from /v1/authorize.
	// Presence of `openid` toggles ID token issuance at /v1/tokens/exchange.
	Scope     string    `db:"scope"`
	ExpiresAt time.Time `db:"expires_at"`
	Used      bool      `db:"used"`
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository interfaces
// ─────────────────────────────────────────────────────────────────────────────

type WalletsQ interface {
	// Insert creates a new wallet row. Returns the created row.
	Insert(w Wallet) (Wallet, error)
	// GetByAddress returns the wallet with the given walletAddress, or nil.
	GetByAddress(walletAddress string) (*Wallet, error)
	// IsBannedByID reports whether the wallet has a non-NULL banned_at
	// timestamp. A non-existent wallet returns (false, nil) — ban is a
	// soft-delete, not an identity check.
	IsBannedByID(walletID string) (bool, error)
}

type AppCredentialsQ interface {
	// Insert creates a new app credential row.
	Insert(c AppCredential) (AppCredential, error)
	// RevokeByWallet marks all credentials for a wallet+platform as revoked.
	RevokeByWallet(walletID, platform string) error
	// GetActiveByWallet returns the current verified credential for a wallet+platform.
	GetActiveByWallet(walletID, platform string) (*AppCredential, error)
}

type AssertionsQ interface {
	// Insert creates a new assertion row.
	Insert(a Assertion) (Assertion, error)
	// GetByWalletAndType returns the latest assertion of the given type for a wallet.
	GetByWalletAndType(walletID, assertionType string) (*Assertion, error)
	// GetLatestByNullifier returns the most recent assertion (any status, any age)
	// carrying the given nullifier_hash, or nil if none exists. Used by
	// /v1/wallets/recover to map a re-proven nullifier back to its prior wallet.
	GetLatestByNullifier(nullifierHash []byte) (*Assertion, error)
}

type PairwiseSubjectsQ interface {
	// Upsert inserts or returns the existing pairwise subject for wallet+client.
	Upsert(ps PairwiseSubject) (PairwiseSubject, error)
	// GetBySubject looks up a pairwise subject row by its subject string.
	GetBySubject(subject string) (*PairwiseSubject, error)
}

type SSOClientsQ interface {
	// GetByID returns the SSO client config, or nil if not found.
	GetByID(clientID string) (*SSOClient, error)
}

type SSOChallengesQ interface {
	// Insert stores a new challenge nonce.
	Insert(c SSOChallenge) error
	// Consume marks a challenge as used and returns it. Returns nil if not found, expired, or already used.
	Consume(nonce string) (*SSOChallenge, error)
	// DeleteExpired purges expired challenges (called from a background job or on demand).
	DeleteExpired() error
}

// WalletChallenge is a short-lived nonce issued for wallet registration (M2).
// Kept separate from SSOChallenge because registration has no client_id / PKCE.
type WalletChallenge struct {
	Nonce     string    `db:"nonce"`
	Platform  string    `db:"platform"`
	ExpiresAt time.Time `db:"expires_at"`
	Used      bool      `db:"used"`
}

type WalletChallengesQ interface {
	// Insert stores a new wallet registration challenge.
	Insert(c WalletChallenge) error
	// Consume atomically marks the nonce as used and returns it.
	// Returns nil (no error) when the nonce is not found, already used, or expired.
	Consume(nonce string) (*WalletChallenge, error)
}

// AuthCode is a one-time authorization code issued by /v1/authorize/verify
// and consumed by /v1/tokens/exchange (auth-code + PKCE flow, M3).
type AuthCode struct {
	Code            string    `db:"code"`
	ClientID        string    `db:"client_id"`
	PairwiseSubject string    `db:"pairwise_subject"`
	CodeChallenge   string    `db:"code_challenge"`
	// OIDCNonce carries the nonce forward from sso_challenges so the ID token
	// can echo it. Empty for non-OIDC flows.
	OIDCNonce string `db:"oidc_nonce"`
	// Scope carries the original /v1/authorize scope forward so exchange can
	// gate ID token issuance on `openid`.
	Scope     string    `db:"scope"`
	ExpiresAt time.Time `db:"expires_at"`
	Used      bool      `db:"used"`
	CreatedAt time.Time `db:"created_at"`
}

type AuthCodesQ interface {
	// Insert stores a new auth code.
	Insert(c AuthCode) error
	// Consume atomically marks the code as used and returns it.
	// Returns nil (no error) when the code is not found, already used, or expired.
	Consume(code string) (*AuthCode, error)
}

// DesktopSession holds the desktop browser's pending auth-code rendezvous
// (Phase 1.9 cross-device QR flow). The desktop creates it at /v1/authorize
// (when display=qr), then polls /v1/authorize/qr/poll. The wallet binds an
// auth code via /v1/authorize/qr/complete after a normal verify.
type DesktopSession struct {
	ID          string    `db:"id"`
	ClientID    string    `db:"client_id"`
	RedirectURI string    `db:"redirect_uri"`
	State       string    `db:"state"`
	// ChallengeNonce links this desktop rendezvous row to the /v1/authorize
	// nonce rendered into the QR payload. It lets /v1/authorize/verify auto-bind
	// the auth code even if the wallet does not call /v1/authorize/qr/complete.
	ChallengeNonce string `db:"challenge_nonce"`
	// Code is NULL until the wallet completes verify + binds.
	Code      *string   `db:"code"`
	CreatedAt time.Time `db:"created_at"`
	ExpiresAt time.Time `db:"expires_at"`
	Consumed  bool      `db:"consumed"`
}

type DesktopSessionsQ interface {
	// Insert stores a new session row.
	Insert(s DesktopSession) error
	// GetByID returns the session by id (regardless of consumed/expired).
	GetByID(id string) (*DesktopSession, error)
	// BindCode atomically attaches an auth code to the session iff the row
	// exists, has not been consumed, has no code yet, and has not expired.
	// Returns the bound session, or nil if the session is not in a bindable
	// state (the caller should treat that as a 4xx).
	BindCode(id, code string) (*DesktopSession, error)
	// BindCodeByChallenge atomically attaches an auth code to the first pending
	// desktop session row that was created for this authorize challenge nonce.
	// Returns nil when no eligible session exists.
	BindCodeByChallenge(challengeNonce, code string) (*DesktopSession, error)
	// ConsumePoll atomically returns the bound code and marks the session
	// consumed. Returns nil if the session has no code yet, has already been
	// consumed, or has expired.
	ConsumePoll(id string) (*DesktopSession, error)
}

// MatrixPendingInvite tracks a fire-and-forget Synapse Admin API call
// (force-join a user into a room). The row is inserted before the goroutine
// is spawned; on success the goroutine deletes the row; on failure it
// increments attempts so a future retry worker can inspect or re-drive it.
type MatrixPendingInvite struct {
	ID        int64     `db:"id"`
	UserID    string    `db:"user_id"`
	RoomID    string    `db:"room_id"`
	Action    string    `db:"action"`
	Attempts  int       `db:"attempts"`
	LastError string    `db:"last_error"`
	CreatedAt time.Time `db:"created_at"`
}

type MatrixPendingInvitesQ interface {
	// Insert stores a pending invite row and returns its auto-generated id.
	Insert(userID, roomID, action string) (int64, error)
	// Delete removes a row that was completed successfully.
	Delete(id int64) error
	// IncrementAttempts bumps the attempt counter and records the last error.
	IncrementAttempts(id int64, lastError string) error
}
