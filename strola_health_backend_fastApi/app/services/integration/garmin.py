from urllib.parse import urlencode

from app.core.config import Settings
from app.models.enums import DataSource
from app.models.integration import IntegrationConnection
from app.services.integration.base import OAuthHealthProvider

# Garmin Connect Developer Program currently issues OAuth2 + PKCE for new
# integrations (the legacy Health API used OAuth1.0a) — confirm which tier
# the client's Garmin application is approved for before implementing
# handle_callback, since the token endpoint differs between them.
GARMIN_AUTHORIZE_URL = "https://connect.garmin.com/oauth2Confirm"
GARMIN_TOKEN_URL = "https://diauth.garmin.com/di-oauth2-service/oauth/token"  # for handle_callback, once implemented


class GarminProvider(OAuthHealthProvider):
    provider = DataSource.garmin

    def __init__(self, settings: Settings):
        self._settings = settings

    def get_authorization_url(self, user_id: str) -> str:
        params = {
            "client_id": self._settings.garmin_client_id,
            "redirect_uri": self._settings.garmin_redirect_uri,
            "response_type": "code",
            "state": user_id,
        }
        return f"{GARMIN_AUTHORIZE_URL}?{urlencode(params)}"

    def handle_callback(self, user_id: str, code: str) -> IntegrationConnection:
        # TODO: exchange `code` for tokens at GARMIN_TOKEN_URL once the
        # client's Garmin Connect Developer Program application is approved.
        raise NotImplementedError("Garmin token exchange pending API credentials")

    def sync(self, connection: IntegrationConnection) -> None:
        # Garmin's Health API is primarily push-based (it pings/pushes data
        # to a registered webhook URL rather than expecting polling) — this
        # pull-style sync is a fallback/backfill path. See `handle_webhook`
        # for the primary integration point once credentials exist.
        raise NotImplementedError("Garmin data sync pending API credentials")

    def handle_webhook(self, payload: dict) -> None:
        # TODO: Garmin's "ping" service notifies a summary is ready and a
        # separate authenticated GET fetches it; the "push" service sends the
        # full payload directly. Match `payload`'s user identifier against
        # IntegrationConnectionRepository.get_by_external_athlete_id, then
        # feed parsed activity through ActivityService.
        raise NotImplementedError("Garmin webhook handling pending API credentials")
