# Cloud Functions Reference

Live reference for every Cloud Function in `strola_health_firebase/functions/src`, deployed to Firebase project **`strolla-health-4c93b`**. Written so a fresh session (or a fresh person) can orient immediately: what exists, what the Flutter mobile app actually calls, and what's admin-panel-only.

**Verified 2026-07-31**: every function the Flutter app calls was cross-checked against `firebase functions:list` on the live project — all 26 mobile-facing callables are deployed and reachable, with zero naming mismatches. Firestore composite indexes for the app's real query shapes were tested directly against the live database (not just declared in `firestore.indexes.json`) — all pass. `flutter analyze lib` and `tsc` both report zero issues as of this writing.

## How to read this doc

- ✅ **Mobile** — called directly by `strola_health_flutter` (via `FirebaseClient.call(...)`, grep-verified in `lib/`).
- 🛠️ **Admin-only** — called only from `strola_health_admin_next` / `strola_health_super_admin_next`.
- ⚙️ **Trigger/Scheduled** — not callable; fires on a Firestore write, a schedule, or a raw HTTP request (not through the callable SDK).
- Function numbers (`#12`, `#34a`, …) are references to the original build plan in `Firebase-Backend-Audit-And-Design.md` — kept in code comments, kept here for cross-referencing.

---

## Mobile app — real backend wiring status

Every one of these is called from Flutter and confirmed live. This is the actual current state of the "Flutter-Backend-Migration-Plan.md" work — treat this table as more current than that plan document.

