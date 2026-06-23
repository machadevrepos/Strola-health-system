from fastapi import APIRouter, Depends, status

from app.api.deps import get_badge_service, require_admin
from app.models.badge import Badge, BadgeCreate, BadgeUpdate, UserBadge
from app.models.user import UserProfile
from app.services.badge_service import BadgeService

router = APIRouter(prefix="/badges", tags=["admin:badges"])


@router.get("", response_model=list[Badge])
def list_badges(
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> list[Badge]:
    return service.list_all()


@router.get("/awards", response_model=list[UserBadge])
def list_all_awards(
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> list[UserBadge]:
    """Every award across every user — the UI filters this client-side for
    both "who has badge X" and "this user's badges"."""
    return service.list_all_awards()


@router.post("", response_model=Badge)
def create_badge(
    payload: BadgeCreate,
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> Badge:
    return service.create(payload)


@router.patch("/{badge_id}", response_model=Badge)
def update_badge(
    badge_id: str,
    payload: BadgeUpdate,
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> Badge:
    return service.update(badge_id, payload)


@router.delete("/{badge_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_badge(
    badge_id: str,
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> None:
    service.delete(badge_id)


@router.post("/{badge_id}/award/{user_id}", response_model=UserBadge)
def award_badge(
    badge_id: str,
    user_id: str,
    current: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> UserBadge:
    return service.award(user_id, badge_id, awarded_by=current.id)


@router.delete("/{badge_id}/award/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def revoke_badge(
    badge_id: str,
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: BadgeService = Depends(get_badge_service),
) -> None:
    service.revoke(user_id, badge_id)
