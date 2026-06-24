# Claude AI Assistant — Strolla Health Flutter App

## Project Context
- **App Name**: Strolla Health (package: `strola_health`)
- **App Type**: BLE step counter + workout tracker + community app
- **Audience**: Women in the UK — professional, warm, encouraging tone
- **Device**: Nordic nRF7002 DK with Zephyr RTOS + MPU-6050 IMU
- **Framework**: Flutter (Dart SDK `^3.10.8`)
- **BLE Protocol**: Nordic UART Service (NUS) over `flutter_reactive_ble`
- **Architecture**: Clean architecture — domain / data / presentation layers
- **State Management**: Riverpod (manual `StateNotifier` pattern — no codegen)

---

## Dependencies (pubspec.yaml — source of truth)

### UI & Animations
- `flutter_animate: ^4.5.0` — entrance animations on lists and cards
- `animate_icons: ^2.0.0` — installed, not yet wired (walk→run→celebrate)
- `glassmorphism: ^3.0.0` — installed, **not used on main screens** (reserved)
- `confetti: ^0.7.0` — goal celebration burst + haptics
- `flex_color_scheme: ^8.4.0` — Material 3 light theme engine
- `lottie: ^3.1.0` — installed, not yet used
- `skeletonizer: ^2.1.3` — shimmer skeletons for async states

### Charts & Gauges
- `fl_chart: ^0.68.0` — bar charts
- `syncfusion_flutter_gauges: ^28.1.0` — `SfRadialGauge` for step ring only

### BLE & Hardware
- `flutter_reactive_ble: ^5.4.0` — all BLE scanning, connecting, notifications
- `permission_handler: ^11.3.1` — location + BLE permissions
- `sensors_plus: ^6.1.1` — installed, not yet used

### State Management
- `flutter_riverpod: ^2.5.1` — manual `StateNotifier` pattern

### Local Storage
- `shared_preferences: ^2.3.2` — persists `dailyGoalProvider`
- `sqflite: ^2.3.3+1` — workout sessions + daily steps
- `path: ^1.9.0` — required by sqflite

### Maps & GPS
- `flutter_map: ^7.0.2` — live session map
- `latlong2: ^0.9.1` — LatLng for polylines
- `geolocator: ^13.0.2` — location stream during sessions

### UI Components
- `numberpicker: ^2.1.2` — goal wheel picker
- `table_calendar: ^3.1.2` — calendar heat-map

### Utilities
- `intl: ^0.19.0` — date formatting
- `timeago: ^3.7.0` — community timestamps
- `home_widget: ^0.7.0` — home/lock screen widgets

**Do NOT add without discussion**: `rive`, `animations`, `flutter_haptics`, `riverpod_annotation`, `syncfusion_flutter_charts`

**Haptics**: Use Flutter's built-in `HapticFeedback` (from `services`), never a package.
- Goal completion: triple `HapticFeedback.heavyImpact()` with 100 ms delays
- Milestones (25 %, 50 %, 75 %): single `HapticFeedback.mediumImpact()`

---

## Design System

> These rules are non-negotiable. Every screen, card, and widget must follow them exactly.
> The app is published to the whole of the UK and must look professional, not vibe-coded.

### Mode
Light only. Never add dark mode branches. `FlexThemeData.light()` is the only theme variant.

---

### Color Palette — `lib/core/constants/app_colors.dart`

Exactly 5 base colors. All usage must derive from these.

| Token | Hex | Usage |
|---|---|---|
| `AppColors.accent` | `#E07A7A` | Primary — ring fill, active nav, buttons, links, FAB |
| `AppColors.accentSecondary` | `#F6B1B1` | Secondary — blush tints, inactive borders, icon bg |
| `AppColors.bgDeep` | `#FFF2F2` | Deepest background (bottom of gradient) |
| `AppColors.bgSurface` | `#FFFFFF` | Card surfaces, nav bar, screen background |
| `AppColors.textPrimary` | `#333333` | All primary text |
| `AppColors.textSecondary` | `#B3333333` | 70 % opacity — secondary / supporting text |
| `AppColors.textMuted` | `#66333333` | 40 % opacity — labels, units, muted metadata |
| `AppColors.goalAmber` | `#E9B44C` | Goal-reached state only (ring + confetti) |
| `AppColors.success` | `#55A56B` | BLE connected status only |
| `AppColors.error` | `#E25858` | Error states only |

