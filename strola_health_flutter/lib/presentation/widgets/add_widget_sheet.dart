import 'dart:io';

import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/widget_service.dart';

/// Opens the "add the home-screen widget" bottom sheet. Shared by the
/// first-time Home prompt and the on-demand Settings entry — same sheet
/// either way, just a different trigger.
Future<void> showAddWidgetSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AddWidgetSheet(),
  );
}

class _AddWidgetSheet extends StatefulWidget {
  const _AddWidgetSheet();

  @override
  State<_AddWidgetSheet> createState() => _AddWidgetSheetState();
}

class _AddWidgetSheetState extends State<_AddWidgetSheet> {
  // null while still checking — avoids flashing the instructions then
  // immediately swapping to the one-tap button on Android.
  bool? _pinSupported;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported =
        Platform.isAndroid && await WidgetService.isPinSupported();
    if (mounted) setState(() => _pinSupported = supported);
  }

  Future<void> _addNow() async {
    setState(() => _requesting = true);
    try {
      await WidgetService.requestPin();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      // Some launchers reject the request even when isPinSupported reports
      // true — fall back to manual instructions rather than failing silently.
      if (mounted) setState(() => _pinSupported = false);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accentSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.steps,
                      color: AppColors.accent,
                      size: AppTheme.iconM,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add the Strolla widget',
                          style: AppTypography.titleM,
                        ),
                        Text(
                          'See your steps right on your home screen',
                          style: AppTypography.bodyS,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXL),
              if (_pinSupported == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spaceL),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (_pinSupported!)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _requesting ? null : _addNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceL,
                      ),
                    ),
                    child: _requesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Add to Home Screen',
                            style: AppTypography.titleS.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                )
              else
                _InstructionsList(isIOS: Platform.isIOS),
              const SizedBox(height: AppTheme.spaceM),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe later',
                    style: AppTypography.bodyM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionsList extends StatelessWidget {
  const _InstructionsList({required this.isIOS});

  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    // No iOS API can trigger the add-widget UI directly — Apple keeps this
    // a manual, user-driven action. Android falls back here too, for the
    // rare launcher that reports pin support but doesn't actually honor it.
    final steps = isIOS
        ? const [
            'Long-press an empty area of your Home Screen',
            'Tap the + button in the top corner',
            'Search for "Strolla Health"',
            'Choose a widget size and tap Add Widget',
          ]
        : const [
            'Long-press an empty area of your Home Screen',
            'Tap Widgets',
            'Find Strolla Health and drag it onto your Home Screen',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.labelM.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(child: Text(steps[i], style: AppTypography.bodyM)),
              ],
            ),
          ),
      ],
    );
  }
}
