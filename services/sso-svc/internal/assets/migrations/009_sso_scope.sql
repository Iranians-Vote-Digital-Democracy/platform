-- 009_sso_scope.sql
--
-- OIDC scope plumbing. The `scope` request param (OIDC Core 1.0 §3.1.2.1) is
-- accepted at /v1/authorize, propagated to the auth code on /v1/authorize/verify,
-- and consumed at /v1/tokens/exchange where the presence of `openid` flips on
-- ID token issuance. Stored as a single space-separated TEXT for fidelity with
-- the wire format; parsing happens in the handler.

-- +migrate Up
ALTER TABLE sso_challenges
    ADD COLUMN IF NOT EXISTS scope TEXT;

ALTER TABLE sso_auth_codes
    ADD COLUMN IF NOT EXISTS scope TEXT;

-- +migrate Down
ALTER TABLE sso_auth_codes
    DROP COLUMN IF EXISTS scope;

ALTER TABLE sso_challenges
    DROP COLUMN IF EXISTS scope;
