from datetime import datetime

from fastapi import APIRouter, Depends, status

from app.api.deps import (
    get_activity_service,
    get_admin_service,
    get_badge_service,
    get_challenge_service,
    get_deletion_service,
    get_device_service,
    get_subscription_service,
    get_user_service,
    require_admin,
    require_super_admin,
)
from app.core.exceptions import NotFoundError
from app.models.activity import DailyActivitySummary, WorkoutSession
from app.models.badge import UserBadge
from app.models.challenge import ChallengeParticipant
from app.models.device import Device
from app.models.user import PrivacySettingsUpdate, Role, UserProfile, UserProfileUpdate
from app.services.activity_service import ActivityService
from app.services.admin_service import AdminService
from app.services.badge_service import BadgeService
from app.services.challenge_service import ChallengeService
from app.services.deletion_service import DeletionService
from app.services.device_service import DeviceService
from app.services.subscription_service import SubscriptionService
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["admin:users"])


@router.get("", response_model=list[UserProfile])
def search_users(
    banned: bool | None = None,
    limit: int = 50,
    _: UserProfile = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
) -> list[UserProfile]:
    return service.search_users(banned=banned, limit=limit)


@router.get("/{user_id}", response_model=UserProfile)
def get_user(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: UserService = Depends(get_user_service),
) -> UserProfile:
    """Full profile detail (admin sees DOB/email/everything — unlike the
    public projection regular users get via `GET /users/{id}`)."""
    profile = service.get(user_id)
    if not profile:
        raise NotFoundError("User not found")
    return profile


@router.patch("/{user_id}", response_model=UserProfile)
def update_user(
    user_id: str,
    payload: UserProfileUpdate,
    _: UserProfile = Depends(require_admin),
    service: UserService = Depends(get_user_service),
) -> UserProfile:
    """Admin override edit — same service the user's own `/users/me`
    uses, just targeting a different uid. For correcting data on a user's
    behalf (support tickets, data-quality fixes), not for routine self-edits."""
    return service.update_profile(user_id, payload)


@router.patch("/{user_id}/privacy", response_model=UserProfile)
def update_user_privacy(
    user_id: str,
    payload: PrivacySettingsUpdate,
    _: UserProfile = Depends(require_admin),
    service: UserService = Depends(get_user_service),
) -> UserProfile:
    return service.update_privacy(user_id, payload)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: DeletionService = Depends(get_deletion_service),
) -> None:
    """Admin-triggered version of the same anonymize-don't-delete-activity
    policy a user's own `DELETE /auth/me` runs — see `DeletionService`."""
    service.delete_account(user_id)


@router.get("/{user_id}/sessions", response_model=list[WorkoutSession])
def get_user_sessions(
    user_id: str,
    limit: int = 50,
    _: UserProfile = Depends(require_admin),
    service: ActivityService = Depends(get_activity_service),
) -> list[WorkoutSession]:
    return service.list_sessions(user_id, limit=limit)


@router.get("/{user_id}/daily-summaries", response_model=list[DailyActivitySummary])
def get_user_daily_summaries(
    user_id: str,
    days: int = 30,
    _: UserProfile = Depends(require_admin),
    service: ActivityService = Depends(get_activity_service),
) -> list[DailyActivitySummary]:
    """Admin-facing equivalent of the self-service `GET /activity/daily` —
    that route is scoped to the caller's own uid, so viewing another user's
    activity history (the user-detail page's chart) needs this."""
    return service.list_recent_daily(user_id, days=days)


@router.get("/{user_id}/devices", response_model=list[Device])
def get_user_devices(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: DeviceService = Depends(get_device_service),
) -> list[Device]:
    return service.list_by_owner(user_id)


@router.get("/{user_id}/badges", response_model=list[UserBadge])
def get_user_badges(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> list[UserBadge]:
    return service.list_for_user(user_id)


@router.get("/{user_id}/challenges", response_model=list[ChallengeParticipant])
def get_user_challenges(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> list[ChallengeParticipant]:
    return service.list_for_user(user_id)


@router.post("/{user_id}/ban", status_code=status.HTTP_204_NO_CONTENT)
def ban_user(
    user_id: str,
    reason: str,
    _: UserProfile = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
) -> None:
    service.ban(user_id, reason=reason)


@router.post("/{user_id}/unban", status_code=status.HTTP_204_NO_CONTENT)
def unban_user(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
) -> None:
    service.unban(user_id)


@router.post("/{user_id}/role", status_code=status.HTTP_204_NO_CONTENT)
def set_role(
    user_id: str,
    role: Role,
    _: UserProfile = Depends(require_super_admin),
    service: AdminService = Depends(get_admin_service),
) -> None:
    """Role promotion is super_admin-only — an ordinary admin must never be
    able to mint another admin or promote themselves to super_admin."""
    service.set_role(user_id, role)


@router.post("/{user_id}/grant-premium", status_code=status.HTTP_204_NO_CONTENT)
def grant_premium(
    user_id: str,
    until: datetime,
    reason: str = "admin_grant",
    _: UserProfile = Depends(require_admin),
    service: SubscriptionService = Depends(get_subscription_service),
) -> None:
    """Same primitive behind the automatic signup trial and a Kickstarter
    backer's 6-month reward — see `SubscriptionService.grant_comp_period`.
    Use this for one-off grants; bulk-granting a backer list is a trivial
    follow-up once there's an actual list to import."""
    service.grant_comp_period(user_id, until=until, reason=reason)


@router.post("/{user_id}/revoke-premium", status_code=status.HTTP_204_NO_CONTENT)
def revoke_premium(
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: SubscriptionService = Depends(get_subscription_service),
) -> None:
    """Revokes a comp grant only — never a real RevenueCat purchase, which
    is cancelled through the App Store/Play Store. See
    `SubscriptionService.revoke_comp`."""
    service.revoke_comp(user_id)
