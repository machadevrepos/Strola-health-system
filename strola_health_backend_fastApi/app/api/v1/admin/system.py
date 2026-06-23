from fastapi import APIRouter, Depends

from app.api.deps import get_admin_service, require_admin, require_super_admin
from app.models.feature_flag import FeatureFlag, FeatureFlagUpdate
from app.models.user import UserProfile
from app.services.admin_service import AdminService

router = APIRouter(prefix="/system", tags=["admin:system"])


@router.get("/feature-flags", response_model=list[FeatureFlag])
def list_feature_flags(
    _: UserProfile = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
) -> list[FeatureFlag]:
    """Read-only — admin-level like the device fleet list, so any admin can
    see config on the Settings page; only super_admin can change it (PUT
    below)."""
    return service.list_feature_flags()


@router.put("/feature-flags/{key}", response_model=FeatureFlag)
def set_feature_flag(
    key: str,
    payload: FeatureFlagUpdate,
    _: UserProfile = Depends(require_super_admin),
    service: AdminService = Depends(get_admin_service),
) -> FeatureFlag:
    """Lets the still-undecided free/premium split become config once the
    client finalizes it, instead of a code change — see
    `app/models/feature_flag.py`."""
    return service.set_feature_flag(key, payload)
