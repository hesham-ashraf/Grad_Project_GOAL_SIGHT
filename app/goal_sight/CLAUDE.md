# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Commands

```bash
# Analyze for errors and warnings
flutter analyze

# Run on a connected device/emulator
flutter run -d emulator-5554

# Build debug APK (requires network access to Maven repos)
flutter build apk --debug

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

> **Note:** `flutter build apk` requires Gradle to download Flutter engine artifacts from Google's Maven repos. If the machine has network/TLS issues connecting to `dl.google.com`, the build will fail at the Gradle step even though `flutter analyze` passes. All Dart-level errors are caught by `flutter analyze`.

---

## Architecture

### Dual-layer structure

The codebase has **two parallel trees** that coexist — an older `lib/features/` tree and a newer `lib/presentation/` tree. Both are active:

| Tree | Used for |
|---|---|
| `lib/features/manager/` | Manager role screens, widgets, mock data |
| `lib/features/auth/` | Auth controller + state |
| `lib/features/admin/` | Admin controller + state |
| `lib/presentation/screens/fan/` | All fan-role screens |
| `lib/presentation/screens/admin/` | All admin-role screens |
| `lib/presentation/widgets/fan/` | All fan-role widgets |
| `lib/presentation/state_management/` | Riverpod providers (app-wide) |
| `lib/shared/` | Reusable primitives (animations, charts, components, widgets) |
| `lib/core/` | Theme, responsive utils, services, constants |
| `lib/data/` | Models, repositories, remote data sources |

New manager/upload work should go in `lib/features/manager/` (screens) and `lib/features/manager/widgets/` (widgets), following the pattern already established there.

### State management

Riverpod with `StateNotifierProvider`. All providers are declared in `lib/presentation/state_management/app_providers.dart`. Mock data is returned directly from providers — no async fetching yet.

The auth flow drives role-based routing: `AuthController` → `AuthState` (status: initial / loading / authenticated / emailVerificationRequired) → `routerProvider` redirects to `/fan`, `/manager`, or `/admin`.

### Navigation

GoRouter in `lib/presentation/state_management/router_provider.dart`. All routes are flat (no nested shell routes). Object passing uses `state.extra` cast to the model type. Custom page transitions via `goalSightTransitionPage()` from `lib/shared/transitions/transitions.dart` — use `GoalSightPageTransition.slideLeft` for drill-downs, `.fade` for top-level, `.modal` for sheets.

The manager shell (`/manager`) renders `ManagerNavigationScreen` which uses `IndexedStack` + `ManagerBottomNavigationBar`. Tabs: Home → Matches → Upload → Players → Profile.

### Design system

All tokens are in `lib/core/theme/app_theme.dart`:

- **Colors:** `AppColors.background` (`#050816`), `.surface`, `.surfaceElevated`, `.surfaceRaised`, `.primaryBlue`, `.primaryPurple`, `.accentCyan`, `.accentGreen`, `.warning`, `.danger`
- **Text styles:** `AppTextStyles.headline()`, `.title()`, `.body()`, `.caption()`, `.button()` — all accept an optional `color:` param
- **Radius:** `AppRadius.card`, `.cardLarge`, `.button`, `.input`, `.chip`
- **Spacing:** `AppSpacing.page`, `.card`, `.cardCompact`, `.section`
- **Gradients:** `AppGradients.brand` (purple→cyan), `.live` (cyan→green), `.surface`
- **Shadows:** `AppShadows.card`, `.cardGlow`, `.buttonGlow`

**Critical:** Always use `.withValues(alpha: x)` for color transparency — **never** `.withOpacity()`. The codebase enforces this consistently and `flutter analyze` flags `.withOpacity()` as deprecated.

### Responsive utilities

`lib/core/utils/responsive.dart` exports a `ResponsiveContext` extension on `BuildContext`:

```dart
context.rs(18, min: 14, max: 22)   // scaled size relative to 390pt baseline
context.sp(16, min: 12, max: 20)   // scaled font size
context.adaptiveLayout(narrow: ..., wide: ...)  // switches at 720pt width
context.isPhone / .isTablet / .isWideLayout
context.padAll(16) / .padSym(h: 20, v: 12)
context.hPad / .sectionGap / .cardPad
```

Also available: `AdaptiveRow`, `ResponsiveGrid`, `ResponsiveCentered` widgets.

### Animation pattern

All screens use `SingleTickerProviderStateMixin` with a single `AnimationController`. Staggered section reveals use `Interval`-based `CurvedAnimation`:

```dart
_ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
_fades = List.generate(N, (i) {
  final start = (i * 0.08).clamp(0.0, 0.85);
  final end = (start + 0.22).clamp(0.0, 1.0);
  return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
});
_slides = _fades.map((f) => Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(f)).toList();
```

Wrap each section: `FadeTransition(opacity: _fades[i], child: SlideTransition(position: _slides[i], child: ...))`.

### Shared primitive widgets

Located in `lib/shared/widgets/`:

- `GsAnimatedBar` — horizontal animated fill bar; params: `value`, `color`, `backgroundColor`, `height`, `label`, `valueLabel`, `showLabel`, `delay`
- `GsDualBar` — two-team comparison bar
- `GsAnimatedCounter` — animated number counter; params: `value`, `style`, `decimals`, `delay`
- `GsStatRing` — circular animated ring; params: `value` (0–1), `color`, `size`, `strokeWidth`, `delay`
- `GsMiniLineChart` — single bezier line chart (CustomPainter); params: `data`, `color`, `height`, `showDots`, `delay`
- `GsDualLineChart` — two-line comparison chart
- `GsPitchWidget` — football pitch with heatmap/formation/arrow overlays
- `GsRadarChart` — spider/radar chart; params: `labels`, `values`, `color`, `size`, `delay`

