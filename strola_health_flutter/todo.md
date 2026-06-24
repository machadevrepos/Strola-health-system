# Client Feature Requests (Sarah)
# ─────────────────────────────────────────────────────────────
# RESEARCH COMPLETE — Library stack chosen per feature below
# Color theme + typography: UNCHANGED (existing AppColors + text theme)
# ─────────────────────────────────────────────────────────────

## Freemium Structure
- [ ] Define which features are free vs premium/paid
- [ ] Paywall screen with premium upsell (GlassCard + confetti on upgrade)
- [ ] Custom branding (client logo, brand name, splash screen)

---

## FEATURE 1 — Walk / Run Session
**Libraries:**
- `geolocator: ^13.x` — live GPS position stream
- `google_maps_flutter: ^2.x` — map display (OR `flutter_map` if no API key)
- `flutter_polyline_points: ^2.x` — draw route on map
- `lottie: ^3.x` — walking/running animated character (from lottiefiles.com, free fitness JSONs)
- `sensors_plus: ^6.x` — accelerometer for cadence detection (walk vs run)

**UI plan:**
- Session start screen: big animated Lottie runner, glass start button with haptic
- Active session: blurred map fullscreen + floating glass card overlay (steps, distance, pace, time)
- Pause/Resume/Stop controls: neumorphic buttons
- Post-session summary: animated stats reveal with confetti on PR (personal record)

**Todos:**
- [ ] Session state machine (idle → active → paused → stopped)
- [ ] Live GPS stream + polyline drawing on map
- [ ] Session timer widget (MM:SS with TweenAnimationBuilder)
- [ ] Lottie walk/run character on start screen
- [ ] Post-session summary screen (animated stats)
- [ ] Save session to sqflite

---

## FEATURE 2 — Workout Log
**Libraries:**
- `skeletonizer: ^1.x` — skeleton shimmer while loading history from DB
- `fl_chart` (already have) — mini sparkline per session
- `sqflite` (already installed) — wire up session storage
- `intl: ^0.19.x` — date/duration formatting

**UI plan:**
- List of past sessions: glass cards with shimmer on load, staggered .fadeIn().slideY()
- Each card: activity type icon (Lottie), date, steps, distance, duration, mini route thumbnail
- Filter tabs: All / Walk / Run (animated tab indicator)
- Empty state: Lottie "no activity yet" animation

**Todos:**
- [ ] Wire sqflite session repository (save + query)
- [ ] Workout log screen with skeletonizer loading states
- [ ] Session card widget (GlassCard + mini stats row)
- [ ] Filter tabs (walk / run / all) with animated underline
- [ ] Empty state Lottie animation

---

## FEATURE 3 — GPS Outdoor Route Tracking
**Libraries:**
- `geolocator: ^13.x` — continuous position updates
- `google_maps_flutter: ^2.x` — interactive map
- `flutter_polyline_points: ^2.x` — route line rendering
- `location: ^7.x` — background location (foreground service on Android)

**UI plan:**
- Map fullscreen with dark/satellite style tile
- Frosted glass overlay card at bottom (pace, elevation, distance)
- Route drawn in accent coral colour on map
- Breadcrumb dots at waypoints

**Todos:**
- [ ] Continuous GPS tracking + polyline update stream
- [ ] Custom dark map style (JSON style for Google Maps)
- [ ] Glass overlay HUD card during tracking
- [ ] Save route coordinates alongside session in sqflite

---

## FEATURE 4 — Daily / Weekly / Monthly Step Totals
**Libraries:**
- `fl_chart` (already have) — bar + line chart variants
- `sqflite` (already installed) — query aggregated step data
- `table_calendar: ^3.x` — monthly calendar heat-map view
- `intl: ^0.19.x` — date grouping

**UI plan:**
- Tab switcher: Day / Week / Month with page-slide animation
- Day view: 24-hour step distribution bar chart
- Week view: existing 7-day bar chart (improve with goal line + animations)
- Month view: calendar heat-map (green gradient intensity = steps)
- Summary cards at top: total, avg/day, best day, goal days hit

**Todos:**
- [ ] Wire sqflite → aggregate steps by day/week/month
- [ ] Day view (hourly distribution from BLE session data)
- [ ] Week view (improve existing WeeklyChart)
- [ ] Month view (table_calendar with colour-coded step intensity)
- [ ] Summary stat cards with animated number counters

---

## FEATURE 5 — Personalised Step Goal Setting
**Libraries:**
- `numberpicker: ^2.x` — drum-roll scroll picker for goal number
- `shared_preferences` (already installed) — persist goal

