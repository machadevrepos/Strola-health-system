import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/account_service.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/screens/auth/forgot_password_screen.dart';
import 'package:strola_health/presentation/screens/auth/sign_up_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/form_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  late bool _rememberMe;

  @override
  void initState() {
    super.initState();
    // Seeded from the persisted value so the checkbox reflects the user's
    // last choice rather than always resetting to the default.
    _rememberMe = ref.read(rememberMeProvider);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your email and password to continue.');
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
            .signIn(email: _emailCtrl.text, password: _passwordCtrl.text);
        // Restores this account's real onboarding status (and the rest of
        // its profile) from the backend — without this, a returning user
        // whose local storage doesn't have it (different device, or a
        // previous logout wiped it) would incorrectly see onboarding again.
        await restoreProfileFromBackend(ref);
      } else {
        // No backend yet — there's no account to check against, so this
        // just demonstrates the flow rather than verifying credentials.
        await ref.read(localSignedInProvider.notifier).signIn();
      }
      // Persisted only once sign-in actually succeeds, not on every
      // checkbox tap — it should reflect the choice made for the session
      // that actually started.
      await ref.read(rememberMeProvider.notifier).set(_rememberMe);
      HapticsHelper.lightImpact();
      // No manual navigation — the root gate reacts to isSignedInProvider.
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Positioned independently of the card below — the wordmark
              // sits at a fixed 10% down the screen regardless of how tall
              // the card ends up, rather than the two pushing each other
              // around through shared column spacing.
              return Stack(
                children: [
                  Positioned(
                    top: constraints.maxHeight * 0.10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'strolla',
                        style: AppTypography.brand.copyWith(fontSize: 45),
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
                                padding: const EdgeInsets.all(AppTheme.spaceXL),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: AppTypography.titleL.copyWith(
                                        fontSize: 26,
                                      ),
                                    ).animate().fadeIn(
                                      duration: AppTheme.animSlow,
                                    ),
                                    const SizedBox(height: AppTheme.spaceXS),
                                    Text(
                                      'Sign in to pick up where you left off.',
                                      style: AppTypography.bodyM.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ).animate().fadeIn(
                                      delay: 60.ms,
                                      duration: AppTheme.animSlow,
                                    ),
                                    const SizedBox(height: AppTheme.spaceXL),
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
                                      hint: 'Your password',
                                      controller: _passwordCtrl,
                                      obscureText: _obscure,
                                      suffixIcon: _obscure
                                          ? AppIcons.visibility
                                          : AppIcons.visibilityOff,
                                      onSuffixTap: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    const SizedBox(height: AppTheme.spaceS),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => _rememberMe = !_rememberMe,
                                          ),
                                          behavior: HitTestBehavior.opaque,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AnimatedContainer(
                                                duration: AppTheme.animFast,
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppTheme.radiusXS,
                                                      ),
                                                  color: _rememberMe
                                                      ? AppColors.accent
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                    color: _rememberMe
                                                        ? AppColors.accent
                                                        : AppColors
                                                              .accentSecondary
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: _rememberMe
                                                    ? const Icon(
                                                        AppIcons.check,
                                                        color: Colors.white,
                                                        size: 12,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(
                                                width: AppTheme.spaceS,
                                              ),
                                              Text(
                                                'Remember me',
                                                style: AppTypography.bodyS
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ForgotPasswordScreen(),
                                            ),
                                          ),
                                          child: Text(
                                            'Forgot password?',
                                            style: AppTypography.bodyS.copyWith(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: AppTheme.spaceS),
                                      Text(
                                        _error!,
                                        style: AppTypography.bodyS.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppTheme.spaceL),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _loading ? null : _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.accent,
                                          disabledBackgroundColor: AppColors
                                              .accentSecondary
                                              .withValues(alpha: 0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusM,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
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
                                                'Sign In',
                                                style: AppTypography.titleS
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceL),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SignUpScreen(),
                                          ),
                                        ),
                                        child: Text.rich(
                                          TextSpan(
                                            text: "Don't have an account? ",
                                            style: AppTypography.bodyM.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Sign Up',
                                                style: AppTypography.bodyM
                                                    .copyWith(
                                                      color: AppColors.accent,
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
                              .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
