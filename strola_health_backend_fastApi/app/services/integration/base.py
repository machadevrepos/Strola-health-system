from abc import ABC, abstractmethod
from typing import ClassVar

from app.models.enums import DataSource
from app.models.integration import IntegrationConnection


class OAuthHealthProvider(ABC):
    """Shared contract for the three cloud-OAuth platforms (Oura, Garmin,
    Strava): the backend itself holds tokens and pulls/receives data
    server-side. Apple Health and Health Connect have no adapter class at
    all — they only ever arrive via the on-device ingestion endpoint (see
    `apple_health.py` / `health_connect.py` for why).
    """

    provider: ClassVar[DataSource]

    @abstractmethod
    def get_authorization_url(self, user_id: str) -> str:
        """Builds the provider's OAuth consent URL. Real, working logic — it
        only needs a client_id/redirect_uri, both plain config rather than a
        secret exchanged at request time."""

    @abstractmethod
    def handle_callback(self, user_id: str, code: str) -> IntegrationConnection:
        """Exchanges the authorization code for tokens and persists an
        `IntegrationConnection`. Requires the provider's client secret —
        stubbed (raises `NotImplementedError`) until real API credentials
        exist; the OAuth redirect plumbing around it is otherwise complete."""

    @abstractmethod
    def sync(self, connection: IntegrationConnection) -> None:
        """Pulls recent activity and feeds it through
        `ActivityService.ingest_session` / `ingest_health_sample`. Not
        invoked automatically anywhere yet — no scheduler is wired up; this
        is the method a future Cloud Scheduler job or an admin-triggered
        "sync now" action would call."""

    def handle_webhook(self, payload: dict) -> None:
        """Oura, Garmin, and Strava all separately support push-style
        webhooks in addition to polling. Not every provider needs this on
        day one, so it's a concrete default rather than abstract — override
        where it matters."""
        raise NotImplementedError(f"{self.provider.value} webhook handling pending API credentials")
