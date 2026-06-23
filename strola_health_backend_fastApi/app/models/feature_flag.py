from datetime import datetime

from pydantic import BaseModel

from app.models.user import SubscriptionTier


class FeatureFlag(BaseModel):
    """A feature key -> required subscription tier. Lets the still-undecided
    free/premium split (per the client's own todo.md) become config the
    super-admin edits, instead of a code change once they decide.
    Known keys today: "widget", "challenges", "activity_insights",
    "extra_stats_tabs" — but this is intentionally open-ended, not an enum,
    since the client hasn't finalized the list yet.
    """

    key: str
    required_tier: SubscriptionTier = SubscriptionTier.free
    description: str | None = None
    updated_at: datetime


class FeatureFlagUpdate(BaseModel):
    required_tier: SubscriptionTier
    description: str | None = None
