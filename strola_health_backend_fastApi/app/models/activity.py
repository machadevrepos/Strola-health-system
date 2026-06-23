from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel, Field

from app.models.enums import DataSource


class ActivityType(StrEnum):
    outdoor_walk = "outdoor_walk"
    outdoor_run = "outdoor_run"
    treadmill = "treadmill"
    strength_training = "strength_training"
    yoga = "yoga"
    pilates = "pilates"
    cardio = "cardio"
    other = "other"

    @property
    def uses_gps(self) -> bool:
        """Only outdoor activities use GPS distance — everything else falls
        back to stride-length estimation."""
        return self in (ActivityType.outdoor_walk, ActivityType.outdoor_run)

    @property
    def counts_steps(self) -> bool:
        return self not in (ActivityType.yoga, ActivityType.pilates)

    @property
    def shows_distance(self) -> bool:
        return self.uses_gps or self is ActivityType.treadmill

    @property
    def met(self) -> float:
        """Metabolic Equivalent of Task, used for calorie calculation —
        ignored entirely for `other` (see `uses_met_calories`)."""
        return {
            ActivityType.outdoor_walk: 3.5,
            ActivityType.outdoor_run: 8.0,
            ActivityType.treadmill: 4.0,
            ActivityType.strength_training: 3.5,
            ActivityType.yoga: 2.5,
            ActivityType.pilates: 3.0,
            ActivityType.cardio: 5.0,
            ActivityType.other: 3.0,
        }[self]

    @property
    def uses_met_calories(self) -> bool:
        """Client's explicit instruction: when a user picks "Other" (and
        optionally names their own workout), skip the MET/activity-factor
        formula entirely and use the flat step-based calorie estimate."""
        return self is not ActivityType.other


class RoutePoint(BaseModel):
    lat: float
    lng: float
    speed_mps: float = 0.0


class WorkoutSession(BaseModel):
    id: str  # client-generated — also the Firestore doc id, making re-uploads idempotent
    user_id: str
    start_time: datetime
    end_time: datetime
    steps: int
    distance_meters: float
    duration_seconds: int
    activity_type: ActivityType
    custom_activity_name: str | None = None  # only meaningful when activity_type == other
    route_points: list[RoutePoint] = Field(default_factory=list)
    avg_pace_sec_per_km: float | None = None
    calories_burned: int | None = None
    source: DataSource = DataSource.strolla_app
    external_id: str | None = None  # synced sources' own id, for dedup on re-sync
    created_at: datetime


class WorkoutSessionCreate(BaseModel):
    """Ingestion payload — the backend fills in distance/calories via
    `calculation_service` when the client doesn't already have them (e.g. a
    synced Garmin/Strava activity arrives with both already computed)."""

    id: str
    start_time: datetime
    end_time: datetime
    steps: int
    distance_meters: float | None = None
    duration_seconds: int
    activity_type: ActivityType
    custom_activity_name: str | None = None
    route_points: list[RoutePoint] = Field(default_factory=list)
    avg_pace_sec_per_km: float | None = None
    calories_burned: int | None = None
    source: DataSource = DataSource.strolla_app
    external_id: str | None = None


class SourceMetrics(BaseModel):
    steps: int = 0
    distance_meters: float = 0.0
    calories: int = 0


class DailyActivitySummary(BaseModel):
    id: str  # f"{user_id}_{date}"
    user_id: str
    date: date
    by_source: dict[str, SourceMetrics] = Field(default_factory=dict)  # keyed by DataSource value
    steps: int = 0
    distance_meters: float = 0.0
    calories: int = 0
    primary_source: DataSource | None = None  # which source's numbers won the merge
    updated_at: datetime
