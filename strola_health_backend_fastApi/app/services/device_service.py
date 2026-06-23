import uuid

from app.core.exceptions import ConflictError, NotFoundError
from app.core.time import utcnow
from app.models.analytics import AnalyticsEventType
from app.models.device import Device, DevicePairingEvent, DevicePairRequest, DeviceProvisionRequest
from app.repositories.device_repository import DeviceRepository, DevicePairingEventRepository
from app.services.analytics_service import AnalyticsService


class DeviceService:
    def __init__(
        self,
        device_repo: DeviceRepository,
        event_repo: DevicePairingEventRepository,
        analytics: AnalyticsService,
    ):
        self._devices = device_repo
        self._events = event_repo
        self._analytics = analytics

    def provision(self, payload: DeviceProvisionRequest) -> Device:
        """Super-admin only: register a new unit from the factory before it's
        ever paired — this is the fleet-management entry point."""
        if self._devices.get_by_serial(payload.serial_number):
            raise ConflictError(f"Device with serial {payload.serial_number} already exists")
        device = Device(
            id=str(uuid.uuid4()),
            serial_number=payload.serial_number,
            device_type=payload.device_type,
            manufacturing_batch=payload.manufacturing_batch,
            created_at=utcnow(),
        )
        return self._devices.upsert(device.id, device)

    def pair(self, user_id: str, payload: DevicePairRequest) -> Device:
        device = self._devices.get_by_serial(payload.serial_number)
        if not device:
            raise NotFoundError(f"No device with serial {payload.serial_number}")
        if device.owner_user_id and device.owner_user_id != user_id:
            raise ConflictError("Device is already paired to another account")

        now = utcnow()
        device.owner_user_id = user_id
        device.ble_mac = payload.ble_mac or device.ble_mac
        device.firmware_version = payload.firmware_version or device.firmware_version
        device.paired_at = now
        device.last_seen_at = now
        self._devices.upsert(device.id, device)
        self._log_event(device.id, user_id, "paired")
        self._analytics.track(AnalyticsEventType.tracker_paired, user_id=user_id)
        return device

    def unpair(self, user_id: str, device_id: str, *, reason: str = "user_unpaired") -> None:
        device = self._devices.get(device_id)
        if not device or device.owner_user_id != user_id:
            raise NotFoundError("Device not found for this account")
        device.owner_user_id = None
        device.paired_at = None
        self._devices.upsert(device.id, device)
        self._log_event(device.id, user_id, "unpaired", reason=reason)

    def unpair_all_for_user(self, user_id: str, *, reason: str) -> None:
        """Used by account deletion — a deleted user can't remain the
        registered owner of a physical unit."""
        for device in self._devices.list_by_owner(user_id):
            self.unpair(user_id, device.id, reason=reason)

    def admin_unpair(self, device_id: str, *, reason: str) -> None:
        """Admin support action: unpair regardless of who's asking. Unlike
        `unpair`, the caller doesn't have to be the device's owner — a
        moderator helping a user who lost their phone needs this."""
        device = self._devices.get(device_id)
        if not device:
            raise NotFoundError("Device not found")
        if not device.owner_user_id:
            raise ConflictError("Device is not currently paired")
        previous_owner = device.owner_user_id
        device.owner_user_id = None
        device.paired_at = None
        self._devices.upsert(device.id, device)
        self._log_event(device.id, previous_owner, "unpaired", reason=reason)

    def list_by_owner(self, user_id: str) -> list[Device]:
        return self._devices.list_by_owner(user_id)

    def list_unpaired(self, *, limit: int = 100) -> list[Device]:
        return self._devices.list_unpaired(limit=limit)

    def list_all(self, *, limit: int = 500) -> list[Device]:
        return self._devices.list_all(limit=limit)

    def heartbeat(self, user_id: str, device_id: str, *, battery_level: int | None = None) -> None:
        device = self._devices.get(device_id)
        if not device or device.owner_user_id != user_id:
            raise NotFoundError("Device not found for this account")
        fields: dict = {"last_seen_at": utcnow()}
        if battery_level is not None:
            fields["battery_level"] = battery_level
        self._devices.update(device_id, fields)

    def _log_event(self, device_id: str, user_id: str, event: str, *, reason: str | None = None) -> None:
        record = DevicePairingEvent(
            id=str(uuid.uuid4()),
            device_id=device_id,
            user_id=user_id,
            event=event,
            at=utcnow(),
            reason=reason,
        )
        self._events.upsert(record.id, record)
