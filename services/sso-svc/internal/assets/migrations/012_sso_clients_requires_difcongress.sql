-- +migrate Up
--
-- Q6 — DIFCongress-membership gate.
--
-- When this flag is set on an SSO client, /v1/authorize/verify requires the
-- wallet to carry a live `difcongress_member` assertion (status=true,
-- not-expired). The assertion is stamped via POST /v1/admin/assertions by the
-- DIFCongress signup worker once a user completes membership signup.
--
-- The flag is enforced at /v1/authorize/verify (alongside zk_required) — it
-- is NOT written into the issued auth code or JWT. Tokens carry no trust
-- bits; relying parties read live assertions via /v1/tokens/validate.
--
-- Default FALSE preserves existing rows. The matrix-mas client is flipped to
-- TRUE in a separate seed; per the M2.5 trust-boundary doctrine, never make
-- assumptions about which client_ids exist at migration time.
ALTER TABLE sso_clients
    ADD COLUMN requires_difcongress BOOLEAN NOT NULL DEFAULT FALSE;

-- +migrate Down
ALTER TABLE sso_clients DROP COLUMN IF EXISTS requires_difcongress;
