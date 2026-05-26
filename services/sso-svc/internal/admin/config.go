// Package admin holds the bearer-token config for sso-svc's small admin
// surface (currently: POST /v1/admin/assertions for the DIFCongress signup
// worker stamping `difcongress_member` rows).
//
// The block is optional in config.yaml. When `admin.token` is empty the
// admin routes register but every request gets 503 — this lets local-dev
// builds boot without a token while still failing closed in production.
package admin

import (
	"github.com/pkg/errors"
	"gitlab.com/distributed_lab/figure"
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/kv"
)

// Config holds the optional `admin:` YAML block settings.
type Config struct {
	// Token is the shared secret presented as `Authorization: Bearer <token>`
	// by trusted callers (e.g. the DIFCongress signup worker). Compared in
	// constant time. Empty disables the admin surface.
	Token string `fig:"token"`
}

// Enabled reports whether the admin surface is usable.
// Returns false when the token is empty (local dev / unconfigured deploys).
func (c *Config) Enabled() bool { return c != nil && c.Token != "" }

// ─────────────────────────────────────────────────────────────────────────────
// comfig wiring
// ─────────────────────────────────────────────────────────────────────────────

// Adminer is the comfig-style accessor embedded in config.Config.
type Adminer interface {
	Admin() *Config
}

type adminer struct {
	once   comfig.Once
	getter kv.Getter
}

// NewAdminer constructs a lazy Adminer backed by the provided kv.Getter.
func NewAdminer(getter kv.Getter) Adminer {
	return &adminer{getter: getter}
}

func (a *adminer) Admin() *Config {
	return a.once.Do(func() interface{} {
		cfg := Config{}

		// The admin: block is optional. safeGetStringMap returns nil when the
		// key is absent, leaving cfg at its zero value (Enabled() → false).
		raw := safeGetStringMap(a.getter, "admin")
		if len(raw) > 0 {
			if err := figure.Out(&cfg).From(raw).Please(); err != nil {
				panic(errors.WithMessage(err, "failed to figure out admin config"))
			}
		}
		return &cfg
	}).(*Config)
}

// safeGetStringMap calls kv.MustGetStringMap and recovers the panic that
// fires when the key is absent. Returns nil in that case.
func safeGetStringMap(getter kv.Getter, key string) (result map[string]interface{}) {
	defer func() { recover() }() //nolint:errcheck
	result = kv.MustGetStringMap(getter, key)
	return
}
