import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/data/repositories/device_repository.dart';
import 'package:strola_health/domain/entities/paired_device.dart';
import 'package:strola_health/presentation/providers/ble_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  @override
  Widget build(BuildContext context) {
    final bleStatus = ref.watch(bleStatusProvider);
    final bleNotifier = ref.read(bleStatusProvider.notifier);

    final isConnected = bleStatus == BleStatus.connected;
    final isScanning = bleStatus == BleStatus.scanning;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child:
                    Text(
                          'Device',
                          style: AppTypography.displayL.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: AppTheme.animSlow)
                        .slideX(begin: 0.12),
              ),
            ),
          ),

          // ── Device illustration card ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: FlatCard(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    // Device visual (nRF7002 DK badge)
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isConnected
                                    ? AppColors.bleConnected
                                    : AppColors.accent)
                                .withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color:
                              (isConnected
                                      ? AppColors.bleConnected
                                      : AppColors.accent)
                                  .withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: isScanning
                          ? Center(
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: const AlwaysStoppedAnimation(
                                        AppColors.bleScanning,
                                      ),
                                    ),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .rotate(duration: 1200.ms)
                          : Icon(
                                  AppIcons.watch,
                                  size: 48,
                                  color: isConnected
                                      ? AppColors.bleConnected
                                      : AppColors.textMuted,
                                )
                                .animate(
                                  onPlay: isConnected
                                      ? (c) => c.repeat(reverse: true)
                                      : null,
                                )
                                .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.08, 1.08),
                                  duration: 1000.ms,
                                  curve: Curves.easeInOut,
                                ),
                    ),
                    const SizedBox(height: 20),
                    // Device name
                    Text(
                      'NRF7002_STEPS',
                      style: AppTypography.titleM.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Nordic nRF5340 · MPU-6050',
                      style: AppTypography.labelM.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status badge
                    _StatusBadge(status: bleStatus),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          ),

          // ── Connect / Disconnect button ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _ConnectButton(
                status: bleStatus,
                onTap: () {
                  if (isConnected) {
                    bleNotifier.disconnect();
                  } else if (!isScanning) {
                    bleNotifier.connect();
                  }
                },
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          ),

          // ── Account pairing ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _PairingCard()
                  .animate()
                  .fadeIn(delay: 250.ms)
                  .slideY(begin: 0.1),
            ),
          ),

          // ── Device specs ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: FlatCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Info',
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    ..._specs.asMap().entries.map(
                      (e) => _SpecRow(
                        label: e.value.$1,
                        value: e.value.$2,
                        index: e.key,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            ),
          ),

          // ── BLE service info ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: FlatCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BLE Services',
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    _ServiceRow(
                      name: 'Nordic UART Service (NUS)',
                      uuid: '6E400001-B5A3-F393-E0A9-E50E24DCCA9E',
                      isActive: isConnected,
                    ),
                    const SizedBox(height: 8),
                    _ServiceRow(
                      name: 'Step Data TX',
                      uuid: '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
                      isActive: isConnected,
                    ),
                    const SizedBox(height: 8),
                    _ServiceRow(
                      name: 'Command RX',
                      uuid: '6E400002-B5A3-F393-E0A9-E50E24DCCA9E',
                      isActive: isConnected,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  static const _specs = [
    ('SoC', 'Nordic nRF5340'),
    ('IMU', 'InvenSense MPU-6050'),
    ('Interface', 'I2C @ 100 kHz'),
    ('BLE Protocol', 'Nordic UART Service'),
    ('Firmware', 'Zephyr RTOS'),
    ('Step Stride', '0.762 m/step'),
  ];
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BleStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      BleStatus.connected => (AppColors.bleConnected, 'Connected'),
      BleStatus.scanning => (AppColors.bleScanning, 'Scanning for device…'),
      BleStatus.disconnected => (AppColors.bleDisconnected, 'Not connected'),
      BleStatus.bluetoothOff => (AppColors.error, 'Bluetooth is off'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelM.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.status, required this.onTap});

  final BleStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isConnected = status == BleStatus.connected;
    final isScanning = status == BleStatus.scanning;
    final isBluetoothOff = status == BleStatus.bluetoothOff;

    return GestureDetector(
      onTap: (isScanning || isBluetoothOff) ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isConnected
              ? LinearGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.6),
                    AppColors.error.withValues(alpha: 0.4),
                  ],
                )
              : isBluetoothOff
              ? LinearGradient(
                  colors: [
                    AppColors.bleDisconnected.withValues(alpha: 0.5),
                    AppColors.bleDisconnected.withValues(alpha: 0.3),
                  ],
                )
              : const LinearGradient(
                  colors: [AppColors.accentSecondary, AppColors.accent],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isConnected ? AppColors.error : AppColors.accent)
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected
                  ? AppIcons.bluetoothDisabled
                  : isScanning
                  ? AppIcons.bluetoothSearch
                  : AppIcons.bluetooth,
              color: Colors.white,
              size: AppTheme.iconM,
            ),
            const SizedBox(width: AppTheme.spaceS),
            Text(
              isConnected
                  ? 'Disconnect'
                  : isScanning
                  ? 'Scanning…'
                  : isBluetoothOff
                  ? 'Turn on Bluetooth to connect'
                  : 'Connect to Device',
              style: AppTypography.bodyL.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.label,
    required this.value,
    required this.index,
  });

  final String label;
  final String value;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child:
          Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: AppTypography.labelM.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.labelM.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              )
              .animate(delay: Duration(milliseconds: 400 + index * 50))
              .fadeIn()
              .slideX(begin: 0.05),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.name,
    required this.uuid,
    required this.isActive,
  });

  final String name;
  final String uuid;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.bleConnected
                : AppColors.bleDisconnected,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.labelM.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              Text(
                uuid,
                style: AppTypography.labelS.copyWith(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Account pairing ──────────────────────────────────────────────────────────
//
// BLE connection (above) and account pairing are two different things: BLE
// is just a live radio link to whatever nearby unit answers to the fixed
// advertised name (every unit advertises the same name — see
// ble_constants.dart, there's no per-unit identifier over the air), while
// pairing is the backend record of which physical unit this account owns.
// A device can be BLE-connected without being paired, and there's no way to
// derive pairing from a BLE connection alone — the serial number printed on
// the unit has to be entered manually once.

class _PairingCard extends ConsumerWidget {
  const _PairingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(myDeviceProvider);

    return FlatCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Pairing',
            style: AppTypography.bodyL.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          deviceAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceM),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
            error: (_, __) => Text(
              'Could not load pairing status.',
              style: AppTypography.labelM.copyWith(color: AppColors.textMuted),
            ),
            data: (device) => device == null
                ? _NotPaired(onPair: () => _openPairSheet(context, ref))
                : _Paired(
                    device: device,
                    onSwitch: () => _openPairSheet(context, ref),
                  ),
          ),
        ],
      ),
    );
  }

  void _openPairSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PairDeviceSheet(),
    );
  }
}

