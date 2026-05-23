package service

import (
	"github.com/go-chi/chi"
	"github.com/jomhoor/sso-svc/internal/jwt"
	"github.com/jomhoor/sso-svc/internal/service/handlers"
	"github.com/jomhoor/sso-svc/internal/service/middleware"
	"github.com/jomhoor/sso-svc/internal/static"
	"gitlab.com/distributed_lab/ape"
)

func (s *service) router() chi.Router {
	r := chi.NewRouter()

	r.Use(
		ape.RecoverMiddleware(s.log),
		ape.LoganMiddleware(s.log),
		ape.CtxMiddleware(
			handlers.CtxLog(s.log),
			handlers.CtxJWT(s.jwt),
			handlers.CtxOIDC(s.oidc),
			handlers.CtxPairwise(s.pairwise),
			handlers.CtxAttestation(s.attestation),
			handlers.CtxCookies(s.cookies),
			handlers.CtxDeeplink(s.deeplink),
			handlers.CtxDB(s.db),
			handlers.CtxZKP(s.zkp),
			handlers.CtxMatrix(s.matrix),
		),
	)

	// Embedded static assets (fonts, images, etc.)
	r.Handle("/static/*", static.Handler("/static/"))

	// Well-known files required for Universal Links (iOS) and App Links (Android).
	// These MUST be served before any auth routes because iOS/Android fetch them
	// on every app install without any credentials.
	r.Get("/.well-known/apple-app-site-association", handlers.AppleAppSiteAssociation)
	r.Get("/.well-known/assetlinks.json", handlers.AssetLinks)

	// OIDC provider metadata (Phase 1.2 / 1.3). Public, cacheable, CORS-open.
	// RPs fetch these once to discover endpoints and verification keys; no
	// secrets are exposed.
	r.Get("/.well-known/openid-configuration", handlers.OIDCDiscovery)
	r.Get("/.well-known/jwks.json", handlers.JWKS)

	// Deep-link target for the SSO flow. iOS Universal Link interception is the
	// primary path (app opens before the browser makes a network request).
	// This handler is the fallback for browser-initiated navigations where iOS
	// does not intercept: it 302-redirects to the jomhoor:// custom scheme so
	// the wallet app still opens regardless.
	r.Get("/auth/sso", handlers.AuthSsoFallback)

	r.Route("/v1", func(r chi.Router) {
		// Wallet registration (M2)
		r.Post("/wallets/challenge", handlers.WalletChallenge)
		r.Post("/wallets/register", handlers.RegisterWallet)

		// Wallet recovery via ZK nullifier (M5). The wallet posts a fresh
		// query proof carrying the same nullifier_hash as the prior wallet;
		// sso-svc rebinds assertions + pairwise_subjects so the user keeps
		// the same `sub` at every relying party after reinstall.
		r.Post("/wallets/recover", handlers.RecoverWallet)

		// OAuth2 auth-code + PKCE flow (M3)
		r.Get("/authorize", handlers.Authorize)
		r.Post("/authorize/verify", handlers.Verify)
		r.Post("/tokens/exchange", handlers.Exchange)

		// Phase 1.9 desktop cross-device QR rendezvous. The page (qr) is
		// served from /v1/authorize when display=qr; these two endpoints are
		// the rendezvous itself: the desktop polls, the wallet binds.
		r.Get("/authorize/qr/poll", handlers.QRPoll)
		r.Post("/authorize/qr/complete", handlers.QRComplete)

		// Public client metadata for consent screen (M4)
		r.Get("/clients/{id}", handlers.GetClient)

		// ZK assertion submission (M5 item 4). Wallet posts a Rarimo query proof;
		// success inserts an `assertions` row that /v1/tokens/validate surfaces live.
		r.Post("/assertions/zk", handlers.SubmitZKAssertion)

		// Pre-flight ZK assertion check (M5 item 1). Wallet calls this before
		// the consent screen when an RP advertises `zk_required=true`, so the
		// user is routed through ZK escalation instead of hitting a silent 403
		// from /v1/authorize/verify.
		r.Get("/wallets/{address}/assertions/zk", handlers.GetZKAssertionStatus)

		// Token introspection (M3)
		r.With(middleware.AuthMiddleware(s.jwt, s.log, jwt.AccessTokenType), middleware.BanMiddleware()).
			Get("/tokens/validate", handlers.Validate)

		// OIDC UserInfo (Phase 1.6). Bearer access token; returns the live
		// claim shape (sub/iss/client_id + optional zk_verified, matrix_localpart).
		r.With(middleware.AuthMiddleware(s.jwt, s.log, jwt.AccessTokenType), middleware.BanMiddleware()).
			Get("/userinfo", handlers.UserInfo)

		// Token refresh
		r.With(middleware.AuthMiddleware(s.jwt, s.log, jwt.RefreshTokenType), middleware.BanMiddleware()).
			Post("/tokens/refresh", handlers.Refresh)
	})

	return r
}
