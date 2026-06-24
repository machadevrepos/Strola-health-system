# Strolla Health

This repo has four projects:

| Folder | What it is |
|---|---|
| `strola_health_backend_fastApi` | FastAPI + Firestore backend — the only API surface; both panels and the mobile app talk to this. |
| `strola_health_admin_next` | Admin panel (Next.js) — day-to-day staff console: users, moderation, challenges/badges, analytics, settings. |
| `strola_health_super_admin_next` | Super Admin panel (Next.js) — everything the Admin panel has, plus device fleet provisioning and staff/role management. |
| `strola_health_flutter` | The mobile app these two panels administer. |

To test the admin panels, you need the **backend** and **at least one** of the
two Next.js panels running locally. Both panels run fine at the same time on
different ports if you want to try both.

## 1. Install prerequisites

- **Node.js 20+** — https://nodejs.org
- **Python 3.13** — https://python.org
- **Firebase CLI** — `npm install -g firebase-tools`
- **Java JRE 11+** — required by the Firestore emulator only. https://adoptium.net
  (skip this if you already have a JDK/JRE installed for anything else)

## 2. Start the Firebase emulator (Firestore + Auth)

This stands in for a real Firebase project — no Firebase account or billing
needed.

```
cd strola_health_backend_fastApi
firebase emulators:start --only firestore,auth
```

Leave this running in its own terminal. The first time you run it, the
Firebase CLI may download the emulator binaries (one-time, a minute or two).
You'll see a table confirming Auth on `:9099` and Firestore on `:8080`, and
an Emulator UI at http://localhost:4000 where you can browse the data
directly if you want to.

## 3. Start the backend

In a **new terminal**:

```
cd strola_health_backend_fastApi
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS/Linux

pip install -r requirements.txt
copy .env.example .env          # Windows
# cp .env.example .env          # macOS/Linux
```

Open `.env` and fill in these values (everything else can stay blank — those
are for real third-party integrations that aren't needed to test the
panels):

```
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
FIREBASE_PROJECT_ID=strolla-health-dev
```

Then seed it with demo data (one-time, with the emulator from step 2 still
running):

```
python scripts/seed_emulator.py
```

This prints a password and two staff emails at the end — **note those down**,
you'll use them to log into the panels. Finally, start the API:

```
uvicorn app.main:app --reload
```

Leave this running too. Visit http://localhost:8000/docs to confirm it's up.

## 4. Start a panel

In a **new terminal**, pick one (or do both, in two terminals):

**Admin panel:**
```
cd strola_health_admin_next
npm install
copy .env.local.example .env.local    # Windows; `cp` on macOS/Linux
npm run dev
```
Opens at **http://localhost:3100**.

**Super Admin panel:**
```
cd strola_health_super_admin_next
npm install
copy .env.local.example .env.local    # Windows; `cp` on macOS/Linux
npm run dev
```
Opens at **http://localhost:3200**.

## 5. Log in

Use one of the emails the seed script printed in step 3, with the password it
printed alongside it:

- The `admin` account works on the **Admin panel** (port 3100).
- The `super_admin` account works on **both** panels — only it can see the
  Fleet and Staff & Roles sections on the Super Admin panel.

If you ever lose the printed credentials, just re-run
`python scripts/seed_emulator.py` — it's safe to run again and will print
them again.

## Troubleshooting

- **"Address already in use" on 8000/8080/9099** — something else on your
  machine is using that port. Stop it, or change the port (backend:
  `uvicorn app.main:app --reload --port 8001` and update
  `NEXT_PUBLIC_API_URL` in both `.env.local` files to match; emulator ports
  are set in `strola_health_backend_fastApi/firebase.json`).
- **Panel loads but every page shows an error** — almost always means the
  backend or emulator isn't running, or `NEXT_PUBLIC_API_URL` in `.env.local`
  doesn't match the port `uvicorn` printed. Check both terminals are still
  running.
- **CORS error in the browser console** — the backend's `.env` has
  `ALLOWED_ORIGINS=http://localhost:3100,http://localhost:3200` by default
  (matching both panels); if you changed a panel's port, add it there too
  and restart `uvicorn`.
