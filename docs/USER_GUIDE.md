# User Guide

GoalSight is a mobile app with three role-based experiences: **Manager**,
**Fan**, and **Admin**. This guide explains how to use each, with a focus on the
core **upload → analyze → results** workflow.

---

## 1. Getting started

### Sign in / sign up

1. Launch the app. You land on the splash → authentication screen.
2. **Sign up** with email + password, or **sign in** with an existing account
   (Google sign-in is also supported).
3. After authentication, the app routes you automatically to the right home
   screen based on your role:
   - Fans → `/fan`
   - Managers → `/manager`
   - Admins → `/admin`

> Demo accounts (quick role-login chips) are available on the login screen for
> trying each role without creating an account.

---

## 2. Manager role (the core experience)

Managers analyse their club's matches. The manager shell has a bottom navigation
bar: **Home → Matches → Upload → Players → Profile**.

### 2.1 The upload & analysis workflow

This is the heart of the app. It is a step machine:

```
File selection → Match details → Confirmation → Processing (Stage 1)
   → Player Naming → Processing (Stage 2) → Results
```

**Step 1 — Select a video.** Tap **Upload**, then choose a match clip from your
device. For a quick demo, use a short clip (a few seconds) — full matches take a
long time on CPU.

**Step 2 — Match details.** Enter the home team, away team, competition, venue,
and match date.

**Step 3 — Confirmation.** Review the details and start the analysis.

**Step 4 — Processing (Stage 1).** The app uploads the video and the service
detects and tracks every player, the ball, goalkeepers and referees, then
clusters the two teams. A progress indicator shows the stage. When Stage 1
finishes, the app advances to the **Player Naming** screen.

**Step 5 — Player Naming (mandatory human-in-the-loop).** This step guarantees
that analytics attach to the correct real-world identities:

- Each detected player is shown as a **card with a multi-frame jersey-crop
  gallery** (pinch to zoom full-screen), the detected **role**, and a
  **jersey-number badge** when the number was read.
- **Pick which detected team is YOUR club.** This maps the model's team 0/1 to
  home/away.
- Optionally **name players** or **link them to existing squad members**; the
  app auto-matches by shirt number where possible.
- Submit to continue.

**Step 6 — Processing (Stage 2).** The service runs the full analysis: applies
your names, computes possession, builds the minimap, computes speed/distance and
heatmaps, derives tactical labels, and generates the AI match report and the
annotated video.

**Step 7 — Results.** The analysis opens automatically, showing:

- the **annotated match video** (with the top-down minimap),
- **per-player ratings** (0–10) with impact / insight / fatigue labels,
- the **team tactical summary** (shape, pressure, build-up, attacking zones),
- **possession** and intensity,
- **heatmaps** (per team + best player),
- and the **AI match report** (dominant team, man of the match, weakest player,
  key insights, coaching recommendations).

You can **export a PDF report** of the match from the results screen.

> If cloud persistence is temporarily unavailable, the result still opens
> (built client-side from the service's raw output), but the match won't appear
> in history/squad until persistence succeeds.

### 2.2 Other manager screens

- **Home** — dashboard with recent matches and squad highlights.
- **Matches** — history of analysed matches; tap one to reopen its full report.
- **Players** — your squad; per-player stats, heatmaps, and risk indicators.
- **Profile** — account and club settings.

---

## 3. Fan role

Fans explore football content (no uploads):

- **Clubs** — browse clubs and their squads.
- **Standings** — league tables.
- **Match analyses** — view published match reports and analytics.
- **Player heatmaps** — see where players covered ground.
- **Profile** — favourites, achievements, and notification preferences.

---

## 4. Admin role

Admins manage the platform at the club level:

- **Club overview** — clubs and high-level analytics.
- **Squad management** — add/edit players and team data.
- **Analytics** — club-wide aggregated insights.
- **Bootstrap** — initial club/admin setup.

---

## 5. Understanding the results

| Metric | What it means |
|---|---|
| **Possession %** | Share of time each team controlled the ball (field-space estimate). |
| **Distance covered** | Total metres run per player/team, derived from the metric pitch projection. |
| **Speed (km/h)** | Per-player speeds; implausible jumps are rejected and smoothed. |
| **Player rating (0–10)** | Derived from measurable on-pitch activity, with impact/insight/fatigue labels. |
| **Man of the match / weakest** | Highest / lowest rated player. |
| **Tactical labels** | Team shape (Wide/Balanced/Compact), pressure (Mid Block/High Press), build-up, attacking zone — each with a human-readable reason. |
| **Heatmaps** | Density of player positions across the pitch. |

> **Honest limitations:** GoalSight does **not** detect discrete events (goals,
> fouls, cards, passes), so it does **not** produce scorelines or goals/assists.
> It reports only what it can measure from positions and tracking — possession,
> movement, ratings, and tactics. Identification is by **jersey number and team
> colour, not faces** (privacy by design).

---

## 6. Tips

- **Use short clips for demos.** A few seconds of footage is enough to see the
  full flow; full matches are slow without a GPU.
- **Name carefully.** The naming step is what binds analytics to real players —
  picking the wrong team here mislabels the whole report.
- **Stable camera helps.** Heavy zoom or rapid broadcast cuts can raise pitch
  calibration error and distort metric analytics.
- **Check connectivity.** The app needs to reach the analysis service
  (`ANALYSIS_API_URL`) and Supabase; if results won't load, confirm the service
  `/health` endpoint is reachable.