| Area | Flutter files | Cloud Functions called |
|---|---|---|
| Profile / onboarding | `backend_api.dart`, `settings_screen.dart` | `updateMyProfile` |
| Privacy settings | `settings_screen.dart` | `updateMyPrivacy` |
| Legal (Terms/Privacy/Guidelines) | `legal_repository.dart` | `recordLegalAcceptance` (+ direct Firestore read of `legalDocumentVersions`) |
| Achievements | `badge_repository.dart` | *(none — direct Firestore read of `badges`/`userBadges`, both client-readable)* |
| Community feed | `community_repository.dart` | `createPost`, `deletePost`, `addComment`, `deleteComment`, `reportContent` (+ direct read of `communityPosts`/`comments`; likes are a direct client write, see below) |
| Public profiles (identity resolution) | `public_profile_repository.dart` | `getPublicProfiles` |
| Friends | `friend_repository.dart` | `sendFriendRequest`, `respondFriendRequest`, `removeFriend`, `searchUsers` (+ direct read of `friendships`) |
| Blocking | `friend_repository.dart` | `blockUser`, `unblockUser` (+ direct read of `blockedUsers`) |
| Challenges | `challenge_repository.dart` | `joinChallenge`, `leaveChallenge`, `createChallenge` (+ direct read of `challenges`/`participants`) |
| Device pairing | `device_repository.dart` | `pairDevice` (+ direct read of `devices` for own device) |
| Workout sessions | `session_repository.dart` | `ingestWorkoutSession` (best-effort, fire-and-forget after local SQLite save) |
| Health platform sync (Apple Health / Health Connect) | `backend_api.dart` | `markOnDeviceConnected`, `ingestHealthSample` |
| Third-party integrations (Strava/Oura/Garmin/MyFitnessPal) | `backend_api.dart`, `integrations_screen.dart` | `startOAuthConnect`, `disconnectIntegration`, `listMyIntegrationConnections` |
| Push notifications | `push_token_service.dart` | `registerDeviceToken`, `unregisterDeviceToken` |
| Announcements banner | `announcement_repository.dart` | *(none — direct Firestore read of `announcements`, audience-matched client-side against the caller's own `users/{uid}` doc)* |

**Direct-write exceptions** (client writes Firestore directly, no callable — deliberate, per `firestore.rules` comments): a post like/unlike is `communityPosts/{id}/likes/{uid}` create/delete, owner-only and idempotent.

---

## Auth & Users

| Function | Caller | Purpose |
|---|---|---|
| `onUserCreate` | ⚙️ Trigger (Firebase Auth) | Seeds the `users/{uid}` doc + default `role: user` claim on signup. v1 trigger (non-blocking), not v2, to avoid requiring Identity Platform. |
| `setUserRole` | 🛠️ Admin | Promote/demote a user's role (user/admin/super_admin). **super_admin only** — a prior version had a privilege-escalation bug (a plain admin could demote a super_admin) that was fixed this session. |
| `banUser` / `unbanUser` | 🛠️ Admin | Full account suspension + immediate session revocation. |
| `banUserFromPosting` / `unbanUserFromPosting` | 🛠️ Admin | Narrower than a full ban — blocks community posts/comments only, optionally time-boxed. |
| `deleteAccount` | ✅ Mobile + 🛠️ Admin | Self-delete (Settings screen) or admin-initiated. Scrubs PII, deliberately **keeps** workout history/routes/posts (renders via a "Deleted User" fallback). |
| `forceLogoutAllUsers` | 🛠️ Admin | **super_admin only.** Revokes every signed-in user's session, project-wide. The single most destructive action in the system. |
| `sendPasswordResetForUser` | 🛠️ Admin | Generates + emails a reset link via the Trigger Email extension (Admin SDK can't send Firebase's built-in reset email itself). |
| `sendAdminEmail` | 🛠️ Admin | One-off email to a user from their profile page. |
| `updateMyProfile` | ✅ Mobile | Self-service profile edit (name/username/bio/height/weight/gender/DOB/reasons/units/goal/onboarding-complete). Never takes a `userId` — always the caller's own uid. |
| `updateUserProfile` | 🛠️ Admin | Same fields plus admin-only cohort fields (`is_ambassador`, `tags`, `country`). |
| `updateMyPrivacy` | ✅ Mobile | Self-service privacy toggle edit (7 settings incl. `hide_location`). |
| `updateUserPrivacy` | 🛠️ Admin | Admin editing another user's privacy settings. |
| `getPublicProfiles` | ✅ Mobile | **Added this session.** Batch uid→identity resolution (name/username/photo, plus stats gated by `privacy.public_profile`). Exists because `users/{uid}` reads are owner/admin-only — nothing else lets a client resolve a foreign-key uid to a name for post authorship, leaderboards, friend lists, etc. |
| `searchUsers` | ✅ Mobile | **Added this session.** Prefix search on `username_lower` (a lowercased mirror field also added this session — see `updateMyProfile.ts`/`onUserCreate.ts`). Powers Find Friends. |
| `addUserNote` | 🛠️ Admin | Internal admin-only note on a user (never shown to the user). |

## Community (posts, comments, likes, moderation)

| Function | Caller | Purpose |
|---|---|---|
| `createPost` | ✅ Mobile | Create a post. Admins may pass `authorId` to post as another account (official "Strolla Health" brand posts). |
| `editPost` / `deletePost` | 🛠️ Admin (edit) / ✅ Mobile (delete, own post) | Edit = owner or admin correction. Delete = permanent, distinct from `hidePost`. |
| `hidePost` / `pinPost` / `lockComments` | 🛠️ Admin | Moderation actions — hide (soft, reversible), pin, lock comments. Independent toggles. |
| `addComment` / `editComment` / `deleteComment` | ✅ Mobile (add/delete) / 🛠️ Admin (edit) | `comments_count` on the parent post is maintained by the `onCommentWrite` trigger, not incremented here. |
| `onCommentWrite` | ⚙️ Trigger | Keeps `communityPosts.comments_count` correct regardless of which path touched the comments subcollection. |
| `onLikeWrite` | ⚙️ Trigger | Likes are a **direct client Firestore write** (`likes/{uid}`, owner-only create/delete — see `firestore.rules`); this trigger keeps `likes_count` denormalized and correct. |
| `reportContent` | ✅ Mobile | Report a post or user. Previously the Flutter report sheet submitted to nothing — this is what made it real. |
| `resolveReport` | 🛠️ Admin | Single atomic moderation action: mutate the target, resolve every open report on it, notify the user — one call instead of client-orchestrated multi-step. |
| `sendFriendRequest` / `respondFriendRequest` / `removeFriend` | ✅ Mobile | Friend request lifecycle. Uses a **deterministic pair-id** (`pairId(uidA, uidB)`) so friendship state has one source of truth regardless of who acted first. |
| `blockUser` / `unblockUser` | ✅ Mobile | UID-based blocking (fixed a legacy Flutter bug that blocked by *display name*). Blocking also dissolves any existing friendship. |

## Challenges

| Function | Caller | Purpose |
|---|---|---|
| `createChallenge` | ✅ Mobile | Creates a **private** challenge (mobile can never create an official one). Creator auto-joins. Generates + returns an invite code for private visibility. |
| `joinChallenge` / `leaveChallenge` | ✅ Mobile | Join by `challengeId` (public) or `inviteCode` (private). |
| `updateChallenge` | 🛠️ Admin | General field editor (title/description/image/dates/rules/badge) — distinct from the lifecycle callables below. |
| `publishChallenge` / `archiveChallenge` / `deleteChallenge` | 🛠️ Admin | Lifecycle transitions. Delete cascades participant removal. |
| `setOfficialMonthlyChallenge` | 🛠️ Admin | Flips `is_official` — only one challenge can hold it at a time. |
| `setChallengeWinner` | 🛠️ Admin | Overrides the auto-computed winner (e.g. post-hoc disqualification). |
| `removeParticipant` | 🛠️ Admin | Admin "kick" from a challenge. |
| `onChallengeEnd` | ⚙️ Scheduled (daily 00:10) | Locks in the default winner (leaderboard leader) at `end_date`. |
| `updateChallengeLeaderboard` | ⚙️ Trigger | Maintains the denormalized `leaderboard_top` array on the challenge doc — this is what "Last Month's Winners" and completed-challenge standings read from, not a live re-query. |

## Devices (BLE hardware fleet)

| Function | Caller | Purpose |
|---|---|---|
| `pairDevice` | ✅ Mobile | Pairs by **serial number** (manually entered — BLE has no per-unit identifier, every unit advertises the same name). Enforces one-device-per-user; pairing a new one auto-unpairs the old. |
| `provisionDevice` / `deleteDevice` | 🛠️ Admin | **super_admin only.** A device that has ever been paired can't be hard-deleted, only marked replaced (warranty/ownership history). |
| `reassignDevice` / `forceUnpairDevice` / `markDeviceReplaced` | 🛠️ Admin | Support-desk actions. `paired_at` is deliberately never cleared by unpair/replace — it's a permanent "was this ever paired" flag `deleteDevice` relies on. |
| `pushFirmwareUpdate` | 🛠️ Admin | Sets a target firmware version string for a device to poll for — no real OTA delivery channel exists yet. |
| `onDeviceWrite` | ⚙️ Trigger | Logs a pairing/unpairing event whenever `owner_user_id` changes, regardless of which callable caused it. |

## Health data (workouts, daily activity)

| Function | Caller | Purpose |
|---|---|---|
| `ingestWorkoutSession` | ✅ Mobile | Uploads a completed session. `id` is client-generated (epoch-ms string) and doubles as the idempotency key. Distance/calories computed server-side if the client didn't already. |
| `ingestHealthSample` | ✅ Mobile | Apple Health / Health Connect sample ingestion. |
| `onDailyActivityWrite` | ⚙️ Trigger | Recomputes denormalized `stats.lifetime_steps`/`streak_current`/`streak_longest` on every `dailyActivity` write. Also syncs steps into any challenge the user is actively in. |

## Integrations (Strava / Oura / Garmin / MyFitnessPal / on-device)

| Function | Caller | Purpose |
|---|---|---|
| `startOAuthConnect` | ✅ Mobile | Begins an OAuth flow; mirrors the old FastAPI endpoint shape exactly so the Flutter `FlutterWebAuth2` call site didn't need to change. |
| `oauthCallback` | ⚙️ HTTP (not callable) | Browser redirect target — completes the OAuth token exchange, bounces back into the app via its custom URL scheme. |
| `markOnDeviceConnected` | ✅ Mobile | Confirms HealthKit/Health Connect connection (no OAuth redirect for these — the OS permission dialog *is* the connect step). |
| `disconnectIntegration` | ✅ Mobile + 🛠️ Admin | Self or admin. Existing synced data is untouched — only the connection/tokens go away. |
| `listMyIntegrationConnections` | ✅ Mobile | **Added this session.** `integrationConnections` is Functions-only in rules (holds OAuth tokens) — this is the only way a user could see their own connection status. |
| `listIntegrationConnections` | 🛠️ Admin | Admin panel's view of every user's connections (token fields stripped). |
| `resyncIntegration` | 🛠️ Admin | Forces one on-demand data pull — also the practical fix for a stuck `error` connection. |
| `syncOAuthProviderData` | ⚙️ Scheduled | Periodic pull for every connected OAuth integration. |
| **Live status**: Strava/Oura/Garmin/MyFitnessPal all show "Coming soon" in the app — Garmin/MyFitnessPal have no real API credentials yet (MyFitnessPal has no public self-serve registration at all since 2019, needs a signed partnership), Strava/Oura are wired end-to-end but gated pending final approval. | | |

## Legal (Terms / Privacy Policy / Community Guidelines)

| Function | Caller | Purpose |
|---|---|---|
| `createLegalDraft` / `updateLegalDraft` / `discardLegalDraft` | 🛠️ Admin | Draft editing lifecycle. |
| `publishLegalVersion` | 🛠️ Admin | Archives the prior published version, promotes the draft, and — if `requires_reaccept` — fans out a `pending` acceptance record to every active user. |
| `recordLegalAcceptance` | ✅ Mobile | Records the caller's accept/decline of the currently published version. |
| `restoreLegalVersionAsDraft` | 🛠️ Admin | Never silently re-publishes an old version — always creates a new draft seeded from historical content. |
| `legalPage` | ⚙️ HTTP (public, unauthenticated) | Serves `/legal/**` for App Store Connect's Privacy Policy URL + the app's own Settings links. |

## Badges / Achievements

| Function | Caller | Purpose |
|---|---|---|
| `createBadge` / `updateBadge` / `deleteBadge` | 🛠️ Admin | Badge definition CRUD. Delete cascades every award referencing it. |
| `awardBadge` / `revokeBadge` | 🛠️ Admin | Manual award/revoke from a user's profile — distinct from the automatic evaluation path (`awarded_by` is set here, null there). |
| *(no callable — direct client read)* | ✅ Mobile | Achievements screen reads `badges`/`userBadges` directly; both collections are client-readable per rules, no callable needed. |

## Push Notifications

| Function | Caller | Purpose |
|---|---|---|
| `registerDeviceToken` / `unregisterDeviceToken` | ✅ Mobile | FCM token lifecycle. Token itself is the doc id, so re-registering is a no-op upsert. |
| `savePushNotification` | 🛠️ Admin | Composer's save-as-draft / schedule / edit-existing-draft actions. |
| `sendPushNotification` | 🛠️ Admin | Sends immediately — either a fresh compose (resolves + saves the segment in the same call) or an existing draft/scheduled one by id. |
| `sendTestPush` | 🛠️ Admin | Sends to one specific user's tokens only, outside audience resolution and send history. |
| `deletePushNotification` | 🛠️ Admin | Discards a draft / cancels a scheduled send (not for already-sent history). |
| `dispatchScheduledPush` | ⚙️ Scheduled (every 5 min) | Actually fires `scheduled`-status notifications when their time comes. |
| `notifyOnCommunityComment` / `notifyOnPostLike` / `notifyOnChallengeJoin` | ⚙️ Trigger | Real push notifications from real other users' actions — replaced the Flutter app's old `Timer.periodic(90s)` fake-event simulator. |

## Announcements

| Function | Caller | Purpose |
|---|---|---|
| `createAnnouncement` / `updateAnnouncement` / `duplicateAnnouncement` / `toggleAnnouncement` / `deleteAnnouncement` | 🛠️ Admin | Full CRUD for the admin panel's Announcements section. |
| *(no callable — direct client read)* | ✅ Mobile | **Added this session.** The home screen banner reads `announcements` directly (client-readable per rules) and does its own audience matching (`everyone`/`free`/`premium`/`new_users`/`beta_testers`/`kickstarter_backers`/`iphone`/`android`/`canada`/`usa`) against the caller's own `users/{uid}` doc. `app_version` audience is a defined-but-unsupported case (no `package_info_plus` dependency wired up to read the running app's version) — deliberately never matches rather than guessing. |

