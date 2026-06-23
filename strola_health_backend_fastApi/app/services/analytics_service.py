import uuid
from datetime import timedelta

from app.core.time import utcnow
from app.models.analytics import AnalyticsEvent, AnalyticsEventType
from app.repositories.analytics_repository import AnalyticsEventRepository


class AnalyticsService:
    def __init__(self, repo: AnalyticsEventRepository):
        self._repo = repo

    def track(
        self,
        event_type: AnalyticsEventType,
        user_id: str | None = None,
        metadata: dict | None = None,
    ) -> AnalyticsEvent:
        event = AnalyticsEvent(
            id=str(uuid.uuid4()),
            event_type=event_type,
            user_id=user_id,
            metadata=metadata or {},
            created_at=utcnow(),
        )
        return self._repo.upsert(event.id, event)

    def daily_active_users(self, *, since_hours: int = 24) -> int:
        events = self._repo.list_since(
            utcnow() - timedelta(hours=since_hours),
            event_type=AnalyticsEventType.app_opened.value,
        )
        return len({e.user_id for e in events if e.user_id})

    def event_counts(self, *, since_days: int = 30) -> dict[str, int]:
        events = self._repo.list_since(utcnow() - timedelta(days=since_days))
        counts: dict[str, int] = {}
        for event in events:
            counts[event.event_type.value] = counts.get(event.event_type.value, 0) + 1
        return counts

    def list_events(self, *, since_days: int = 30) -> list[AnalyticsEvent]:
        """Raw events for the admin dashboard's day-by-day charts (DAU trend,
        funnel) — those need a per-day breakdown `event_counts` doesn't give,
        and the event volume at this stage is small enough that returning
        the raw list and aggregating client-side is simpler than adding a
        bespoke time-series endpoint per chart."""
        return self._repo.list_since(utcnow() - timedelta(days=since_days))
