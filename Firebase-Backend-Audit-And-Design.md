# Strolla Health — Firebase Backend Audit & Design

**Implementation status (2026-07-29): deployed to production.** Part 3's Cloud Functions are built and live on `strolla-health-4c93b` — see `strola_health_firebase/functions/src/` (95 functions across auth, devices, integrations, health, challenges, badges, community, moderation, premium, push, legal, settings, announcements, analytics). Firestore rules and indexes deployed. Smoke-tested end-to-end against production. Not yet connected to the three client apps — see `strola_health_firebase/README.md` for exact status, deploy gotchas encountered, and what's left (Strava secret swap-in, Trigger Email extension install, frontend wiring).

**Date:** 2026-07-24
**Architecture decision (confirmed with client):** the real backend is **Firebase Cloud Functions + Firestore + Firebase Auth (custom claims) + Secret Manager**. `strola_health_backend_fastApi` is reserved for a **future milestone** — not deployed, not extended, not a dependency of this work. It is used below **only as reference material**: its Pydantic models already encode a well-thought-out data shape (field names, invariants, comments) that both Next.js panels' `types.ts` were explicitly written to mirror, so it's the fastest way to recover intent without re-deriving it from UI alone.

**Apps involved:**
| App | State today |
|---|---|
| `strola_health_admin_next` | UI-complete, 17 sections, 100% mock data (`IS_MOCK_MODE`) |
| `strola_health_super_admin_next` | UI-complete, mirrors admin_next + Fleet + Staff & Roles, 100% mock data |
| `strola_health_flutter` | UI-complete, local-first (SQLite/SharedPreferences), real Firebase Auth wiring for sign-in only, everything else unbacked or fully mock |
| `strola_health_backend_fastApi` | Fully built against Firestore already — **reference only, out of scope** |

---

## Part 1 — Findings

### 1.1 Admin Panel (`strola_health_admin_next`)

Central entity is `UserProfile`:
```
id, email, username, name, location, country, bio, photo_url, height_cm, gender,
date_of_birth, reasons[], units, onboarding_complete, daily_goal_steps, weight_kg,
role(user/admin/super_admin), privacy{public_profile, share_activity,
  show_in_leaderboards, allow_friend_requests, hide_activity_data, hide_achievements,
  hide_recent_activity}, subscription{tier, status, started_at, comp_until,
  comp_reason, revenuecat_app_user_id, renews_at, cancelled_at}, banned, ban_reason,
posting_banned, posting_ban_reason, posting_banned_until, is_ambassador,
platform, device_model, app_version, tags[], deleted, deleted_at, created_at, updated_at
```

**Dashboard** — reads: total users +30d growth, DAU, active this week/month, new signups +growth, posts today, open reports, active challenges, paired/total devices, premium subscribers, synthetic MRR, DAU chart (30/90/365d), subscription-mix donut, a merged "needs attention" feed (reports, support tickets, firmware failures, deletion requests), synthetic recent-crashes card. No writes on this page.

**Users** — list: tracker status, last-active, CSV export, filters (role/status/subscription/tracker/platform/country/ambassador/joined-this-week/inactive-30d/tags). Detail: lifetime steps/streak/challenges/achievements, 30d steps chart, sessions table, subscription history (reconstructed, not persisted), account timeline. Actions: edit profile fields, toggle ambassador, toggle 7 privacy flags individually, change role (with elevation warning), suspend/unsuspend, ban/unban from posting (with optional timed `until`), delete account (**scrubs PII, keeps workout history/GPS/community posts** — `deleted=true`, name/email/bio/photo/location nulled), grant/revoke premium (7d/30d/90d/6mo-kickstarter/1yr-beta/lifetime presets — **fully independent of RevenueCat**, only touches `comp_until`/`comp_reason`), reset password (fires Auth reset email), send one-off email, award/revoke a badge, unpair a device, add admin-only note, add/remove cohort tags. Bulk: suspend, grant-30d-premium.

**Community** — `CommunityPost{id, author_id, content, timestamp, likes_count, comments_count, step_count, badge_emoji, image_url, moderation{hidden,hidden_by,hidden_reason,hidden_at}, pinned, comments_locked}`, `CommunityComment{id, post_id, author_id, content, timestamp, hidden}`. Actions: post as official "Strolla Health" account, edit post content/step_count/badge_emoji, remove photo, pin/unpin, lock/unlock comments, hide/unhide (reason), delete permanently, ban author from posting, edit/delete comment (must decrement `comments_count`).

