from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode

import httpx

from app.core.config import Settings
from app.core.time import utcnow
from app.models.activity import ActivityType, WorkoutSessionCreate
from app.models.enums import DataSource
from app.models.integration import ConnectionStatus, IntegrationConnection
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.repositories.user_repository import UserRepository
from app.services.activity_service import ActivityService
from app.services.integration.base import OAuthHealthProvider

STRAVA_AUTHORIZE_URL = "https://www.strava.com/oauth/authorize"
STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token"
STRAVA_ACTIVITIES_URL = "https://www.strava.com/api/v3/athlete/activities"

# Strava's `type` covers far more sports than this app models explicitly —
# anything unmapped falls back to `other` rather than raising.
_STRAVA_TYPE_MAP = {
    "Walk": ActivityType.outdoor_walk,
    "Hike": ActivityType.outdoor_walk,
    "Run": ActivityType.outdoor_run,
    "TrailRun": ActivityType.outdoor_run,
    "VirtualRun": ActivityType.treadmill,
    "WeightTraining": ActivityType.strength_training,
    "Yoga": ActivityType.yoga,
    "Pilates": ActivityType.pilates,
    "Workout": ActivityType.cardio,
    "Crossfit": ActivityType.cardio,
}


class StravaProvider(OAuthHealthProvider):
    provider = DataSource.strava

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
        self._users = user_repo

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
        response = httpx.post(
            STRAVA_TOKEN_URL,
            data={
                "client_id": self._settings.strava_client_id,
                "client_secret": self._settings.strava_client_secret,
                "code": code,
                "grant_type": "authorization_code",
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()
        athlete_id = data.get("athlete", {}).get("id")

        connection = IntegrationConnection(
            id=self._connections.doc_id(user_id, self.provider),
            user_id=user_id,
            provider=self.provider,
            status=ConnectionStatus.connected,
            access_token=data["access_token"],
            refresh_token=data["refresh_token"],
            expires_at=datetime.fromtimestamp(data["expires_at"], tz=timezone.utc),
            scopes=(data.get("scope") or "").split(","),
            external_athlete_id=str(athlete_id) if athlete_id is not None else None,
            connected_at=utcnow(),
        )
        self._connections.upsert(connection.id, connection)
        return connection

    def sync(self, connection: IntegrationConnection) -> None:
        access_token = self._ensure_fresh_token(connection)
        profile = self._users.get(connection.user_id)
        if profile is None:
            return

        response = httpx.get(
            STRAVA_ACTIVITIES_URL,
            headers={"Authorization": f"Bearer {access_token}"},
            params={"per_page": 30},
            timeout=10,
        )
        response.raise_for_status()

        for activity in response.json():
            start = datetime.fromisoformat(activity["start_date"].replace("Z", "+00:00"))
            elapsed = activity["elapsed_time"]
            session = WorkoutSessionCreate(
                id=f"strava_{activity['id']}",
                start_time=start,
                end_time=start + timedelta(seconds=elapsed),
                # Strava doesn't report step counts (distance/pace-based
                # sports) — left at 0 rather than guessed; distance still
                # drives calorie estimation in calculation_service.
                steps=0,
                distance_meters=activity.get("distance"),
                duration_seconds=elapsed,
                activity_type=_STRAVA_TYPE_MAP.get(activity.get("type", ""), ActivityType.other),
                source=DataSource.strava,
                external_id=str(activity["id"]),
            )
            self._activities.ingest_session(connection.user_id, session, profile)

        self._connections.upsert(
            connection.id,
            connection.model_copy(update={"last_synced_at": utcnow()}),
        )

    def _ensure_fresh_token(self, connection: IntegrationConnection) -> str:
        if connection.expires_at and connection.expires_at > utcnow() and connection.access_token:
            return connection.access_token

        response = httpx.post(
            STRAVA_TOKEN_URL,
            data={
                "client_id": self._settings.strava_client_id,
                "client_secret": self._settings.strava_client_secret,
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
                "refresh_token": data["refresh_token"],
                "expires_at": datetime.fromtimestamp(data["expires_at"], tz=timezone.utc),
            }
        )
        self._connections.upsert(refreshed.id, refreshed)
        return refreshed.access_token
