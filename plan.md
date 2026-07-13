# Firebase Connection Plan — Mobile App + Admin Panel

**Scope:** wire real Firebase (Auth first, data layer deferred) into `strola_health_flutter` and `strola_health_admin_next`. The client does not need the FastAPI backend (`strola_health_backend_fastApi`) running for this phase — everything here is Firebase-direct.

**Current state:** nothing is connected yet. No `google-services.json`, `GoogleService-Info.plist`, or `firebase_options.dart` exist in the Flutter project. Both apps already have full Firebase Auth code paths written and battle-tested against a **local mock stand-in** (this is exactly what "mobile is complete" and the recent admin mock-mode work already built) — they just need a real project behind them.

---

## The one decision this plan hinges on

Both apps' "mock mode" toggle currently controls **two different things at once**:

- **`strola_health_flutter`**: `firebaseAvailableProvider` (set in `main.dart` from whether `Firebase.initializeApp()` succeeded) gates *only* auth — sign-in state. There's no coupling to app data here; steps/sessions/community are already local-first (SQLite + mock), so this side is naturally already in the shape this phase wants.
- **`strola_health_admin_next`**: `IS_MOCK_MODE` (`src/lib/mock-mode.ts`) gates **both** auth (`auth-context.tsx`) *and* every data call (`src/lib/data/api.ts`, every `fetchX`/`updateX`/`createX`). It's one switch today.

Since the client doesn't want the backend yet, we want **real Firebase Auth + still-mocked data** in the admin panel simultaneously — which today's single flag can't express. This plan treats **splitting that flag in two** (`NEXT_PUBLIC_MOCK_AUTH` and `NEXT_PUBLIC_MOCK_DATA`, both defaulting to the old combined behavior) as required, not optional — see Phase 3.

---

## Phase 1 — Firebase project setup

1. Create the Firebase project (one project is enough for this phase — a dev/prod split is a later concern, noted at the bottom).
2. Enable **Authentication → Email/Password** provider (the only method either app's sign-in/sign-up screens currently call).
3. Register three apps under it:
   - Android — package name `com.machadev.strola_health`
   - iOS — bundle id `com.machadev.strolaHealth`
   - Web — for the admin panels (`strola_health_admin_next`, and `strola_health_super_admin_next` if it gets the same treatment)
4. Generate a service account key (Project Settings → Service Accounts) — needed once, for Phase 4's custom-claims script. Store it outside the repo (never commit it).

## Phase 2 — Mobile app (`strola_health_flutter`)

1. Run `flutterfire configure` (recommended over hand-placing config files — it registers all platforms in one pass and generates `lib/firebase_options.dart`, which `main.dart` should then pass into `Firebase.initializeApp(options: ...)` instead of the current bare call).
2. This drops in `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` automatically.
3. No app-code changes needed beyond wiring `firebase_options.dart` in — `AuthService`, `auth_providers.dart`, sign-in/up/forgot-password screens, and the "remember me" sign-out-on-launch logic in `main.dart` are already written against real `FirebaseAuth`, just currently unreachable because `Firebase.initializeApp()` has nothing to initialize against.
4. **Test end-to-end on a real device/emulator**: splash → intro → sign up with a real email → onboarding → sign out → sign back in → forgot-password email → delete account. All of these are real Firebase Auth operations already coded, not stubs — this is the actual acceptance test for this phase on the mobile side.

## Phase 3 — Admin panel (`strola_health_admin_next`)

1. Split the mock flag (see decision above):
   - `src/lib/mock-mode.ts`: add `IS_MOCK_AUTH` and `IS_MOCK_DATA`, each reading its own env var, both falling back to the existing `NEXT_PUBLIC_MOCK_MODE` if their specific var isn't set (so nothing breaks for anyone still running full-mock).
   - `auth-context.tsx`, `login/page.tsx`: switch their `IS_MOCK_MODE` checks to `IS_MOCK_AUTH`.
   - `data/api.ts`: switch its `IS_MOCK_MODE` checks to `IS_MOCK_DATA`.
2. Set `.env.local`:
   ```
   NEXT_PUBLIC_MOCK_AUTH=false
   NEXT_PUBLIC_MOCK_DATA=true        # stays true until the backend phase
   NEXT_PUBLIC_FIREBASE_API_KEY=...
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
   ```
3. No further code changes needed for sign-in itself — `firebase-client.ts` and `auth-context.tsx`'s non-mock branch (`onIdTokenChanged`, `signInWithEmailAndPassword`) are already correct.
4. **Test**: sign in with a real Firebase account and confirm the dashboard loads — data will still come from `mock-api.ts` (expected and correct for this phase), only the *session* is real.

Repeat steps 1–4 for `strola_health_super_admin_next` if/when it gets the same mock-mode treatment `admin_next` already has (it currently has none — separate follow-up, not blocking this phase).

## Phase 4 — Staff roles (custom claims)

Admin access is gated by a Firebase custom claim (`role: "admin" | "super_admin"`), read in `auth-context.tsx` via `getIdTokenResult().claims.role`. With no backend running, nothing sets this claim on sign-up — it has to be set out-of-band:

1. Write a small one-off Node script (`firebase-admin` SDK + the Phase 1 service account key) that takes an email and a role and calls `setCustomUserClaims`.
2. Run it once per real staff account you create (mirroring the mock seed's staff list — e.g. an admin account and a super_admin account) so there's something to actually sign in as and test role-gating against.
3. Document the script's usage in the repo (not committed alongside the service account key itself).

## Explicitly out of scope for this phase

- FastAPI backend — not deployed, not connected. Confirmed by the client.
- Firestore for business data (users, posts, challenges, devices, etc.) — the admin panel keeps reading/writing `mock-api.ts` (`NEXT_PUBLIC_MOCK_DATA=true`); the Flutter app keeps its local-first SQLite + mock behavior. Moving real data onto Firestore/FastAPI is a distinct, later phase — don't start it opportunistically while doing this one.
- Push notifications (FCM), RevenueCat webhook wiring, the admin audit-log backend, GDPR export tooling — all flagged in the earlier admin audit as separate, backend-dependent work.
- Dev/staging/prod Firebase project separation — fine to run this phase against a single project; split later once there's something real to protect.

## Acceptance checklist for "Firebase is connected"

- [ ] Firebase project created, Email/Password auth enabled
- [ ] Mobile: `flutterfire configure` run, `firebase_options.dart` wired into `main.dart`
- [ ] Mobile: real sign-up → sign-in → sign-out → password-reset all verified on device
- [ ] Admin: mock flag split into `IS_MOCK_AUTH` / `IS_MOCK_DATA`
- [ ] Admin: `.env.local` set to real auth + mock data, sign-in verified with a real account
- [ ] At least one real `admin` and one real `super_admin` account exist with custom claims set, and role-gating in the admin UI has been checked against both
