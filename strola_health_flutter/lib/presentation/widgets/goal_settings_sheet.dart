import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/constants/step_goals.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

void showGoalSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GoalSheet(),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet();

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late int _pickerValue;
  late double _weightValue;
  late final ConfettiController _confetti;

  static const _quickPicks = [5000, 7500, 10000, 15000, 20000];

  @override
  void initState() {
    super.initState();
    _pickerValue = ref.read(dailyGoalProvider);
    _weightValue = ref.read(userWeightKgProvider);
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(dailyGoalProvider.notifier).setGoal(_pickerValue);
    await ref.read(userWeightKgProvider.notifier).setWeight(_weightValue);
    HapticsHelper.goalReached();
    _confetti.play();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final progress = (_pickerValue / StepGoals.maxDailyGoal).clamp(0.0, 1.0);

    final maxSheetHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        60;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.accentSecondary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Daily Step Goal',
                      style: AppTypography.titleL.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ).animate().fadeIn(duration: AppTheme.animSlow).slideY(begin: 0.12),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Scroll the wheel or tap a quick pick below.',
                      style: AppTypography.bodyS.copyWith(letterSpacing: 0),
                    ).animate().fadeIn(delay: 80.ms),

                    const SizedBox(height: 24),

                    // Step count preview + ring progress
                    FlatCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (c, a) => FadeTransition(
                                    opacity: a,
                                    child: ScaleTransition(scale: a, child: c),
                                  ),
                                  child: Text(
                                    _formatNumber(_pickerValue),
                                    key: ValueKey(_pickerValue),
                                    style: AppTypography.displayXL.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'steps · ${_kcal(_pickerValue)} kcal · ${_km(_pickerValue)}',
                                  style: AppTypography.labelM.copyWith(
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: 1,
                                  strokeWidth: 5,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.accentSecondary.withValues(alpha: 0.2),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: const AlwaysStoppedAnimation(0),
                                  builder: (_, __) => CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 5,
                                    strokeCap: StrokeCap.round,
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),

                    const SizedBox(height: 20),

                    // Drum-roll number picker
                    Center(
                      child: NumberPicker(
                        value: _pickerValue,
                        minValue: StepGoals.minDailyGoal,
                        maxValue: StepGoals.maxDailyGoal,
                        step: 500,
                        itemHeight: 48,
                        itemWidth: 160,
                        axis: Axis.vertical,
                        selectedTextStyle: AppTypography.displayM.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                        textStyle: AppTypography.titleM.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          HapticsHelper.selection();
                          setState(() => _pickerValue = v);
                        },
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 20),

                    // Quick pick chips
                    Text(
                      'QUICK PICKS',
                      style: AppTypography.labelS.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickPicks.asMap().entries.map((e) {
                        final val = e.value;
                        final isSelected = _pickerValue == val;
                        return GestureDetector(
                              onTap: () {
                                HapticsHelper.lightImpact();
                                setState(() => _pickerValue = val);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent.withValues(alpha: 0.2)
                                      : AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent.withValues(
                                            alpha: 0.6,
                                          )
                                        : AppColors.accentSecondary.withValues(
                                            alpha: 0.3,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _formatNumber(val),
                                  style: AppTypography.bodyS.copyWith(
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            )
                            .animate(
                              delay: Duration(milliseconds: 200 + e.key * 50),
                            )
                            .fadeIn()
                            .slideX(begin: 0.1);
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Body weight ────────────────────────────────────────
                    Text(
                      'BODY WEIGHT',
                      style: AppTypography.labelS.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Used to personalise your calorie estimates.',
                      style: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FlatCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.weight,
                            color: AppColors.accent,
                            size: AppTheme.iconM,
                          ),
                          const SizedBox(width: AppTheme.spaceM),
                          Expanded(
                            child: Text(
                              '${_weightValue.toInt()} kg',
                              style: AppTypography.titleL.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          // Decrement
                          _WeightButton(
                            icon: AppIcons.remove,
                            onTap: () {
                              HapticsHelper.selection();
                              setState(() {
                                _weightValue =
                                    (_weightValue - 1).clamp(30.0, 200.0);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          // Increment
                          _WeightButton(
                            icon: AppIcons.add,
                            onTap: () {
                              HapticsHelper.selection();
                              setState(() {
                                _weightValue =
                                    (_weightValue + 1).clamp(30.0, 200.0);
                              });
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),

                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Save Goal',
                          style: AppTypography.titleM.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                  ],
                ),
              ),

              SizedBox(height: bottomPadding + 12),
            ],
            ),
          ),
        ),

        // Confetti — Positioned.fill so it never drives the Stack's height
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                gravity: 0.4,
                colors: const [
                  AppColors.accent,
                  AppColors.accentSecondary,
                  AppColors.bgDeep,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) => n >= 1000
      ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}'
      : '$n';

  String _kcal(int steps) {
    final weight = ref.read(userWeightKgProvider);
    return '${(steps * weight * 0.000571).toInt()}';
  }

  String _km(int steps) {
    final km = steps * 0.762 / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}

class _WeightButton extends StatelessWidget {
  const _WeightButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: AppColors.accent, size: 18),
      ),
    );
  }
}
