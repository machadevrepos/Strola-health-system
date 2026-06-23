from google.cloud import firestore

from app.models.enums import DataSource
from app.models.integration import IntegrationConnection
from app.repositories.base import FirestoreRepository


class IntegrationConnectionRepository(FirestoreRepository[IntegrationConnection]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "integration_connections", IntegrationConnection)

    @staticmethod
    def doc_id(user_id: str, provider: DataSource) -> str:
        return f"{user_id}_{provider.value}"

    def get_connection(self, user_id: str, provider: DataSource) -> IntegrationConnection | None:
        return self.get(self.doc_id(user_id, provider))

    def list_for_user(self, user_id: str) -> list[IntegrationConnection]:
        return self.query([("user_id", "==", user_id)])

    def get_by_external_athlete_id(self, provider: DataSource, external_athlete_id: str) -> IntegrationConnection | None:
        """Used by webhook receivers (Garmin push, Strava webhook) to match an
        incoming payload back to a Strolla user — they identify the athlete
        by the provider's own id, not ours."""
        results = self.query(
            [("provider", "==", provider), ("external_athlete_id", "==", external_athlete_id)],
            limit=1,
        )
        return results[0] if results else None
