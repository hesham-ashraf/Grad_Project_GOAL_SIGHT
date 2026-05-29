-- ============================================================
-- Goal Sight MVP - Auth Profiles Trigger
-- File: 005_auth_profiles_trigger.sql
-- Description:
-- Creates a signup trigger to auto-create a profile row after
-- a new Supabase Auth user is created.
-- Safe to re-run.
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, avatar_url, created_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email, 'New User'),
    'fan',
    new.raw_user_meta_data->>'avatar_url',
    now()
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Recreate trigger safely on re-run
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();
