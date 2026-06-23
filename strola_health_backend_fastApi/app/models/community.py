from datetime import datetime

from pydantic import BaseModel, Field


class ModerationInfo(BaseModel):
    hidden: bool = False
    hidden_by: str | None = None
    hidden_reason: str | None = None
    hidden_at: datetime | None = None


class CommunityPost(BaseModel):
    id: str
    author_id: str
    content: str
    timestamp: datetime
    likes_count: int = 0
    comments_count: int = 0
    step_count: int | None = None
    badge_emoji: str | None = None
    image_url: str | None = None
    moderation: ModerationInfo = Field(default_factory=ModerationInfo)


class CommunityPostCreate(BaseModel):
    content: str
    step_count: int | None = None
    image_url: str | None = None
    badge_emoji: str | None = None


class CommunityPostUpdate(BaseModel):
    """Admin correction of a post's content — distinct from moderation
    (hide/delete/remove-photo), which changes visibility rather than content."""

    content: str | None = None
    step_count: int | None = None
    badge_emoji: str | None = None


class PostLike(BaseModel):
    id: str  # f"{post_id}_{user_id}" — doubles as the idempotency/like-toggle key
    post_id: str
    user_id: str
    created_at: datetime