## Premium / Billing

| Function | Caller | Purpose |
|---|---|---|
| `grantPremium` / `extendPremium` / `revokePremium` | 🛠️ Admin | The **comp path** — entirely independent of RevenueCat, only touches `comp_until`/`comp_reason`. Covers signup trials, Kickstarter rewards, admin comps — all the same mechanism with a different reason string. |
| `revenueCatWebhook` | ⚙️ HTTP (RevenueCat → server) | Keeps `subscription.{tier,status,renews_at,cancelled_at,revenuecat_app_user_id}` in sync. Never touches the comp fields above. |

## Settings / Config (admin panels)

| Function | Caller | Purpose |
|---|---|---|
| `updateAppContent` | 🛠️ Admin | Staging library for content the Flutter app would fetch by `key` — the app currently still uses hardcoded strings for this content, so this is ahead of client-side wiring. |
| `updateAppSettings` | 🛠️ Admin | **super_admin only.** Pricing/trial length/minimum app version — single-doc partial update. |
| `updateFeatureFlag` | 🛠️ Admin | Runtime-editable free/premium feature split, no app release needed. |
| `grantBetaOverride` / `revokeBetaOverride` | 🛠️ Admin | Per-user (or `target_type: "ambassador"`, applies dynamically to every ambassador) feature overrides. |