**Moderation/Reports** — `Report{id, reporter_id, target_type(post/user), target_id, category, reason, status(open/resolved/dismissed), action_taken, resolved_by, resolved_at, resolution_note, created_at}`. Every resolve action is compound: mutate target + resolve N open reports on it + send a canned notification email — must be one atomic transaction server-side. Actions: dismiss, remove post, warn, mute 24h/7d, ban permanently, delete account, delete all posts by author.

**Challenges/Badges** —
```
Challenge: id, title, description, goal_steps, start_date, end_date, badge_emoji,
  accent_color_value, visibility(public/private), is_official, invite_code,
  created_by, created_at, image_url, rules, winner_type(most_steps/goal_completion_pct),
  status(draft/published/archived), winner_user_id, admin_notes
ChallengeParticipant: id, challenge_id, user_id, steps, locked_daily_goal, joined_at, left_at
Badge: id, name, description, emoji, requirement_metric, requirement_value, enabled, visible
UserBadge: id, user_id, badge_id, awarded_at, awarded_by
```
Official monthly challenge: draft→published→archived lifecycle, only one `is_official=true` at a time. Winner defaults to leaderboard leader at `end_date`, admin-overridable. Badges: manual award only today — `requirement_metric`/`requirement_value` are described as machine-evaluable but nothing evaluates them yet (auto-award engine is a real gap).

**Announcements** — in-app banner: `{id, emoji, message, link_target, audience(+version targeting), active, starts_at, ends_at, created_by, created_at}`. Audience size + seen/dismissed/clicked are **entirely synthetic today** — no real impression pipeline. Mobile app doesn't render banners at all yet.

**App Content** — flat key→value config store (`key, category, label, value, updated_at`) with `{Variable}` placeholders. **Mobile app has zero remote-config fetch today — every string is hardcoded** in `notification_copy.dart` etc. This is a staging library ahead of the client.

**Push Notifications** — `PushNotification{id, segment, title, body, link_target(+sub-target), status(draft/scheduled/sent), scheduled_at, recipient_count, delivered_count, opened_count, sent_by, created_at, sent_at}`. **No FCM wired at all** — delivered/opened stats are randomly simulated. Needs real FCM send, segment→token resolution, scheduled-send mechanism, and real delivery/open telemetry.

**Premium** — no separate collection; lives on `UserProfile.subscription`. Real/paying and trial rows are **read-only in admin** (RevenueCat-managed); only the comp path (`comp_until`/`comp_reason`) is admin-mutable, explicitly never touching `tier`/`status`. MRR/conversion/churn/LTV are synthetic, client-computed.

**Connected Apps** — `IntegrationConnection{id, user_id, provider(healthkit/health_connect/oura/garmin/strava/strolla_app/strolla_device/manual), status(connected/disconnected/error), scopes[], external_athlete_id, last_synced_at, connected_at, error_message}` (+ `access_token`/`refresh_token` per the FastAPI reference — **never exposed to the admin UI**, Oura/Garmin/Strava only). Admin actions: resync, disconnect.

**Legal** — `LegalDocumentVersion{id, doc_type, version, status(draft/published/archived), content, changelog, effective_date, requires_reaccept, created_by, created_at, published_at}`, `LegalAcceptance{id, user_id, doc_type, version, status(accepted/pending/declined), responded_at}`. **`publishLegalVersion` is the clearest single "atomic backend job" in the whole audit**: archive prior published version → promote draft → if `requires_reaccept`, fan out a `pending` `LegalAcceptance` to every active user. Mobile app doesn't fetch legal docs remotely yet — no real accept/decline gate exists client-side.

**Settings** —
- *App Settings* (singleton doc): step/challenge defaults, trial/pricing, default privacy for signups, default notification toggles, content limits, `minimum_required_app_version`. Plus a standalone **"force logout everyone"** action (`admin.auth().revokeRefreshTokens` for every user or a global cutoff instant).
- *Beta Testing*: `BetaOverride{id, feature_key, target_type(user_id/email/ambassador), target_value, created_by, created_at}`.
- *Feature Flags*: `FeatureFlag{key, required_tier(free/premium), description, updated_at}` — literally the free/premium split, runtime-configurable.
- *Devices (Fleet)*: also present on the plain Admin panel's Settings tab (unlike Super Admin, which has a dedicated Fleet page) — see §1.2.
- *Activity Log*: currently a **session-only in-memory store** — every mutating action across the whole app calls `logAction(action, target)`. This must become a real persisted `auditLog` collection.