**Rules**:
- No other colors. Do not introduce purple, blue, green, grey, or any new hex value.
- Opacity variants must use `withValues(alpha: x)` on the 5 base colors — never new hex.
- `AppColors.bgGradient` (surface → deep → mid) is the full-screen background drawn by `MainShell`.
- Scaffold background is always `Colors.transparent` — the gradient is on the parent container.

---

### Typography — `lib/core/constants/app_typography.dart`

Always use `AppTypography.*` constants. **Never write an inline `TextStyle` in a widget.**

| Constant | Size | Weight | Letter Spacing | Use case |
|---|---|---|---|---|
| `AppTypography.displayXL` | 52 | w800 | -2.0 | Step count hero, primary KPI |
| `AppTypography.displayL` | 36 | w700 | -1.5 | Session stats, large metrics |
| `AppTypography.displayM` | 28 | w700 | -1.0 | Card-level hero numbers |
| `AppTypography.titleL` | 20 | w600 | -0.4 | Screen-level titles |
| `AppTypography.titleM` | 17 | w600 | -0.3 | In-screen section headers |
| `AppTypography.titleS` | 15 | w600 | -0.2 | Sub-section labels |
| `AppTypography.bodyL` | 15 | w500 | -0.1 | Stat values, primary list items |
| `AppTypography.bodyM` | 14 | w400 | 0.0 | Secondary body copy |
| `AppTypography.bodyS` | 13 | w400 | +0.1 | Supporting text, timestamps |
| `AppTypography.labelM` | 12 | w500 | +0.3 | Tag text, metadata |
| `AppTypography.labelS` | 11 | w500 | +0.4 | Unit labels below stat values |
| `AppTypography.brand` | 26 | w800 | -0.8 | "strolla" wordmark in app bar only |

**Rules**:
- For color overrides use `.copyWith(color: ...)` — never a wrapping `DefaultTextStyle`.
- Display styles have `fontFeatures: [FontFeature.tabularFigures()]` built in — do not add it again.
- `height` is set on every style — do not override height without good reason.

---

### Icons — `lib/core/constants/app_icons.dart`

Always use `AppIcons.*` constants. **Never use `Icons.*` directly in widgets.**

All icons are from the **Material outline family** (`_outlined` or `_outline` or `_border`).
Never use filled variants (e.g., `Icons.home`, `Icons.favorite`, `Icons.notifications`).

Key icon constants:
- Navigation: `AppIcons.home`, `.stats`, `.start`, `.community`, `.profile`
- Metrics: `AppIcons.steps`, `.calories`, `.distance`, `.duration`, `.pace`
- Actions: `AppIcons.back`, `.close`, `.add`, `.share`, `.settings`, `.filter`
- Goals: `AppIcons.goal`, `.goalReached`, `.streak`, `.trophy`, `.milestone`
- Session: `AppIcons.play`, `.pause`, `.stop`, `.map`, `.timer`
- BLE: `AppIcons.bluetooth`, `.bluetoothSearch`, `.bluetoothConnected`, `.battery`
- Community: `AppIcons.like`, `.comment`, `.challenge`, `.people`
- Status: `AppIcons.info`, `.warning`, `.error`

---

### Spacing & Sizing — `lib/core/constants/app_theme.dart`

Always use `AppTheme.*` constants. **Never hard-code numeric spacing or radii.**

**Spacing scale**:
`spaceXS` 4 · `spaceS` 8 · `spaceM` 12 · `spaceL` 16 · `spaceXL` 20 · `spaceXXL` 24 · `spaceXXXL` 32

- `AppTheme.screenPaddingH = 24` — horizontal screen padding, used on all screens
- `AppTheme.sectionGap = 14` — vertical gap between cards

**Border radius scale**:
`radiusXS` 6 · `radiusS` 10 · `radiusM` 14 · `radiusL` 18 · `radiusXL` 22 · `radiusSheet` 28 · `radiusFull` 999

- Standard card: `AppTheme.radiusL` (18)
- Buttons / chips: `AppTheme.radiusM` (14) or `AppTheme.radiusFull` (pill)
- Bottom sheets: `AppTheme.radiusSheet` (28)

**Icon sizes**:
`iconXS` 14 · `iconS` 16 · `iconM` 20 · `iconL` 24 · `iconXL` 28 · `iconXXL` 36

