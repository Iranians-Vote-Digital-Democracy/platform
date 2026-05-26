// Package middleware: admin bearer-token guard.
//
// Used by /v1/admin/* routes. Compares the presented bearer token against
// admin.Config.Token in constant time. Returns 503 when the admin surface is
// disabled (empty token) so misconfigured deploys fail closed.
package middleware

import (
	"crypto/subtle"
	"fmt"
	"net/http"
	"strings"

	"github.com/google/jsonapi"
	"github.com/jomhoor/sso-svc/internal/admin"
	"github.com/jomhoor/sso-svc/internal/jwt"
	"gitlab.com/distributed_lab/ape"
	"gitlab.com/distributed_lab/ape/problems"
)

// serviceUnavailable mirrors the constructors in ape/problems for a status the
// upstream package doesn't expose. Used when the admin surface is disabled.
func serviceUnavailable() *jsonapi.ErrorObject {
	return &jsonapi.ErrorObject{
		Title:  http.StatusText(http.StatusServiceUnavailable),
		Status: fmt.Sprintf("%d", http.StatusServiceUnavailable),
	}
}

// AdminTokenMiddleware enforces `Authorization: Bearer <admin.token>`.
// When the admin block is unconfigured (token empty), every request gets
// 503 — this protects local-dev builds that boot without admin secrets
// while still surfacing the route in /v1/.
func AdminTokenMiddleware(cfg *admin.Config) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !cfg.Enabled() {
				ape.RenderErr(w, serviceUnavailable())
				return
			}

			header := r.Header.Get(jwt.AuthorizationHeaderName)
			if !strings.HasPrefix(header, jwt.BearerTokenPrefix) {
				ape.RenderErr(w, problems.Unauthorized())
				return
			}

			presented := strings.TrimPrefix(header, jwt.BearerTokenPrefix)
			if subtle.ConstantTimeCompare([]byte(presented), []byte(cfg.Token)) != 1 {
				ape.RenderErr(w, problems.Unauthorized())
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
