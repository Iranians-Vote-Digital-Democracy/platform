package jwt

import (
	"strings"
	"time"

	"github.com/pkg/errors"
	"gitlab.com/distributed_lab/figure"
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/kv"
)

type Jwter interface {
	JWT() *JWTIssuer
}

type jwter struct {
	once   comfig.Once
	getter kv.Getter
}

func NewJwter(getter kv.Getter) Jwter {
	return &jwter{getter: getter}
}

// jwtConfig is the YAML shape under the top-level `jwt:` key.
//
// As of Phase 1.1 we use RS256 with a current + optional previous keypair.
// Keys are PEM-encoded RSA private keys, supplied either inline (with the
// YAML `|` block scalar) or via env-var substitution. ParseRSAPrivateKey
// transparently accepts base64 and "\n"-escaped PEM, so any secret manager
// will work.
type jwtConfig struct {
	CurrentKID        string `fig:"current_kid,required"`
	CurrentPrivateKey string `fig:"current_private_key,required"`
	// Previous key is optional — only set during a key rotation window.
	PreviousKID        string `fig:"previous_kid"`
	PreviousPrivateKey string `fig:"previous_private_key"`

	AccessExpirationTime  time.Duration `fig:"access_expiration_time,required"`
	RefreshExpirationTime time.Duration `fig:"refresh_expiration_time,required"`
}

func (j *jwter) JWT() *JWTIssuer {
	return j.once.Do(func() interface{} {
		cfg := jwtConfig{}
		if err := figure.Out(&cfg).From(kv.MustGetStringMap(j.getter, "jwt")).Please(); err != nil {
			panic(errors.WithMessage(err, "failed to figure out jwt config"))
		}

		current, err := ParseRSAPrivateKey(cfg.CurrentPrivateKey)
		if err != nil {
			panic(errors.WithMessage(err, "parse current_private_key"))
		}

		issuer := &JWTIssuer{
			current:           Keypair{KID: cfg.CurrentKID, Private: current},
			accessExpiration:  cfg.AccessExpirationTime,
			refreshExpiration: cfg.RefreshExpirationTime,
		}

		// Previous keypair is fully optional. Both kid and key must be present
		// to be considered configured; either alone is a config error.
		hasPrevKID := strings.TrimSpace(cfg.PreviousKID) != ""
		hasPrevKey := strings.TrimSpace(cfg.PreviousPrivateKey) != ""
		switch {
		case hasPrevKID && hasPrevKey:
			prev, err := ParseRSAPrivateKey(cfg.PreviousPrivateKey)
			if err != nil {
				panic(errors.WithMessage(err, "parse previous_private_key"))
			}
			if cfg.PreviousKID == cfg.CurrentKID {
				panic(errors.New("previous_kid must differ from current_kid"))
			}
			issuer.previous = &Keypair{KID: cfg.PreviousKID, Private: prev}
		case hasPrevKID || hasPrevKey:
			panic(errors.New("previous_kid and previous_private_key must both be set or both omitted"))
		}

		return issuer
	}).(*JWTIssuer)
}