- Nav bar icons: `AppTheme.iconM` (20) → actually `navIconSize` 22
- Stat chip icons: `AppTheme.iconL` (24)
- Step ring center: `AppTheme.iconXXL` (36)

**Shadows** — always use these; never write a custom `BoxShadow`:
- `AppTheme.cardShadow` — flat content cards
- `AppTheme.elevatedShadow` — buttons, FABs, prominent cards
- `AppTheme.glowShadow` — avatar / icon circle glow

**Animation durations**:
`animXS` 150ms · `animFast` 200ms · `animNormal` 300ms · `animSlow` 500ms · `animSpring` 700ms · `animCrawl` 900ms

---

### Card — `lib/presentation/widgets/flat_card.dart`

`FlatCard` is the **only** card widget for content. Never use bare `Container`, `Material`, `Card`, or `GlassCard` for screen content.

```dart
FlatCard(
  child: ...,
  padding: const EdgeInsets.all(AppTheme.spaceL),  // default
  borderRadius: AppTheme.radiusL,                   // default 18
)
```

`FlatCard` spec: white surface · `AppTheme.radiusL` radius · `AppTheme.cardShadow` · thin blush border (`accentSecondary` at 25 % alpha).

---

### FlexColorScheme Config (`main.dart`)

```dart
FlexThemeData.light(
  colors: FlexSchemeColor(
    primary:            Color(0xFFE07A7A),
    primaryContainer:   Color(0xFFFFDADA),
    secondary:          Color(0xFFF6B1B1),
    secondaryContainer: Color(0xFFFFE7E7),
    tertiary:           Color(0xFFE9B44C),
    tertiaryContainer:  Color(0xFFFFE8B8),
    appBarColor:        Color(0xFFFFFFFF),
    error:              Color(0xFFE25858),
  ),
  surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
  blendLevel: 8,
  subThemesData: FlexSubThemesData(defaultRadius: 16),
)
// theme.textTheme → AppTypography.textTheme (set in main.dart)
// theme.scaffoldBackgroundColor → Colors.transparent (gradient on MainShell)
```

---

## BLE Device Constants — `lib/core/constants/ble_constants.dart`

```
deviceName:   'NRF7002_STEPS'
serviceUuid:  '6e400001-b5a3-f393-e0a9-e50e24dcca9e'
txCharUuid:   '6e400003-b5a3-f393-e0a9-e50e24dcca9e'  (notify — firmware → phone)
rxCharUuid:   '6e400002-b5a3-f393-e0a9-e50e24dcca9e'  (write — phone → firmware)
scanTimeout:  15 seconds
maxRetries:   6 — exponential backoff 1→2→4→8→16→30 s
```

Packet formats (3 encodings):
1. 4 bytes → `uint32_t` little-endian
2. 2 bytes → `uint16_t` little-endian
3. N bytes → ASCII/UTF-8 string (strip null + non-digits)

---

