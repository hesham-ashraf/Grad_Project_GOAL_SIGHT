-- GOALSIGHT - Supabase Migration
-- Run this in the Supabase SQL Editor: https://supabase.com/dashboard/project/hciiygxvwlhasesytrbp/sql
-- Or via: psql "postgresql://postgres:YOUR_PASSWORD@db.hciiygxvwlhasesytrbp.supabase.co:5432/postgres" -f migration.sql

-- Enable UUID extension (already enabled on Supabase by default)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
DO $$ BEGIN
  CREATE TYPE "Role" AS ENUM ('fan', 'manager', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "MatchStatus" AS ENUM ('scheduled', 'live', 'completed', 'postponed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username       VARCHAR(50)  NOT NULL,
  email          VARCHAR(255) NOT NULL UNIQUE,
  password       VARCHAR(255) NOT NULL,
  role           "Role"       NOT NULL DEFAULT 'fan',
  favorite_team  VARCHAR(255),
  is_active      BOOLEAN      NOT NULL DEFAULT true,
  last_login     TIMESTAMPTZ,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS users_email_idx  ON users(email);
CREATE INDEX IF NOT EXISTS users_role_idx   ON users(role);

-- Matches table
CREATE TABLE IF NOT EXISTS matches (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  home_team_name   VARCHAR(255) NOT NULL,
  home_team_logo   TEXT         NOT NULL DEFAULT '⚽',
  home_team_score  INTEGER      NOT NULL DEFAULT 0,
  away_team_name   VARCHAR(255) NOT NULL,
  away_team_logo   TEXT         NOT NULL DEFAULT '⚽',
  away_team_score  INTEGER      NOT NULL DEFAULT 0,
  date             TIMESTAMPTZ  NOT NULL,
  venue            VARCHAR(255) NOT NULL,
  league           VARCHAR(255) NOT NULL,
  season           VARCHAR(50)  NOT NULL DEFAULT '2025/2026',
  status           "MatchStatus" NOT NULL DEFAULT 'scheduled',
  statistics       JSONB        NOT NULL DEFAULT '{}',
  events           JSONB        NOT NULL DEFAULT '[]',
  created_by       UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS matches_date_idx    ON matches(date DESC);
CREATE INDEX IF NOT EXISTS matches_status_idx  ON matches(status);
CREATE INDEX IF NOT EXISTS matches_league_idx  ON matches(league);

-- Auto-update updated_at on row changes
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_updated_at  ON users;
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS matches_updated_at ON matches;
CREATE TRIGGER matches_updated_at
  BEFORE UPDATE ON matches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