**UI plan:**
- Settings screen section OR bottom sheet modal
- Drum-roll picker: scroll through 1,000–30,000 in 500 increments
- Live preview: StepRing updates in real-time as you scroll picker
- Confirm button: haptic + confetti burst when new goal saved
- Quick-pick chips: 5k / 7.5k / 10k / 15k

**Todos:**
- [ ] Wire shared_preferences → save/load dailyGoalProvider
- [ ] Goal picker bottom sheet (numberpicker + quick chips)
- [ ] Live StepRing preview in sheet
- [ ] Persist goal across app restarts

---

## FEATURE 6 — Home Screen Widget
**Libraries:**
- `home_widget: ^0.6.x` — Flutter ↔ native widget bridge
- Native: SwiftUI (iOS) + Jetpack Glance / XML (Android)

**UI plan:**
- Small widget: circular step ring + step count + goal %
- Medium widget: step count + calories + distance + day label
- Data updates: every time app receives BLE step update → push to home_widget

**Note:** Requires native code (SwiftUI for iOS, Glance/XML for Android). Not pure Flutter.

**Todos:**
- [ ] Android widget (Jetpack Glance or XML layout)
- [ ] iOS widget (SwiftUI WidgetKit)
- [ ] home_widget bridge to push step data from Flutter
- [ ] Background update trigger on step count change

---

## FEATURE 7 — Community Forum
**Libraries:**
- `firebase_core + cloud_firestore + firebase_auth: latest` — backend
- `cached_network_image: ^3.x` — user avatars (cached, no flicker)
- `timeago: ^3.x` — "2 hours ago" relative timestamps
- `skeletonizer: ^1.x` — post list shimmer loading

**UI plan:**
- Feed of posts: glass cards, avatar, username, timestamp, content, like/comment counts
- Like button: animated heart burst (flutter_animate scale + opacity)
- New post: glass bottom sheet with text input + image picker
- Post detail: threaded replies with staggered animation

**Todos:**
- [ ] Firebase setup (Auth + Firestore data model)
- [ ] Community feed screen (paginated Firestore query)
- [ ] Post card widget (glass + avatar + like animation)
- [ ] New post bottom sheet
- [ ] Post detail + threaded replies

---

## FEATURE 8 — Step Challenges
**Libraries:**
- `animated_leaderboard: ^0.x` — animated rank cards
- `cloud_firestore` (same as community) — challenge data + real-time rankings
- `confetti` (already have) — winner celebration

**UI plan:**
- Challenge browse: cards showing name, prize badge, days left, participant count
- Active challenge card on HomeScreen: mini leaderboard showing your rank + top 3
- Leaderboard screen: animated_leaderboard with rank transitions
- Challenge complete: full-screen confetti + trophy Lottie animation
- Create challenge: invite friends by username / share link

**Todos:**
- [ ] Firestore data model (challenges, participants, daily snapshots)
- [ ] Challenge browse + join screen
- [ ] Animated leaderboard screen
- [ ] Active challenge widget on HomeScreen
- [ ] Daily step snapshot sync to Firestore
- [ ] Challenge completion screen (confetti + Lottie trophy)

---

## SKIPPING FOR NOW
- [ ] Integration with Apple Health, Google Health, Strava, etc.

---

## GLOBAL UI POLISH (applies to every screen)
New packages to add:
- `lottie: ^3.x` — replaces rive (simpler, free assets on lottiefiles.com)
- `skeletonizer: ^1.x` — skeleton shimmer on all data-loading screens
- `page_transition: ^2.x` — premium page route transitions (fade+scale, shared axis)
- `google_maps_flutter: ^2.x` — GPS maps
- `geolocator: ^13.x` — GPS location
- `flutter_polyline_points: ^2.x` — route drawing
- `numberpicker: ^2.x` — goal setting picker
- `table_calendar: ^3.x` — monthly heat-map
- `cached_network_image: ^3.x` — network images
- `timeago: ^3.x` — relative timestamps
- `animated_leaderboard: ^0.x` — leaderboard UI
- `firebase_core + firebase_auth + cloud_firestore` — community + challenges
- `home_widget: ^0.6.x` — home screen widget
- `sensors_plus: ^6.x` — accelerometer for walk/run detection
- `intl: ^0.19.x` — formatting (likely already transitive)

Rules for every screen built:
- Skeleton shimmer ALWAYS shown before real data appears
- Every list item: .fadeIn().slideY(begin: 0.15) stagger
- Every number that changes: TweenAnimationBuilder
- All surfaces: GlassCard (never bare Container or Card)
- Error/empty states: Lottie animation (never blank screen or generic text)
- Page transitions: page_transition (not default push)
- No overflow: test on 320px width + large font size
