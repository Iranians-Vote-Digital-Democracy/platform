-- +migrate Up

-- Phase 2.2 (MAS upstream OIDC) — Matrix needs a stable, opaque-but-readable
-- localpart per (wallet, client) pair. We derive it deterministically from
-- the existing pairwise subject and persist it on pairwise_subjects so:
--   1. The same wallet logging into MAS always lands on the same Matrix user.
--   2. Other RPs that ask for the `matrix_localpart` claim get the same value.
--   3. We can rename without breaking RP linkage by updating one row.
--
-- The column is nullable: most pairwise rows belong to non-Matrix RPs and
-- have no localpart. The column is populated lazily on first MAS login.
--
-- UNIQUE guarantees we never collide on the Matrix side; a duplicate insert
-- attempt surfaces as a clear error instead of silently merging two wallets
-- into one Matrix account.
ALTER TABLE pairwise_subjects
    ADD COLUMN IF NOT EXISTS matrix_localpart TEXT;

-- Unique index, partial on NOT NULL — same reasoning as wallets_banned_at_idx:
-- the column is sparse, and a partial unique index lets us enforce uniqueness
-- only over the populated rows.
CREATE UNIQUE INDEX IF NOT EXISTS pairwise_subjects_matrix_localpart_uniq
    ON pairwise_subjects(matrix_localpart)
    WHERE matrix_localpart IS NOT NULL;

-- +migrate Down

DROP INDEX IF EXISTS pairwise_subjects_matrix_localpart_uniq;
ALTER TABLE pairwise_subjects
    DROP COLUMN IF EXISTS matrix_localpart;
