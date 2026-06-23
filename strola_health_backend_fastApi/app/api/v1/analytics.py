from fastapi import APIRouter, Depends, status

from app.api.deps import get_analytics_service, get_current_user
from app.models.analytics import AnalyticsEventType
from app.models.user import UserProfile
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["analytics"])

# Lightweight client-fired pings for the handful of tracked events that have
# no other natural service hook to live on (account_created, tracker_paired,
# workout_started/completed, community_post_created, challenge_joined/
# completed, premium_started/cancelled, and health_app_connected are all
# already tracked inside the relevant service call).


@router.post("/app-opened", status_code=status.HTTP_204_NO_CONTENT)
def track_app_opened(
    current: UserProfile = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> None:
    """Fired once per app launch — backs the admin dashboard's DAU figure."""
    service.track(AnalyticsEventType.app_opened, user_id=current.id)


@router.post("/steps-shared", status_code=status.HTTP_204_NO_CONTENT)
def track_steps_shared(
    current: UserProfile = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> None:
    service.track(AnalyticsEventType.steps_shared, user_id=current.id)


@router.post("/widget-enabled", status_code=status.HTTP_204_NO_CONTENT)
def track_widget_enabled(
    current: UserProfile = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> None:
    service.track(AnalyticsEventType.widget_enabled, user_id=current.id)
