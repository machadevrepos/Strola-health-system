from datetime import datetime

from pydantic import BaseModel


class Badge(BaseModel):
    id: str
    name: str
    description: str
    emoji: str
    created_at: datetime


class BadgeCreate(BaseModel):
    name: str
    description: str
    emoji: str


class BadgeUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    emoji: str | None = None


class UserBadge(BaseModel):
    id: str  # f"{user_id}_{badge_id}"
    user_id: str
    badge_id: str
    awarded_at: datetime
    awarded_by: str | None = None  # admin uid, null if system-awarded
