import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/fitness_calculator.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/data/datasources/backend_api.dart';
import 'package:strola_health/domain/entities/user_profile.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/form_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.isEditing = false});

  /// When true, the wizard pre-fills from the saved profile and pops on save
  /// instead of being the app's root screen.
  final bool isEditing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _stepCount = 6;
  final _pageController = PageController();
  int _page = 0;

  // ── Form state ──────────────────────────────────────────────────────────────
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  double _heightCm = 170;
  double _weightKg = 65;
  DateTime? _dob;
  Gender _gender = Gender.preferNotToSay;
  int _stepGoal = 10000;
  final Set<StrollaReason> _reasons = {};
  UnitSystem _units = UnitSystem.metric;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _usernameCtrl.text = profile.username;
    _nameCtrl.text = profile.name;
    _locationCtrl.text = profile.location ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _heightCm = profile.heightCm;
    _weightKg = ref.read(userWeightKgProvider);
    _dob = profile.dateOfBirth;
    _gender = profile.gender;
    _stepGoal = ref.read(dailyGoalProvider);
    _reasons.addAll(profile.reasons);
    _units = profile.units;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_page) {
      case 0:
        return _usernameCtrl.text.trim().isNotEmpty &&
            _nameCtrl.text.trim().isNotEmpty;
      case 2:
        // Height/weight/gender all have defaults and gender is explicitly
        // optional (see _bodyStep) — date of birth has no sensible default
        // and isn't marked optional, so it must be set before continuing.
        return _dob != null;
      case 4:
        // At least one reason — the step asks the user to select from a
        // list, so leaving it untouched shouldn't be allowed through.
        return _reasons.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_page < _stepCount - 1) {
      HapticsHelper.selection();
      _pageController.nextPage(
        duration: AppTheme.animNormal,
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_page > 0) {
      _pageController.previousPage(
        duration: AppTheme.animNormal,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _complete() async {
    final profile = UserProfile(
      username: _usernameCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      photoPath: ref.read(userProfileProvider).photoPath,
      heightCm: _heightCm,
      gender: _gender,
      dateOfBirth: _dob,
      reasons: _reasons,
      units: _units,
      onboardingComplete: true,
    );

    // Read everything from `ref` up front, before any `await` — saving the
    // profile below flips `onboardingComplete`, which the root gate reacts
    // to by swapping this screen straight out of the tree. Any `ref.read`
    // after that point throws ("used after disposed"), even though the
    // notifiers/services themselves are plain objects that stay perfectly
    // usable once captured.
    final profileNotifier = ref.read(userProfileProvider.notifier);
    final weightNotifier = ref.read(userWeightKgProvider.notifier);
    final goalNotifier = ref.read(dailyGoalProvider.notifier);
    final shouldSyncBackend =
        ref.read(firebaseAvailableProvider) &&
        ref.read(authStateProvider).value != null;
    final backendApi = ref.read(backendApiProvider);
    final isEditing = widget.isEditing;

    await profileNotifier.save(profile);
    await weightNotifier.setWeight(_weightKg);
    await goalNotifier.setGoal(_stepGoal);
    HapticsHelper.goalReached();

    // Best-effort — the local save above is the source of truth regardless;
    // this just keeps the backend account in step once auth exists. Retried
    // a few times rather than a single silent attempt: right after sign-up,
    // the Firestore user doc this call updates is still being created by a
    // non-blocking auth trigger (see onUserCreate.ts) — a fast onboarding
    // flow can genuinely win that race and hit a transient "not found" on
    // the first try. A single failed attempt here used to mean the backend
    // profile simply never existed, silently, forever.
    if (shouldSyncBackend) {
      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          await backendApi.updateProfile(
            profile,
            dailyGoalSteps: _stepGoal,
            weightKg: _weightKg,
          );
          break;
        } catch (e) {
          if (attempt == maxAttempts) {
            debugPrint(
              '[OnboardingScreen] backend profile sync failed after '
              '$attempt attempts, local save still stands: $e',
            );
          } else {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }
    }

    if (isEditing && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Stepper ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceL,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceM,
                ),
                child: Row(
                  children: [
                    if (widget.isEditing || _page > 0)
                      GestureDetector(
                        onTap: widget.isEditing && _page == 0
                            ? () => Navigator.pop(context)
                            : _back,
                        child: const Icon(
                          AppIcons.back,
                          color: AppColors.textPrimary,
                          size: AppTheme.iconM,
                        ),
                      )
                    else
                      const SizedBox(width: AppTheme.iconM),
                    Expanded(
                      child: _StepProgress(current: _page, total: _stepCount),
                    ),
                    const SizedBox(width: AppTheme.iconM),
                  ],
                ),
              ),

              // ── Pages ───────────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _ProfileStep(
                      usernameCtrl: _usernameCtrl,
                      nameCtrl: _nameCtrl,
                      locationCtrl: _locationCtrl,
                      bioCtrl: _bioCtrl,
                      onChanged: () => setState(() {}),
                    ),
                    _unitsStep(),
                    _bodyStep(),
                    _goalStep(),
                    _reasonStep(),
                    _preferencesStep(),
                  ],
                ),
              ),

              // ── Bottom nav ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceS,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceXXL,
                ),
                child: Row(
                  children: [
                    if (_page > 0) ...[
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _back,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceL,
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: AppTypography.titleS.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                    ],
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        onPressed: _canAdvance ? _next : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.accentSecondary
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spaceL,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _page == _stepCount - 1
                              ? (widget.isEditing
                                    ? 'Save Changes'
                                    : 'Complete Setup')
                              : 'Continue',
                          style: AppTypography.titleS.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: Preferences (units) ────────────────────────────────────────────
  Widget _unitsStep() {
    return _StepScaffold(
      title: 'Preferences',
      subtitle:
          "Choose how you'd like to see your stats. You can change this "
          'later in Settings.',
      children: [
        FlatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.units,
                    color: AppColors.accent,
                    size: AppTheme.iconM,
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Text('Units', style: AppTypography.bodyL),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              _UnitToggle(
                value: _units,
                onChanged: (u) {
                  HapticsHelper.selection();
                  setState(() => _units = u);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: Body metrics ────────────────────────────────────────────────────
  Widget _bodyStep() {
    return _StepScaffold(
      title: 'Your health profile',
      children: [
        FlatCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PickerRow(
                icon: AppIcons.height,
                label: 'Height',
                value: _heightLabel(),
                onTap: _pickHeight,
              ),
              const _RowDivider(),
              _PickerRow(
                icon: AppIcons.weight,
                label: 'Weight',
                value: _weightLabel(),
                onTap: _pickWeight,
              ),
              const _RowDivider(),
              _PickerRow(
                icon: AppIcons.calendar,
                label: 'Date of Birth',
                value: _dob == null ? 'Select' : _formatDob(_dob!),
                onTap: _pickDob,
              ),
              const _RowDivider(),
              _PickerRow(
                icon: AppIcons.gender,
                label: 'Gender',
                optional: true,
                value: _gender.label,
                onTap: _pickGender,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        _InfoNote(
          'We use this information to personalize your distance, calorie '
          'estimates, and activity insights.',
        ),
      ],
    );
  }

  // ── Step 4: Goal ──────────────────────────────────────────────────────────────
  Widget _goalStep() {
    const quick = [5000, 8000, 10000, 12000, 15000];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Your daily goal',
            style: AppTypography.titleL,
          ).animate().fadeIn(duration: AppTheme.animFast).slideY(begin: 0.1),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'How many steps are you aiming for each day?',
            style: AppTypography.bodyM,
          ),
          const SizedBox(height: AppTheme.spaceXL),
          Expanded(
            child: FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.target,
                    color: AppColors.accent,
                    size: AppTheme.iconXXL,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    Formatters.stepCount(_stepGoal),
                    style: AppTypography.displayXL,
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text('steps per day', style: AppTypography.labelM),
                  const SizedBox(height: AppTheme.spaceXXL),
                  Wrap(
                    spacing: AppTheme.spaceS,
                    runSpacing: AppTheme.spaceS,
                    alignment: WrapAlignment.center,
                    children: quick.map((g) {
                      final active = _stepGoal == g;
                      return GestureDetector(
                        onTap: () {
                          HapticsHelper.lightImpact();
                          setState(() => _stepGoal = g);
                        },
                        child: AnimatedContainer(
                          duration: AppTheme.animFast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceL,
                            vertical: AppTheme.spaceS,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.accent.withValues(alpha: 0.10)
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                            border: Border.all(
                              color: active
                                  ? AppColors.accent.withValues(alpha: 0.45)
                                  : AppColors.accentSecondary.withValues(
                                      alpha: 0.30,
                                    ),
                            ),
                          ),
                          child: Text(
                            Formatters.stepCount(g),
                            style: AppTypography.labelM.copyWith(
                              color: active
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  TextButton(
                    onPressed: _pickGoal,
                    child: Text(
                      'Set a custom goal',
                      style: AppTypography.labelM.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  // ── Step 5: Reasons ───────────────────────────────────────────────────────────
  Widget _reasonStep() {
    return _StepScaffold(
      title: 'Tell us about you',
      subtitle:
          'What best describes your main reason for choosing Strolla? '
          'Select all that apply.',
      children: [
        ...StrollaReason.values.map((r) {
          final selected = _reasons.contains(r);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
            child: _ReasonTile(
              reason: r,
              selected: selected,
              onTap: () {
                HapticsHelper.lightImpact();
                setState(() {
                  if (selected) {
                    _reasons.remove(r);
                  } else {
                    _reasons.add(r);
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  // ── Step 6: Recap ──────────────────────────────────────────────────────────
  Widget _preferencesStep() {
    return _StepScaffold(
      title: 'Almost done!',
      subtitle: "Here's a quick recap of your setup.",
      children: [
        // Friendly recap
        FlatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.goalReached,
                    color: AppColors.success,
                    size: AppTheme.iconM,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Text("You're all set!", style: AppTypography.titleS),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              _recapRow(
                'Daily goal',
                '${Formatters.stepCount(_stepGoal)} steps',
              ),
              _recapRow('Height', _heightLabel()),
              _recapRow('Weight', _weightLabel()),
              _recapRow(
                'Units',
                _units == UnitSystem.metric ? 'Metric' : 'Imperial',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Row(
        children: [
          Text(label, style: AppTypography.bodyM),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyL.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Labels ────────────────────────────────────────────────────────────────────
  String _heightLabel() {
    if (_units == UnitSystem.imperial) {
      final (ft, inch) = FitnessCalculator.cmToFtIn(_heightCm);
      return "$ft' $inch\"";
    }
    return '${_heightCm.round()} cm';
  }

  String _weightLabel() {
    if (_units == UnitSystem.imperial) {
      return '${FitnessCalculator.kgToLb(_weightKg).round()} lb';
    }
    return '${_weightKg.round()} kg';
  }

  String _formatDob(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ── Pickers ──────────────────────────────────────────────────────────────────
  Future<void> _pickHeight() async {
    if (_units == UnitSystem.imperial) {
      final (initFt, initIn) = FitnessCalculator.cmToFtIn(_heightCm);
      final result = await _showHeightSheet(
        initialFeet: initFt,
        initialInches: initIn,
      );
      if (result != null) {
        setState(
          () => _heightCm = FitnessCalculator.ftInToCm(result.$1, result.$2),
        );
      }
      return;
    }
    final result = await _showWheelSheet(
      title: 'Height',
      min: 120,
      max: 220,
      step: 1,
      initial: _heightCm.round(),
      suffix: 'cm',
    );
    if (result != null) setState(() => _heightCm = result.toDouble());
  }

  Future<void> _pickWeight() async {
    if (_units == UnitSystem.imperial) {
      final result = await _showWheelSheet(
        title: 'Weight',
        min: 66,
        max: 440,
        step: 1,
        initial: FitnessCalculator.kgToLb(_weightKg).round(),
        suffix: 'lb',
      );
      if (result != null) {
        setState(() => _weightKg = FitnessCalculator.lbToKg(result.toDouble()));
      }
      return;
    }
    final result = await _showWheelSheet(
      title: 'Weight',
      min: 30,
      max: 200,
      step: 1,
      initial: _weightKg.round(),
      suffix: 'kg',
    );
    if (result != null) setState(() => _weightKg = result.toDouble());
  }

  Future<void> _pickGoal() async {
    final result = await _showWheelSheet(
      title: 'Daily Step Goal',
      min: 1000,
      max: 30000,
      step: 500,
      initial: _stepGoal,
      suffix: 'steps',
    );
    if (result != null) setState(() => _stepGoal = result);
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickGender() async {
    const order = [
      Gender.female,
      Gender.male,
      Gender.other,
      Gender.preferNotToSay,
    ];
    final picked = await showModalBottomSheet<Gender>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetContainer(
        title: 'Gender',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: order.map((g) {
            final selected = g == _gender;
            return ListTile(
              title: Text(
                g.label,
                style: AppTypography.bodyL.copyWith(
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: selected
                  ? const Icon(
                      AppIcons.check,
                      color: AppColors.accent,
                      size: AppTheme.iconM,
                    )
                  : null,
              onTap: () => Navigator.pop(context, g),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _gender = picked);
  }

  Future<int?> _showWheelSheet({
    required String title,
    required int min,
    required int max,
    required int step,
    required int initial,
    required String suffix,
  }) {
    int value = initial.clamp(min, max);
    // Snap to step grid
    value = min + ((value - min) ~/ step) * step;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetContainer(
        title: title,
        child: StatefulBuilder(
          builder: (context, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NumberPicker(
                value: value,
                minValue: min,
                maxValue: max,
                step: step,
                itemHeight: 48,
                axis: Axis.vertical,
                onChanged: (v) => setSheet(() => value = v),
                textStyle: AppTypography.titleM.copyWith(
                  color: AppColors.textMuted,
                ),
                selectedTextStyle: AppTypography.displayM.copyWith(
                  fontSize: 26,
                ),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.accentSecondary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(suffix, style: AppTypography.labelM),
              const SizedBox(height: AppTheme.spaceL),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, value),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spaceL,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm',
                    style: AppTypography.titleS.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<(int, int)?> _showHeightSheet({
    required int initialFeet,
    required int initialInches,
  }) {
    int feet = initialFeet.clamp(3, 7);
    int inches = initialInches.clamp(0, 11);
    return showModalBottomSheet<(int, int)>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetContainer(
        title: 'Height',
        child: StatefulBuilder(
          builder: (context, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NumberPicker(
                    value: feet,
                    minValue: 3,
                    maxValue: 7,
                    itemHeight: 48,
                    itemWidth: 64,
                    axis: Axis.vertical,
                    onChanged: (v) => setSheet(() => feet = v),
                    textStyle: AppTypography.titleM.copyWith(
                      color: AppColors.textMuted,
                    ),
                    selectedTextStyle: AppTypography.displayM.copyWith(
                      fontSize: 26,
                    ),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceS,
                    ),
                    child: Text('ft', style: AppTypography.labelM),
                  ),
                  NumberPicker(
                    value: inches,
                    minValue: 0,
                    maxValue: 11,
                    itemHeight: 48,
                    itemWidth: 64,
                    axis: Axis.vertical,
                    onChanged: (v) => setSheet(() => inches = v),
                    textStyle: AppTypography.titleM.copyWith(
                      color: AppColors.textMuted,
                    ),
                    selectedTextStyle: AppTypography.displayM.copyWith(
                      fontSize: 26,
                    ),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spaceS),
                    child: Text('in', style: AppTypography.labelM),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceL),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, (feet, inches)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spaceL,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm',
                    style: AppTypography.titleS.copyWith(color: Colors.white),
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

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — PROFILE (stateful text fields)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.usernameCtrl,
    required this.nameCtrl,
    required this.locationCtrl,
    required this.bioCtrl,
    required this.onChanged,
  });

  final TextEditingController usernameCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController bioCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "Let's set up your profile",
      subtitle:
          'Just a few details to personalize your experience and keep your '
          'stats accurate.',
      children: [
        AppFormField(
          icon: AppIcons.profile,
          label: 'Username',
          hint: 'e.g. sarah.walks',
          controller: usernameCtrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppTheme.spaceM),
        AppFormField(
          icon: AppIcons.profile,
          label: 'Name',
          hint: 'e.g. Sarah Abu-Ramadan',
          controller: nameCtrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppTheme.spaceM),
        AppFormField(
          icon: AppIcons.location,
          label: 'Location',
          optional: true,
          hint: 'e.g. Toronto, Canada',
          controller: locationCtrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppTheme.spaceM),
        AppFormField(
          icon: AppIcons.edit,
          label: 'Bio',
          optional: true,
          hint: 'Tell others a little about yourself',
          controller: bioCtrl,
          maxLines: 3,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED STEP WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spaceM),
          Text(
            title,
            style: AppTypography.titleL,
          ).animate().fadeIn(duration: AppTheme.animFast).slideY(begin: 0.1),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text(subtitle!, style: AppTypography.bodyM),
          ],
          const SizedBox(height: AppTheme.spaceXL),
          ...children,
          const SizedBox(height: AppTheme.spaceXXXL),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final done = (i ~/ 2) < current;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: done
                  ? AppColors.accent
                  : AppColors.accentSecondary.withValues(alpha: 0.30),
            ),
          );
        }
        final index = i ~/ 2;
        final active = index == current;
        final done = index < current;
        return AnimatedContainer(
          duration: AppTheme.animFast,
          width: active ? 12 : 10,
          height: active ? 12 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (active || done)
                ? AppColors.accent
                : AppColors.accentSecondary.withValues(alpha: 0.30),
          ),
        );
      }),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.optional = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceL,
          vertical: AppTheme.spaceM + 2,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: AppTheme.iconM),
            const SizedBox(width: AppTheme.spaceM),
            Text(label, style: AppTypography.bodyL),
            if (optional) ...[
              const SizedBox(width: AppTheme.spaceXS),
              Text('(Optional)', style: AppTypography.labelS),
            ],
            const Spacer(),
            Text(
              value,
              style: AppTypography.bodyM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceXS),
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppTheme.iconM,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: AppTheme.spaceL,
    endIndent: AppTheme.spaceL,
    color: AppColors.accentSecondary.withValues(alpha: 0.18),
  );
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final StrollaReason reason;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (reason) {
    StrollaReason.strollerWagon => AppIcons.stroller,
    StrollaReason.walkingPad => AppIcons.walk,
    StrollaReason.cantWearWearable => AppIcons.work,
    StrollaReason.accurateTracking => AppIcons.steps,
    StrollaReason.other => AppIcons.more,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.06)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.accentSecondary.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: AppTheme.animFast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                color: selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.accent
                      : AppColors.accentSecondary.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      AppIcons.check,
                      color: Colors.white,
                      size: AppTheme.iconXS,
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spaceM),
            Icon(_icon, color: AppColors.accent, size: AppTheme.iconM),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reason.title, style: AppTypography.bodyL),
                  if (reason.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(reason.subtitle!, style: AppTypography.bodyS),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.value, required this.onChanged});

  final UnitSystem value;
  final ValueChanged<UnitSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.accentSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          _segment('Metric (km, kg, cm)', UnitSystem.metric),
          _segment('Imperial (mi, lb, ft)', UnitSystem.imperial),
        ],
      ),
    );
  }

  Widget _segment(String label, UnitSystem unit) {
    final active = value == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(unit),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelM.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          AppIcons.info,
          color: AppColors.textMuted,
          size: AppTheme.iconXS + 2,
        ),
        const SizedBox(width: AppTheme.spaceS),
        Expanded(child: Text(text, style: AppTypography.labelS)),
      ],
    );
  }
}

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spaceM),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceL,
          AppTheme.spaceM,
          AppTheme.spaceL,
          AppTheme.spaceL,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(title, style: AppTypography.titleM),
            const SizedBox(height: AppTheme.spaceM),
            child,
          ],
        ),
      ),
    );
  }
}
