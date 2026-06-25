import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/domain/entities/app_notification.dart';
import 'package:strola_health/presentation/providers/navigation_providers.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/skeleton_loaders.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _routeTabIndex = {
    'home': 0,
    'stats': 1,
    'community': 2,
    'challenges': 3,
  };

  void _onTileTap(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(notificationsProvider.notifier).markRead(n.id);
    final tabIndex = _routeTabIndex[n.routeTarget];
    if (tabIndex != null) {
      ref.read(mainTabIndexProvider.notifier).state = tabIndex;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(AppIcons.back,
                color: AppColors.textPrimary, size: AppTheme.iconM),
          ),
          title: Text('Notifications', style: AppTypography.titleM),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.accentSecondary.withValues(alpha: 0.15),
            ),
          ),
        ),
        body: notificationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.screenPaddingH,
              AppTheme.spaceL,
              AppTheme.screenPaddingH,
              0,
            ),
            child: NotificationListSkeleton(),
          ),
          error: (_, __) => const Center(
            child: Text('Could not load notifications.', style: AppTypography.bodyM),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceXXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.notifications,
                        size: AppTheme.iconXXL,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        "You're all caught up",
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final sections = _groupByDay(notifications);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPaddingH,
                AppTheme.spaceL,
                AppTheme.screenPaddingH,
                AppTheme.spaceXXL,
              ),
              children: [
                for (final section in sections) ...[
                  _SectionHeader(label: section.label),
                  for (final n in section.notifications) ...[
                    _NotificationTile(
                      notification: n,
                      onTap: () => _onTileTap(context, ref, n),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                  ],
                  const SizedBox(height: AppTheme.spaceM),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<_DaySection> _groupByDay(List<AppNotification> notifications) {
    final sections = <String, List<AppNotification>>{};
    for (final n in notifications) {
      sections.putIfAbsent(Formatters.dayLabel(n.timestamp), () => []).add(n);
    }
    return sections.entries
        .map((e) => _DaySection(label: e.key, notifications: e.value))
        .toList();
  }
}

class _DaySection {
  const _DaySection({required this.label, required this.notifications});
  final String label;
  final List<AppNotification> notifications;
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spaceXS,
        bottom: AppTheme.spaceS,
      ),
      child: Text(label, style: AppTypography.labelM),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconBg = isUnread
        ? AppColors.accent.withValues(alpha: 0.09)
        : AppColors.accentSecondary.withValues(alpha: 0.09);
    final iconColor = isUnread ? AppColors.accent : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: FlatCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceL,
          vertical: AppTheme.spaceM,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                notification.category.icon,
                color: iconColor,
                size: AppTheme.iconS,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.titleS.copyWith(
                      color: isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: AppTypography.bodyS,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(timeago.format(notification.timestamp), style: AppTypography.labelS),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: AppTheme.spaceS),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppTheme.animSlow).slideY(begin: 0.06);
  }
}
