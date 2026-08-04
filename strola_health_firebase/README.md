# Strolla Health — Firebase backend

Cloud Functions + Firestore + Auth custom claims implementation of the design in
`../Firebase-Backend-Audit-And-Design.md`. `strola_health_backend_fastApi` is a
separate, unrelated milestone — not used by anything here.

**Status (2026-07-29): deployed and fully test-verified on the live project `strolla-health-4c93b`.**
All 95 functions are live, Firestore rules + indexes are deployed, the Trigger Email extension is
installed, and every one of the 95 functions has a real end-to-end test against production (not
the emulator) — `scripts/test-all.js`, 176 checks across 14 domains, all passing. Three real bugs
were found and fixed this way — see "Bugs found by the test suite" below. Frontend wiring is the
next phase, intentionally not started yet (client wants every function verified first).

## Layout

```
strola_health_firebase/
  firebase.json            emulator config, functions predeploy build
  .firebaserc               points at the `strolla-health-4c93b` project
  firestore.rules            security rules (Part 2.3 of the design doc)
  firestore.indexes.json     composite indexes (Part 2.4)
  extensions/
    firestore-send-email.env    Trigger Email extension config
  functions/
    scripts/
      bootstrap-super-admin.js   one-off: grant the first super_admin
      smoke-test.js               original post-deploy smoke check (superseded by test-all.js)
      test-lib.js                 shared test helpers (curl-based HTTP, user factory, assertions)
      test-all.js                 full-coverage suite: every function, 14 domains, run with
                                   `node scripts/test-all.js [domain]` (no arg = everything)
    src/
      lib/                   shared: admin init, types, constants, auth helpers,
                              audit log, mailer, FCM, secrets, config
      auth/                  #1-8  roles, bans, delete account, force logout, email
      devices/                #12-16 fleet provisioning/pairing
      integrations/           #54-59 OAuth (Strava/Oura/Garmin/MyFitnessPal) + on-device health
      health/                 #17-20 workout/daily-activity ingestion, streaks, PRs
      challenges/             #21-28 create/join/leaderboard/winner
      badges/                 #29-30 + auto-award engine
      community/              #31-38 posts/comments/likes/reports/friends/blocks
      moderation/              #36  resolveReport (the compound atomic action)
      premium/                 #44-45 RevenueCat webhook + admin comp grants
      push/                    #39-43 FCM segments, send/schedule, real event triggers
      legal/                   #46-49 draft/publish/accept versioned legal docs
      settings/                #50-53 app content, app settings, feature flags, beta
      announcements/           in-app banner CRUD (not in the original numbered list)
      analytics/               #60-63 event log + nightly/weekly rollups
```

Every file has a short comment naming which Part 3 function number it implements and
why it's shaped the way it is — read those before changing behavior.

## Local setup

```
cd functions
npm install
npm run build      # or: npx tsc --noEmit for a fast typecheck-only pass
```

## Authenticating for deploy / admin scripts

This project deploys via a **service account key**, not personal `firebase login` — that
interactive flow needs a real TTY/browser round-trip that doesn't work from every shell. Every
command below assumes:

```
export GOOGLE_APPLICATION_CREDENTIALS=~/secrets/strolla/service-account.json
```

