# Strolla Health — Backend (FastAPI + Firestore)

The API gateway for the Strolla Health mobile app, the Admin panel, and the
Super Admin panel. FastAPI is the **only** API surface in the system — every
client (Flutter app, both Next.js panels) talks to this service; nothing
talks to Firestore directly. Firebase Authentication handles identity
(email/password + Sign in with Apple + Google); this service verifies the
resulting Firebase ID token on every request and reads a `role` custom claim
(`user` / `admin` / `super_admin`) for authorization.

See `/docs` (Swagger UI) once running for the full endpoint reference — this
README covers setup, not the API surface.

## Architecture

```
app/
├── main.py            — app factory, router registration, CORS
├── core/               — config, Firebase init, token verification, exceptions
├── models/              — Pydantic domain models (one file per aggregate)
├── repositories/         — Firestore access layer (the only layer touching Firestore directly)
├── services/              — business logic, including the wearable integration adapters
│   └── integration/        — Apple Health / Health Connect / Oura / Garmin / Strava
└── api/v1/                  — routers; api/v1/admin/ requires admin or super_admin
```

Layering rule: routers depend only on services; services depend only on
repositories; repositories are the only code that imports
`google.cloud.firestore`. `app/api/deps.py` is the dependency-injection hub —
every repository/service is wired there.

## Local setup

1. **Python 3.13**, then:
   ```
   pip install -r requirements.txt
   cp .env.example .env
   ```

2. **Firestore + Auth, without a live Firebase project**: install the
   [Firebase CLI](https://firebase.google.com/docs/cli) and run the Local
   Emulator Suite:
   ```
   firebase emulators:start --only firestore,auth
   ```
   Then set in `.env`:
   ```
   FIRESTORE_EMULATOR_HOST=localhost:8080
   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
   FIREBASE_PROJECT_ID=strolla-health-dev
   ```
   No service account credentials are needed against the emulator.

3. **Against a real Firebase project**: create a service account
   (Firebase Console → Project Settings → Service Accounts → Generate new
   private key), save the JSON somewhere local, and set
   `FIREBASE_CREDENTIALS_PATH` + `FIREBASE_PROJECT_ID` in `.env`. Leave the
   two `*_EMULATOR_HOST` vars blank.

4. **Run it**:
   ```
   uvicorn app.main:app --reload
   ```
   Visit `http://localhost:8000/docs`.

## Creating the first super_admin

There is deliberately no HTTP endpoint that promotes a user to `super_admin`
— that must never be self-service. After signing up normally (through the
app or `/docs` with a token from the Auth emulator/a real account), run:

```python
from app.api.deps import get_db
from app.repositories.user_repository import UserRepository
from app.repositories.analytics_repository import AnalyticsEventRepository
from app.services.analytics_service import AnalyticsService
from app.services.auth_service import AuthService

db = get_db()
auth_service = AuthService(UserRepository(db), AnalyticsService(AnalyticsEventRepository(db)), trial_period_days=30)
auth_service.ensure_first_super_admin("<firebase-uid>")
```

This only succeeds if no `super_admin` exists yet anywhere in the system.
Every promotion after that goes through `POST /api/v1/admin/users/{id}/role`,
which itself requires an existing `super_admin`.

## What's stubbed, and why

Oura, Garmin, and Strava integrations are structurally complete (OAuth
authorization URLs, connection storage, webhook receivers) but their actual
token-exchange and data-pull HTTP calls raise `NotImplementedError` with a
`TODO` pointing at what's needed — there are no API credentials for any of
the three yet. See `app/services/integration/{oura,garmin,strava}.py`.

Apple Health and Android Health Connect have no adapter class at all by
design — see `app/services/integration/apple_health.py` for why; the
ingestion endpoint (`POST /api/v1/integrations/ingest`) is real and working.

RevenueCat webhook event parsing and the subscription state machine are
fully implemented (`app/services/subscription_service.py`); only the
webhook's bearer-token check needs a real `REVENUECAT_WEBHOOK_AUTH_TOKEN`
once a RevenueCat project exists.
