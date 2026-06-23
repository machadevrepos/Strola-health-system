"""Apple HealthKit has no adapter class — unlike Oura/Garmin/Strava, there is
no server-to-server OAuth flow. HealthKit only exposes data to the app
running on-device, via the native HealthKit SDK (the Flutter `health`
package wraps it).

The entire backend integration point is `POST /api/v1/integrations/ingest`
(see `app/api/v1/integrations.py`), which accepts a `HealthSampleIngest`
payload the Flutter app builds after reading HealthKit locally, and routes it
through `ActivityService.ingest_health_sample`. This is also the fallback
step-count source for users who don't own a Strolla device — their phone's
own motion sensor feeds HealthKit, which feeds this same endpoint.

There is nothing else to implement here on the backend side; the remaining
work for this integration is entirely on the Flutter side (reading HealthKit
via the `health` package and posting the result).
"""
