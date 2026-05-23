package jwt

import (
	"fmt"
	"time"

	jwtlib "github.com/golang-jwt/jwt/v5"
)

const (
	AuthorizationHeaderName = "Authorization"
	BearerTokenPrefix       = "Bearer "

	AccessTokenType  = "access"
	RefreshTokenType = "refresh"
	// IDTokenType is issued only when an /v1/tokens/exchange request includes
	// scope=openid (Phase 1.5).
	IDTokenType = "id"

	claimType     = "token_type"
	claimSub      = "sub"
	claimClientID = "client_id"
)

// AuthClaim is the minimal claim set carried in our access / refresh tokens.
//
// Invariant: Subject is always the per-RP pairwise subject ("ps_…"). Never
// the wallet address. Trust signals (zk_verified, etc.) are NOT in the JWT —
// /v1/tokens/validate and /v1/userinfo fetch them live from the assertions
// table so revocations take effect immediately.
type AuthClaim struct {
	Subject  string
	ClientID string
	Type     string
}

// JWTIssuer signs and verifies our access / refresh / id tokens.
//
// As of Phase 1.1 we use RS256 (asymmetric) so relying parties can verify
// tokens against the public JWKS at /.well-known/jwks.json without sharing a
// symmetric secret. Two keypairs are held at all times:
//
//   - current  — signs every new token; its kid is set in the JWT header.
//   - previous — optional; accepted for verification only, never used for
//     signing. This lets us rotate the signing key without invalidating
//     tokens still inside their TTL.
//
// During a normal rotation:
//  1. Generate a new keypair, promote it to `current`, demote the old
//     current to `previous`. Restart sso-svc.
//  2. After refresh_expiration_time has elapsed, drop the `previous` key.
//     Restart sso-svc again.
type JWTIssuer struct {
	current  Keypair
	previous *Keypair // nil during normal steady-state operation

	accessExpiration  time.Duration
	refreshExpiration time.Duration
}

// NewIssuer is the constructor production config uses (via the figure
// loader) and that tests in sibling packages can call directly when they
// already have keypairs in hand. The unexported fields stay unexported —
// downstream code goes through the public methods on the returned issuer.
func NewIssuer(current Keypair, previous *Keypair, accessExp, refreshExp time.Duration) *JWTIssuer {
	return &JWTIssuer{
		current:           current,
		previous:          previous,
		accessExpiration:  accessExp,
		refreshExpiration: refreshExp,
	}
}

// JWKS returns the public keys to expose at /.well-known/jwks.json.
// Current key is listed first so verifiers commonly hit it on the first try.
func (i *JWTIssuer) JWKS() map[string]any {
	keys := []map[string]any{i.current.JWK()}
	if i.previous != nil {
		keys = append(keys, i.previous.JWK())
	}
	return map[string]any{"keys": keys}
}

// CurrentKID returns the kid stamped into every freshly-issued token.
func (i *JWTIssuer) CurrentKID() string {
	return i.current.KID
}

func (i *JWTIssuer) IssueJWT(claim *AuthClaim) (token string, exp time.Time, err error) {
	exp = time.Now().UTC()

	claims := jwtlib.MapClaims{
		claimSub:      claim.Subject,
		claimClientID: claim.ClientID,
		claimType:     claim.Type,
	}

	switch claim.Type {
	case AccessTokenType, IDTokenType:
		// ID tokens inherit the access-token lifetime; they are short-lived
		// proofs of authentication, not long-lived session anchors.
		exp = exp.Add(i.accessExpiration)
	case RefreshTokenType:
		exp = exp.Add(i.refreshExpiration)
	default:
		err = fmt.Errorf("unknown token type: %s", claim.Type)
		return
	}

	claims["exp"] = exp.Unix()
	claims["iat"] = time.Now().UTC().Unix()

	tok := jwtlib.NewWithClaims(jwtlib.SigningMethodRS256, claims)
	// kid header lets verifiers pick the right public key from JWKS.
	tok.Header["kid"] = i.current.KID
	token, err = tok.SignedString(i.current.Private)
	return
}

// IssueIDToken signs an OpenID Connect ID Token (OIDC Core §2).
//
// Base claims (sub, client_id, token_type, exp, iat) are produced the same
// way as IssueJWT(IDTokenType); the `extra` map is merged in so callers can
// add iss/aud/nonce/zk_verified/circuit_id/matrix_localpart per OIDC rules.
// Caller-provided keys override defaults — intentional, because the caller
// knows the canonical iss/aud values.
func (i *JWTIssuer) IssueIDToken(claim *AuthClaim, extra map[string]any) (token string, exp time.Time, err error) {
	exp = time.Now().UTC().Add(i.accessExpiration)

	claims := jwtlib.MapClaims{
		claimSub:      claim.Subject,
		claimClientID: claim.ClientID,
		claimType:     IDTokenType,
		"exp":         exp.Unix(),
		"iat":         time.Now().UTC().Unix(),
	}
	for k, v := range extra {
		claims[k] = v
	}

	tok := jwtlib.NewWithClaims(jwtlib.SigningMethodRS256, claims)
	tok.Header["kid"] = i.current.KID
	token, err = tok.SignedString(i.current.Private)
	return
}

func (i *JWTIssuer) ValidateJWT(str string) (*AuthClaim, error) {
	token, err := jwtlib.Parse(str, func(t *jwtlib.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwtlib.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		// Pick the verification key by kid header. Missing kid falls back to
		// the current key — a kindness to any token we issued before kid
		// stamping landed; new tokens always carry kid.
		kid, _ := t.Header["kid"].(string)
		if kid == "" || kid == i.current.KID {
			return i.current.Public(), nil
		}
		if i.previous != nil && kid == i.previous.KID {
			return i.previous.Public(), nil
		}
		return nil, fmt.Errorf("unknown kid: %s", kid)
	}, jwtlib.WithExpirationRequired())
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwtlib.MapClaims)
	if !ok {
		return nil, fmt.Errorf("failed to unwrap claims")
	}

	sub, _ := claims[claimSub].(string)
	cid, _ := claims[claimClientID].(string)
	typ, _ := claims[claimType].(string)

	if sub == "" || typ == "" {
		return nil, fmt.Errorf("malformed token: missing required claims")
	}

	return &AuthClaim{
		Subject:  sub,
		ClientID: cid,
		Type:     typ,
	}, nil
}
