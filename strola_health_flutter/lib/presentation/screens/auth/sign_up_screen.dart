import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/widgets/form_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your email and password to continue.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = "Those passwords don't match — give it another try.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (ref.read(firebaseAvailableProvider)) {
        await ref.read(authServiceProvider).signUp(
              email: _emailCtrl.text,
              password: _passwordCtrl.text,
            );
      } else {
        // No backend yet — there's no account being created for real, so
        // this just demonstrates the flow rather than registering anything.
        await ref.read(localSignedInProvider.notifier).signIn();
      }
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.screenPaddingH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spaceL),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      AppIcons.back,
                      color: AppColors.textPrimary,
                      size: AppTheme.iconM,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Text('Create your account', style: AppTypography.titleL.copyWith(fontSize: 28))
                    .animate()
                    .fadeIn(duration: AppTheme.animSlow),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  "We'll set up your profile right after this.",
                  style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 60.ms, duration: AppTheme.animSlow),
                const SizedBox(height: AppTheme.spaceXXL),
                AppFormField(
                  icon: AppIcons.email,
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppTheme.spaceM),
                AppFormField(
                  icon: AppIcons.password,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  suffixIcon: _obscure ? AppIcons.visibility : AppIcons.visibilityOff,
                  onSuffixTap: () => setState(() => _obscure = !_obscure),
                ),
                const SizedBox(height: AppTheme.spaceM),
                AppFormField(
                  icon: AppIcons.password,
                  label: 'Confirm Password',
                  hint: 'Type it again',
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    _error!,
                    style: AppTypography.bodyS.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceL),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.accentSecondary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: AppTypography.titleS.copyWith(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
