import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/providers/ble_providers.dart';

class BleStatusChip extends ConsumerWidget {
  const BleStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(bleStatusProvider);

    final (color, label, icon) = switch (status) {
      BleStatus.connected => (
        AppColors.bleConnected,
        'NRF7002 Connected',
        AppIcons.bluetoothConnected,
      ),
      BleStatus.scanning => (
        AppColors.bleScanning,
        'Scanning…',
        AppIcons.bluetoothSearch,
      ),
      BleStatus.disconnected => (
        AppColors.bleDisconnected,
        'Disconnected',
        AppIcons.bluetoothDisabled,
      ),
    };

    return GestureDetector(
      onTap: () {
        final notifier = ref.read(bleStatusProvider.notifier);
        switch (status) {
          case BleStatus.disconnected:
            notifier.connect();
          case BleStatus.scanning:
            break; // wait — don't cancel mid-scan from chip tap
          case BleStatus.connected:
            notifier.disconnect();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulse dot only when scanning
            if (status == BleStatus.scanning)
              Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 500.ms)
                  .then()
                  .fadeOut(duration: 500.ms)
            else
              Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
