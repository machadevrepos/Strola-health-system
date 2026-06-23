from urllib.parse import urlencode

from app.core.config import Settings
from app.models.enums import DataSource
from app.models.integration import IntegrationConnection
from app.services.integration.base import OAuthHealthProvider

STRAVA_AUTHORIZE_URL = "https://www.strava.com/oauth/authorize"
STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token"  # for handle_callback, once implemented
STRAVA_ACTIVITIES_URL = "https://www.strava.com/api/v3/athlete/activities"  # for sync(), once implemented


class StravaProvider(OAuthHealthProvider):
    provider = DataSource.strava

    def __init__(self, settings: Settings):
        self._settings = settings

    def get_authorization_url(self, user_id: str) -> str:
        params = {
            "client_id": self._settings.strava_client_id,
            "redirect_uri": self._settings.strava_redirect_uri,
            "response_type": "code",
            "scope": "activity:read",
            "state": user_id,
            "approval_prompt": "auto",
        }
        return f"{STRAVA_AUTHORIZE_URL}?{urlencode(params)}"

    def handle_callback(self, user_id: str, code: str) -> IntegrationConnection:
        # TODO: POST {client_id, client_secret, code, grant_type=authorization_code}
        # to STRAVA_TOKEN_URL once the client has a Strava API application,
        # then persist the returned access/refresh tokens + athlete id.
        raise NotImplementedError("Strava token exchange pending API credentials")

    def sync(self, connection: IntegrationConnection) -> None:
        # TODO: GET STRAVA_ACTIVITIES_URL with the stored access_token
        # (refreshing first if expired — Strava tokens expire in 6 hours),
        # map each activity to WorkoutSessionCreate(source=strava,
        # external_id=activity.id) and call ActivityService.ingest_session.
        raise NotImplementedError("Strava data sync pending API credentials")

    def handle_webhook(self, payload: dict) -> None:
        # TODO: Strava's webhook push sends {aspect_type, object_id,
        # owner_id, ...} on new/updated activities — match owner_id against
        # IntegrationConnectionRepository.get_by_external_athlete_id, then
        # fetch and ingest the single activity referenced by object_id.
        raise NotImplementedError("Strava webhook handling pending API credentials")
