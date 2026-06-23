from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel, EmailStr, Field


class Role(StrEnum):
    user = "user"
    admin = "admin"
    super_admin = "super_admin"


class Gender(StrEnum):
    male = "male"
    female = "female"
    other = "other"
    prefer_not_to_say = "prefer_not_to_say"

    @property
    def stride_multiplier(self) -> float:
        """Height x this = estimated stride length in metres, per the
        client's specified formula. `other`/`prefer_not_to_say` use the
        midpoint, matching the app's existing gender-neutral fallback
        convention for stride/BMR estimation."""
        return {
            Gender.female: 0.413,
            Gender.male: 0.415,
            Gender.other: 0.414,
            Gender.prefer_not_to_say: 0.414,
        }[self]


class UnitSystem(StrEnum):
    metric = "metric"
    imperial = "imperial"


class StrollaReason(StrEnum):
    stroller_wagon = "stroller_wagon"
    walking_pad = "walking_pad"
    cant_wear_wearable = "cant_wear_wearable"
    accurate_tracking = "accurate_tracking"
    other = "other"


class PrivacySettings(BaseModel):
    public_profile: bool = True
    share_activity: bool = True
    show_in_leaderboards: bool = True
    allow_friend_requests: bool = True
    hide_activity_data: bool = False
    hide_achievements: bool = False
    hide_recent_activity: bool = False


class SubscriptionTier(StrEnum):
    free = "free"
    premium = "premium"


class SubscriptionStatus(StrEnum):
    trialing = "trialing"
    active = "active"
    cancelled = "cancelled"
    expired = "expired"


class Subscription(BaseModel):
    """Tracks RevenueCat-driven purchases AND Strolla-granted comp periods
    through one shared primitive (`comp_until`/`comp_reason`) rather than two
    parallel systems — the automatic 1-month signup trial, an admin's manual
    premium grant, and a Kickstarter backer's 6-month reward are all just a
    `comp_until` date with a different `comp_reason`.
    """

    tier: SubscriptionTier = SubscriptionTier.free
    status: SubscriptionStatus = SubscriptionStatus.trialing
    # The automatic 1-month signup trial, a Kickstarter backer's 6-month
    # reward, and an admin's manual "grant premium" action are all just this
    # one field with a different `comp_reason` — one mechanism, not three.
    comp_until: datetime | None = None
    comp_reason: str | None = None  # "signup_trial" | "kickstarter_backer" | "admin_grant" | ...
    revenuecat_app_user_id: str | None = None
    renews_at: datetime | None = None
    cancelled_at: datetime | None = None

    def has_premium_access(self, *, at: datetime) -> bool:
        if self.tier == SubscriptionTier.premium and self.status == SubscriptionStatus.active:
            return True
        if self.comp_until and at < self.comp_until:
            return True
        return False


class UserProfile(BaseModel):
    id: str  # Firebase Auth uid — also the Firestore doc id
    email: EmailStr | None = None
    username: str = ""
    name: str = ""
    location: str | None = None
    bio: str | None = None
    photo_url: str | None = None
    height_cm: float = 170
    gender: Gender = Gender.prefer_not_to_say
    date_of_birth: date | None = None
    reasons: list[StrollaReason] = Field(default_factory=list)
    units: UnitSystem = UnitSystem.metric
    onboarding_complete: bool = False
    daily_goal_steps: int = 10_000
    weight_kg: float | None = None
    role: Role = Role.user
    privacy: PrivacySettings = Field(default_factory=PrivacySettings)
    subscription: Subscription = Field(default_factory=Subscription)
    banned: bool = False
    ban_reason: str | None = None
    deleted: bool = False
    deleted_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class UserProfileUpdate(BaseModel):
    """Fields the user themselves may edit via PATCH /users/me. Role,
    subscription, ban status, and deletion are server/admin-managed only —
    deliberately absent here so they can never be set via this schema."""

    username: str | None = None
    name: str | None = None
    location: str | None = None
    bio: str | None = None
    photo_url: str | None = None
    height_cm: float | None = None
    gender: Gender | None = None
    date_of_birth: date | None = None
    reasons: list[StrollaReason] | None = None
    units: UnitSystem | None = None
    onboarding_complete: bool | None = None
    daily_goal_steps: int | None = None
    weight_kg: float | None = None


class PrivacySettingsUpdate(BaseModel):
    public_profile: bool | None = None
    share_activity: bool | None = None
    show_in_leaderboards: bool | None = None
    allow_friend_requests: bool | None = None
    hide_activity_data: bool | None = None
    hide_achievements: bool | None = None
    hide_recent_activity: bool | None = None


class PublicUserProfile(BaseModel):
    """Safe projection for community/leaderboard contexts. No DOB, no email,
    no internal fields — and resolves deleted accounts to a 'Deleted User'
    placeholder instead of requiring every caller to check `deleted` itself.
    """

    id: str
    username: str
    name: str
    photo_url: str | None = None

    @classmethod
    def from_profile(cls, profile: UserProfile) -> "PublicUserProfile":
        if profile.deleted:
            return cls(id=profile.id, username="deleted_user", name="Deleted User", photo_url=None)
        return cls(id=profile.id, username=profile.username, name=profile.name, photo_url=profile.photo_url)
