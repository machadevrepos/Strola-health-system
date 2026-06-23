from google.cloud import firestore

from app.models.device import Device, DevicePairingEvent
from app.repositories.base import FirestoreRepository


class DeviceRepository(FirestoreRepository[Device]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "devices", Device)

    def get_by_serial(self, serial_number: str) -> Device | None:
        results = self.query([("serial_number", "==", serial_number)], limit=1)
        return results[0] if results else None

    def list_unpaired(self, *, limit: int = 100) -> list[Device]:
        return self.query([("owner_user_id", "==", None)], limit=limit)

    def list_all(self, *, limit: int = 500) -> list[Device]:
        """Fleet-wide view: paired and unpaired together, for the Fleet
        console's stats and table — unlike `list_unpaired`, which is the
        stock-check used during provisioning."""
        return self.query(order_by="created_at", descending=True, limit=limit)

    def list_by_owner(self, user_id: str) -> list[Device]:
        return self.query([("owner_user_id", "==", user_id)])


class DevicePairingEventRepository(FirestoreRepository[DevicePairingEvent]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "device_pairing_events", DevicePairingEvent)

    def list_for_device(self, device_id: str, *, limit: int = 50) -> list[DevicePairingEvent]:
        return self.query([("device_id", "==", device_id)], order_by="at", descending=True, limit=limit)
