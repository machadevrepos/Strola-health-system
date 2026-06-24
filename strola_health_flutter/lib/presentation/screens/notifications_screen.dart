import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPaddingH,
            AppTheme.spaceL,
            AppTheme.screenPaddingH,
            AppTheme.spaceXXL,
          ),
          children: const [
            _SectionHeader(label: 'Today'),
            _NotificationTile(
              type: _NotifType.connectionRequest,
              title: 'New connection request',
              body: 'Sophie Walker wants to connect with you.',
              time: '2 min ago',
              isUnread: true,
              delay: 60,
            ),
            SizedBox(height: AppTheme.spaceS),
            _NotificationTile(
              type: _NotifType.like,
              title: 'Emily liked your post',
              body: '"Just completed my morning 5K — feeling great! 🌸"',
              time: '18 min ago',
              isUnread: true,
              delay: 120,
            ),
            SizedBox(height: AppTheme.spaceS),
            _NotificationTile(
              type: _NotifType.comment,
              title: 'Jake commented on your post',
              body: '"Amazing effort, keep it up! 💪"',
              time: '45 min ago',
              isUnread: true,
              delay: 180,
            ),
            SizedBox(height: AppTheme.spaceXL),
            _SectionHeader(label: 'Yesterday'),
            _NotificationTile(
              type: _NotifType.like,
              title: 'Priya and 3 others liked your post',
              body: '"Hit 10,000 steps for the 5th day in a row! 🔥"',
              time: '1 day ago',
              isUnread: false,
              delay: 240,
            ),
            SizedBox(height: AppTheme.spaceS),
            _NotificationTile(
              type: _NotifType.comment,
              title: 'Mia commented on your post',
              body: 'You\'re an inspiration! How do you stay motivated?',
              time: '1 day ago',
              isUnread: false,
              delay: 280,
            ),
            SizedBox(height: AppTheme.spaceS),
            _NotificationTile(
              type: _NotifType.connectionRequest,
              title: 'New connection request',
              body: 'Hannah Mills wants to connect with you.',
              time: '1 day ago',
              isUnread: false,
              delay: 320,
            ),
          ],
        ),
      ),
    );
  }
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

enum _NotifType { connectionRequest, like, comment }

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.delay,
  });

  final _NotifType type;
  final String title;
  final String body;
  final String time;
  final bool isUnread;
  final int delay;

  IconData get _icon {
    switch (type) {
      case _NotifType.connectionRequest:
        return AppIcons.people;
      case _NotifType.like:
        return AppIcons.like;
      case _NotifType.comment:
        return AppIcons.comment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconBg = isUnread
        ? AppColors.accent.withValues(alpha: 0.09)
        : AppColors.accentSecondary.withValues(alpha: 0.09);
    final iconColor =
        isUnread ? AppColors.accent : AppColors.textSecondary;

    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: iconColor, size: AppTheme.iconS),
          ),
          const SizedBox(width: AppTheme.spaceM),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleS.copyWith(
                    color: isUnread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppTypography.bodyS,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(time, style: AppTypography.labelS),
              ],
            ),
          ),

          // Unread dot
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
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: AppTheme.animSlow)
        .slideY(begin: 0.06);
  }
}
