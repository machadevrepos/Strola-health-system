from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel


class ChallengeVisibility(StrEnum):
    public = "public"
    private = "private"


class Challenge(BaseModel):
    id: str
    title: str
    description: str
    goal_steps: int
    start_date: date
    end_date: date
    badge_emoji: str = "🏆"
    accent_color_value: int | None = None
    visibility: ChallengeVisibility = ChallengeVisibility.public
    is_official: bool = False  # the admin-managed recurring public monthly challenge
    invite_code: str | None = None  # private challenges only
    created_by: str | None = None  # null for official/system challenges
    created_at: datetime


class ChallengeCreate(BaseModel):
    title: str
    description: str
    goal_steps: int
    start_date: date
    end_date: date
    badge_emoji: str = "🏆"
    accent_color_value: int | None = None
    visibility: ChallengeVisibility = ChallengeVisibility.public


class ChallengeUpdate(BaseModel):
    """Admin edit of an existing challenge. All fields optional — only
    supplied fields change. `visibility`/`is_official` are deliberately
    excluded: visibility doesn't change after creation in practice, and
    `is_official` has its own dedicated super_admin-only endpoint since it's
    a "only one at a time" invariant, not a plain field edit."""

    title: str | None = None
    description: str | None = None
    goal_steps: int | None = None
    start_date: date | None = None
    end_date: date | None = None
    badge_emoji: str | None = None
    accent_color_value: int | None = None


class ChallengeParticipant(BaseModel):
    id: str  # f"{challenge_id}_{user_id}"
    challenge_id: str
    user_id: str
    steps: int = 0
    # Snapshot of the user's personal daily step goal at join time, so a later
    # change to their goal doesn't retroactively change a challenge already in
    # progress. `challenge.goal_steps` remains the shared cumulative target
    # used for the leaderboard %; this is the per-user reference value for any
    # "did you hit your own goal today" style completion logic.
    locked_daily_goal: int
    joined_at: datetime
    left_at: datetime | None = None

    @property
    def is_active(self) -> bool:
        return self.left_at is None
