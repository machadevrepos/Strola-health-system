/// This account's currently paired hardware unit — mirrors `devices/{id}`
/// where `owner_user_id == me` (see strola_health_firebase/functions/src/lib/types.ts
/// `Device`). Only the fields the app actually displays are modeled here.
class PairedDevice {
  const PairedDevice({
    required this.id,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.batteryLevel,
  });

  final String id;
  final String serialNumber;
  final String? firmwareVersion;
  final int? batteryLevel;

  factory PairedDevice.fromFirestore(Map<String, dynamic> data, String docId) {
    return PairedDevice(
      id: docId,
      serialNumber: data['serial_number'] as String? ?? '',
      firmwareVersion: data['firmware_version'] as String?,
      batteryLevel: (data['battery_level'] as num?)?.toInt(),
    );
  }
}
