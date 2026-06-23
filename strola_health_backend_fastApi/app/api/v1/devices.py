from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user, get_device_service
from app.models.device import Device, DevicePairRequest
from app.models.user import UserProfile
from app.services.device_service import DeviceService

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("/pair", response_model=Device)
def pair_device(
    payload: DevicePairRequest,
    current: UserProfile = Depends(get_current_user),
    service: DeviceService = Depends(get_device_service),
) -> Device:
    return service.pair(current.id, payload)


@router.post("/{device_id}/unpair", status_code=status.HTTP_204_NO_CONTENT)
def unpair_device(
    device_id: str,
    current: UserProfile = Depends(get_current_user),
    service: DeviceService = Depends(get_device_service),
) -> None:
    service.unpair(current.id, device_id)


@router.get("/mine", response_model=list[Device])
def list_my_devices(
    current: UserProfile = Depends(get_current_user),
    service: DeviceService = Depends(get_device_service),
) -> list[Device]:
    return service.list_by_owner(current.id)


@router.post("/{device_id}/heartbeat", status_code=status.HTTP_204_NO_CONTENT)
def device_heartbeat(
    device_id: str,
    battery_level: int | None = None,
    current: UserProfile = Depends(get_current_user),
    service: DeviceService = Depends(get_device_service),
) -> None:
    service.heartbeat(current.id, device_id, battery_level=battery_level)
