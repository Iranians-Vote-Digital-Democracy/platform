// Package oidc holds OpenID Connect provider metadata shared by the discovery
// handler (/.well-known/openid-configuration) and the ID-token issuer.
//
// As of Phase 1.2 the only setting is the canonical issuer URL — the public
// HTTPS origin that relying parties have whitelisted as their trust anchor
// (e.g. https://sso.jomhoor.org). It is intentionally NOT derived from the
// incoming request Host header: a misconfigured nginx upstream or a proxy
// stripping Host could otherwise emit discovery documents under the wrong
// origin and break RP verification.
package oidc

import (
	"strings"

	"github.com/pkg/errors"
	"gitlab.com/distributed_lab/figure"
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/kv"
)

// Config is the figure-loaded `oidc:` config block.
type Config struct {
	Issuer string `fig:"issuer,required"`
}

// IssuerURL returns the issuer with any trailing slash trimmed. OIDC
// discovery treats "https://x/" and "https://x" as different issuers, and
// downstream RPs commonly use exact string comparison; pick one canonical
// form.
func (c *Config) IssuerURL() string {
	return strings.TrimRight(c.Issuer, "/")
}

type Oidcer interface {
	OIDC() *Config
}

type oidcer struct {
	once   comfig.Once
	getter kv.Getter
}

func NewOidcer(getter kv.Getter) Oidcer {
	return &oidcer{getter: getter}
}

func (o *oidcer) OIDC() *Config {
	return o.once.Do(func() interface{} {
		cfg := Config{}
		if err := figure.Out(&cfg).From(kv.MustGetStringMap(o.getter, "oidc")).Please(); err != nil {
			panic(errors.WithMessage(err, "failed to figure out oidc config"))
		}
		if !strings.HasPrefix(cfg.Issuer, "https://") && !strings.HasPrefix(cfg.Issuer, "http://") {
			panic(errors.New("oidc.issuer must be an absolute http(s) URL"))
		}
		return &cfg
	}).(*Config)
}
