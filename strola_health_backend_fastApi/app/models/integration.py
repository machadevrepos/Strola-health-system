from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel

from app.models.enums import DataSource


class ConnectionStatus(StrEnum):
    connected = "connected"
    disconnected = "disconnected"
    error = "error"


class IntegrationConnection(BaseModel):
    id: str  # f"{user_id}_{provider}"
    user_id: str
    provider: DataSource
    status: ConnectionStatus = ConnectionStatus.disconnected
    access_token: str | None = None  # Oura/Garmin/Strava only — never set for healthkit/health_connect
    refresh_token: str | None = None
    expires_at: datetime | None = None
    scopes: list[str] = []
    external_athlete_id: str | None = None  # provider's own user/athlete id, for webhook matching
    last_synced_at: datetime | None = None
    connected_at: datetime | None = None
    error_message: str | None = None


class OAuthConnectResponse(BaseModel):
    authorization_url: str


class HealthSampleIngest(BaseModel):
    """Generic payload the Flutter app POSTs after reading Apple HealthKit or
    Android Health Connect on-device (via the `health` package). There is no
    backend HTTP call for these two sources — this ingestion endpoint is the
    entire integration. Also the path used when a user has no Strolla device
    and relies on their phone's own step sensor."""

    source: DataSource  # healthkit | health_connect
    date: date
    steps: int | None = None
    distance_meters: float | None = None
    calories: int | None = None
