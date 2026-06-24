import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:strola_health/core/constants/ble_constants.dart';

enum BleServiceStatus {
  idle,
  requestingPermissions,
  permissionDenied,
  scanning,
  connecting,
  connected,
  disconnected,
  error,
}

/// Manages the full BLE lifecycle for the nRF5340 + NUS step counter.
///
/// Crash-safety guarantees:
///   • Generation counter (_connectionGen) — every new _connect() or stop() call
///     bumps the counter. All async callbacks snapshot the counter at creation
///     time and silently drop if it no longer matches. This eliminates stale
///     "disconnected" events re-triggering reconnects after a new attempt starts.
///   • All subscriptions are nulled after cancel so a dead reference can never
///     receive a platform re-emit.
///   • _active is checked at every async boundary (after permission await, inside
///     every callback) so stop() mid-flight leaves no dangling work.
///   • subscribeToCharacteristic is wrapped in try/catch for the synchronous
///     throw that occurs on app-restart when the OS holds a phantom connection.
class BleStepService {
  BleStepService(this._ble);

  final FlutterReactiveBle _ble;

  final _stepController = StreamController<int>.broadcast();
  final _statusController = StreamController<BleServiceStatus>.broadcast();

  Stream<int> get stepStream => _stepController.stream;
  Stream<BleServiceStatus> get statusStream => _statusController.stream;
  BleServiceStatus get status => _status;

  BleServiceStatus _status = BleServiceStatus.idle;
  String? _deviceId;
  int _reconnectCount = 0;
  bool _active = false;

  // Bumped on every _connect() and stop(). Callbacks that snapshot a stale
  // generation are dropped, preventing the reconnect storm.
  int _connectionGen = 0;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _charSub;
  Timer? _reconnectTimer;
  Timer? _scanTimer;

