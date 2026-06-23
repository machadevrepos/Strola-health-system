from datetime import datetime

from google.cloud import firestore

from app.models.analytics import AnalyticsEvent
from app.repositories.base import FirestoreRepository


class AnalyticsEventRepository(FirestoreRepository[AnalyticsEvent]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "analytics_events", AnalyticsEvent)

    def list_since(self, since: datetime, *, event_type: str | None = None, limit: int = 5000) -> list[AnalyticsEvent]:
        """Used for basic admin-dashboard counts. Pulls raw events and counts
        client-side rather than using Firestore aggregation queries — fine at
        the event volume an early-stage app generates; worth revisiting with
        `count()` aggregation queries if this gets expensive later."""
        filters: list[tuple[str, str, object]] = [("created_at", ">=", since)]
        if event_type:
            filters.append(("event_type", "==", event_type))
        return self.query(filters, limit=limit)