## Actual File Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       — color palette (5 base colors + derived)
│   │   ├── app_typography.dart   — ALL TextStyle constants (AppTypography)
│   │   ├── app_icons.dart        — ALL icon constants (AppIcons, outline family)
│   │   ├── app_theme.dart        — spacing, radii, shadows, animation durations
│   │   ├── ble_constants.dart    — UUIDs, device name, backoff config
│   │   └── step_goals.dart       — default 10k, cal/step, stride, milestones
│   └── utils/
│       ├── formatters.dart       — step/distance/calorie/date formatters
│       └── haptics_helper.dart   — goal + milestone haptic wrappers
├── data/
│   ├── datasources/
│   │   ├── ble_step_service.dart — BLE lifecycle + generation-counter + packet parser
│   │   └── local_database.dart   — SQLite: workout_sessions + daily_steps
│   └── repositories/
│       ├── session_repository.dart   — CRUD sessions + daily aggregation
│       └── community_repository.dart — mock posts + challenges
├── domain/
│   └── entities/
│       ├── workout_session.dart
│       ├── community_post.dart
│       └── challenge.dart
├── presentation/
│   ├── providers/
│   │   ├── ble_providers.dart        — bleServiceProvider, bleStatusProvider, bleStepStreamProvider
│   │   ├── step_providers.dart       — stepCountProvider, dailyGoalProvider, derived providers
│   │   ├── session_providers.dart    — SessionNotifier: GPS, timer, pause/resume, save
│   │   └── community_providers.dart  — PostsNotifier, ChallengesNotifier
│   ├── screens/
│   │   ├── main_shell.dart             — 5-tab nav bar + gradient background
│   │   ├── home_screen.dart            — dashboard: step ring, stat chips, chart, milestones
│   │   ├── stats_screen.dart           — weekly/monthly stats
│   │   ├── session_screen.dart         — session type picker + live map/timer
│   │   ├── session_summary_screen.dart — post-session recap + confetti
│   │   ├── community_screen.dart       — feed + challenges
│   │   └── profile_screen.dart         — settings, goal, integrations
│   └── widgets/
│       ├── flat_card.dart          — FlatCard: the ONLY card widget
│       ├── step_ring.dart          — SfRadialGauge step ring
│       ├── weekly_chart.dart       — fl_chart bar chart
│       ├── ble_status_chip.dart    — BLE connection pill
│       ├── goal_settings_sheet.dart — NumberPicker bottom sheet
│       ├── skeleton_loaders.dart   — Skeletonizer shimmer
│       ├── route_map.dart          — flutter_map polyline map
│       ├── strolla_icons.dart      — custom painted icons (shoe, footstep, etc.)
│       └── widget_preview_card.dart — home/lock screen widget preview
```

---

## Navigation

**5-tab bottom nav** (flat white bar, center FAB):

| Nav index | Label | Destination |
|-----------|-------|-------------|
| 0 | Home | `HomeScreen` |
| 1 | Stats | `StatsScreen` |
| 2 | **Start** (FAB) | `SessionScreen` — modal push |
| 3 | Community | `CommunityScreen` |
| 4 | Profile | `ProfileScreen` |

FAB: 52 px coral circle (`AppColors.accent`), `AppIcons.start` icon, raised above nav bar.
Active nav items: coral (`AppColors.accent`). Inactive: muted (`AppColors.textMuted`).

---

## Provider Architecture

```
bleServiceProvider (Provider<BleStepService>)
  ├─ bleStepStreamProvider (StreamProvider<int>)   — raw BLE step count
  └─ bleStatusProvider (StateNotifier<BleStatus>)

stepCountProvider (StateNotifier<int>)
  ├─ real steps from bleStepStreamProvider when connected
  └─ mock timer (+1–8 every 3 s) when disconnected

dailyGoalProvider (StateNotifier<int>)    — SharedPreferences persisted
userWeightKgProvider (StateNotifier<double>) — SharedPreferences persisted

caloriesProvider   (Provider<int>)    — steps × weight × 0.000571 (need to add the activityFactor as well)
distanceProvider   (Provider<String>) — formatted km/m string (Stride length)
progressProvider   (Provider<double>) — steps ÷ goal, clamped 0.0–1.0
weeklyStepsProvider (Provider<List<int>>) — [Mon…Sat hardcoded, today=live]
goalReachedProvider (Provider<bool>)

sessionProvider (StateNotifier<SessionState>)
postsProvider, challengesProvider
```

---

## SQLite Schema

```sql
CREATE TABLE workout_sessions (
  id               TEXT    PRIMARY KEY,
  start_time       INTEGER NOT NULL,
  end_time         INTEGER NOT NULL,
  steps            INTEGER NOT NULL,
  distance_meters  REAL    NOT NULL,
  duration_seconds INTEGER NOT NULL,
  activity_type    TEXT    NOT NULL,      -- 'walk' | 'run'
  route_points     TEXT    NOT NULL DEFAULT ''
);

