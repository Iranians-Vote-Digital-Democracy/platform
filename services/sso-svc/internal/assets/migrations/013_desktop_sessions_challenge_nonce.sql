-- +migrate Up
--
-- Tie desktop QR rendezvous rows to the original authorize challenge nonce.
-- This allows /v1/authorize/verify to auto-bind auth codes for desktop polls
-- even if the wallet does not call /v1/authorize/qr/complete.
ALTER TABLE desktop_sessions
    ADD COLUMN challenge_nonce TEXT;

CREATE INDEX desktop_sessions_challenge_nonce_idx
    ON desktop_sessions(challenge_nonce);

-- +migrate Down
DROP INDEX IF EXISTS desktop_sessions_challenge_nonce_idx;
ALTER TABLE desktop_sessions
    DROP COLUMN IF EXISTS challenge_nonce;
