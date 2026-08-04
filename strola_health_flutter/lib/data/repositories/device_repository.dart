import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/domain/entities/paired_device.dart';

/// Real Firestore/Cloud-Function-backed device pairing. There is no
/// per-unit serial number exchanged over BLE (every unit advertises the
/// same name — see ble_constants.dart), so pairing needs the serial number
/// printed on the physical device, entered manually — this repository is
/// what backs that flow.
class DeviceRepository {
  DeviceRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    return uid;
  }

  /// Null when this account has no device paired yet — real state, not an
  /// error.
  Future<PairedDevice?> getMyDevice() async {
    final snap = await _firestore
        .collection('devices')
        .where('owner_user_id', isEqualTo: _uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PairedDevice.fromFirestore(
      snap.docs.first.data(),
      snap.docs.first.id,
    );
  }

  /// Pairing a new serial automatically unpairs whatever this account had
  /// paired before (server-side, one-device-per-user) — see pairDevice.ts.
  Future<void> pairDevice({
    required String serialNumber,
    String? bleMac,
    String? firmwareVersion,
  }) => FirebaseClient.call('pairDevice', {
    'serialNumber': serialNumber,
    if (bleMac != null) 'bleMac': bleMac,
    if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
  });

  /// Heartbeat while a BLE session is live, so `last_seen_at` on the admin
  /// dashboard reflects the device's real live state rather than staying
  /// frozen at whatever it was when the device was first paired. Silently
  /// no-ops server-side (via a best-effort caller — see BleStepService) if
  /// this account has no paired device, so it's always safe to call.
  Future<void> reportStatus({int? batteryLevel, String? firmwareVersion}) =>
      FirebaseClient.call('reportDeviceStatus', {
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
      });
}

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (_) => DeviceRepository(FirebaseClient.firestore, FirebaseAuth.instance),
);

final myDeviceProvider = FutureProvider<PairedDevice?>((ref) {
  return ref.watch(deviceRepositoryProvider).getMyDevice();
});