**Analytics** — the widest cross-entity aggregator: DAU/WAU/MAU, DAU/signups trend charts, avg session length, avg streak, most-common goal, challenge participation, avg daily steps trend, screen-usage (placeholder, no real analytics SDK), feature adoption %, goal completion rate, community health (posts/comments/likes 30d — **no friend/follow model exists, "new friends" explicitly untracked**), premium conversion/churn/LTV/ARPU (synthetic), retention curve (day 0/1/3/7/14/30), user funnel, tracker usage (connected/synced today, avg battery, sync failures, firmware breakdown). `AnalyticsEvent{id, event_type, user_id, metadata, created_at}` is the master event log every rollup derives from — currently entirely synthetic, no real analytics SDK feeds it from the mobile app.

**Auth/roles** — `role ∈ {user, admin, super_admin}`. Admin panel layout gates `allow: [admin, super_admin]`. **No further role differentiation exists anywhere in the admin panel UI** — every admin and super_admin can currently do the same things (role changes, force-logout, device delete, legal publish included). `onIdTokenChanged` (not `onAuthStateChanged`) is used specifically so a claims change propagates without re-login — **confirms `role` must live in Firebase custom claims**, not only Firestore.

**`api-client.ts` / `firebase-client.ts`** — a real REST client already exists, pointed at `http://localhost:8000/api/v1` (FastAPI shape) with `Authorization: Bearer <Firebase ID token>`. `firebase-client.ts` is **Auth-only today — no Firestore/Storage/Functions SDK initialized anywhere**. `data/api.ts`'s ~90 real-mode functions are effectively the full REST surface spec (exact verb/path/param shape) for everything above — several endpoints are explicitly marked "doesn't exist on the backend yet" (crash reports, support tickets, firmware failures, deletion requests, all push endpoints, app-content, admin post-authoring, user notes) — real backend-design gaps, not just a Firebase-migration exercise.

### 1.2 Super Admin Panel (`strola_health_super_admin_next`)

11 of 13 shared pages are **byte-identical** to `admin_next`. Two trivial diffs (Settings drops the devices-fetch since Fleet is its own page here; Premium drops the 30d-events fetch/copy). `queries.ts` has genuine additions (`fleetStats`, `listStaff`, `listPromotableUsers`).

**Fleet** —
```
Device: id, serial_number, device_type("strolla_nrf7002"), ble_mac, firmware_version,
  manufacturing_batch, owner_user_id, paired_at, last_seen_at, battery_level,
  last_synced_at, created_at, replaced_at
```
Stats: total, paired, in-stock (`owner_user_id` null — note this bucket also currently includes replaced-but-unassigned devices numerically, even though the UI hides their action menu), low-battery (<15%) count.
Actions: **provision** (serial+batch, no server-side uniqueness check exists today — must add one), **reassign** (direct, no unpair-first step required), **push firmware** (just sets a string — no real OTA), **force unpair** (support-case framing), **mark replaced** (compound: unpair + retire, should be one transaction), **delete** (only allowed if never paired — a real constraint the backend must enforce itself, not trust the client to gate). `FirmwareUpdateFailure{id, device_id, attempted_version, error, occurred_at, resolved}` exists as a type but nothing writes to it — placeholder for real OTA telemetry. One device per user assumed throughout (no multi-device handling).

**Staff & Roles** — staff are just `UserProfile` rows with `role ∈ {admin, super_admin}`, not a separate collection. `listStaff`/`listPromotableUsers` filter live user data (promotable = role=user, not banned, not deleted — same helper used by Fleet's reassign picker). All role changes funnel through one call, `changeUserRole(userId, role)`, which in mock mode is a **blind unguarded assignment** — no self-demotion guard, no last-super_admin guard, no persisted "promoted at" timestamp (only `created_at`, the account's own signup date, is shown as "Staff since"). **Critical difference from admin_next**: this entire app's layout gates `allow: [super_admin]` — i.e. `admin` role gets zero access to Fleet/Staff, full-app-level, not page-level. So the claims/authorization model is: `admin` → admin_next only; `super_admin` → both apps.

### 1.3 Flutter Mobile App (`strola_health_flutter`)

**Auth** — dual-mode: falls back to a no-credential local "demo sign-in" if Firebase isn't configured, otherwise real `FirebaseAuth` (`signIn`, `signUp`, `sendPasswordResetEmail`, `signOut`, `deleteAccount` — all implemented and mapped to friendly error copy). "Remember me" is app-level logic (signs cached session back out on launch if unchecked — Firebase Auth itself always persists natively). Delete/logout both wipe local SQLite + SharedPreferences; delete-account additionally calls Firebase `user.delete()`. `restoreProfileFromBackend` calls `GET /auth/me`-shaped logic after sign-in only (not sign-up).

