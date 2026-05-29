-- ============================================================
-- Goal Sight MVP - Roles Update
-- File: 006_roles_update.sql
-- Description:
-- Replaces the legacy role "coach" with "manager" in profiles.
-- Updates the role constraint and converts existing rows.
-- Safe to re-run.
-- ============================================================

-- Remove the old role constraint (safe to re-run)
alter table public.profiles
  drop constraint if exists profiles_role_check;

-- Convert any existing "coach" roles to "manager"
update public.profiles
set role = 'manager'
where role = 'coach';

-- Recreate the role constraint with the new allowed values
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('admin', 'manager', 'player', 'fan'));
