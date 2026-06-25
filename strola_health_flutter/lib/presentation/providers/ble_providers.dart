import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/datasources/ble_step_service.dart';

// ── UI-facing BLE status enum ────────────────────────────────────────────────

enum BleStatus { disconnected, scanning, connected }

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
        BleServiceStatus.scanning ||
        BleServiceStatus.connecting ||
        BleServiceStatus.requestingPermissions => BleStatus.scanning,
        _ => BleStatus.disconnected,
      };
      if (state != mapped) state = mapped;
    });
  }

  final Ref _ref;
  late final StreamSubscription<BleServiceStatus> _subscription;

  /// Kick off scanning + connection from the UI (e.g. "Connect" button tap).
  Future<void> connect() async {
    state = BleStatus.scanning;
    await _ref.read(bleServiceProvider).start();
  }

  Future<void> disconnect() async {
    await _ref.read(bleServiceProvider).stop();
    state = BleStatus.disconnected;
  }

  @override
  void dispose() {
    _subscription.cancel();
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
