-- +migrate Up

-- Phase 1.4 — OIDC nonce support in the auth-code flow.
--
-- /v1/authorize accepts an optional `nonce` query parameter (OIDC Core 1.0
-- §3.1.2.1); we persist it alongside the existing code_challenge so that
-- /v1/tokens/exchange can echo it back inside the ID token (§3.1.3.7).
--
-- The column is named `oidc_nonce` (NOT `nonce`) because this table already
-- has a `nonce` column that serves as the challenge primary key — that one
-- is an internally-generated session id, completely unrelated to the OIDC
-- replay-protection nonce the client supplies. Conflating them would create
-- a subtle correctness bug.
--
-- Nullable because the legacy auth-code flow used by Taraaz / difcongress
-- does not send a nonce; only OIDC-aware RPs (MAS, Element) populate it.
ALTER TABLE sso_challenges
    ADD COLUMN IF NOT EXISTS oidc_nonce TEXT;

-- The nonce must flow through to /v1/tokens/exchange so the ID token can echo
-- it back. /authorize → sso_challenges → /authorize/verify → sso_auth_codes
-- → /tokens/exchange. exchange.go reads the auth-code row (not the challenge,
-- which is already consumed by verify), so the code row must carry the nonce.
ALTER TABLE sso_auth_codes
    ADD COLUMN IF NOT EXISTS oidc_nonce TEXT;

-- +migrate Down

ALTER TABLE sso_auth_codes
    DROP COLUMN IF EXISTS oidc_nonce;
ALTER TABLE sso_challenges
    DROP COLUMN IF EXISTS oidc_nonce;
