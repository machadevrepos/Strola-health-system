import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

/// No backend supports a generic app-invite link (there's only a private
/// challenge invite-code system, which is unrelated) and there's no address
/// book integration, so this screen shares a static, honest promo message —
/// personalized with the caller's own real display name where available —
/// rather than a fabricated per-user tracking code or a fake contacts list.
class InviteFriendsScreen extends ConsumerWidget {
  const InviteFriendsScreen({super.key});

  static const _shareDomain = 'strollahealth.com';

  void _copyLink(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: _shareMessage(ref)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite message copied'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: false,
              leading: PressableScale(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  AppIcons.back,
                  color: AppColors.textPrimary,
                  size: AppTheme.iconM,
                ),
              ),
              title: Text('Invite Friends', style: AppTypography.titleM),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  0,
                  AppTheme.screenPaddingH,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Walk together, go further',
                      style: AppTypography.titleL,
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Invite your friends to Strolla and cheer each other on '
                      'with shared steps, streaks, and challenges.',
                      style: AppTypography.bodyS,
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Invite message card — there's no generic app-invite
                    // link or contacts integration on the backend, so this
                    // shares a static, honest promo message instead of a
                    // fabricated tracking code.
                    FlatCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    AppIcons.share,
                                    color: AppColors.accent,
                                    size: AppTheme.iconS,
                                  ),
                                  const SizedBox(width: AppTheme.spaceS),
                                  Text(
                                    'Your invite message',
                                    style: AppTypography.titleS,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceL,
                                  vertical: AppTheme.spaceM,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bgDeep,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                  border: Border.all(
                                    color: AppColors.accentSecondary.withValues(
                                      alpha: 0.30,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _shareMessage(ref),
                                        style: AppTypography.bodyS.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spaceS),
                                    const Icon(
                                      AppIcons.copy,
                                      color: AppColors.textMuted,
                                      size: AppTheme.iconS,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => _copyLink(context, ref),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusM,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppTheme.spaceL,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        AppIcons.copy,
                                        color: Colors.white,
                                        size: AppTheme.iconS,
                                      ),
                                      const SizedBox(width: AppTheme.spaceS),
                                      Text(
                                        'Copy Invite Message',
                                        style: AppTypography.bodyL.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 60.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Personalizes with the caller's own real name (local `userProfileProvider`
  /// — no backend fabrication) when it's set, otherwise a generic message.
  String _shareMessage(WidgetRef ref) {
    final name = ref.watch(userProfileProvider).name;
    return name.trim().isNotEmpty
        ? '$name invited you to join Strolla! Walk together, go further. '
              'Download the app at $_shareDomain'
        : 'Join me on Strolla! Walk together, go further. '
              'Download the app at $_shareDomain';
  }
}
