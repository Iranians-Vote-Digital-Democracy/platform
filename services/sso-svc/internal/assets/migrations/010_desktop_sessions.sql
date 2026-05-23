-- +migrate Up
--
-- Desktop cross-device QR flow (Phase 1.9).
--
-- A `desktop_sessions` row is created when /v1/authorize is hit with
-- `display=qr` (or by future UA-detection). The desktop browser polls
-- /v1/authorize/qr/poll until the wallet POSTs to /v1/authorize/qr/complete,
-- which binds the auth code to the session. The desktop then redirects to
-- the RP's redirect_uri with ?code=&state= as in the same-device flow.
--
-- `code` is NULL until the wallet completes. `consumed` flips when the
-- desktop's poll has read the code; reads after that return 410.
CREATE TABLE desktop_sessions (
    id              TEXT        PRIMARY KEY,
    client_id       TEXT        NOT NULL REFERENCES sso_clients(id),
    redirect_uri    TEXT        NOT NULL,
    state           TEXT        NOT NULL,
    code            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,
    consumed        BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX desktop_sessions_expires_idx ON desktop_sessions(expires_at);

-- +migrate Down
DROP TABLE IF EXISTS desktop_sessions;