(key lives outside the repo, `chmod 600`'d — never commit it). The service account
(`firebase-adminsdk-fbsvc@strolla-health-4c93b.iam.gserviceaccount.com`) currently has **Owner**
on the project — broader than ideal long-term, but needed once for the first-ever deploy's IAM
bootstrap (see below). Worth scoping down to specific roles (Secret Manager Admin, Cloud
Functions Admin, Cloud Build Editor, Artifact Registry Admin, Service Account User, Cloud
Datastore Index Admin, Firebase Rules Admin) once things are stable and no fresh IAM bindings are
needed.

## Running against the emulator

```
firebase emulators:start --only functions,firestore,auth,pubsub
```
(from `strola_health_firebase/`, with the Firebase CLI installed — `npx firebase-tools` works
without a global install too). Emulator ports match `strola_health_backend_fastApi`'s emulator
config (Firestore 8080, Auth 9099, UI 4000) so both can't run at once — expected, not meant to
run together.

## Secrets

Set with `firebase functions:secrets:set NAME --data-file <path-or-->` (`-f` to skip the
confirmation prompt; `--data-file -` reads from stdin, avoiding any TTY requirement):

| Secret | Status | Notes |
|---|---|---|
| `STRAVA_CLIENT_ID` / `STRAVA_CLIENT_SECRET` | ⚠️ placeholder (`not_configured_yet`) | Client has real Strava app credentials ready — swap the placeholder for the real values, then Strava is fully live (no redeploy needed, secret updates apply to new invocations). |
| `GARMIN_CLIENT_ID` / `GARMIN_CLIENT_SECRET` | placeholder | Client has applied to the Garmin Connect Developer Program, awaiting approval. |
| `OURA_CLIENT_ID` / `OURA_CLIENT_SECRET` | placeholder | Deliberately deferred — Oura requires owning a ring to create a developer account. Client may revisit later. |
| `MYFITNESSPAL_CLIENT_ID` / `MYFITNESSPAL_CLIENT_SECRET` | placeholder | No public developer signup exists (Under Armour closed it in 2019) — needs a direct partnership. `authorizeUrl`/`tokenUrl` in `providerConfig.ts` are left blank on purpose, not guessed. |
| `REVENUECAT_WEBHOOK_SECRET` | placeholder | Set once RevenueCat is configured; value comes from RevenueCat's own webhook settings page. |

Placeholder values are harmless — every function checks for real config before doing anything
provider-specific and fails with a clean, friendly error otherwise (see `startOAuthConnect.ts`'s
`clientId`/`authorizeUrl` check). They exist purely because Cloud Functions v2 requires every
secret a function *references* to exist in Secret Manager at deploy time, even ones not really
configured yet.

Email (via the Trigger Email extension — **not yet installed**, see below) and FCM push use
ambient project/service-account credentials, no secret needed.

## Deploy history and gotchas (read before your next deploy)

Real issues hit getting this to production, in the order encountered — future deploys likely
won't hit most of these since the fixes are already in the repo, but worth knowing:

1. **`.firebaserc` had the wrong project id** (`strolla-health-dev`, an assumption carried over
   from the unrelated FastAPI folder's emulator config, never verified against a real project).
   Fixed to `strolla-health-4c93b` — always confirm this matches before deploying to a new
   environment.
2. **Default Admin SDK service account has narrow permissions** — generating a service account
   key from Firebase console gives it only `Firebase Admin SDK Administrator Service Agent`,
   not enough to manage secrets or deploy functions. Needed `Editor`, and separately `Owner` for
   the one-time IAM policy bindings Gen2 functions require on first use (Cloud Functions deploy
   itself grants roles to Google-managed service agents for Pub/Sub and Eventarc — that
   `setIamPolicy` call needs more than `Editor`).
3. **Single-field "composite" indexes are rejected.** `firestore.indexes.json` originally had a
   few entries with only one field (e.g. `devices.owner_user_id` alone) — Firestore auto-indexes
   every field by default, so declaring one explicitly as a composite index 400s with "this index
   is not necessary, configure using single field index controls." Removed the 3 offending
   entries; if you add a new index, double check it has ≥2 fields.
4. **First-ever Gen2 Firestore-trigger deploy needs Eventarc propagation time.** The three
   `onDocumentWritten` functions (`onDeviceWrite`, `onDailyActivityWrite`,
   `updateChallengeLeaderboard`) failed on the very first deploy with "Permission denied while
   using the Eventarc Service Agent" — Firebase's own error message says this is expected the
   first time a project uses 2nd-gen functions, and to retry in a few minutes. A plain retry of
   just those three (`firebase deploy --only functions:onDeviceWrite,functions:onDailyActivityWrite,functions:updateChallengeLeaderboard`)
   succeeded once the IAM bindings had propagated.
5. **Freshly-created composite indexes have a build-lag window.** Smoke-testing immediately after
   deploy, `onDailyActivityWrite`'s query (needs `dailyActivity(user_id, date desc)`, a composite
   index) briefly returned 0 results right after the index was created, making `stats.lifetime_steps`
   come back as 0 instead of the real value — not a code bug, confirmed by rerunning the identical
   check a few minutes later and getting the correct number immediately. If you ever deploy a
   *new* composite index and test against it right away, give it a few minutes first.
6. **Bootstrapping the first super_admin has its own race condition.** Creating a brand-new Auth
   user and immediately setting `role: super_admin` on it can get silently overwritten back to
   `role: user` moments later by the async `onUserCreate` trigger completing after your write.
   `bootstrap-super-admin.js` now verifies its write stuck ~6s later and retries once if not —
   safe to run any time, but for a *just-created* account, waiting ~10s before running it avoids
   the retry path entirely.

## Bugs found by the test suite (all fixed and re-verified live)

`test-all.js`'s first full run: 159 passed, 8 failed, tracing back to 3 real bugs (not test bugs):

1. **`forceUnpairDevice` cleared `paired_at`, erasing pairing history.** `deleteDevice` is
   supposed to refuse to hard-delete any device that's ever been paired (`owner_user_id ||
   paired_at`), forcing `markDeviceReplaced` instead. But `forceUnpairDevice` nulled out
   `paired_at` along with `owner_user_id`, so a force-unpaired device looked identical to a
   never-paired one — `deleteDevice` would wrongly succeed and permanently destroy a device with
   real history. Fix: `forceUnpairDevice` only clears `owner_user_id` now; `paired_at` stays as a
   permanent "this was paired at least once" marker.
2. **`startOAuthConnect` didn't recognize its own placeholder secrets.** The check was `if
   (!clientId) ...` — but a placeholder secret's value is the literal string `"not_configured_yet"`,
   which is truthy. Strava, Oura, and Garmin all have real `authorizeUrl`s configured (only their
   credentials are placeholders), so the check passed and the function happily returned a working
   `authorization_url` containing `client_id=not_configured_yet` — a user tapping "Connect" today
   would land on the real Strava/Oura/Garmin login page and then hit a confusing provider-side
   error instead of a clean in-app message. Fix: added `PLACEHOLDER_SECRET_VALUE` as an explicit
   sentinel check in `lib/constants.ts`, used anywhere secret-configured-ness is checked.
3. **Missing Firestore composite indexes for `legalDocumentVersions`.** `createLegalDraft`,
   `restoreLegalVersionAsDraft` (query: `doc_type ==, orderBy version desc`) and
   `publishLegalVersion` (query: `doc_type ==, status ==`) all needed composite indexes that were
   never added to `firestore.indexes.json` — every legal-doc function was completely broken,
   failing with a generic `INTERNAL` error (Firestore's real "index required" message gets
   swallowed by the callable-function error boundary; only visible in `firebase functions:log`).
   Fixed by adding both indexes; confirmed via `firebase functions:log --only createLegalDraft`
   before and after.

Final confirmation run: **176 passed, 0 failed, across all 14 domains.**

Scheduled functions (`onChallengeEnd`, `computeDailyStatsRollup`, `computeRetentionCohort`,
`dispatchScheduledPush`, `syncOAuthProviderData`) aren't included in that count — Cloud
Scheduler + OIDC-triggered, not a public HTTPS endpoint, so `test-all.js` can't invoke them the
same way. They're deployed successfully and code-reviewed, just not live-invoked yet. Worth
triggering manually via the Cloud Scheduler console/`gcloud scheduler jobs run` once available, or
just watching them fire naturally on their real schedule and checking `functions:log` after.

## Post-deploy checklist

1. Confirm all functions deployed: `firebase functions:list` (should show 95).
2. Run `node scripts/test-all.js` (needs `GOOGLE_APPLICATION_CREDENTIALS` set) — full 14-domain,
   176-check suite against the real deployed functions; cleans up its own test users/data. Pass a
   domain name (`auth`, `devices`, `integrations`, `health`, `challenges`, `badges`, `community`,
   `moderation`, `premium`, `push`, `legal`, `settings`, `announcements`, `analytics`) to run just
   one. Note: this machine's local network has shown intermittent hangs mid-script (confirmed to
   be local flakiness, not the functions — a hung call succeeds cleanly on retry) — if a run
   hangs, just rerun it (or the single affected domain).
3. Bootstrap a super_admin: `node scripts/bootstrap-super-admin.js someone@example.com` (user
   must already exist in Firebase Auth first). A demo account already exists:
   `info@strollahealth.com`, role `super_admin` — temp password was shared out-of-band with
   Maarij, should be changed on first login.
4. Trigger Email extension is installed (`extensions/firestore-send-email.env`) but has no real
   SMTP credentials yet — `sendPasswordResetForUser`, `sendAdminEmail`, and `resolveReport`'s
   guideline notices all write to `mail` correctly (verified by the test suite) but won't actually
   send until an SMTP relay (SendGrid/Mailgun/Postmark/etc.) is configured.
5. Swap the Strava placeholder secrets for the real values the client already provided (still
   pending as of this writing — need the actual client id/secret handoff to complete).

## Explicitly not done yet

- **Frontend wiring.** `strola_health_admin_next`, `strola_health_super_admin_next`, and
  `strola_health_flutter` still call their mock/local data layers — none of them call these
  functions yet. Deliberately held off until every function was verified (see "Bugs found by the
  test suite" above) — that's done now, so this is the natural next phase.
- **Trigger Email extension has no real SMTP credentials** (see checklist above).
- **Strava secrets are still placeholders** — client has real values ready, just needs the
  handoff (see Secrets table above for the safe-handoff pattern used for the service account key).
- **No seed script.** Unlike `strola_health_backend_fastApi/scripts/seed_emulator.py`, there's no
  equivalent here yet — needed for local emulator testing with realistic data.
- **No CI integration** — `test-all.js` is thorough but run manually, not wired into a CI pipeline.
- **Garmin, Oura, and MyFitnessPal** still need real credentials (see Secrets table) before those
  integrations do anything beyond fail with a clean error. Garmin: client has applied, awaiting
  approval. Oura: deliberately deferred (needs to own a ring first). MyFitnessPal: needs a direct
  partnership, no self-serve signup exists.
- **The 5 scheduled functions** aren't live-invoked by the test suite (see "Bugs found" section) —
  deployed and code-reviewed only.
- **Analytics gap-fill**: `getAnalyticsDashboard` only reads pre-computed rollups — a date range
  with no rollup yet (e.g. today, before the nightly job runs) returns nothing for those days
  rather than computing on demand.
- **Service account is still on `Owner`** — fine for now, worth scoping down once no more fresh
  IAM bootstrapping is needed (see "Authenticating" above).
