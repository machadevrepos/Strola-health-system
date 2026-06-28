import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/form_field.dart';

const _kMinPasswordLength = 8;

bool _hasMinLength(String v) => v.length >= _kMinPasswordLength;
bool _hasDigit(String v) => RegExp(r'\d').hasMatch(v);
bool _hasUppercase(String v) => RegExp(r'[A-Z]').hasMatch(v);
bool _hasSymbol(String v) =>
    RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/;`~]').hasMatch(v);

int _passwordScore(String v) => [
  _hasMinLength(v),
  _hasDigit(v),
  _hasUppercase(v),
  _hasSymbol(v),
].where((met) => met).length;

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Fill in every field to continue.');
      return;
    }
    if (_passwordScore(_passwordCtrl.text) < 4) {
      setState(
        () => _error = "Your password doesn't meet all the requirements yet.",
      );
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(
        () => _error = "Those passwords don't match — give it another try.",
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (ref.read(firebaseAvailableProvider)) {
        await ref
            .read(authServiceProvider)
            .signUp(email: _emailCtrl.text, password: _passwordCtrl.text);
      } else {
        // No backend yet — there's no account being created for real, so
        // this just demonstrates the flow rather than registering anything.
        await ref.read(localSignedInProvider.notifier).signIn();
      }
      // Carried into the local profile now so the onboarding wizard's own
      // username step (onboarding_screen.dart) opens pre-filled instead of
      // asking for the same thing twice.
      await ref
          .read(userProfileProvider.notifier)
          .update((p) => p.copyWith(username: _usernameCtrl.text.trim()));
      // A brand new account should always be remembered, even if this
      // device has a leftover `false` from a previous, different account
      // that unchecked it on sign-in.
      await ref.read(rememberMeProvider.notifier).set(true);
      HapticsHelper.lightImpact();
      // No manual navigation — the root gate reacts to isSignedInProvider and
      // carries the new (unauthenticated-profile) user into the existing
      // onboarding wizard next.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              // Kept outside the centered block below — a back button
              // anchors to the top regardless of how tall the form is.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceL,
                  AppTheme.screenPaddingH,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      AppIcons.back,
                      color: AppColors.textPrimary,
                      size: AppTheme.iconM,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Positioned independently of the card below — the
                    // wordmark sits at a fixed 10% down this remaining
                    // space regardless of how tall the card ends up.
                    return Stack(
                      children: [
                        Positioned(
                          top: constraints.maxHeight * 0.10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              'strolla',
                              style: AppTypography.brand.copyWith(
                                fontSize: 45,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.screenPaddingH,
                            ),
                            child:
                                FlatCard(
                                      padding: const EdgeInsets.all(
                                        AppTheme.spaceXL,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create your account',
                                            style: AppTypography.titleL
                                                .copyWith(fontSize: 26),
                                          ).animate().fadeIn(
                                            duration: AppTheme.animSlow,
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceXS,
                                          ),
                                          Text(
                                            "We'll set up your profile right after this.",
                                            style: AppTypography.bodyM.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ).animate().fadeIn(
                                            delay: 60.ms,
                                            duration: AppTheme.animSlow,
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceXL,
                                          ),
                                          AppFormField(
                                            icon: AppIcons.profile,
                                            label: 'Username',
                                            hint: 'e.g. sarah.walks',
                                            controller: _usernameCtrl,
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceM,
                                          ),
                                          AppFormField(
                                            icon: AppIcons.email,
                                            label: 'Email',
                                            hint: 'you@example.com',
                                            controller: _emailCtrl,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceM,
                                          ),
                                          AppFormField(
                                            icon: AppIcons.password,
                                            label: 'Password',
                                            hint: 'At least 8 characters',
                                            controller: _passwordCtrl,
                                            obscureText: _obscure,
                                            suffixIcon: _obscure
                                                ? AppIcons.visibility
                                                : AppIcons.visibilityOff,
                                            onSuffixTap: () => setState(
                                              () => _obscure = !_obscure,
                                            ),
                                            // Re-renders the strength bar/checklist
                                            // below on every keystroke.
                                            onChanged: (_) => setState(() {}),
                                          ),
                                          if (_passwordCtrl
                                              .text
                                              .isNotEmpty) ...[
                                            const SizedBox(
                                              height: AppTheme.spaceM,
                                            ),
                                            _PasswordStrength(
                                              password: _passwordCtrl.text,
                                            ),
                                          ],
                                          const SizedBox(
                                            height: AppTheme.spaceM,
                                          ),
                                          AppFormField(
                                            icon: AppIcons.password,
                                            label: 'Confirm Password',
                                            hint: 'Type it again',
                                            controller: _confirmCtrl,
                                            obscureText: _obscure,
                                            suffixIcon: _obscure
                                                ? AppIcons.visibility
                                                : AppIcons.visibilityOff,
                                            onSuffixTap: () => setState(
                                              () => _obscure = !_obscure,
                                            ),
                                          ),
                                          if (_error != null) ...[
                                            const SizedBox(
                                              height: AppTheme.spaceM,
                                            ),
                                            Text(
                                              _error!,
                                              style: AppTypography.bodyS
                                                  .copyWith(
                                                    color: AppColors.error,
                                                  ),
                                            ),
                                          ],
                                          const SizedBox(
                                            height: AppTheme.spaceL,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                              onPressed: _loading
                                                  ? null
                                                  : _submit,
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.accent,
                                                disabledBackgroundColor:
                                                    AppColors.accentSecondary
                                                        .withValues(alpha: 0.5),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppTheme.radiusM,
                                                      ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: AppTheme.spaceL,
                                                    ),
                                              ),
                                              child: _loading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation(
                                                              Colors.white,
                                                            ),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Sign Up',
                                                      style: AppTypography
                                                          .titleS
                                                          .copyWith(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceL,
                                          ),
                                          Center(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(context),
                                              child: Text.rich(
                                                TextSpan(
                                                  text:
                                                      'Already have an account? ',
                                                  style: AppTypography.bodyM
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Sign In',
                                                      style: AppTypography.bodyM
                                                          .copyWith(
                                                            color: AppColors
                                                                .accent,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: AppTheme.animSlow)
                                    .slideY(
                                      begin: 0.04,
                                      curve: Curves.easeOutCubic,
                                    ),
                          ),
                        ),
                      ],
                    );
                  },
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
// PASSWORD STRENGTH — segmented bar + the 4 requirements, ticking off live
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  static const _requirements = [
    ('At least 8 characters', _hasMinLength),
    ('One uppercase letter', _hasUppercase),
    ('One number', _hasDigit),
    ('One symbol', _hasSymbol),
  ];

  @override
  Widget build(BuildContext context) {
    final score = _passwordScore(password);
    final (barColor, label) = switch (score) {
      0 || 1 => (AppColors.error, 'Weak'),
      2 => (AppColors.goalAmber, 'Fair'),
      3 => (AppColors.goalAmber, 'Good'),
      _ => (AppColors.success, 'Strong'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _requirements.length; i++)
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < _requirements.length - 1 ? 4 : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < score
                        ? barColor
                        : AppColors.accentSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelS.copyWith(
            color: barColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Wrap(
          spacing: AppTheme.spaceM,
          runSpacing: 4,
          children: [
            for (final (label, check) in _requirements)
              _RequirementChip(label: label, met: check(password)),
          ],
        ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? AppIcons.goalReached : AppIcons.circleOutline,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelS.copyWith(color: color)),
      ],
    );
  }
}
