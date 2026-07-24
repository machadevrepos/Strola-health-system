from urllib.parse import urlencode

from app.core.config import Settings
from app.models.enums import DataSource
from app.models.integration import IntegrationConnection
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.repositories.user_repository import UserRepository
from app.services.activity_service import ActivityService
from app.services.integration.base import OAuthHealthProvider

# Garmin Connect Developer Program currently issues OAuth2 + PKCE for new
# integrations (the legacy Health API used OAuth1.0a) — Garmin's approval
# email states which one a given application is granted, and the two have
# different token endpoints/exchange parameters (PKCE requires a
# code_verifier generated at authorize time and presented again here, which
# this codebase has nowhere to persist between those two requests yet — that
# storage is the first thing to add once the approval comes through, ahead
# of the exchange logic itself). Confirm the tier before implementing
# handle_callback — writing it against the wrong one won't just fail loudly,
# Strava/Oura-shaped code that *looks* plausible for the wrong OAuth
# generation is the kind of bug that's easy to ship by accident.
GARMIN_AUTHORIZE_URL = "https://connect.garmin.com/oauth2Confirm"
GARMIN_TOKEN_URL = "https://diauth.garmin.com/di-oauth2-service/oauth/token"  # for handle_callback, once confirmed


class GarminProvider(OAuthHealthProvider):
    provider = DataSource.garmin

    def __init__(
        self,
        settings: Settings,
        connection_repo: IntegrationConnectionRepository,
        activity_service: ActivityService,
        user_repo: UserRepository,
    ):
        self._settings = settings
        # Unused until handle_callback/sync are implemented — kept for
        # interface consistency with the other two OAuth providers so
        # `registry.build_oauth_providers` can construct all three uniformly.
        self._connections = connection_repo
        self._activities = activity_service
        self._users = user_repo

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
        # client's Garmin Connect Developer Program application is approved
        # AND the approved OAuth tier (PKCE vs legacy) is confirmed.
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
