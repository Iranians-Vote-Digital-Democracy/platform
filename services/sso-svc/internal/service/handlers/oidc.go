// OIDC discovery + JWKS endpoints (Phase 1.2 / 1.3).
//
// These two endpoints are the public contract that lets any OIDC-compliant
// relying party verify our tokens without bespoke integration code:
//
//   /.well-known/openid-configuration  — provider metadata, RFC 8414
//   /.well-known/jwks.json             — public verification keys, RFC 7517
//
// Both are served unauthenticated, cacheable, and CORS-allowed for the
// browsers that bootstrap OIDC libraries.
package handlers

import (
	"encoding/json"
	"net/http"
)

// oidcCacheSeconds — how long browsers and RP libraries may cache the
// discovery document and JWKS. Five minutes is the OIDC community default;
// it bounds the window for a key rotation to propagate, while still cutting
// the request rate by ~99% for typical RP fleets.
const oidcCacheSeconds = 300

// OIDCDiscovery serves /.well-known/openid-configuration.
//
// Per OpenID Connect Discovery 1.0 §3, this document tells relying parties
// where every other endpoint lives, what signing algorithms we use, and
// which scopes/claims they can request. Keep this list in sync with what
// the rest of sso-svc actually supports — RPs reject responses that violate
// what discovery promised.
func OIDCDiscovery(w http.ResponseWriter, r *http.Request) {
	iss := OIDC(r).IssuerURL()

	doc := map[string]any{
		"issuer":                                iss,
		"authorization_endpoint":                iss + "/v1/authorize",
		"token_endpoint":                        iss + "/v1/tokens/exchange",
		"userinfo_endpoint":                     iss + "/v1/userinfo",
		"jwks_uri":                              iss + "/.well-known/jwks.json",
		"response_types_supported":              []string{"code"},
		"subject_types_supported":               []string{"pairwise"},
		"id_token_signing_alg_values_supported": []string{"RS256"},
		"scopes_supported":                      []string{"openid", "profile"},
		// claims_supported is advisory; we always emit `sub`, conditionally
		// emit `zk_verified`/`circuit_id`/`matrix_localpart` based on the
		// wallet's assertions and the client config.
		"claims_supported": []string{
			"sub", "iss", "aud", "exp", "iat", "nonce",
			"zk_verified", "circuit_id", "matrix_localpart",
		},
		"grant_types_supported": []string{"authorization_code", "refresh_token"},
		// We accept client credentials in the JSON body of /v1/tokens/exchange.
		// The closest standard mapping is client_secret_post.
		"token_endpoint_auth_methods_supported": []string{"client_secret_post"},
		"code_challenge_methods_supported":      []string{"S256"},
	}

	writeOIDCJSON(w, r, doc)
}

// JWKS serves /.well-known/jwks.json — the public counterparts of the keys
// that sign our access / refresh / id tokens. Two keypairs are exposed during
// a rotation window (current + previous) so tokens minted just before a
// rollover still verify; outside rotation the response carries one key.
func JWKS(w http.ResponseWriter, r *http.Request) {
	writeOIDCJSON(w, r, JWT(r).JWKS())
}

// writeOIDCJSON is the shared response shape for both well-known endpoints.
// Both should be publicly cacheable (no secrets in either) and CORS-open so
// SPAs can fetch them before posting a token to their own backend.
func writeOIDCJSON(w http.ResponseWriter, r *http.Request, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "public, max-age=300")
	// OIDC RP libraries fetch these from JS contexts. The documents contain
	// no secrets, so a wildcard origin is safe.
	w.Header().Set("Access-Control-Allow-Origin", "*")
	_ = oidcCacheSeconds // keep the named constant referenced for future tuning
	if err := json.NewEncoder(w).Encode(body); err != nil {
		Log(r).WithError(err).Error("encode oidc well-known response")
	}
}
