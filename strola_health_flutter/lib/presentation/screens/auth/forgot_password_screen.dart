import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/form_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email to continue.');
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
            .sendPasswordResetEmail(_emailCtrl.text);
      }
      // No backend yet — nothing is actually sent, but the confirmation
      // screen still shows so the flow is demoable end-to-end.
      setState(() => _sent = true);
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
              // anchors to the top regardless of how tall the content is.
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
                                      child: _sent
                                          ? _SentConfirmation(
                                              email: _emailCtrl.text,
                                            )
                                          : _ResetForm(
                                              emailCtrl: _emailCtrl,
                                              loading: _loading,
                                              error: _error,
                                              onSubmit: _submit,
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

class _ResetForm extends StatelessWidget {
  const _ResetForm({
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset your password',
          style: AppTypography.titleL.copyWith(fontSize: 26),
        ).animate().fadeIn(duration: AppTheme.animSlow),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          "Enter your email and we'll send you a link to reset it.",
          style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(delay: 60.ms, duration: AppTheme.animSlow),
        const SizedBox(height: AppTheme.spaceXXL),
        AppFormField(
          icon: AppIcons.email,
          label: 'Email',
          hint: 'you@example.com',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        if (error != null) ...[
          const SizedBox(height: AppTheme.spaceM),
          Text(
            error!,
            style: AppTypography.bodyS.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppTheme.spaceL),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.accentSecondary.withValues(
                alpha: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Send Reset Link',
                    style: AppTypography.titleS.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check your email',
          style: AppTypography.titleL.copyWith(fontSize: 24),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          "We've sent a password reset link to $email. "
          "Follow the link there to choose a new password.",
          style: AppTypography.bodyM.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppTheme.animSlow);
  }
}
