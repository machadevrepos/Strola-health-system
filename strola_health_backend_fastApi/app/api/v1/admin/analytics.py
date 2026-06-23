from fastapi import APIRouter, Depends

from app.api.deps import get_analytics_service, require_admin
from app.models.analytics import AnalyticsEvent
from app.models.user import UserProfile
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["admin:analytics"])


@router.get("/dau")
def daily_active_users(
    since_hours: int = 24,
    _: UserProfile = Depends(require_admin),
    service: AnalyticsService = Depends(get_analytics_service),
) -> dict:
    return {"daily_active_users": service.daily_active_users(since_hours=since_hours)}


@router.get("/event-counts")
def event_counts(
    since_days: int = 30,
    _: UserProfile = Depends(require_admin),
    service: AnalyticsService = Depends(get_analytics_service),
) -> dict:
    return service.event_counts(since_days=since_days)


@router.get("/events", response_model=list[AnalyticsEvent])
def list_events(
    since_days: int = 30,
    _: UserProfile = Depends(require_admin),
    service: AnalyticsService = Depends(get_analytics_service),
) -> list[AnalyticsEvent]:
    """Raw events for the dashboard's DAU-trend and funnel charts, which need
    a per-day breakdown that `/dau` and `/event-counts` (both single-window
    aggregates) don't provide."""
    return service.list_events(since_days=since_days)
