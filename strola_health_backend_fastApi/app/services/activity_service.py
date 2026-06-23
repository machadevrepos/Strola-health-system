from datetime import date

from app.core.time import utcnow
from app.models.activity import (
    DailyActivitySummary,
    SourceMetrics,
    WorkoutSession,
    WorkoutSessionCreate,
)
from app.models.analytics import AnalyticsEventType
from app.models.enums import SOURCE_PRIORITY, DataSource
from app.models.integration import HealthSampleIngest
from app.models.user import UserProfile
from app.repositories.activity_repository import (
    DailyActivitySummaryRepository,
    WorkoutSessionRepository,
)
from app.services import calculation_service
from app.services.analytics_service import AnalyticsService


def _aggregation_source(source: DataSource) -> DataSource:
    """Sessions recorded in-app are always step-counted via the paired
    Strolla device when one is connected, so for the *daily priority merge*
    they're attributed to `strolla_device` — `strolla_app` only exists to
    describe who recorded the discrete session, not which sensor counted the
    steps. Sessions synced in from an external platform keep their own
    source so `SOURCE_PRIORITY` still applies correctly."""
    return DataSource.strolla_device if source == DataSource.strolla_app else source


class ActivityService:
    def __init__(
        self,
        session_repo: WorkoutSessionRepository,
        daily_repo: DailyActivitySummaryRepository,
        analytics: AnalyticsService,
        challenge_service=None,
    ):
        self._sessions = session_repo
        self._daily = daily_repo
        self._analytics = analytics
        # Optional to avoid forcing a hard dependency for tests/callers that
        # don't care about challenges — when present, every write that
        # changes a day's total also re-syncs that day's active challenges.
        self._challenge_service = challenge_service

    def track_workout_started(self, user_id: str) -> None:
        self._analytics.track(AnalyticsEventType.workout_started, user_id=user_id)

    def ingest_session(self, user_id: str, payload: WorkoutSessionCreate, profile: UserProfile) -> WorkoutSession:
        distance = payload.distance_meters
        if distance is None:
            distance = calculation_service.estimate_distance_meters(
                steps=payload.steps,
                activity_type=payload.activity_type,
                height_cm=profile.height_cm,
                gender=profile.gender,
                gps_distance_meters=None,
            )

        calories = payload.calories_burned
        if calories is None:
            calories = calculation_service.estimate_calories(
                steps=payload.steps,
                duration_seconds=payload.duration_seconds,
                weight_kg=profile.weight_kg,
                activity_type=payload.activity_type,
            )

        session = WorkoutSession(
            id=payload.id,
            user_id=user_id,
            start_time=payload.start_time,
            end_time=payload.end_time,
            steps=payload.steps,
            distance_meters=distance,
            duration_seconds=payload.duration_seconds,
            activity_type=payload.activity_type,
            custom_activity_name=payload.custom_activity_name,
            route_points=payload.route_points,
            avg_pace_sec_per_km=payload.avg_pace_sec_per_km,
            calories_burned=calories,
            source=payload.source,
            external_id=payload.external_id,
            created_at=utcnow(),
        )
        self._sessions.upsert(session.id, session)

        self._apply_to_daily_summary(
            user_id=user_id,
            day=session.start_time.date(),
            source=_aggregation_source(session.source),
            steps=session.steps,
            distance_meters=session.distance_meters,
            calories=calories,
        )
        self._analytics.track(
            AnalyticsEventType.workout_completed,
            user_id=user_id,
            metadata={"activity_type": session.activity_type.value, "steps": session.steps},
        )
        return session

    def ingest_health_sample(self, user_id: str, payload: HealthSampleIngest) -> DailyActivitySummary:
        """Apple HealthKit / Android Health Connect report a running daily
        total, not a delta — so this replaces the bucket rather than adding to
        it (unlike workout sessions, where multiple sessions in a day add up).
        """
        return self._apply_to_daily_summary(
            user_id=user_id,
            day=payload.date,
            source=payload.source,
            steps=payload.steps or 0,
            distance_meters=payload.distance_meters or 0.0,
            calories=payload.calories or 0,
            additive=False,
        )

    def _apply_to_daily_summary(
        self,
        *,
        user_id: str,
        day: date,
        source: DataSource,
        steps: int,
        distance_meters: float,
        calories: int,
        additive: bool = True,
    ) -> DailyActivitySummary:
        """Merges one source's reading into the day's summary and recomputes
        the canonical total by walking `SOURCE_PRIORITY` — the Strolla
        device's own number always wins over a synced wearable for the same
        day, per the client's explicit step-priority requirement (e.g. a user
        wearing both a Strolla tracker and an Apple Watch sees Strolla's
        count, not the watch's).
        """
        doc_id = self._daily.doc_id(user_id, day)
        summary = self._daily.get(doc_id) or DailyActivitySummary(
            id=doc_id, user_id=user_id, date=day, updated_at=utcnow()
        )

        existing = summary.by_source.get(source.value, SourceMetrics())
        if additive:
            bucket = SourceMetrics(
                steps=existing.steps + steps,
                distance_meters=existing.distance_meters + distance_meters,
                calories=existing.calories + calories,
            )
        else:
            bucket = SourceMetrics(steps=steps, distance_meters=distance_meters, calories=calories)
        summary.by_source[source.value] = bucket

        for candidate in SOURCE_PRIORITY:
            candidate_bucket = summary.by_source.get(candidate.value)
            if candidate_bucket and candidate_bucket.steps > 0:
                summary.steps = candidate_bucket.steps
                summary.distance_meters = candidate_bucket.distance_meters
                summary.calories = candidate_bucket.calories
                summary.primary_source = candidate
                break
        else:
            summary.steps = 0
            summary.distance_meters = 0.0
            summary.calories = 0
            summary.primary_source = None

        summary.updated_at = utcnow()
        self._daily.upsert(doc_id, summary)
        if self._challenge_service is not None:
            self._challenge_service.sync_user_progress(user_id, day)
        return summary

    def get_daily_summary(self, user_id: str, day: date) -> DailyActivitySummary | None:
        return self._daily.get_for_day(user_id, day)

    def list_recent_daily(self, user_id: str, *, days: int = 30) -> list[DailyActivitySummary]:
        return self._daily.list_recent(user_id, days=days)

    def list_sessions(self, user_id: str, *, limit: int = 50) -> list[WorkoutSession]:
        return self._sessions.list_for_user(user_id, limit=limit)
