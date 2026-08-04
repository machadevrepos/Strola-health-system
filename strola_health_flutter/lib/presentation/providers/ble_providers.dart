import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/datasources/ble_step_service.dart';
import 'package:strola_health/data/repositories/device_repository.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';

// ── UI-facing BLE status enum ────────────────────────────────────────────────

enum BleStatus { disconnected, scanning, connected, bluetoothOff }

// ── BleStepService singleton ─────────────────────────────────────────────────

final bleServiceProvider = Provider<BleStepService>((ref) {
  final service = BleStepService(FlutterReactiveBle());
  ref.onDispose(service.dispose);
  return service;
});

// ── Connection status (maps internal BleServiceStatus → UI BleStatus) ────────

final bleStatusProvider = StateNotifierProvider<BleStatusNotifier, BleStatus>(
  (ref) => BleStatusNotifier(ref),
);

class BleStatusNotifier extends StateNotifier<BleStatus> {
  BleStatusNotifier(this._ref) : super(BleStatus.disconnected) {
    // Mirror the real BLE service status into the simple UI enum.
    // ref.read() is correct here — we're setting up a one-time subscription,
    // not reacting to provider rebuilds (ref.watch is invalid in StateNotifier).
    _subscription = _ref.read(bleServiceProvider).statusStream.listen((s) {
      final mapped = switch (s) {
        BleServiceStatus.connected => BleStatus.connected,
        BleServiceStatus.bluetoothOff => BleStatus.bluetoothOff,
        BleServiceStatus.scanning ||
        BleServiceStatus.connecting ||
        BleServiceStatus.requestingPermissions => BleStatus.scanning,
        _ => BleStatus.disconnected,
      };
      if (state != mapped) state = mapped;
      _onMappedStatus(mapped);
    });
  }

  final Ref _ref;
  late final StreamSubscription<BleServiceStatus> _subscription;
  Timer? _heartbeatTimer;

  /// Kick off scanning + connection from the UI (e.g. "Connect" button tap).
  Future<void> connect() async {
    state = BleStatus.scanning;
    await _ref.read(bleServiceProvider).start();
  }

  Future<void> disconnect() async {
    await _ref.read(bleServiceProvider).stop();
    state = BleStatus.disconnected;
  }

  /// While actually connected, pings `reportDeviceStatus` every 5 minutes so
  /// the admin dashboard's `last_seen_at` reflects a live session instead of
  /// staying frozen at whatever it was the moment the device was first
  /// paired. Starts/stops itself off the mapped status — no separate call
  /// site needed.
  void _onMappedStatus(BleStatus mapped) {
    if (mapped == BleStatus.connected) {
      _heartbeatTimer ??= Timer.periodic(
        const Duration(minutes: 5),
        (_) => _reportStatus(),
      );
      unawaited(
        _reportStatus(),
      ); // one immediately on connect, not just 5 min later
    } else {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
  }

  Future<void> _reportStatus() async {
    if (!_ref.read(firebaseAvailableProvider)) return;
    try {
      await _ref.read(deviceRepositoryProvider).reportStatus();
    } catch (_) {
      // Best-effort — a failed heartbeat shouldn't affect the live BLE
      // connection or surface to the user; it'll just retry in 5 minutes.
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

// ── Raw step stream from BLE ─────────────────────────────────────────────────

final bleStepStreamProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(bleServiceProvider).stepStream;
});

// ── Battery level — stub ─────────────────────────────────────────────────────
// No characteristic exposing battery is parsed from the device yet
// (`BleStepService` only handles the step-count packet). Returns null until
// firmware exposes a battery service and this is wired up for real; the Low
// Battery notification detector watches this and is ready to fire once it
// does.
final batteryLevelProvider = Provider<int?>((ref) => null);
