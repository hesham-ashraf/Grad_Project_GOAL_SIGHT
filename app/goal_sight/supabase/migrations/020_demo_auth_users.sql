-- ============================================================
-- Goal Sight — Demo auth users (DEV SEED)
-- File: 020_demo_auth_users.sql
-- Description:
--   Creates the three demo accounts used by the login screen's quick-login
--   chips, with confirmed emails so they can sign in immediately. The
--   handle_new_user trigger (see 019) creates their profiles with the role
--   carried in user metadata.
--
--     fan@goalsight.ai     / 123456   (role: fan)
--     manager@goalsight.ai / 123456   (role: manager)
--     admin@goalsight.ai   / 123456   (role: admin)
--
-- DEV ONLY — do not run against production. Idempotent (skips existing emails).
-- Requires the pgcrypto extension (installed in the `extensions` schema).
-- ============================================================

do $$
declare
  demo record;
  uid uuid;
begin
  for demo in
    select * from (values
      ('fan@goalsight.ai','Fan User','fan'),
      ('manager@goalsight.ai','Manager User','manager'),
      ('admin@goalsight.ai','Admin User','admin')
    ) as t(email, full_name, role)
  loop
    if not exists (select 1 from auth.users where email = demo.email) then
      uid := gen_random_uuid();

      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, confirmation_token, recovery_token,
        email_change_token_new, email_change,
        raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at
      ) values (
        '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
        demo.email, extensions.crypt('123456', extensions.gen_salt('bf')),
        now(), '', '', '', '',
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('full_name', demo.full_name, 'role', demo.role),
        now(), now()
      );

      -- email column on auth.identities is generated from identity_data; omit it.
      insert into auth.identities (
        id, user_id, identity_data, provider, provider_id,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), uid,
        jsonb_build_object('sub', uid::text, 'email', demo.email,
                           'email_verified', true, 'phone_verified', false),
        'email', uid::text, now(), now(), now()
      );
    end if;
  end loop;
end $$;
