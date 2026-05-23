-- +migrate Up
--
-- Phase 3 access-tier management: outbox table for Synapse Admin API calls.
--
-- When /v1/tokens/exchange fires for a matrix-mas client, sso-svc inserts a
-- row here BEFORE spawning the goroutine that calls the Synapse Admin API.
-- On success the goroutine deletes the row; on failure it increments attempts.
-- This INSERT-first pattern ensures a future retry worker can recover work
-- that was lost to a mid-flight crash.
--
-- `action` is currently always 'join' (the Synapse admin join endpoint works
-- for both public rooms and invite-only spaces). Reserved for future 'invite'
-- semantics if granular invite tracking is needed.
CREATE TABLE matrix_pending_invites (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     TEXT        NOT NULL,   -- @localpart:jomhoor.org
    room_id     TEXT        NOT NULL,   -- room alias or internal room ID
    action      TEXT        NOT NULL DEFAULT 'join',
    attempts    INT         NOT NULL DEFAULT 0,
    last_error  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Quickly find all pending rows for a given user (e.g. admin tooling, retry).
CREATE INDEX matrix_pending_invites_user_idx ON matrix_pending_invites(user_id);

-- +migrate Down
DROP TABLE IF EXISTS matrix_pending_invites;