CREATE TABLE daily_steps (
  date  TEXT    PRIMARY KEY,             -- 'YYYY-MM-DD'
  steps INTEGER NOT NULL
);
```

---

## Implementation Status

### Complete
- BLE scanning/connecting, exponential backoff, generation-counter async safety
- Step counting (BLE real + mock fallback)
- Daily goal, persisted (`shared_preferences`)
- SQLite schema + `SessionRepository`
- `CommunityRepository` (mock, Firebase-ready)
- Domain entities: `WorkoutSession`, `CommunityPost`, `Challenge`
- GPS workout sessions + session map + session summary
- Community forum + challenges
- 5-tab glass nav → now flat white nav
- Confetti + haptics on goal
- `FlatCard` canonical card widget
- `AppTypography`, `AppIcons`, `AppTheme` token files

### In Progress / Partial
- `weeklyStepsProvider` — hardcoded Mon–Sat, needs SQLite
- Activity calendar — mock data, not SQLite
- `AnimateIcons` — installed but not wired

### Not Yet Implemented
- Firebase community integration
- User profile / settings screen
- Personal record detection
- Offline sync queue
- Push notifications

---

## Architecture Rules

### BLE
- All BLE logic in `BleStepService` + providers only — never in widgets
- Use **generation counter** (`_connectionGen`) for all async BLE callbacks
- Always set `_active = false` before `await`-ing async cancel/dispose
- GPS permissions requested in widget layer (not in notifiers)

### Performance
- `stepCountProvider` deduplicates — don't emit on every raw BLE packet
- `const` widgets everywhere possible
- `AutomaticKeepAliveClientMixin` on chart/calendar tabs

---

## Code Generation Rules (Must Follow Every Time)

### 1. Design Tokens — Always Use Constants
```dart
// CORRECT
Text('Steps', style: AppTypography.labelS)
Icon(AppIcons.steps, size: AppTheme.iconL)
FlatCard(padding: const EdgeInsets.all(AppTheme.spaceL), child: ...)

// WRONG — never do this
Text('Steps', style: TextStyle(fontSize: 11, ...))
Icon(Icons.directions_walk_rounded, size: 24)
Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), ...))
```

### 2. Icons — Outline Only
```dart
// CORRECT
Icon(AppIcons.home)        // home_outlined
Icon(AppIcons.like)        // favorite_border

// WRONG
Icon(Icons.home_rounded)   // filled
Icon(Icons.favorite)       // filled
```

### 3. Typography — Named Constants Only
```dart
// CORRECT
AppTypography.displayXL    // hero step number
AppTypography.titleM       // card header
AppTypography.bodyM        // description text

// WRONG
TextStyle(fontSize: 52, fontWeight: FontWeight.w800, ...)
Theme.of(context).textTheme.displayLarge  // use AppTypography directly
```

### 4. Card — FlatCard Only
```dart
// CORRECT
FlatCard(child: ...)

// WRONG
Card(child: ...)
Container(decoration: BoxDecoration(color: Colors.white, ...), child: ...)
GlassCard(child: ...)     // never on main screen content
```

### 5. Spacing — AppTheme Constants
```dart
// CORRECT
SizedBox(height: AppTheme.sectionGap)
Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH))

// WRONG
SizedBox(height: 14)
Padding(padding: const EdgeInsets.symmetric(horizontal: 24))
```

### 6. Animations
- All list items: `.animate().fadeIn(duration: AppTheme.animSlow.ms).slideY(begin: 0.12)`
- Stagger: each card adds 60–80 ms delay
- Screen transitions: `AnimatedSwitcher` with `FadeTransition` + `Offset(0.03, 0)` slide
- Numeric values: always `TweenAnimationBuilder<int>` or `<double>`

### 7. Reactive data
- `ref.watch` or `StreamBuilder` — never `setState` for BLE/step data

### 8. Goal celebration
- Confetti + triple `HapticFeedback.heavyImpact()` — **always both together**

### 9. Step ring
- Always `SfRadialGauge` — never custom painters for the ring

### 10. Light theme — text is always dark
- `AppColors.textPrimary` (`#333333`) on all light backgrounds
- Never invert to white text on the app background

### 11. Professional standard
- No decorative elements that serve no function
- No emoji in UI except where data explicitly calls for it (e.g. streak "🔥" from user data)
- Consistent corner radii — always `AppTheme.radiusL` for cards unless documented otherwise
- No mixed icon families — outline only, via `AppIcons`

---

## Example — Correct Pattern

```dart
class StepSummaryCard extends ConsumerWidget {
  const StepSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final goal  = ref.watch(dailyGoalProvider);

    return FlatCard(
      child: Row(
        children: [
          Icon(AppIcons.steps, size: AppTheme.iconL, color: AppColors.accent),
          const SizedBox(width: AppTheme.spaceM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: steps),
                duration: AppTheme.animSpring,
                builder: (_, v, __) => Text(
                  Formatters.stepCount(v),
                  style: AppTypography.displayM,
                ),
              ),
              Text('of ${Formatters.stepCount(goal)} steps',
                  style: AppTypography.labelS),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.animSlow.ms).slideY(begin: 0.12);
  }
}
```
