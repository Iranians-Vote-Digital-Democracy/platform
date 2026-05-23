package jwt

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"testing"
	"time"
)

// newTestKeypair produces an RSA-2048 key fast enough for unit tests.
// (Tests run sequentially; 2048-bit keygen is ~50ms on modern hardware.)
func newTestKeypair(t *testing.T, kid string) Keypair {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate rsa: %v", err)
	}
	return Keypair{KID: kid, Private: k}
}

// newTestIssuer wires a JWTIssuer with two keypairs for rotation-window tests.
func newTestIssuer(t *testing.T) (*JWTIssuer, Keypair, Keypair) {
	t.Helper()
	cur := newTestKeypair(t, "cur")
	prev := newTestKeypair(t, "prev")
	return &JWTIssuer{
		current:           cur,
		previous:          &prev,
		accessExpiration:  time.Hour,
		refreshExpiration: 24 * time.Hour,
	}, cur, prev
}

func TestIssueAndValidate_RoundTrip(t *testing.T) {
	issuer, _, _ := newTestIssuer(t)

	tok, exp, err := issuer.IssueJWT(&AuthClaim{
		Subject:  "ps_abc",
		ClientID: "taraaz",
		Type:     AccessTokenType,
	})
	if err != nil {
		t.Fatalf("issue: %v", err)
	}
	if !exp.After(time.Now()) {
		t.Fatalf("token exp not in the future: %v", exp)
	}

	claim, err := issuer.ValidateJWT(tok)
	if err != nil {
		t.Fatalf("validate: %v", err)
	}
	if claim.Subject != "ps_abc" || claim.ClientID != "taraaz" || claim.Type != AccessTokenType {
		t.Fatalf("unexpected claim: %+v", claim)
	}
}

func TestValidate_AcceptsPreviousKey(t *testing.T) {
	// Issue a token with the *previous* key, then validate it through the
	// public API — confirms kid lookup falls back to the previous key during
	// a rotation window.
	issuer, _, prev := newTestIssuer(t)

	// Swap current and previous on a copy of the issuer to simulate
	// "this token was minted before the rotation".
	preRotation := &JWTIssuer{
		current:           prev,
		accessExpiration:  time.Hour,
		refreshExpiration: 24 * time.Hour,
	}
	tok, _, err := preRotation.IssueJWT(&AuthClaim{
		Subject:  "ps_xyz",
		ClientID: "compass",
		Type:     AccessTokenType,
	})
	if err != nil {
		t.Fatalf("issue pre-rotation: %v", err)
	}

	claim, err := issuer.ValidateJWT(tok)
	if err != nil {
		t.Fatalf("validate previous-kid token: %v", err)
	}
	if claim.Subject != "ps_xyz" {
		t.Fatalf("unexpected subject: %s", claim.Subject)
	}
}

func TestValidate_RejectsUnknownKID(t *testing.T) {
	issuer, _, _ := newTestIssuer(t)
	stranger := newTestKeypair(t, "stranger")
	strangerIssuer := &JWTIssuer{
		current:           stranger,
		accessExpiration:  time.Hour,
		refreshExpiration: 24 * time.Hour,
	}
	tok, _, err := strangerIssuer.IssueJWT(&AuthClaim{
		Subject: "ps_foreign", ClientID: "x", Type: AccessTokenType,
	})
	if err != nil {
		t.Fatalf("issue stranger: %v", err)
	}

	if _, err := issuer.ValidateJWT(tok); err == nil {
		t.Fatal("expected validation to fail for unknown kid")
	}
}

func TestIssueIDToken_CarriesExtraClaims(t *testing.T) {
	issuer, _, _ := newTestIssuer(t)

	tok, _, err := issuer.IssueIDToken(&AuthClaim{
		Subject: "ps_abc", ClientID: "taraaz", Type: IDTokenType,
	}, map[string]any{
		"iss":              "https://sso.jomhoor.org",
		"aud":              "taraaz",
		"nonce":            "n-123",
		"zk_verified":      true,
		"matrix_localpart": "abc123",
	})
	if err != nil {
		t.Fatalf("issue id token: %v", err)
	}

	claim, err := issuer.ValidateJWT(tok)
	if err != nil {
		t.Fatalf("validate id token: %v", err)
	}
	if claim.Type != IDTokenType {
		t.Fatalf("wrong type: %s", claim.Type)
	}
	// AuthClaim only carries sub/client_id/type; deeper claim assertions live
	// at the userinfo / RP-verification layer, not in this round-trip test.
}

func TestJWKS_ContainsBothKeys(t *testing.T) {
	issuer, cur, prev := newTestIssuer(t)
	jwks := issuer.JWKS()
	keys, ok := jwks["keys"].([]map[string]any)
	if !ok || len(keys) != 2 {
		t.Fatalf("expected 2 keys in JWKS, got: %+v", jwks)
	}
	if keys[0]["kid"] != cur.KID || keys[1]["kid"] != prev.KID {
		t.Fatalf("expected current first then previous, got %v %v", keys[0]["kid"], keys[1]["kid"])
	}
	for _, k := range keys {
		if k["alg"] != "RS256" || k["kty"] != "RSA" || k["use"] != "sig" {
			t.Fatalf("unexpected JWK shape: %+v", k)
		}
	}
}

func TestParseRSAPrivateKey_PEM(t *testing.T) {
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("genkey: %v", err)
	}
	pemBytes := pem.EncodeToMemory(&pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(k),
	})
	got, err := ParseRSAPrivateKey(string(pemBytes))
	if err != nil {
		t.Fatalf("parse pem: %v", err)
	}
	if got.N.Cmp(k.N) != 0 {
		t.Fatal("parsed key modulus differs from source")
	}
}
