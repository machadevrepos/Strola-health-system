from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, Field


class AnalyticsEventType(StrEnum):
    account_created = "account_created"
    app_opened = "app_opened"  # DAU is derived from this — distinct events per user per day
    tracker_paired = "tracker_paired"
    workout_started = "workout_started"
    workout_completed = "workout_completed"
    steps_shared = "steps_shared"
    community_post_created = "community_post_created"
    challenge_joined = "challenge_joined"
    challenge_completed = "challenge_completed"
    premium_started = "premium_started"
    premium_cancelled = "premium_cancelled"
    widget_enabled = "widget_enabled"
    health_app_connected = "health_app_connected"


class AnalyticsEvent(BaseModel):
    id: str
    event_type: AnalyticsEventType
    user_id: str | None = None
    metadata: dict = Field(default_factory=dict)
    created_at: datetime


class AnalyticsEventCreate(BaseModel):
    event_type: AnalyticsEventType
    metadata: dict = Field(default_factory=dict)
