from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel


class DeviceType(StrEnum):
    strolla_nrf7002 = "strolla_nrf7002"  # current hardware: Nordic nRF7002 + MPU-6050 IMU


class Device(BaseModel):
    id: str
    serial_number: str
    device_type: DeviceType = DeviceType.strolla_nrf7002
    ble_mac: str | None = None
    firmware_version: str | None = None
    manufacturing_batch: str | None = None
    owner_user_id: str | None = None
    paired_at: datetime | None = None
    last_seen_at: datetime | None = None
    battery_level: int | None = None
    created_at: datetime


class DeviceProvisionRequest(BaseModel):
    """Super-admin: register a new unit from the factory before it's ever paired."""

    serial_number: str
    device_type: DeviceType = DeviceType.strolla_nrf7002
    manufacturing_batch: str | None = None


class DevicePairRequest(BaseModel):
    serial_number: str
    ble_mac: str | None = None
    firmware_version: str | None = None


class DevicePairingEvent(BaseModel):
    id: str
    device_id: str
    user_id: str
    event: str  # "paired" | "unpaired"
    at: datetime
    reason: str | None = None  # "user_unpaired" | "account_deleted" | "warranty_swap" | ...
