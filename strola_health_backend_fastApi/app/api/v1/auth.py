from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user, get_deletion_service
from app.models.user import UserProfile
from app.services.deletion_service import DeletionService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=UserProfile)
def get_me(current: UserProfile = Depends(get_current_user)) -> UserProfile:
    """Also the JIT-provisioning trigger: the first authenticated call any
    new Firebase Auth user makes (right after sign-up) creates their
    Firestore profile via `get_current_user` -> `AuthService.get_or_provision`."""
    return current


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_me(
    current: UserProfile = Depends(get_current_user),
    deletion_service: DeletionService = Depends(get_deletion_service),
) -> None:
    deletion_service.delete_account(current.id)
