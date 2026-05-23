package jwt

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"math/big"
	"strings"

	"github.com/pkg/errors"
)

// Keypair is a single RSA signing key, identified by a stable kid.
//
// The kid (key id) lets JWT consumers and the JWKS endpoint distinguish between
// the current signing key and any previous keys still accepted for validation
// during rotation.
type Keypair struct {
	KID     string
	Private *rsa.PrivateKey
}

// Public returns the RSA public key for this keypair. Convenience wrapper.
func (k *Keypair) Public() *rsa.PublicKey {
	return &k.Private.PublicKey
}

// JWK returns the public key serialized as a JSON Web Key (RFC 7517).
// Field order is irrelevant to the spec, but we emit n/e last because the
// modulus is long and that keeps log lines readable.
func (k *Keypair) JWK() map[string]any {
	pub := k.Public()
	return map[string]any{
		"kty": "RSA",
		"use": "sig",
		"alg": "RS256",
		"kid": k.KID,
		"n":   base64.RawURLEncoding.EncodeToString(pub.N.Bytes()),
		"e":   base64.RawURLEncoding.EncodeToString(big.NewInt(int64(pub.E)).Bytes()),
	}
}

// ParseRSAPrivateKey accepts an RSA private key in any of these forms:
//   - PEM literal ("-----BEGIN RSA PRIVATE KEY-----\n…")
//   - PEM with literal "\n" sequences (common when the PEM is stored in an env var)
//   - base64-encoded PEM (also common in single-line secret managers)
//
// PKCS#1 and PKCS#8 are both supported.
func ParseRSAPrivateKey(raw string) (*rsa.PrivateKey, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, errors.New("empty key material")
	}

	// Some secret managers force single-line storage; normalize the common
	// literal "\n" escape back to a real newline so PEM decoding works.
	raw = strings.ReplaceAll(raw, "\\n", "\n")

	// If the input looks like base64 (no PEM header), try decoding it first.
	if !strings.Contains(raw, "BEGIN") {
		decoded, err := base64.StdEncoding.DecodeString(raw)
		if err == nil && strings.Contains(string(decoded), "BEGIN") {
			raw = string(decoded)
		}
	}

	block, _ := pem.Decode([]byte(raw))
	if block == nil {
		return nil, errors.New("failed to decode PEM block")
	}

	// PKCS#1 ("RSA PRIVATE KEY") — what `openssl genrsa` emits by default.
	if key, err := x509.ParsePKCS1PrivateKey(block.Bytes); err == nil {
		return key, nil
	}

	// PKCS#8 ("PRIVATE KEY") — what newer tooling emits.
	parsed, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, errors.Wrap(err, "parse private key (tried PKCS#1 and PKCS#8)")
	}
	rsaKey, ok := parsed.(*rsa.PrivateKey)
	if !ok {
		return nil, errors.New("private key is not RSA")
	}
	return rsaKey, nil
}
