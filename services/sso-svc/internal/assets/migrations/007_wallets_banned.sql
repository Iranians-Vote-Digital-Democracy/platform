-- +migrate Up

-- Q1 ban anchor — a soft-delete column the new ban middleware checks on every
-- authenticated request. A non-NULL banned_at means the wallet is denied at
-- the SSO layer regardless of valid attestation / valid ZK / valid session.
-- Soft-delete (rather than DELETE) so we keep the audit trail and can lift the
-- ban without a re-registration round-trip.
ALTER TABLE wallets
    ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;

-- Partial index: 99%+ of rows have banned_at = NULL. A predicated index keeps
-- the index small and makes lookups for "is this wallet banned right now?"
-- effectively O(1) without bloating writes for the common (unbanned) path.
CREATE INDEX IF NOT EXISTS wallets_banned_at_idx
    ON wallets(banned_at)
    WHERE banned_at IS NOT NULL;

-- +migrate Down

DROP INDEX IF EXISTS wallets_banned_at_idx;
ALTER TABLE wallets
    DROP COLUMN IF EXISTS banned_at;
