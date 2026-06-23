from fastapi import APIRouter, Depends, status

from app.api.deps import get_device_service, require_admin, require_super_admin
from app.models.device import Device, DeviceProvisionRequest
from app.models.user import UserProfile
from app.services.device_service import DeviceService

router = APIRouter(prefix="/devices", tags=["admin:devices"])


@router.post("", response_model=Device)
def provision_device(
    payload: DeviceProvisionRequest,
    _: UserProfile = Depends(require_super_admin),
    service: DeviceService = Depends(get_device_service),
) -> Device:
    """Fleet provisioning is super_admin-only — registering hardware units
    touches manufacturing/warranty, not the day-to-day moderation an
    ordinary admin handles."""
    return service.provision(payload)


@router.get("", response_model=list[Device])
def list_devices(
    limit: int = 500,
    _: UserProfile = Depends(require_admin),
    service: DeviceService = Depends(get_device_service),
) -> list[Device]:
    """Fleet-wide list (paired and unpaired) — read-only, so admin-level like
    `admin_unpair_device` below: any admin can see fleet status on the
    Overview/Settings pages, but only super_admin can provision new units."""
    return service.list_all(limit=limit)


@router.get("/unpaired", response_model=list[Device])
def list_unpaired(
    limit: int = 100,
    _: UserProfile = Depends(require_super_admin),
    service: DeviceService = Depends(get_device_service),
) -> list[Device]:
    return service.list_unpaired(limit=limit)


@router.post("/{device_id}/unpair", status_code=status.HTTP_204_NO_CONTENT)
def admin_unpair_device(
    device_id: str,
    reason: str = "admin_unpaired",
    _: UserProfile = Depends(require_admin),
    service: DeviceService = Depends(get_device_service),
) -> None:
    """Routine support action (a user lost their phone, a warranty swap is
    in progress) — kept admin-level, unlike fleet provisioning above, which
    touches manufacturing and stays super_admin-only."""
    service.admin_unpair(device_id, reason=reason)
