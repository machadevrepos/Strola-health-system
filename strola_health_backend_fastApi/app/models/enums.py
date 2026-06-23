from enum import StrEnum


class DataSource(StrEnum):
    """Where a piece of activity data originated.

    Used in two related but distinct contexts:
    - `WorkoutSession.source` — what recorded this discrete session
      (`strolla_app` covers every session recorded through the app's own
      tracker, whether or not BLE was connected during it).
    - `DailyActivitySummary.by_source` keys / `IntegrationConnection.provider`
      — which step-counting source contributed to a day's totals.
    One shared vocabulary so these never drift into incompatible enums.
    """

    strolla_app = "strolla_app"
    strolla_device = "strolla_device"
    healthkit = "healthkit"
    health_connect = "health_connect"
    oura = "oura"
    garmin = "garmin"
    strava = "strava"
    manual = "manual"

    @property
    def is_cloud_oauth(self) -> bool:
        """True for sources the backend itself pulls server-side via OAuth.
        False for on-device-read sources (HealthKit/Health Connect) and the
        BLE device/app/manual entry, which only ever arrive via the ingestion
        endpoint — the backend never makes an outbound call for those."""
        return self in (DataSource.oura, DataSource.garmin, DataSource.strava)


# Priority order used when merging same-day step data from multiple sources
# into one canonical daily total — earlier wins. Strolla's own hardware always
# wins, even over a paired Apple Watch, per the client's explicit requirement.
SOURCE_PRIORITY: list[DataSource] = [
    DataSource.strolla_device,
    DataSource.healthkit,
    DataSource.health_connect,
    DataSource.garmin,
    DataSource.oura,
    DataSource.strava,
    DataSource.manual,
]
