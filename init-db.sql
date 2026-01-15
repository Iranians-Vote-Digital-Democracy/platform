-- Initialize databases for Rarimo services
-- Run this when PostgreSQL starts for the first time

-- Database for proof-verification-relayer
CREATE DATABASE proof_verification;
GRANT ALL PRIVILEGES ON DATABASE proof_verification TO rarimo;

-- Database for geo-points-svc
CREATE DATABASE geo_points;
GRANT ALL PRIVILEGES ON DATABASE geo_points TO rarimo;
