from datetime import date

from fastapi import APIRouter, Depends, status

from app.api.deps import get_activity_service, get_current_user
from app.models.activity import DailyActivitySummary, WorkoutSession, WorkoutSessionCreate
from app.models.user import UserProfile
from app.services.activity_service import ActivityService
from app.services.calculation_service import CALORIE_DISCLAIMER

router = APIRouter(prefix="/activity", tags=["activity"])


@router.post("/sessions/start", status_code=status.HTTP_204_NO_CONTENT)
def track_session_started(
    current: UserProfile = Depends(get_current_user),
    service: ActivityService = Depends(get_activity_service),
) -> None:
    """Lightweight analytics ping fired when the user taps "Start" in the
    app, so workout_started vs workout_completed funnel drop-off is visible
    on the admin analytics dashboard."""
    service.track_workout_started(current.id)


@router.post("/sessions", response_model=WorkoutSession)
def upload_session(
    payload: WorkoutSessionCreate,
    current: UserProfile = Depends(get_current_user),
    service: ActivityService = Depends(get_activity_service),
) -> WorkoutSession:
    """The session's client-generated `id` is the Firestore doc id, so
    re-uploading the same session (e.g. after a flaky connection) is
    idempotent rather than creating a duplicate."""
    return service.ingest_session(current.id, payload, current)


@router.get("/sessions", response_model=list[WorkoutSession])
def list_sessions(
    limit: int = 50,
    current: UserProfile = Depends(get_current_user),
    service: ActivityService = Depends(get_activity_service),
) -> list[WorkoutSession]:
    return service.list_sessions(current.id, limit=limit)


@router.get("/daily/{day}", response_model=DailyActivitySummary | None)
def get_daily_summary(
    day: date,
    current: UserProfile = Depends(get_current_user),
    service: ActivityService = Depends(get_activity_service),
) -> DailyActivitySummary | None:
    return service.get_daily_summary(current.id, day)


@router.get("/daily", response_model=list[DailyActivitySummary])
def list_recent_daily(
    days: int = 30,
    current: UserProfile = Depends(get_current_user),
    service: ActivityService = Depends(get_activity_service),
) -> list[DailyActivitySummary]:
    return service.list_recent_daily(current.id, days=days)


@router.get("/calorie-disclaimer")
def calorie_disclaimer() -> dict:
    """Client's explicit ask: surface somewhere that calorie figures are
    estimates, not a medical measurement."""
    return {"disclaimer": CALORIE_DISCLAIMER}
