# Firestore Disaster Recovery Runbook

Project: `strolla-health-4c93b` · Database: `(default)` · Location: `nam5`

## What's enabled, as of 2026-08-03

| Setting | Value |
|---|---|
| Point-in-Time Recovery (PITR) | **Enabled** |
| Version retention window | 7 days (604800s) |
| Delete protection | **Enabled** (the database itself can't be deleted via API/CLI without first disabling this) |

Enabled via:
```
firebase firestore:databases:update '(default)' \
  --point-in-time-recovery ENABLED \
  --delete-protection ENABLED \
  --project strolla-health-4c93b
```

### What PITR actually covers

Continuous version history for every document write, for the last 7 days.
It protects against:
- A bad deploy/migration that corrupts or deletes data across many
  documents.
- An admin action (or a bug in one) that wrongly mutates/deletes records.
- Human error — someone runs the wrong script against production.

It does **not** protect against a bug that's been silently writing wrong
data for *longer* than 7 days, and it does not replace the app-level
recovery already built for account deletion specifically (`deleteAccount.ts`
soft-deletes with a 90-day window before `purgeDeletedAccounts.ts` hard-
deletes — see that function's own comments; PITR is a second, independent
safety net under that, not a replacement for it).

### Cost

PITR bills for the extra 7 days of continuous change history it retains,
on top of normal Firestore storage. It scales with how much data changes,
not with total database size — for this app's write volume, the
incremental cost is expected to be small, but it is not free. Worth
revisiting on a Firebase billing report a few weeks in, since this is a
solo/freelancer-run project.

## How to restore

Firestore's PITR restore does **not** overwrite the live database in place.
It clones the source database, at a chosen point in the last 7 days, into a
**new, separate database**. This is deliberate — it means a restore attempt
can never itself be the thing that destroys data, and the restored copy can
be inspected before anything is switched over.

### 1. Decide the restore point

You need an ISO 8601 timestamp within the last 7 days (or omit it to use
the most recent snapshot). If you don't know the exact moment, err earlier
— restoring to a few minutes before the bad event is safer than a few
minutes after.

### 2. Clone to a new database

```
firebase firestore:databases:clone '(default)' restore-YYYYMMDD-HHMM \
  --snapshot-time 2026-08-03T09:15:00Z \
  --project strolla-health-4c93b
```

This creates a brand-new database (`restore-YYYYMMDD-HHMM` — name it
whatever's clear) containing every document as it existed at that instant.
The live `(default)` database is untouched during this step.

### 3. Verify the clone

Before touching anything live:
- Open the new database in the [Firebase Console](https://console.firebase.google.com/project/strolla-health-4c93b/firestore)
  (databases are switchable via the database picker at the top of the
  Firestore page) and spot-check the data that was affected.
- If you have the diagnostic Node scripts pattern used elsewhere in this
  project (a script using `firebase-admin` + the service account JSON to
  read specific documents), point `admin.firestore()` at the cloned
  database name and compare specific known-good/known-bad documents.

### 4. Cut over

There is no automatic "promote clone to default" operation — Cloud
Functions and both admin panels are all hardcoded to use the `(default)`
database (via `firebase-admin`'s default `getFirestore()` and the client
SDKs' default app). To actually cut over, either:

- **Point everything at the cloned database** (bigger operation — every
  `getFirestore()` call in `functions/src/lib/admin.ts`, and every client
  SDK init in the Flutter app / both Next.js panels, would need a database
  ID passed explicitly). Only do this for a genuine full-database
  disaster.
- **Restore specific documents only** (the far more likely real case —
  "this one migration corrupted these 200 user docs"): write a one-off
  Node script, same pattern as the diagnostic scripts already used in this
  project, that reads the affected documents from the cloned database and
  writes them back into `(default)` with the Admin SDK. Far less
  disruptive than a full cutover, and the normal path for "a bug/bad
  script wrote wrong data to N documents."

### 5. Clean up

Delete the temporary clone database once you're done with it — it's a full
copy and bills as one:
```
firebase firestore:databases:delete restore-YYYYMMDD-HHMM --project strolla-health-4c93b
```

## Also covered elsewhere (not duplicated here)

- **Account deletion's own 90-day retention** — see
  `strola_health_firebase/functions/src/users/purgeDeletedAccounts.ts` and
  `deleteAccount.ts`. Independent of PITR.
- **Firestore security rules regression tests** — `functions/test/rules.test.ts`
  (`npm run test:rules`), which is a different kind of safety net
  (prevents bad rules from shipping, not data loss recovery).
