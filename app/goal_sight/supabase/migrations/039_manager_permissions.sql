-- ---------------------------------------------------------------------------
-- Migration 039 — Manager Permissions
--
-- Adds boolean permission columns to the managers table so the admin can
-- grant or revoke what each manager is allowed to do in the app.
-- Defaults are permissive (all true) so existing managers keep full access.
-- ---------------------------------------------------------------------------

ALTER TABLE managers
  ADD COLUMN IF NOT EXISTS can_upload       BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS can_edit_players BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS can_manage_staff BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN managers.can_upload       IS 'Manager may upload match videos';
COMMENT ON COLUMN managers.can_edit_players IS 'Manager may add/edit player records';
COMMENT ON COLUMN managers.can_manage_staff IS 'Manager may invite or deactivate other managers (reserved for senior staff)';