**Profile** — `UserProfile{username, name, location?, bio?, photoPath?(local only), heightCm, gender, dateOfBirth?, reasons(Set), units, onboardingComplete}` + separate `dailyGoalProvider`(int)/`userWeightKgProvider`(double) — matches the FastAPI `UserProfile`/`UserProfileUpdate` field-for-field via explicit snake_case mapping helpers, confirming the intended contract. `photoPath` has no remote/Storage equivalent yet.

**Steps/Home** — live step count from BLE or a mock timer; `daily_steps` SQLite table (`date PK, steps, goal` — goal snapshotted per day so raising your goal later doesn't retroactively change past "did you hit it" results). **No sync endpoint exists for daily steps at all today** — entirely local. `weeklyStepsProvider`/`todayHourlyStepsProvider` are partly hardcoded mock arrays, not fully real yet.

**Sessions/Workouts** — `WorkoutSession{id(client-generated, idempotency key), startTime, endTime, steps, distanceMeters, durationSeconds, activityType, routePoints[{lat,lng,speedMps}], avgPaceSecPerKm?, caloriesBurned?, customActivityName?}` — matches FastAPI's `WorkoutSession`/`WorkoutSessionCreate` closely (source/external_id fields exist server-side for sync dedup, not yet in the Flutter entity — worth adding). Personal records (4 categories: longest duration, farthest distance, most steps, best pace) computed live via full-table SQL scan on every save — **no dedicated records store**; real backend should likely persist these and recompute via trigger instead of scanning. **Zero backend endpoint exists for sessions today.**

**Activity/Stats** — all derived client-side from local `daily_steps`/`workout_sessions`; `recentActivityProvider` pads real data with deterministic mock filler when history is thin — a client-only demo behavior that must not leak into the real backend design (the real backend should just return real history, however short).

**Challenges** — **two divergent, unreconciled models exist client-side**: the private/joinable `Challenge` (rank-based leaderboard) vs. the Challenge-of-the-Month screen's own local model (goal-completion-%-based leaderboard, separate mock data entirely). Real backend needs one unified `Challenge` with a `winner_type`/leaderboard-sort-mode discriminator (this matches the FastAPI reference's `winner_type` field exactly — good sign the unification is already anticipated there). Create-challenge form (name/duration/dates/winner-method/invite) is **UI-only, not persisted anywhere**. Zero backend endpoints exist for challenges today (join/create/leaderboard all needed net-new).

**Achievements/Badges** — **no entity, no backend field at all** — badges are a hardcoded hand-authored catalog in `achievements_screen.dart` with `earned: true/false` **hardcoded per badge in source**, not computed. This needs the real `Badge`/`UserBadge` model wired through, plus the auto-award evaluation engine flagged as missing on the admin side too.

**Community** — `CommunityPost{id, authorName(denormalized string, not a real FK — needs to become authorUserId), content, timestamp, likes, comments(count only, no Comment entity/UI exists at all), isLiked, stepCount?, badgeEmoji?, imageUrl?(local path)}`. Likes toggle locally with no backend. Report flow exists in UI but submits to nothing. Blocking is **name-based, not user-ID-based** (`blocked_users` SharedPreferences set of display names) — will break once real users can share a name; must become UID-based. Friends/Find-Friends/Invite-Friends are **entirely hardcoded mock lists**, no backend, no real friend graph, no real referral code system (hardcoded single invite string). This is the single largest net-new area: posts, comments, likes, friend graph, reports, blocks, referrals all need building essentially from zero.

**Connected Devices (BLE)** — no persisted entity, transient connection state only; device identity hardcoded to one BLE service (`NRF7002_STEPS`). No backend touchpoint by design (BLE is phone↔device direct) except that accumulated steps need a real push-to-backend path, which doesn't exist yet (same gap as Steps/Home above).

**Connected Apps/Integrations** — this is the **one area with a fairly complete backend contract already defined** in `backend_api.dart`: `GET /integrations`, `GET /integrations/{provider}/connect` → `{authorization_url}`, backend-side OAuth callback redirecting to `strolahealth://` custom scheme, `POST /integrations/{provider}/connected` (on-device providers), `POST /integrations/ingest` (body: `{source, date, steps?, distance_meters?, calories?}`). Matches FastAPI's `IntegrationConnection`/`HealthSampleIngest`/`OAuthConnectResponse` closely — this is the strongest existing spec to build the Cloud Functions equivalent against.

**Notifications** — `AppNotification{id, category(8 types: goalReminder, goalAchieved, streak, challenge, community, lowBattery, deviceDisconnected, personalRecord), title, body, timestamp, isRead, routeTarget?}`, local-only (SharedPreferences, capped 50), generated by **client-side detectors**, not server push. Community-category notifications are explicitly a **90-second local timer simulating fake activity** — "no real multi-user backend yet" per the code's own comment. Device/goal/streak/personal-record detectors are real logic reacting to real local state and are good candidates to mirror server-side (via Cloud Functions + FCM) once there's a real backend, rather than staying purely client-simulated for challenge/community events which fundamentally need server knowledge of other users.

