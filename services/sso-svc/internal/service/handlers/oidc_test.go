package handlers

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/jomhoor/sso-svc/internal/jwt"
	"github.com/jomhoor/sso-svc/internal/oidc"
	"gitlab.com/distributed_lab/logan/v3"
)

// makeIssuer builds a JWTIssuer with a fresh in-memory RSA keypair. We
// round-trip through PEM + ParseRSAPrivateKey so this test also exercises
// the PEM parser the production config relies on.
func makeIssuer(t *testing.T) *jwt.JWTIssuer {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("genkey: %v", err)
	}
	pemBytes := pem.EncodeToMemory(&pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(k),
	})
	parsed, err := jwt.ParseRSAPrivateKey(string(pemBytes))
	if err != nil {
		t.Fatalf("parse pem: %v", err)
	}
	return jwt.NewIssuer(jwt.Keypair{KID: "kT", Private: parsed}, nil, time.Hour, 24*time.Hour)
}

// withCtx mirrors the ctx wiring CtxMiddleware does in production so the
// handler getters don't panic.
func withCtx(r *http.Request, issuer *jwt.JWTIssuer, cfg *oidc.Config) *http.Request {
	ctx := r.Context()
	ctx = context.WithValue(ctx, logCtxKey, logan.New())
	ctx = context.WithValue(ctx, jwtCtxKey, issuer)
	ctx = context.WithValue(ctx, oidcCtxKey, cfg)
	return r.WithContext(ctx)
}

func TestOIDCDiscovery_Shape(t *testing.T) {
	issuer := makeIssuer(t)
	cfg := &oidc.Config{Issuer: "https://sso.jomhoor.org"}

	req := withCtx(httptest.NewRequest(http.MethodGet, "/.well-known/openid-configuration", nil), issuer, cfg)
	w := httptest.NewRecorder()
	OIDCDiscovery(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status: %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("content-type: %s", ct)
	}

	var doc map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &doc); err != nil {
		t.Fatalf("decode: %v", err)
	}

	expectString(t, doc, "issuer", "https://sso.jomhoor.org")
	expectString(t, doc, "authorization_endpoint", "https://sso.jomhoor.org/v1/authorize")
	expectString(t, doc, "token_endpoint", "https://sso.jomhoor.org/v1/tokens/exchange")
	expectString(t, doc, "userinfo_endpoint", "https://sso.jomhoor.org/v1/userinfo")
	expectString(t, doc, "jwks_uri", "https://sso.jomhoor.org/.well-known/jwks.json")
	expectStringInList(t, doc, "response_types_supported", "code")
	expectStringInList(t, doc, "subject_types_supported", "pairwise")
	expectStringInList(t, doc, "id_token_signing_alg_values_supported", "RS256")
	expectStringInList(t, doc, "code_challenge_methods_supported", "S256")
	expectStringInList(t, doc, "scopes_supported", "openid")
	expectStringInList(t, doc, "claims_supported", "matrix_localpart")
}

func TestOIDCDiscovery_TrimsTrailingSlash(t *testing.T) {
	issuer := makeIssuer(t)
	cfg := &oidc.Config{Issuer: "https://sso.jomhoor.org/"}

	req := withCtx(httptest.NewRequest(http.MethodGet, "/.well-known/openid-configuration", nil), issuer, cfg)
	w := httptest.NewRecorder()
	OIDCDiscovery(w, req)

	var doc map[string]any
	_ = json.Unmarshal(w.Body.Bytes(), &doc)
	expectString(t, doc, "issuer", "https://sso.jomhoor.org")
	expectString(t, doc, "jwks_uri", "https://sso.jomhoor.org/.well-known/jwks.json")
}

func TestJWKS_Shape(t *testing.T) {
	issuer := makeIssuer(t)
	cfg := &oidc.Config{Issuer: "https://sso.jomhoor.org"}

	req := withCtx(httptest.NewRequest(http.MethodGet, "/.well-known/jwks.json", nil), issuer, cfg)
	w := httptest.NewRecorder()
	JWKS(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status: %d", w.Code)
	}
	var doc map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &doc); err != nil {
		t.Fatalf("decode: %v", err)
	}
	keys, ok := doc["keys"].([]any)
	if !ok || len(keys) != 1 {
		t.Fatalf("expected 1 key, got: %+v", doc)
	}
	first, _ := keys[0].(map[string]any)
	if first["alg"] != "RS256" || first["kty"] != "RSA" || first["use"] != "sig" {
		t.Fatalf("unexpected JWK: %+v", first)
	}
	if _, ok := first["n"].(string); !ok {
		t.Fatal("missing modulus n")
	}
	if _, ok := first["e"].(string); !ok {
		t.Fatal("missing exponent e")
	}
}

// ── helpers ───────────────────────────────────────────────────────────────────

func expectString(t *testing.T, doc map[string]any, key, want string) {
	t.Helper()
	got, _ := doc[key].(string)
	if got != want {
		t.Fatalf("doc[%q] = %q, want %q", key, got, want)
	}
}

func expectStringInList(t *testing.T, doc map[string]any, key, want string) {
	t.Helper()
	raw, ok := doc[key].([]any)
	if !ok {
		t.Fatalf("doc[%q] not a list: %T", key, doc[key])
	}
	for _, item := range raw {
		if s, _ := item.(string); s == want {
			return
		}
	}
	t.Fatalf("%q missing from doc[%q]: %+v", want, key, raw)
}
