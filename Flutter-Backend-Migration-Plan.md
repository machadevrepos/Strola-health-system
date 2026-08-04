# Flutter → Firebase Backend Migration Plan

Status: **awaiting sign-off, no code changed yet.**

## Why this exists

The mobile app currently talks to the retired FastAPI backend (`api_client.dart`'s
`apiBaseUrl` defaults to `http://localhost:8000/api/v1`) for everything except sign-in
identity. The real backend (`strola_health_firebase`, project `strolla-health-4c93b`) has
been fully built, deployed, and tested all session, this plan is what it takes to actually
point the app at it. See `[[mobile-app-still-on-fastapi]]` memory for how this was first
found.

This document is the audit phase, same process as the original backend build: explore
first, agree on scope, then implement. Nothing below has been implemented yet.

## What the audit found

Ran a file-by-file survey of every feature area that would touch the backend. Result:
this is bigger than "wire Community and Challenges", it's ten feature areas, and a few of
them have **no real implementation at all today**, not even mock data, just hardcoded
UI or a cosmetic action that does nothing. Grouping by what's actually needed:

### Tier 1 — Swap the data source, no new UI needed

| Feature | Today | Fix |
|---|---|---|
| Privacy settings | `PrivacySettingsNotifier` writes only to `SharedPreferences` (`profile_providers.dart:103-130`) — never sent anywhere | Call `updateUserPrivacy` on every change |
| Workout sessions | Saved to local SQLite only (`session_repository.dart`) — nothing pushes to the backend | Call `ingestWorkoutSession` after each save |
| Device pairing | Pure local BLE state (`ble_providers.dart`) — no server record of who's paired to what | Call the real pairing function on connect, force-unpair equivalent on disconnect |
| Badges/achievements | `achievements_screen.dart` renders three `const` lists with `earned: true/false` **hardcoded in source** — not tied to any user | Read real `badges` + `userBadges` collections |
| Push token registration | Not implemented — `firebase_messaging` isn't even a pubspec dependency | Add the dependency, call `registerDeviceToken`/`unregisterDeviceToken` |
| Reporting | `report_sheet.dart`'s `_submit()` does haptic + pop + a `SnackBar` — **no network call at all**, purely cosmetic | Call `reportContent` |
| Legal documents | `settings_screen.dart` renders three `const String` bodies with a hardcoded "Last updated: June 2026" — no real version, no acceptance tracking, no re-accept prompt | Fetch the real published `legalDocumentVersions`, call `recordLegalAcceptance` |
| Community posts/challenges | `CommunityRepository` is a fully in-memory mock (already known before this audit) | Real Firestore reads + the community/challenge callables |

### Tier 2 — Integrations, mostly wired, finish the edges

- Connect flow for Apple Health/Health Connect and the OAuth redirect flow (Garmin) already
  correctly call `getIntegrations`/`getOAuthAuthorizationUrl`/`markOnDeviceConnected`/
  `ingestHealthSample` — just pointed at FastAPI instead of the real backend, same fix as
  everything else here.
- Strava and Oura tiles are already disabled ("Coming soon", not tappable) — matches the
  real backend's actual credential status (placeholder secrets), correct as-is, no client
  change needed there.
- **No disconnect or resync button exists anywhere** — once connected, there's no further
  UI. `disconnectIntegration`/`resyncIntegration` have zero callers today.
- **MyFitnessPal has no UI at all** — not referenced anywhere in the integrations screen.

### Tier 3 — Needs actual new UI, not just rewiring

- **Announcements** — zero UI anywhere in the app (`grep -i announce` across all of `lib/`
  returns nothing). The admin panels' whole Announcements feature has no mobile
  counterpart to show them in. Needs a banner/modal component built from scratch.
- **Friends** — `find_friends_screen.dart` is a hardcoded discover list where "sending a
  request" just toggles local state; the Community screen's "Friends" tab is a hardcoded
  const list; the block list is real-ish but only ever persisted to `SharedPreferences`.
  None of `sendFriendRequest`/`respondFriendRequest`/`removeFriend`/`blockUser`/
  `unblockUser` are called anywhere. This is close to a from-scratch build, not a rewiring
  job, worth a scope call: is this a real feature to finish, or deferred like MyFitnessPal?

### Tier 4 — Explicitly out of scope for this pass

- **Profile photo upload** — `photoPath` is local-only; the backend has no Cloud Storage
  wired up for it yet at all. This needs new backend infrastructure (Storage rules + an
  upload endpoint) before the client side is even possible. Separate milestone.
- **RevenueCat** — already correctly implemented client-side, just waiting on real
  credentials from Sarah (already documented, unrelated to this migration).
- **Local notification triggers** (goal/streak/device alerts) — on-device only by design,
  not a backend concern.

## Recommended sequencing

1. **Foundation**: add `cloud_firestore`/`cloud_functions` to `pubspec.yaml`, build the
   Flutter-side equivalent of `firestore-helpers.ts`/`callFn` (a thin wrapper so every
   screen doesn't hand-rope Firestore reads), retire `api_client.dart`/`backend_api.dart`'s
   FastAPI base URL entirely rather than running both backends side by side.
2. **Tier 1** in the order listed, each one is an isolated, testable swap with no new UI
   design needed.
3. **Tier 2** edges (disconnect/resync buttons, MyFitnessPal tile showing "needs
   partnership" same as the admin panel's Connected Apps catalog does).
4. **Tier 3**, once Tier 1/2 are done and reviewed, since these need actual UI/UX design
   decisions, not just data-layer swaps.
5. Tier 4 stays parked.

## Open questions for sign-off

- Confirm the tier order above, or reprioritize (e.g. Community/Challenges first since
  that's what surfaced the original gap).
- Friends (Tier 3): finish it for real, or explicitly deprioritize for now?
- Announcements (Tier 3): build the banner/modal now, or after everything else?