class _NotPaired extends StatelessWidget {
  const _NotPaired({required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "This device isn't paired to your account yet.",
          style: AppTypography.labelM.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        PressableScale(
          onTap: onPair,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Text(
              'Pair This Device',
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Paired extends StatelessWidget {
  const _Paired({required this.device, required this.onSwitch});

  final PairedDevice device;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              AppIcons.goalReached,
              color: AppColors.bleConnected,
              size: AppTheme.iconS,
            ),
            const SizedBox(width: AppTheme.spaceXS),
            Text(
              'Paired · ${device.serialNumber}',
              style: AppTypography.labelM.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        if (device.batteryLevel != null) ...[
          const SizedBox(height: 4),
          Text(
            'Battery: ${device.batteryLevel}%',
            style: AppTypography.labelS.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spaceM),
        PressableScale(
          onTap: onSwitch,
          child: Text(
            'Pair a Different Device',
            style: AppTypography.labelM.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PairDeviceSheet extends ConsumerStatefulWidget {
  const _PairDeviceSheet();

  @override
  ConsumerState<_PairDeviceSheet> createState() => _PairDeviceSheetState();
}

class _PairDeviceSheetState extends ConsumerState<_PairDeviceSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final serial = _controller.text.trim();
    if (serial.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(deviceRepositoryProvider).pairDevice(serialNumber: serial);
      ref.invalidate(myDeviceProvider);
      if (mounted) {
        HapticsHelper.lightImpact();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusSheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPaddingH,
              AppTheme.spaceM,
              AppTheme.screenPaddingH,
              AppTheme.spaceL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text('Pair Your Device', style: AppTypography.titleL),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  "Enter the serial number printed on the back of your device.",
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTypography.bodyL,
                  decoration: InputDecoration(
                    hintText: 'e.g. STR-00042',
                    hintStyle: AppTypography.bodyL.copyWith(
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.bgDeep,
                    contentPadding: const EdgeInsets.all(AppTheme.spaceL),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    _error!,
                    style: AppTypography.bodyS.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceL),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _submitting ? 'Pairing…' : 'Pair Device',
                      style: AppTypography.bodyL.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