## Analytics

| Function | Caller | Purpose |
|---|---|---|
| `logAnalyticsEvent` | — | Master event log (validated server-side rather than a direct client Firestore write). Not currently called from the Flutter app. |
| `computeDailyStatsRollup` | ⚙️ Scheduled (daily 00:30) | Pre-aggregates the previous day so the admin Analytics page doesn't scan raw events on every load. |
| `computeRetentionCohort` | ⚙️ Scheduled (weekly, Monday 01:00) | Day-30 retention cohort computation. |
| `getAnalyticsDashboard` | 🛠️ Admin | Serves pre-computed rollups for the Analytics page's date range. |

---

## Data model reference — where each Firestore collection is read from

Collections the Flutter app reads **directly** (no callable — all covered by `firestore.rules`, cross-checked this session): `announcements`, `badges`, `blockedUsers`, `challenges` (+ `participants` subcollection), `comments` (nested under `communityPosts`), `communityPosts`, `devices` (own only), `friendships`, `legalDocumentVersions`, `likes` (nested), `userBadges`, `users` (own only).

`integrationConnections` is the one collection that's **Functions-only, even for the owning user** (`allow read: if false` — it holds OAuth tokens) — every access goes through `listMyIntegrationConnections`/`listIntegrationConnections`.

## Flutter data layer — entities / repositories / providers added this session

