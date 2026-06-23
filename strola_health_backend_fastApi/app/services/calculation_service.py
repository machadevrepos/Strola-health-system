"""Distance and calorie estimation — formulas specified directly by the
client, not guessed. Both are explicitly estimates, not medical-grade
measurements; surface `CALORIE_DISCLAIMER` wherever calorie figures are shown.
"""

from app.models.activity import ActivityType
from app.models.user import Gender

CALORIE_DISCLAIMER = (
    "Calories burned are an estimate based on activity type, steps, and "
    "weight — not a precise medical measurement."
)

# Matches the Flutter `WorkoutSession.calories` fallback (`steps * 0.04`) so
# client and backend agree when neither has a better number to use.
CALORIES_PER_STEP = 0.04


def estimate_stride_length_m(height_cm: float, gender: Gender) -> float:
    """Distance = Steps x Stride Length, stride length from height + gender:
    women ~= height x 0.413, men ~= height x 0.415 (cm -> m via /100)."""
    return (height_cm / 100) * gender.stride_multiplier


def estimate_distance_meters(
    *,
    steps: int,
    activity_type: ActivityType,
    height_cm: float,
    gender: Gender,
    gps_distance_meters: float | None,
) -> float:
    """GPS distance wins for outdoor walk/run when available; everything
    else (treadmill, strength, yoga, etc.) uses the stride-length formula."""
    if activity_type.uses_gps and gps_distance_meters is not None:
        return gps_distance_meters
    return steps * estimate_stride_length_m(height_cm, gender)


def estimate_calories(
    *,
    steps: int,
    duration_seconds: int,
    weight_kg: float | None,
    activity_type: ActivityType,
) -> int:
    """MET-based estimate for everything except 'Other' (and any custom-named
    workout under it) — the client wants that case to skip the activity
    factor entirely and use the flat step-based estimate instead, same as
    when weight isn't known yet (can't compute MET x weight x time)."""
    if not activity_type.uses_met_calories or not weight_kg:
        return round(steps * CALORIES_PER_STEP)
    hours = duration_seconds / 3600
    return round(activity_type.met * weight_kg * hours)
