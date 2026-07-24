from datetime import date, timedelta
from urllib.parse import urlencode

import httpx

from app.core.config import Settings
from app.core.time import utcnow
from app.models.enums import DataSource
from app.models.integration import ConnectionStatus, HealthSampleIngest, IntegrationConnection
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.repositories.user_repository import UserRepository
from app.services.activity_service import ActivityService
from app.services.integration.base import OAuthHealthProvider

OURA_AUTHORIZE_URL = "https://cloud.ouraring.com/oauth/authorize"
OURA_TOKEN_URL = "https://api.ouraring.com/oauth/token"
OURA_DAILY_ACTIVITY_URL = "https://api.ouraring.com/v2/usercollection/daily_activity"


class OuraProvider(OAuthHealthProvider):
    provider = DataSource.oura

    def __init__(
        self,
        settings: Settings,
        connection_repo: IntegrationConnectionRepository,
        activity_service: ActivityService,
        user_repo: UserRepository,
    ):
        self._settings = settings
        self._connections = connection_repo
        self._activities = activity_service
        # Unused here — Oura's daily summary feeds ingest_health_sample, which
        # (unlike ingest_session) doesn't need a UserProfile. Kept for
        # interface consistency with the other two OAuth providers.
        self._users = user_repo

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
        response = httpx.post(
            OURA_TOKEN_URL,
            data={
                "client_id": self._settings.oura_client_id,
                "client_secret": self._settings.oura_client_secret,
                "redirect_uri": self._settings.oura_redirect_uri,
                "code": code,
                "grant_type": "authorization_code",
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()

        connection = IntegrationConnection(
            id=self._connections.doc_id(user_id, self.provider),
            user_id=user_id,
            provider=self.provider,
            status=ConnectionStatus.connected,
            access_token=data["access_token"],
            # Single-use — the next refresh call returns a new one that must
            # overwrite this, never reused (see _ensure_fresh_token).
            refresh_token=data["refresh_token"],
            expires_at=utcnow() + timedelta(seconds=data.get("expires_in", 86400)),
            scopes=(data.get("scope") or "").split(" "),
            connected_at=utcnow(),
        )
        self._connections.upsert(connection.id, connection)
        return connection

    def sync(self, connection: IntegrationConnection) -> None:
        access_token = self._ensure_fresh_token(connection)

        end = date.today()
        start = end - timedelta(days=7)
        response = httpx.get(
            OURA_DAILY_ACTIVITY_URL,
            headers={"Authorization": f"Bearer {access_token}"},
            params={"start_date": start.isoformat(), "end_date": end.isoformat()},
            timeout=10,
        )
        response.raise_for_status()

        for day in response.json().get("data", []):
            sample = HealthSampleIngest(
                source=DataSource.oura,
                date=date.fromisoformat(day["day"]),
                steps=day.get("steps"),
                distance_meters=day.get("equivalent_walking_distance"),
                calories=day.get("active_calories"),
            )
            self._activities.ingest_health_sample(connection.user_id, sample)

        self._connections.upsert(
            connection.id,
            connection.model_copy(update={"last_synced_at": utcnow()}),
        )

    def _ensure_fresh_token(self, connection: IntegrationConnection) -> str:
        if connection.expires_at and connection.expires_at > utcnow() and connection.access_token:
            return connection.access_token

        response = httpx.post(
            OURA_TOKEN_URL,
            data={
                "client_id": self._settings.oura_client_id,
                "client_secret": self._settings.oura_client_secret,
                "refresh_token": connection.refresh_token,
                "grant_type": "refresh_token",
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()

        refreshed = connection.model_copy(
            update={
                "access_token": data["access_token"],
                "refresh_token": data["refresh_token"],  # single-use — must persist the new one
                "expires_at": utcnow() + timedelta(seconds=data.get("expires_in", 86400)),
            }
        )
        self._connections.upsert(refreshed.id, refreshed)
        return refreshed.access_token