| Feature | Entity | Repository | Providers |
|---|---|---|---|
| Public profiles | `domain/entities/public_profile.dart` | `data/repositories/public_profile_repository.dart` | `publicProfileProvider` (family) |
| Community | `domain/entities/community_post.dart` (post + comment) | `data/repositories/community_repository.dart` | `postsProvider`, `commentsProvider` (family), `blockedUsersProvider` |
| Challenges | `domain/entities/challenge.dart` (+ `ChallengeLeaderboardEntry`) | `data/repositories/challenge_repository.dart` | `officialChallengeProvider`, `lastCompletedOfficialChallengeProvider`, `challengeLeaderboardProvider` (family), `challengeLeaderboardTopProvider` (family), `myChallengesProvider` |
| Friends | `domain/entities/friend.dart` | `data/repositories/friend_repository.dart` | `friendshipsProvider`, `friendshipWithProvider` (family) |
| Devices | `domain/entities/paired_device.dart` | `data/repositories/device_repository.dart` | `myDeviceProvider` |
| Announcements | `domain/entities/announcement.dart` | `data/repositories/announcement_repository.dart` | `activeAnnouncementProvider` |

## Known scope boundaries (deliberate, not oversights)

- **No image upload pipeline** — there's no Firebase Storage bucket or upload callable anywhere in the backend yet. Community post photos and profile photo upload are UI-only for now; nothing sends a local file path to the backend pretending it's a hosted URL.
- **Cross-user stats are limited by `firestore.rules` on purpose** — `dailyActivity`, `userBadges`, and full `users/{uid}` docs are owner/admin-only reads. `PublicProfileScreen` only shows what `getPublicProfiles` actually exposes (identity + `privacy.public_profile`-gated lifetime stats) — no fabricated "steps today"/"achievements"/"friend count" for other users.
- **`announcements` audience `app_version`** is defined in the type system and admin UI but never matches on mobile — no version-reading package wired in yet.
- **Garmin/MyFitnessPal OAuth** have no real client credentials configured (`providerConfig.ts` leaves `authorizeUrl`/`tokenUrl` blank for MyFitnessPal specifically — no public API registration exists for it since 2019). Both show as "Coming soon"/"Pending approval" in the app rather than a broken connect flow.
- **`invite_friends_screen.dart`** has no real generic app-invite/referral backend (only private-challenge invite codes exist, which are unrelated) — it shares a real personalized message (the signed-in user's own name) rather than a fabricated tracking code or contacts list.
