-- RPC: promote an existing fan user to manager role.
-- Called by the admin client; SECURITY DEFINER lets it read auth.users and
-- write to profiles/managers without exposing those tables over RLS.

CREATE OR REPLACE FUNCTION promote_to_manager(
  p_email          TEXT,
  p_club_id        UUID,
  p_can_upload     BOOLEAN DEFAULT TRUE,
  p_can_edit_players BOOLEAN DEFAULT TRUE,
  p_can_manage_staff BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id  UUID;
  v_name     TEXT;
  v_mgr_id   UUID;
BEGIN
  -- 1. Find user in auth.users by email.
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No GoalSight account found for email: %', p_email;
  END IF;

  -- 2. Pull their display name from profiles.
  SELECT full_name INTO v_name
  FROM profiles
  WHERE id = v_user_id;

  -- 3. Guard: already a manager of this club?
  IF EXISTS (
    SELECT 1 FROM managers
    WHERE email = p_email AND club_id = p_club_id
  ) THEN
    RAISE EXCEPTION 'This user is already a manager of this club.';
  END IF;

  -- 4. Promote: update role and set club_id on the profile.
  UPDATE profiles
  SET role = 'manager', club_id = p_club_id
  WHERE id = v_user_id;

  -- 5. Create the managers row.
  INSERT INTO managers (
    name, email, club_id, is_active,
    can_upload, can_edit_players, can_manage_staff,
    upload_count, matches_analyzed, tactical_rating, last_active
  )
  VALUES (
    COALESCE(v_name, p_email), p_email, p_club_id, TRUE,
    p_can_upload, p_can_edit_players, p_can_manage_staff,
    0, 0, 0, NOW()
  )
  RETURNING id INTO v_mgr_id;

  RETURN jsonb_build_object(
    'id',    v_mgr_id,
    'name',  COALESCE(v_name, p_email),
    'email', p_email
  );
END;
$$;

-- Only admins (service role or RLS-verified admin) may call this function.
REVOKE ALL ON FUNCTION promote_to_manager(TEXT, UUID, BOOLEAN, BOOLEAN, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION promote_to_manager(TEXT, UUID, BOOLEAN, BOOLEAN, BOOLEAN) TO authenticated;
