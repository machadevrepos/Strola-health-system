from urllib.parse import urlencode

from app.core.config import Settings
from app.models.enums import DataSource
from app.models.integration import IntegrationConnection
from app.services.integration.base import OAuthHealthProvider

OURA_AUTHORIZE_URL = "https://cloud.ouraring.com/oauth/authorize"
OURA_TOKEN_URL = "https://api.ouraring.com/oauth/token"  # for handle_callback, once implemented
OURA_DAILY_ACTIVITY_URL = "https://api.ouraring.com/v2/usercollection/daily_activity"  # for sync(), once implemented


class OuraProvider(OAuthHealthProvider):
    provider = DataSource.oura

    def __init__(self, settings: Settings):
        self._settings = settings

    def get_authorization_url(self, user_id: str) -> str:
        params = {
            "client_id": self._settings.oura_client_id,
            "redirect_uri": self._settings.oura_redirect_uri,
            "response_type": "code",
            "scope": "daily personal",
            "state": user_id,
        }
        return f"{OURA_AUTHORIZE_URL}?{urlencode(params)}"

    def handle_callback(self, user_id: str, code: str) -> IntegrationConnection:
        # TODO: POST {code, client_id, client_secret, redirect_uri,
        # grant_type=authorization_code} to OURA_TOKEN_URL once the client
        # has Oura developer credentials (see .env.example), then persist the
        # returned access/refresh tokens as an IntegrationConnection.
        raise NotImplementedError("Oura token exchange pending API credentials")

    def sync(self, connection: IntegrationConnection) -> None:
        # TODO: GET OURA_DAILY_ACTIVITY_URL with the stored access_token,
        # then call ActivityService.ingest_health_sample(user_id, ...) per
        # day returned, refreshing the token first if expired.
        raise NotImplementedError("Oura data sync pending API credentials")
