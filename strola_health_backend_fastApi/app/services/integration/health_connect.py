"""Android Health Connect has no adapter class, for the same reason as Apple
HealthKit (see `apple_health.py`) — it's an on-device API, not a cloud OAuth
platform. This is also the single integration point for BOTH Google Fit and
Samsung Health on Android: Google Fit's own REST API is being sunset in
favor of Health Connect, and Samsung Health has no general-purpose public
cloud API — both platforms write into Health Connect, and the Flutter app
reads from Health Connect once, rather than integrating three separate SDKs.

The entire backend integration point is `POST /api/v1/integrations/ingest`
(see `app/api/v1/integrations.py`), which accepts a `HealthSampleIngest`
payload tagged `source=health_connect` and routes it through
`ActivityService.ingest_health_sample`. As with HealthKit, this is also the
fallback step-count source for Android users without a Strolla device.
"""