  // ── Public API ──────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_active) return;
    _active = true;
    _reconnectCount = 0;
    await _requestPermissionsThenScan();
  }

  Future<void> stop() async {
    _active = false;
    _connectionGen++; // invalidate every in-flight callback instantly

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _scanTimer?.cancel();
    _scanTimer = null;

    await _scanSub?.cancel();
    _scanSub = null;
    await _connectSub?.cancel();
    _connectSub = null;
    await _charSub?.cancel();
    _charSub = null;

    _setStatus(BleServiceStatus.idle);
  }

  void dispose() {
    stop(); // async, but guards in _setStatus / _stepController protect against races
    _stepController.close();
    _statusController.close();
  }

  // ── Permissions ─────────────────────────────────────────────────────────

  Future<void> _requestPermissionsThenScan() async {
    _setStatus(BleServiceStatus.requestingPermissions);

    bool granted;
    if (Platform.isAndroid) {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      granted = results.values.every((s) => s == PermissionStatus.granted);
    } else if (Platform.isIOS) {
      granted = (await Permission.bluetooth.request()).isGranted;
    } else {
      granted = true;
    }

    // Guard: stop() may have been called while the permission dialog was open
    if (!_active) return;

    if (!granted) {
      _setStatus(BleServiceStatus.permissionDenied);
      return;
    }
    _startScan();
  }

  // ── Scanning ────────────────────────────────────────────────────────────

  void _startScan() {
    if (!_active) return;
    _setStatus(BleServiceStatus.scanning);

    _scanSub?.cancel();
    _scanSub = null;

    _scanSub = _ble
        .scanForDevices(
          withServices: [Uuid.parse(BleConstants.serviceUuid)],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            if (!_active) return;
            if (device.name == BleConstants.deviceName ||
                device.id == _deviceId) {
              _scanSub?.cancel();
              _scanSub = null;
              _scanTimer?.cancel();
              _scanTimer = null;
              _deviceId = device.id;
              _connect(device.id);
            }
          },
          onError: (_) {
            if (_active) _scheduleReconnect();
          },
        );

    // Time-box scan — avoid draining battery forever
    _scanTimer = Timer(
      const Duration(seconds: BleConstants.scanTimeoutSeconds),
      () {
        if (_active && _status == BleServiceStatus.scanning) {
          _scanSub?.cancel();
          _scanSub = null;
          _scheduleReconnect();
        }
      },
    );
  }

  // ── Connection ───────────────────────────────────────────────────────────

  void _connect(String deviceId) {
    if (!_active) return;

    // Cancel old subscription and null it before creating the new one.
    // Nulling prevents a platform re-emit on the dead reference.
    _connectSub?.cancel();
    _connectSub = null;

    // Snapshot the current generation. Any event that arrives with a different
    // generation was fired by a previous connection attempt and is dropped.
    final gen = ++_connectionGen;
    _setStatus(BleServiceStatus.connecting);

    _connectSub = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) {
            // Drop stale events from a superseded connection attempt
            if (gen != _connectionGen || !_active) return;

            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                _reconnectCount = 0;
                _setStatus(BleServiceStatus.connected);
                _subscribeToStepData(deviceId, gen);

              case DeviceConnectionState.disconnected:
                _charSub?.cancel();
                _charSub = null;
                _setStatus(BleServiceStatus.disconnected);
                _scheduleReconnect(); // _active already checked at top of handler

              default:
                break;
            }
          },
          onError: (_) {
            if (gen != _connectionGen || !_active) return;
            _setStatus(BleServiceStatus.error);
            _scheduleReconnect();
          },
        );
  }

  // ── NUS TX characteristic subscription ──────────────────────────────────

  void _subscribeToStepData(String deviceId, int gen) {
    if (!_active || gen != _connectionGen) return;

    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(BleConstants.serviceUuid),
      characteristicId: Uuid.parse(BleConstants.txCharUuid),
      deviceId: deviceId,
    );

    _charSub?.cancel();
    _charSub = null;

    try {
      // subscribeToCharacteristic can throw synchronously on app-restart when
      // the OS holds a phantom connection from the previous session.
      _charSub = _ble
          .subscribeToCharacteristic(char)
          .listen(
            (bytes) {
              if (gen != _connectionGen || !_active) return;
              final steps = _parseStepData(bytes);
              if (steps != null && !_stepController.isClosed) {
                _stepController.add(steps);
              }
            },
            onError: (_) {
              // Characteristic errors on disconnect are normal — the connection
              // subscription already handles the reconnect flow.
            },
            cancelOnError: false,
          );
    } catch (_) {
      // Synchronous throw: treat as an immediate disconnect and reconnect
      if (_active && gen == _connectionGen) {
        _setStatus(BleServiceStatus.disconnected);
        _scheduleReconnect();
      }
    }
  }

  // ── Packet parser ────────────────────────────────────────────────────────
  // Handles the three common encodings a Zephyr NUS firmware may send:
  //   4 bytes → uint32_t LE  |  2 bytes → uint16_t LE  |  N bytes → ASCII

  int? _parseStepData(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final view = ByteData.sublistView(Uint8List.fromList(bytes));
      if (bytes.length == 4) return view.getUint32(0, Endian.little);
      if (bytes.length == 2) return view.getUint16(0, Endian.little);
      final raw = String.fromCharCodes(
        bytes,
      ).trim().replaceAll('\x00', '').replaceAll(RegExp(r'[^\d]'), '');
      final parsed = int.tryParse(raw);
      return (parsed != null && parsed >= 0) ? parsed : null;
    } catch (_) {
      return null;
    }
  }

  // ── Exponential backoff reconnection ────────────────────────────────────

  void _scheduleReconnect() {
    if (!_active) return;

    _reconnectTimer?.cancel();
    // 1 s → 2 s → 4 s → 8 s → 16 s → 30 s (capped)
    final seconds = min(1 << _reconnectCount, 30);
    _reconnectCount = (_reconnectCount + 1).clamp(
      0,
      BleConstants.maxReconnectAttempts,
    );

    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!_active) return;
      if (_deviceId != null) {
        _connect(_deviceId!);
      } else {
        _startScan();
      }
    });
  }

  // ── Internal helper ──────────────────────────────────────────────────────

  void _setStatus(BleServiceStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }
}