All animate on first render via internal `AnimationController` + `Future.delayed(delay, ...)`.

### Mock data locations

| Area | File |
|---|---|
| Manager dashboard | `lib/features/manager/manager_dashboard_mock_data.dart` |
| Manager matches | `lib/features/manager/manager_matches_mock_data.dart` |
| Upload / analysis generation | `lib/features/manager/manager_upload_mock_data.dart` |
| Players (manager view) | `lib/features/manager/players_mock_data.dart` |
| Match analyses (3 matches) | `lib/presentation/state_management/match_analysis_providers.dart` |
| Fan clubs | `lib/presentation/state_management/clubs_provider.dart` |
| Team members | `lib/presentation/state_management/app_providers.dart` (`teamMembersProvider`) |

### Repository pattern (Mock Data Architecture)

Interfaces live in `lib/data/repositories/interfaces/`, mock implementations in `lib/data/repositories/mock/`. Riverpod providers in `lib/presentation/state_management/repository_providers.dart`.

| Interface | Mock | Swap to |
|---|---|---|
| `IClubRepository` | `MockClubRepository` | `SupabaseClubRepository` |
| `IPlayerRepository` | `MockPlayerRepository` | `SupabasePlayerRepository` |
| `IAnalysisRepository` | `MockAnalysisRepository` | `SupabaseAnalysisRepository` |
| `IUploadRepository` | `MockUploadRepository` | `SupabaseUploadRepository` |
| `IManagerRepository` | `MockManagerRepository` | `SupabaseManagerRepository` |

Key providers: `clubListProvider`, `squadProvider`, `playerRiskProvider`, `squadRiskProvider`, `matchAnalysisListProvider`, `uploadHistoryProvider`, `managerListProvider`.

`RiskAnalysisModel` in `lib/data/models/risk_analysis_model.dart` — composite fatigue/injury/consistency/tactical risk per player. `RiskLevel` enum (low/medium/high/critical) with severity scores (0.15/0.45/0.72/0.95).

### UX Polish components

Located in `lib/shared/animations/`:

- `GsPullRefresh` — `RefreshIndicator` wrapper with haptic feedback; applied to Fan Home, Matches, Clubs, Standings, Manager Dashboard, Upload History, Admin Dashboard
- `GsSuccessOverlay` — full-screen animated success overlay; call `GsSuccessOverlay.show(context, type: GsSuccessType.uploadComplete)`; `GsSuccessSnackBar.show()` for lightweight variant
- `GsAiLoader` — futuristic AI processing overlay with rotating rings, scan lines, stage timeline; use `GsAiStageCard` for compact inline version
- `GsInsightReveal` — staggered AI insight list reveal with fade+slide per item
- `GsShimmer` — shimmer loading animation wrapper; convenience constructors: `GsShimmer.bar(width, height)`, `GsShimmer.line(height)`, `GsShimmer.circle(size)`, `GsShimmer.card(height, radius)`; convenience layouts: `GsShimmerListItem`, `GsShimmerStatCard`, `GsShimmerPage`

`HapticService` in `lib/core/services/haptic_service.dart` — centralised haptic patterns: `selection()`, `light()`, `medium()`, `success()`, `error()`, `refresh()`, `aiReveal()`, `longPress()`.

### Auth screen components

All auth screens (`login`, `register`, `forgot_password`, `email_verification`) use the **dark premium glassmorphism** aesthetic — same `#050816` background as the rest of the app. Do **not** wrap auth screens with `Theme(data: AppTheme.lightTheme(), ...)`.

Shared auth widgets in `lib/presentation/widgets/auth_card_widgets.dart`:

- `AuthBackground` — dark `Scaffold` + gradient orbs (wrap each auth screen's return value)
- `AuthCard` — glassmorphism container (`AppColors.surfaceElevated` + outline border + shadow)
- `AuthGradientTitle` — brand gradient headline via `ShaderMask`
- `AuthErrorBox` — styled error container (danger border + icon)
- `AuthSuccessBox` — styled success container (green border + icon)
- `AuthDividerLabel` — horizontal divider with center text
- `DemoLoginSection` — quick role-login chips (Fan / Manager / Admin)
- `PasswordToggleIcon` — eye icon for password visibility toggle

`GoalSightLogo` widget — use `showSubtitle: false` on auth screens and splash (the screens provide their own tagline text below the logo). The logo always renders the icon + "GOALSIGHT" gradient text. The optional subtitle ("Football Analytics Platform") is for standalone brand moments only.

### Supabase / backend

`lib/core/supabase/supabase_config.dart` holds connection config. Supabase is initialized in `main.dart` only if `hasSupabaseConfig` is true. All current data flows are mock — **do not integrate Supabase or real APIs** until Phase 2 of the roadmap.

The `kShowSupabaseTestPage` flag in `router_provider.dart` redirects the initial route to a test page; keep it `false`.

### Development phases

See `DEVELOPMENT_ROADMAP.md` for the full phase breakdown. Currently in **Phase 1 (Flutter frontend)**. The remaining manager work is tracked there under "Manager Role" and "Upload Workflow".
