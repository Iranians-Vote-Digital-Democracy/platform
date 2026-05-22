-- init-matrix-db.sql
-- Run once by postgres docker-entrypoint-initdb.d on first container start.
-- Creates the MAS database alongside the default synapse database.
-- The `matrix` user (POSTGRES_USER) already exists and owns both databases.

-- Synapse database (already created as POSTGRES_DB, but configure locale explicitly)
-- Synapse REQUIRES LC_COLLATE='C' and LC_CTYPE='C' to function correctly.
-- We cannot ALTER DATABASE after creation to change these, so drop and recreate.
UPDATE pg_database SET datcollate='C', datctype='C' WHERE datname='synapse';

-- MAS database
CREATE DATABASE mas
    WITH OWNER = matrix
    ENCODING = 'UTF8'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C'
    TEMPLATE = template0;

GRANT ALL PRIVILEGES ON DATABASE synapse TO matrix;
GRANT ALL PRIVILEGES ON DATABASE mas TO matrix;
