# Screenshots & Sample Outputs

This page collects screenshots of the GoalSight app and sample outputs from the
AI pipeline. Image assets live in [`screenshots/`](screenshots/).

> **For the team:** add your captured images to `docs/screenshots/` and link them
> below. Suggested filenames are listed so the links work as soon as you drop the
> files in. Capture on an emulator/device with `flutter run` (or use the in-app
> screenshot tooling). For the model, the annotated video and heatmap PNGs are
> produced under `football_ai/outputs/`.

---

## App preview

![GoalSight app preview](screenshots/app-preview.png)

---

## Suggested screenshot set

Drop these into `docs/screenshots/` and they will render here.

### Authentication & onboarding
- `auth-login.png` — login screen (dark glassmorphism)
- `auth-register.png` — sign-up screen

### Manager
- `manager-dashboard.png` — manager home dashboard
- `upload-select.png` — video selection
- `upload-details.png` — match details form
- `processing-stage1.png` — Stage 1 detection progress (AI loader)
- `player-naming.png` — **the human-in-the-loop naming screen** (jersey-crop gallery + team pick)
- `processing-stage2.png` — Stage 2 analysis progress
- `results-overview.png` — results: ratings, tactical summary, possession
- `results-video.png` — annotated video with minimap
- `results-heatmap.png` — player/team heatmap
- `pdf-report.png` — exported PDF match report
- `players-squad.png` — squad / players screen

### Fan
- `fan-home.png` — fan home
- `fan-standings.png` — league standings
- `fan-match-analysis.png` — published match analysis
- `fan-player-heatmap.png` — player heatmap

### Admin
- `admin-overview.png` — club overview
- `admin-squad.png` — squad management

---

## Sample model outputs

The `football_ai` pipeline writes these artifacts to `outputs/` (`<stem>` = the
uploaded video / job id). Add representative copies here for the submission.

| Artifact | File pattern | Suggested asset |
|---|---|---|
| Annotated final video | `<stem>_final_with_minimap.mp4` | link or short GIF `sample-annotated.gif` |
| Team heatmap | `<stem>_team0_heatmap.png` | `sample-team0-heatmap.png` |
| Best-player heatmap | `<stem>_team0_best_player_heatmap.png` | `sample-best-player-heatmap.png` |
| Top-down minimap | `<stem>_minimap.mp4` | `sample-minimap.gif` |
| AI match report (JSON) | `<stem>_final_report.json` | paste an excerpt below |

### Example match-report excerpt (JSON)

```jsonc
{
  "dominant_team": "home",
  "man_of_the_match": { "name": "Player 10", "rating": 8.4 },
  "weakest_player":   { "name": "Player 3",  "rating": 5.1 },
  "key_insights": [
    "Home team controlled possession and pressed high.",
    "Away team sat in a mid-block and transitioned quickly."
  ],
  "recommendations": [
    "Exploit the wide channels — away full-backs left space behind.",
    "Manage minutes for Player 7 (high fatigue indicators)."
  ]
}
```

> The full artifact reference (every JSON/PNG/MP4 the pipeline produces) is in
> [GOALSIGHT_TECHNICAL_DOCUMENTATION.md — Appendix A](../GOALSIGHT_TECHNICAL_DOCUMENTATION.md#appendix-a--output-artifacts-reference).
