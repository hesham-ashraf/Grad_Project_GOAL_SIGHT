# GoalSight Documentation

Submission documentation for **GoalSight — AI-Powered Football Match Analysis
Platform** (Team 62, Zewail City CSAI).

Start at the [project README](../README.md) for the overview, then dive into the
documents below.

| Document | What's inside |
|---|---|
| [SETUP.md](SETUP.md) | Step-by-step setup for all three tiers + full **environment requirements** and every environment variable. |
| [DEPLOYMENT.md](DEPLOYMENT.md) | **Deployment**: WSL+ngrok demo, AWS GPU + Docker production, Supabase setup, release builds. |
| [USER_GUIDE.md](USER_GUIDE.md) | **User documentation** — manager / fan / admin walkthroughs and the upload workflow. |
| [API.md](API.md) | **API documentation** — the analysis-service HTTP job API (endpoints, request/response shapes, lifecycle). |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | **Database schema** — Supabase/PostgreSQL tables, ER diagram, RLS multi-tenancy, storage buckets. |
| [SCREENSHOTS.md](SCREENSHOTS.md) | **Screenshots & sample outputs** (assets in [`screenshots/`](screenshots/)). |

## Deeper reference

- [GOALSIGHT_TECHNICAL_DOCUMENTATION.md](../GOALSIGHT_TECHNICAL_DOCUMENTATION.md)
  — the complete technical reference and single source of truth: architecture,
  every CV pipeline phase, the service, the app, the database, ethics/compliance,
  testing/evaluation, and known limitations.

## Source-tree docs (not part of the formal submission set)

- [`app/goal_sight/analysis_service/README.md`](../app/goal_sight/analysis_service/README.md) — service-level README.
- [`app/goal_sight/analysis_service/RUN_WSL_NGROK.md`](../app/goal_sight/analysis_service/RUN_WSL_NGROK.md) — WSL+ngrok runbook.
- [`app/goal_sight/docs/`](../app/goal_sight/docs/) — earlier app-side contract/schema notes.