**Premium/Purchases** — dual source of truth by design: `isPremiumProvider = RevenueCat entitlement OR backend comp_until/tier` (comp/trial grants wouldn't show in RevenueCat). `PurchaseService.logIn(firebaseUid)`/`logOut()` link/unlink RevenueCat identity on sign-in/out — important to preserve so entitlements don't leak across accounts on a shared device.

**Widgets** — `WidgetService.update({steps, goal, distance, calories, activeMin, motivation})` is fully implemented for iOS (App Group) and Android but **has zero call sites anywhere in the app** — an integration gap, not a backend one; flagging since it affects what "last known totals" cache needs to stay fresh.

---

## Part 2 — Firestore Database Design

Design principles applied:
- **Flat top-level collections with a `userId`/owner field** for anything an admin needs to query cross-user (sessions, daily activity, reports, devices, analytics events) — Firestore collection-group queries are more awkward to secure and index than a flat collection with a composite index, and the admin panel's entire reason for existing is cross-user queries.
- **Subcollections** only where access is always scoped to one parent and the parent is the natural security boundary (post comments/likes, user notes, device tokens).
- **Denormalize read-heavy counters** (`likesCount`, `commentsCount`, streaks, lifetime steps) onto the parent/user doc, maintained by Cloud Function triggers — never computed by scanning on every read once real user counts exist.
- **Never store OAuth tokens or anything secret-shaped in a client-readable path.** `integrationConnections` access/refresh tokens are Functions-only (Admin SDK bypasses rules; client rules deny read/write on those fields entirely — see §2.3).
- **Role lives in Firebase Auth custom claims**, mirrored onto `users/{uid}.role` for querying/display — every role-changing Cloud Function must update both atomically.

### 2.1 Collections

```
users/{uid}                                  doc id = Firebase Auth UID
  ├─ notes/{noteId}                          admin-only subcollection (UserNote)
  └─ deviceTokens/{tokenId}                  FCM tokens, {token, platform, updatedAt}

workoutSessions/{sessionId}                  id = client-generated (idempotent re-upload)
dailyActivity/{uid}_{date}                   one per user per day
personalRecords/{uid}                        one doc per user, map of 4 categories

challenges/{challengeId}
  └─ participants/{uid}                      ChallengeParticipant

badges/{badgeId}
userBadges/{uid}_{badgeId}                   flat, so admin can query by badgeId too

communityPosts/{postId}
  ├─ comments/{commentId}
  └─ likes/{uid}                             doc existence = like (idempotent toggle)

reports/{reportId}
friendships/{uidLow}_{uidHigh}                sorted pair, {status, requestedBy, createdAt, respondedAt}
blockedUsers/{blockerUid}_{blockedUid}
inviteReferrals/{code}                        {ownerUid, createdAt, usesCount}

devices/{deviceId}
devicePairingEvents/{eventId}
firmwareUpdateFailures/{id}

integrationConnections/{uid}_{provider}       Functions-only read/write (tokens live here)

announcements/{id}
appContent/{key}
pushNotifications/{id}
legalDocumentVersions/{id}
legalAcceptances/{uid}_{docType}

appSettings/singleton                         one doc
featureFlags/{key}
betaOverrides/{id}
auditLog/{id}

analyticsEvents/{id}                          high-volume, see §2.4 re: retention/export
dailyStatsRollups/{date}                      scheduled-computed
retentionCohorts/{signupWeek}

supportTickets/{id}                           new — flagged gap, see Part 4
accountDeletionRequests/{id}                  optional, see Part 4
revenueCatEvents/{id}                         raw webhook log, for auditability/replay
```

### 2.2 Key field notes / carried-over invariants

- `users/{uid}.subscription` — **two independent mechanisms in one object**: `tier`/`status`/`renewsAt`/`cancelledAt`/`revenuecatAppUserId` written **only** by `revenueCatWebhook`; `compUntil`/`compReason` written **only** by admin grant/revoke/extend functions. No function should ever write to both halves. `hasPremiumAccess = tier==premium && status==active || now < compUntil`.
- `challenges/{id}` unifies the admin's official-monthly model and the Flutter app's two divergent local models: add `type: "official_monthly" | "private"` and keep `winnerType: "most_steps" | "goal_completion_pct"` as the leaderboard sort discriminator both UIs already (separately) expect.
- `dailyActivity/{uid}_{date}.bySource` mirrors the FastAPI reference's `SOURCE_PRIORITY` merge order (`strolla_device` beats HealthKit beats Health Connect beats Garmin beats Oura beats Strava beats manual) — this priority list should live as a shared constant in the Functions codebase, not be re-derived.
- `workoutSessions.routePoints` — recommend an **encoded polyline string** (Google's polyline algorithm) instead of a raw array of `{lat,lng,speed}` objects once real GPS sessions arrive; a 45-minute outdoor run easily produces thousands of points and Firestore documents cap at 1MiB. Flag as a decision point (§4).
- `communityPosts.moderation` stays embedded (small, always read with the post); `comments`/`likes` are subcollections because they're unbounded and only ever queried scoped to one post.
- `blockedUsers`/`friendships` use **UID pairs**, fixing the Flutter app's current name-based blocking bug outright at the schema level.
- Personal records move from "recompute via full scan on every session save" to **one maintained doc per user**, updated transactionally by the same function that ingests a session.

### 2.3 Security rules shape (summary, not full rules file)

| Collection | Client read | Client write |
|---|---|---|
| `users/{uid}` | owner + any authenticated (public fields only, via a Cloud Function-served public projection — mirrors FastAPI's `PublicUserProfile`) | owner (non-privileged fields only), admin/super_admin via Functions |
| `users/{uid}/notes` | admin/super_admin only | Functions only |
| `workoutSessions`, `dailyActivity`, `personalRecords` | owner only (+ admin) | Functions only (never direct client writes — always validated/computed server-side) |
| `challenges`, `challenges/{id}/participants` | any authenticated | join/leave via Functions; challenge CRUD admin-only via Functions |
| `communityPosts`, `comments` | any authenticated (excluding `moderation.hidden`) | create via Functions (validates content length, banned/muted status); edit/delete own via Functions |
| `communityPosts/{id}/likes/{uid}` | any authenticated | **owner-only direct client write is acceptable here** (idempotent toggle, low risk) — one of the few direct-write exceptions |
| `reports` | admin/super_admin only (+ own submitted reports, write-only for the reporter) | create via Functions (from app); resolve admin-only via Functions |
| `devices`, `integrationConnections` | owner (device: limited fields) / admin | Functions only |
| `announcements`, `appContent`, `featureFlags`, `legalDocumentVersions` (published only) | any authenticated | admin/super_admin via Functions |
| `pushNotifications`, `auditLog`, `analyticsEvents`, `appSettings`, `betaOverrides`, `legalAcceptances` (all), `dailyStatsRollups` | admin/super_admin only | Functions only |
| `integrationConnections.accessToken`/`refreshToken` | **nobody**, ever, client-side | Functions only |

Role check pattern: `request.auth.token.role in ['admin','super_admin']` (custom claims), with a second `super_admin`-only tier for: role changes, force-logout-all, legal publish, device delete, fleet provisioning — **this super_admin-only enforcement doesn't exist in either Next.js app's UI today and must be added at the Function layer regardless of what the UI currently allows**, since the super-admin app's own layout already assumes an all-or-nothing split (§1.2).

### 2.4 Composite indexes needed

```
users:              (role ASC, banned ASC, createdAt DESC)
users:               (deleted ASC, createdAt DESC)
users:               (subscription.tier ASC, subscription.status ASC)
users:               (tags ARRAY_CONTAINS, createdAt DESC)
users:               (isAmbassador ASC, createdAt DESC)
workoutSessions:     (userId ASC, startTime DESC)
dailyActivity:       (userId ASC, date DESC)
dailyActivity:       (date ASC)                        -- cross-user daily rollups
challenges/participants (collection group): (challengeId ASC, steps DESC)  -- leaderboard
communityPosts:      (moderation.hidden ASC, pinned DESC, timestamp DESC)
communityPosts:      (authorId ASC, timestamp DESC)
reports:             (status ASC, createdAt DESC)
reports:             (targetType ASC, targetId ASC, status ASC)
devices:             (ownerUserId ASC)
devices:             (replacedAt ASC, ownerUserId ASC)
userBadges:          (userId ASC)
userBadges:          (badgeId ASC)
legalAcceptances:    (docType ASC, version ASC, status ASC)
pushNotifications:   (status ASC, scheduledAt ASC)
analyticsEvents:     (eventType ASC, createdAt DESC)
analyticsEvents:     (userId ASC, eventType ASC, createdAt DESC)
auditLog:            (actorUid ASC, timestamp DESC)
```
(Single-field indexes are automatic in Firestore and omitted above.)

---

## Part 3 — Firebase Cloud Functions plan (for your review before anything is built)

Grouped by domain. Type: **CB** = callable, **HTTPS** = plain HTTPS endpoint (for webhooks/OAuth redirects that can't carry a Firebase ID token), **FT** = Firestore trigger, **AT** = Auth trigger, **SCH** = scheduled.

### Auth & Roles
1. `onUserCreate` (AT) — creates `users/{uid}` with defaults, sets custom claim `role=user`
2. `setUserRole` (CB, admin+; super_admin-only when target/new role is `super_admin`) — updates Firestore + custom claims atomically, blocks self-demotion and last-super_admin removal, writes audit log
3. `banUser` / `unbanUser` (CB, admin+)
4. `banUserFromPosting` / `unbanUserFromPosting` (CB, admin+, supports timed `until`)
5. `deleteAccount` (CB, self or admin) — scrub PII, keep content, delete Auth user, unpair devices, RevenueCat logout, cascade
6. `forceLogoutAllUsers` (CB, super_admin only) — batched `revokeRefreshTokens`
7. `sendPasswordResetForUser` (CB, admin+)
8. `sendAdminEmail` (CB, admin+) — needs an email provider secret (§4)

### Users / Profile
9. `updateMyProfile` (CB) 10. `adminUpdateUserProfile` (CB, admin+) 11. `addUserNote` / `setAmbassadorFlag` / `updateUserTags` (CB, admin+)

### Devices / Fleet
12. `provisionDevice` (CB, admin+, enforces unique `serialNumber`) 13. `pairDevice` (CB, from app) 14. `reassignDevice` / `forceUnpairDevice` / `markDeviceReplaced` / `deleteDevice` (CB, admin+) 15. `pushFirmwareUpdate` (CB, admin+) 16. `onDeviceWrite` (FT) — writes `devicePairingEvents`

### Health Data / Sessions
17. `ingestWorkoutSession` (CB) — idempotent by `id`, computes distance/calories server-side if missing, upserts `dailyActivity` transactionally
18. `ingestHealthSample` (CB) — HealthKit/Health Connect, merges into `dailyActivity.bySource` per `SOURCE_PRIORITY`
19. `onDailyActivityWrite` (FT) — recomputes streak + lifetime steps onto `users/{uid}`, evaluates badge auto-award, updates any active challenge participant's `steps`
20. `recomputePersonalRecords` (internal helper, called from #17)

### Challenges
21. `createChallenge` (CB) — private challenges, server-generated invite code
22. `joinChallenge` / `leaveChallenge` (CB)
23. `setOfficialMonthlyChallenge` (CB, admin+) 24. `publishChallenge` / `archiveChallenge` / `deleteChallenge` (CB, admin+, cascades participants) 25. `removeParticipant` (CB, admin+) 26. `setChallengeWinner` (CB, admin+)
27. `onChallengeEnd` (SCH, daily) — locks in default winner at `endDate`
28. `updateChallengeLeaderboard` (FT on participant write) — maintains denormalized top-N on the challenge doc

### Badges / Achievements
29. `createBadge` / `updateBadge` / `deleteBadge` (CB, admin+, cascades `userBadges`) 30. `awardBadge` / `revokeBadge` (CB, admin+, manual) — shares logic with #19's auto-award path

### Community
31. `createPost` (CB) 32. `editPost` / `deletePost` / `hidePost` / `pinPost` / `lockComments` (CB) 33. `likePost`/`unlikePost` — direct client write per §2.3, but `onLikeWrite` (FT) maintains `likesCount` 34. `addComment` / `editComment` / `deleteComment` (CB) + `onCommentWrite` (FT) maintains `commentsCount` 35. `reportContent` (CB) 36. `resolveReport` (CB, admin+) — the compound atomic action from §1.1 37. `sendFriendRequest` / `respondFriendRequest` / `removeFriend` (CB) 38. `blockUser` / `unblockUser` (CB)

### Notifications / Push
39. `registerDeviceToken` (CB) 40. `sendPushNotification` (CB, admin+) — resolves segment→tokens, FCM send, updates counts 41. `dispatchScheduledPush` (SCH, every few minutes) — sends anything due 42. `sendTestPush` (CB, admin+) 43. `notifyOnChallengeEvent` / `notifyOnCommunityEvent` (FT, replaces the Flutter app's fake 90s timer with real server-triggered pushes once there are real other users)

### Premium / Subscriptions
44. `revenueCatWebhook` (HTTPS, signature-verified via secret) — writes `subscription.{tier,status,renewsAt,cancelledAt,revenuecatAppUserId}` + logs to `revenueCatEvents`
45. `grantPremium` / `extendPremium` / `revokePremium` (CB, admin+) — `comp_*` fields only

### Legal
46. `createLegalDraft` / `updateLegalDraft` / `discardLegalDraft` (CB, admin+) 47. `publishLegalVersion` (CB, admin+) — the atomic archive→promote→fan-out job from §1.1 48. `recordLegalAcceptance` (CB, from app) 49. `restoreLegalVersionAsDraft` (CB, admin+)

### App Content / Settings / Flags
50. `updateAppContent` (CB, admin+) 51. `updateAppSettings` (CB, super_admin only — pricing/trial/minimum-version live here) 52. `updateFeatureFlag` (CB, admin+) 53. `grantBetaOverride` / `revokeBetaOverride` (CB, admin+)

### Integrations
54. `startOAuthConnect` (CB) — returns `authorization_url`, needs per-provider client secrets 55. `oauthCallback` (HTTPS) — exchanges code, stores tokens, redirects to `strolahealth://` 56. `markOnDeviceConnected` (CB) 57. `resyncIntegration` (CB, admin+ or self) 58. `disconnectIntegration` (CB) 59. `syncOAuthProviderData` (SCH, per provider — pulls via stored tokens)

### Analytics
60. `logAnalyticsEvent` (CB, lightweight — see §4 re: whether this duplicates Firebase Analytics) 61. `computeDailyStatsRollup` (SCH, nightly) 62. `computeRetentionCohort` (SCH, weekly) 63. `getAnalyticsDashboard` (CB, admin+ — serves rollups + on-demand gap-fill)

### Cross-cutting
64. `writeAuditLog` (internal helper invoked by every admin-facing function above, not user-callable itself) — replaces the in-memory `audit-log-store.ts`

**That's ~64 functions.** Not all need to ship in the first pass — Part 4 flags which areas are genuinely new-build (community/friends/challenges/badges) vs. straightforward wiring (integrations, which already has a near-complete contract).

---

## Part 4 — Decisions (confirmed 2026-07-25)

1. **GPS route storage** — ✅ encoded polyline string.
2. **Email provider** — ✅ Firebase "Trigger Email" extension.
3. **Custom analytics events vs. Firebase Analytics/GA4** — ✅ custom `analyticsEvents` collection + nightly/weekly rollups. Written via a callable Cloud Function (`logAnalyticsEvent`), not direct client writes — keeps validation/abuse-prevention server-side and the write path consistent with everything else. Rollups (`computeDailyStatsRollup`, `computeRetentionCohort`) are scheduled Cloud Functions reading raw events into `dailyStatsRollups`/`retentionCohorts`.
4. **Crash reporting** — ✅ Firebase Crashlytics (drop the placeholder `crashReports` collection from the build plan; Dashboard's "recent crashes" card wires to Crashlytics data instead, separate integration task on the Flutter side, not a Cloud Function).
5. **Support tickets / account-deletion-request queue** — ✅ build as real collections + functions now (`supportTickets`, `accountDeletionRequests` stay in scope).
6. **Multi-device per user** — ✅ confirmed one device per user only; `Device.owner_user_id` stays effectively 1:1, no multi-device handling needed.
7. **Super-admin-only actions** — ✅ confirmed; enforced at the Function layer regardless of current UI gating.
8. **Firebase project topology** — ✅ single project for now, matches `plan.md`'s original deferral.

---

## Part 5 — Suggested build order (once you've reviewed Part 3/4)

1. Auth & Roles (#1–8) + `users` collection + rules — unblocks everything else, including finally connecting real staff logins.
2. Devices/Fleet (#12–16) — self-contained, mirrors an already-complete UI spec closely.
3. Integrations (#54–59) — the one area with a near-complete client contract already (`backend_api.dart`), lowest ambiguity.
4. Health data: sessions/daily activity/streaks/personal records (#17–20) — foundational for challenges, badges, and analytics that depend on it.
5. Challenges + Badges (#21–30) — depends on #17–20 for real progress numbers.
6. Community + friends (#31–38) — the largest net-new area; can be sequenced in parallel with #5 if needed.
7. Moderation/Reports (#35–36) — depends on Community existing.
8. Premium/RevenueCat webhook (#44–45) — independent, can happen anytime.
9. Push notifications (#39–43) — benefits from segments (users) + challenges + community already existing to target against.
10. Legal, App Content, Announcements, Settings, Feature Flags, Beta (#46–53) — lower urgency, mostly straightforward CRUD once the auth/roles foundation is in place.
11. Analytics rollups + audit log (#60–64) — layer on top once the underlying collections have real data flowing.

---

*This document is the audit + design deliverable requested. No Cloud Functions code has been written yet — next step is your sign-off on Part 3 (function list) and Part 4 (open decisions) before implementation begins.*
