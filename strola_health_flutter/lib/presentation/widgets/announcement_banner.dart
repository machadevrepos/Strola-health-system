import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/push_routing.dart';
import 'package:strola_health/data/repositories/announcement_repository.dart';
import 'package:strola_health/presentation/providers/navigation_providers.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

/// Real Firestore-backed announcement banner (`announcements` collection,
/// admin-authored). Renders nothing when there's no active/matching,
/// not-yet-dismissed announcement — a real empty state, not a placeholder.
///
/// `link_target` uses the same tab mapping push notifications do
/// (push_routing.dart) — tapping the message content (not the dismiss X)
/// switches MainShell to that tab and reports a "clicked" event. No target
/// means the banner stays dismiss-only, same as before.
class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(activeAnnouncementProvider);

    return announcementAsync.maybeWhen(
      data: (announcement) {
        if (announcement == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPaddingH,
            0,
            AppTheme.screenPaddingH,
            AppTheme.spaceM,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceL,
              vertical: AppTheme.spaceM,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: AppColors.accentSecondary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcement.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: announcement.linkTarget == null
                        ? null
                        : () {
                            final tabIndex = tabIndexForLinkTarget(
                              announcement.linkTarget,
                            );
                            ref
                                .read(announcementRepositoryProvider)
                                .trackClicked(announcement.id);
                            if (tabIndex != null) {
                              ref.read(mainTabIndexProvider.notifier).state =
                                  tabIndex;
                            }
                          },
                    child: Text(
                      announcement.message,
                      style: AppTypography.bodyS.copyWith(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                PressableScale(
                  onTap: () => ref
                      .read(announcementRepositoryProvider)
                      .dismiss(announcement.id)
                      .then((_) => ref.invalidate(activeAnnouncementProvider)),
                  child: const Icon(
                    AppIcons.close,
                    color: AppColors.textMuted,
                    size: AppTheme.iconS,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: AppTheme.animSlow).slideY(begin: 0.1),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
