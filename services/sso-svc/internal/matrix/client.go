// Package matrix provides a thin Synapse Admin API client for Phase 3
// access-tier management.
//
// When AdminURL is empty (the default in local dev and Taraaz deploys) all
// client methods become no-ops — the same binary works across environments
// without any conditional compilation.
package matrix

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"github.com/pkg/errors"
	"gitlab.com/distributed_lab/figure"
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/kv"
)

// Config holds the optional `matrix:` YAML block settings.
// All fields default to the zero value when the block is absent; an empty
// AdminURL disables the integration entirely.
type Config struct {
	// AdminURL is the internal base URL of the Synapse homeserver used to call
	// the Admin API (e.g. http://synapse:8008). Leave empty to disable.
	AdminURL string `fig:"admin_url"`

	// AdminToken is the Bearer token for a Synapse admin user. Never logged.
	AdminToken string `fig:"admin_token"`

	// PublicRoom is the room alias or ID that every authenticated user is
	// force-joined to on login (Tier 1, e.g. "#tcf-public:jomhoor.org").
	PublicRoom string `fig:"public_room"`

	// VerifiedSpace is the room alias or ID that ZK-verified users are
	// force-joined to on login (Tier 2, e.g. "#tcf-verified:jomhoor.org").
	VerifiedSpace string `fig:"verified_space"`
}

// Client wraps the Synapse Admin API.  Create via NewMatrixer / Matrix().
type Client struct {
	cfg  Config
	http *http.Client
}

// IsEnabled reports whether the Matrix integration is active.
// Returns false when AdminURL is empty (local dev / Taraaz).
func (c *Client) IsEnabled() bool {
	return c.cfg.AdminURL != ""
}

// PublicRoom returns the alias every authenticated user is auto-joined to.
func (c *Client) PublicRoom() string { return c.cfg.PublicRoom }

// VerifiedSpace returns the alias ZK-verified users are auto-joined to.
func (c *Client) VerifiedSpace() string { return c.cfg.VerifiedSpace }

// JoinRoom force-joins userID into roomID via the Synapse Admin API.
//
//	POST {adminURL}/_synapse/admin/v1/join/{roomIdOrAlias}
//	Body: {"user_id": "@localpart:jomhoor.org"}
//
// The call is a no-op (returns nil) when AdminURL is empty.
func (c *Client) JoinRoom(userID, roomID string) error {
	if !c.IsEnabled() {
		return nil
	}

	body, _ := json.Marshal(map[string]string{"user_id": userID})
	endpoint := fmt.Sprintf("%s/_synapse/admin/v1/join/%s",
		c.cfg.AdminURL, url.PathEscape(roomID))

	req, err := http.NewRequest(http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return errors.Wrap(err, "build synapse join request")
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.cfg.AdminToken)

	resp, err := c.http.Do(req)
	if err != nil {
		return errors.Wrap(err, "synapse join request")
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("synapse join %s for %s: HTTP %d", roomID, userID, resp.StatusCode)
	}
	return nil
}

// ─────────────────────────────────────────────────────────────────────────────
// comfig wiring
// ─────────────────────────────────────────────────────────────────────────────

// Matrixer is the comfig-style interface embedded in Config and service.
type Matrixer interface {
	Matrix() *Client
}

type matrixer struct {
	once   comfig.Once
	getter kv.Getter
}

// NewMatrixer constructs a lazy Matrixer backed by the provided kv.Getter.
func NewMatrixer(getter kv.Getter) Matrixer {
	return &matrixer{getter: getter}
}

func (m *matrixer) Matrix() *Client {
	return m.once.Do(func() interface{} {
		cfg := Config{}

		// The matrix: block is optional. safeGetStringMap returns nil instead
		// of panicking when the key is absent, leaving cfg at zero values.
		raw := safeGetStringMap(m.getter, "matrix")
		if len(raw) > 0 {
			if err := figure.Out(&cfg).From(raw).Please(); err != nil {
				panic(errors.WithMessage(err, "failed to figure out matrix config"))
			}
		}

		if cfg.AdminURL == "" {
			// No-op client for local dev / Taraaz.
			return &Client{cfg: cfg}
		}
		return &Client{
			cfg:  cfg,
			http: &http.Client{Timeout: 10 * time.Second},
		}
	}).(*Client)
}

// safeGetStringMap calls kv.MustGetStringMap and recovers the panic that fires
// when the key is absent from the config. Returns nil in that case.
func safeGetStringMap(getter kv.Getter, key string) (result map[string]interface{}) {
	defer func() { recover() }() //nolint:errcheck
	result = kv.MustGetStringMap(getter, key)
	return
}
