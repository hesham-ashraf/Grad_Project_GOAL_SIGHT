# Phase 15 Runtime Summary

## Verdict
FAIL

## What Passed
- Authenticated sign-in succeeded for all four supplied users.
- The harness confirmed the authenticated identities returned by Supabase:
  - Admin: `b830875d-9fdc-4ad8-a4ed-ba1b2e99498c`
  - Manager: `1c34db13-cc1f-46bc-a1e0-dffc73342689`
  - Player: `05cc12a7-ffc8-4532-885e-daa345c1954d`
  - Fan: `3cee463a-f9cf-4847-a3a2-ec39d661968a`

## Runtime Failure
The suite stopped during the player mapping preflight because authenticated reads against `public.profiles` and `public.players` still recurse through `public.has_role()`.

Exact failures observed:
- `No linked player row exists for the authenticated player profile b830875d-9fdc-4ad8-a4ed-ba1b2e99498c.`
- Direct authenticated reads of `profiles` and `players` returned:
  - `code: 54001`
  - `message: stack depth limit exceeded`

## Root Cause
`public.has_role()` still depends on `public.profiles`, and `public.profiles` policies depend on `public.has_role()`. That creates a recursive RLS loop during authenticated runtime reads.

## Recommended Fix
The repo now includes a remediation migration at [supabase/migrations/032_role_claim_hardening.sql](../migrations/032_role_claim_hardening.sql) that:
- Redefines `public.has_role()` to read JWT role claims instead of querying `public.profiles`.
- Backfills the current `auth.users` rows so authenticated sessions carry the role claim.

That migration still needs to be applied to the live Supabase project before Phase 15 can pass.

## Coverage Blocked By The Failure
Because the stack-depth recursion appears on the early profile/player checks, the remaining Phase 15 runtime categories were not trustworthy to continue:
- Admin table reads
- Upload job ownership
- Fan notifications and activity logs
- Storage authorization
- Realtime authorization

## Artifact
- [phase15_runtime_results.json](phase15_runtime_results.json)
