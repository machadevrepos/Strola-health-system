# Admin Panel Feature Roadmap

Source: client's feature wish-list (2026-07-08, confirmed 2026-07-09). Built in `strola_health_admin_next` only, on mock data (`mock-data.ts` → `mock-store.ts` → `mock-api.ts`, branched via `IS_MOCK_MODE`) — no backend/FastAPI changes yet.

Status: **all 17 sections built and verified** (typecheck clean, every route smoke-tested, no runtime errors). Feature Flags was already complete before this pass.

---

## What shipped

| Section | Notes |
|---|---|
| Dashboard | Added active this week/month, new signups, premium subscribers, active challenges, posts today, recent crashes (new `CrashReport` mock type — no real Crashlytics/Sentry yet). |
| Users | Search already existed. Added reset-password + send-email actions, and seeded profile photos (half the users, via pravatar) since photo viewing had nothing to render before. |
| Community | Added a real `CommunityComment` model (comments only existed as a count before), pin post, lock comments, ban-from-posting (new `posting_banned` field on `UserProfile`, distinct from a full account ban), and a Photos grid tab. |
| Reported Content | Original content was already shown inline. Added Ignore/Remove/Warn/Suspend as direct one-click actions from a report instead of one generic "resolve" dialog. |
| Public Challenge of the Month | Added `image_url`, `rules`, `winner_type` (most steps / goal completion %), and a draft → published → archived lifecycle with Publish/Archive actions. |
| Completed Public Challenges | New "Completed" tab: winner (defaults to the leaderboard leader, editable), admin-only notes. |
| Achievements | Badge CRUD already existed. Added `requirement_metric` + `requirement_value` (so "100k Steps" → "150k Steps" is a number edit, not an app release) and enabled/visible toggles. |
| Push Notifications | New subsystem — segment picker (everyone/premium/free/Canada/USA/inactive-30d/challenge participants/tracker owners) with a live recipient-count estimate, compose UI with the client's own example templates, send history. |
| Premium | New overview page — subscriber list sorted by soonest-expiring, admin-comp vs. real-subscription distinction, synthetic MRR estimate (clearly labelled as illustrative), Extend/Remove for comp'd subscribers. |
| Tracker Management | Reassign, push firmware update, and mark-replaced added to the existing device fleet panel (was unpair/provision only). |
| Connected Apps | New aggregate view — per-provider connected-user counts (bar chart) + a "needs reconnecting" list for errored connections. |
| App Content | New editable copy store — welcome messages, challenge descriptions, quotes, notification text, empty states — seeded partly from the app's real `notification_copy.dart` strings. |
| Analytics | New page: daily users, retention (by real signup-to-reopen cohort), avg daily steps, feature-usage breakdown, challenge participation, workout starts, community posts, shares, health-app connections. |
| Legal | Versioned Privacy Policy / Terms / Community Guidelines editor, with a distinct "save & force re-accept" action that bumps the version. |
| App Settings | New tab — default daily goal, challenge defaults, notification defaults, image size limit, character limits. |
| Beta Testing | New tab — grant a feature to a specific user, a specific email, or all "ambassadors" (new `is_ambassador` flag, toggleable from a user's profile), independent of the global feature flag. |
| Announcements | New page — the client's explicitly-requested feature. Create/edit/schedule (start/end date)/activate an in-app banner. Note: this only covers the **admin side** — actually showing the banner once-per-user-on-open is a Flutter app change, not built here. |

---

## Known gaps / follow-ups worth flagging

- **App Content, Legal, and Announcements** only cover the admin-panel editing side. The Flutter app doesn't yet read any of this remotely — it still uses hardcoded strings (`notification_copy.dart`, etc.) and has no announcement-banner UI. Making the admin edits actually take effect needs mobile-app work too.
- **Which app owns what**: everything above was built in `strola_health_admin_next` (the day-to-day tool). `strola_health_super_admin_next` still only has its own separate Fleet/Staff pages and was not touched — mirror these additions there if the client wants super-admins to see them too.
- **Dashboard's "recent app crashes"** and **Premium's revenue estimate** are explicitly synthetic — there's no real crash-reporting pipeline or RevenueCat price data behind them yet.
