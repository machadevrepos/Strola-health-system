from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_user_service
from app.core.exceptions import NotFoundError
from app.models.user import PrivacySettingsUpdate, PublicUserProfile, UserProfile, UserProfileUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.patch("/me", response_model=UserProfile)
def update_me(
    payload: UserProfileUpdate,
    current: UserProfile = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
) -> UserProfile:
    return service.update_profile(current.id, payload)


@router.patch("/me/privacy", response_model=UserProfile)
def update_my_privacy(
    payload: PrivacySettingsUpdate,
    current: UserProfile = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
) -> UserProfile:
    return service.update_privacy(current.id, payload)


@router.get("/{user_id}", response_model=PublicUserProfile)
def get_public_profile(
    user_id: str,
    _: UserProfile = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
) -> PublicUserProfile:
    profile = service.get_public(user_id)
    if not profile:
        raise NotFoundError("User not found")
    return profile
