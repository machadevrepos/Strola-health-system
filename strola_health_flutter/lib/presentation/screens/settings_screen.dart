import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/account_service.dart';
import 'package:strola_health/domain/entities/user_profile.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart'
    show AuthException;
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/screens/integrations_screen.dart';
import 'package:strola_health/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:strola_health/presentation/screens/paywall_screen.dart';
import 'package:strola_health/presentation/providers/purchase_providers.dart';
import 'package:strola_health/presentation/widgets/add_widget_sheet.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(userProfileProvider).units;
    final unitsLabel = units == UnitSystem.metric
        ? 'Metric (km, kg, cm)'
        : 'Imperial (mi, lb, ft)';
    final isPremium = ref.watch(isPremiumProvider);

    void push(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return _SettingsScaffold(
      title: 'Settings',
      children: [
        _SectionLabel('Account'),
        _SectionCard(
          delay: 60,
          rows: [
            _SettingsRow(
              icon: AppIcons.premium,
              title: 'Strolla Premium',
              trailingValue: isPremium ? 'Active' : 'Upgrade',
              onTap: () => push(const PaywallScreen()),
            ),
            _SettingsRow(
              icon: AppIcons.profile,
              title: 'Edit Profile',
              onTap: () => push(const OnboardingScreen(isEditing: true)),
            ),
            _SettingsRow(
              icon: AppIcons.password,
              title: 'Change Password',
              onTap: () => push(const ChangePasswordPage()),
            ),
            _SettingsRow(
              icon: AppIcons.notifications,
              title: 'Notification Settings',
              onTap: () => push(const NotificationSettingsPage()),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXL),

        _SectionLabel('Privacy'),
        _SectionCard(
          delay: 120,
          rows: [
            _SettingsRow(
              icon: AppIcons.privacy,
              title: 'Privacy Settings',
              onTap: () => push(const PrivacySettingsPage()),
            ),
            _SettingsRow(
              icon: AppIcons.block,
              title: 'Blocked Users',
              onTap: () => push(const BlockedUsersPage()),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXL),

        _SectionLabel('Preferences'),
        _SectionCard(
          delay: 180,
          rows: [
            _SettingsRow(
              icon: AppIcons.units,
              title: 'Units',
              trailingValue: unitsLabel,
              onTap: () => push(const UnitsPage()),
            ),
            _SettingsRow(
              icon: AppIcons.widget,
              title: 'Add Home Screen Widget',
              onTap: () => showAddWidgetSheet(context),
            ),
            _SettingsRow(
              icon: AppIcons.connectedApps,
              title: 'Connected Apps',
              onTap: () => push(const IntegrationsScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXL),

        _SectionLabel('Support'),
        _SectionCard(
          delay: 240,
          rows: [
            _SettingsRow(
              icon: AppIcons.comment,
              title: 'Contact Us',
              onTap: () => push(const ContactUsPage()),
            ),
            _SettingsRow(
              icon: AppIcons.document,
              title: 'Terms of Service',
              onTap: () => push(
                const LegalPage(title: 'Terms of Service', body: _kTermsBody),
              ),
            ),
            _SettingsRow(
              icon: AppIcons.shield,
              title: 'Privacy Policy',
              onTap: () => push(
                const LegalPage(title: 'Privacy Policy', body: _kPrivacyBody),
              ),
            ),
            _SettingsRow(
              icon: AppIcons.groups,
              title: 'Community Guidelines',
              onTap: () => push(
                const LegalPage(
                  title: 'Community Guidelines',
                  body: _kCommunityGuidelinesBody,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXXL),

        // Log out
        GestureDetector(
          onTap: () => _confirmLogout(context, ref),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Text(
              'Log Out',
              textAlign: TextAlign.center,
              style: AppTypography.titleS.copyWith(color: AppColors.error),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: AppTheme.spaceM),
        Center(
          child: GestureDetector(
            onTap: () => _confirmDeleteAccount(context, ref),
            child: Text(
              'Delete Account',
              style: AppTypography.bodyM.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 330.ms),

        const SizedBox(height: AppTheme.spaceL),
        Center(
          child: Text('Strolla Health 1.0.0', style: AppTypography.labelS),
        ),
        const SizedBox(height: AppTheme.spaceXXXL),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: AppTypography.titleM),
        content: Text(
          "This clears your profile, weight, goal, streaks, and workout "
          "history from this device — there's no backend yet to restore "
          "them from, so this can't be undone.",
          style: AppTypography.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.titleS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              Navigator.of(context).popUntil((r) => r.isFirst);
              await signOutAndWipeLocalData(ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Log Out',
              style: AppTypography.bodyM.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: AppTypography.titleM),
        content: Text(
          'This permanently deletes your account and erases your profile, '
          "weight, goal, streaks, and workout history from this device. "
          "This can't be undone.",
          style: AppTypography.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.titleS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await deleteAccountAndWipeData(ref);
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              } on AuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete Account',
              style: AppTypography.bodyM.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED SCAFFOLD + ROWS
// ═════════════════════════════════════════════════════════════════════════════

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              AppIcons.back,
              color: AppColors.textPrimary,
              size: AppTheme.iconM,
            ),
          ),
          title: Text(title, style: AppTypography.titleM),
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPaddingH,
            AppTheme.spaceL,
            AppTheme.screenPaddingH,
            0,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.rows, this.delay = 0});

  final List<Widget> rows;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            indent: AppTheme.spaceL + 30,
            endIndent: AppTheme.spaceL,
            color: AppColors.accentSecondary.withValues(alpha: 0.16),
          ),
        );
      }
    }
    return FlatCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.05);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingValue,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceL,
          vertical: AppTheme.spaceL,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: AppTheme.iconM),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(child: Text(title, style: AppTypography.bodyL)),
            if (trailingValue != null)
              Padding(
                padding: const EdgeInsets.only(right: AppTheme.spaceS),
                child: Text(trailingValue!, style: AppTypography.labelM),
              ),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyL),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodyS),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accent,
            activeThumbColor: Colors.white,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.accentSecondary.withValues(
              alpha: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD
// ═════════════════════════════════════════════════════════════════════════════

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_next.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = "New passwords don't match.");
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password updated.'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Change Password',
      children: [
        _PasswordField(label: 'Current Password', controller: _current),
        const SizedBox(height: AppTheme.spaceM),
        _PasswordField(label: 'New Password', controller: _next),
        const SizedBox(height: AppTheme.spaceM),
        _PasswordField(label: 'Confirm New Password', controller: _confirm),
        if (_error != null) ...[
          const SizedBox(height: AppTheme.spaceM),
          Text(
            _error!,
            style: AppTypography.bodyS.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppTheme.spaceXL),
        _PrimaryButton(label: 'Update Password', onTap: _submit),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTypography.bodyM.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgSurface,
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? AppIcons.visibilityOff : AppIcons.visibility,
            color: AppColors.textMuted,
            size: AppTheme.iconM,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(
            color: AppColors.accentSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS
// ═════════════════════════════════════════════════════════════════════════════

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _push = true;
  bool _milestones = true;
  bool _friends = true;
  bool _challenges = true;
  bool _comments = true;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Notification Settings',
      children: [
        FlatCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ToggleRow(
                title: 'Push Notifications',
                subtitle: 'Allow Strolla to send you push alerts',
                value: _push,
                onChanged: (v) => setState(() => _push = v),
              ),
              _div(),
              _ToggleRow(
                title: 'Milestone Alerts',
                subtitle: 'When you reach various milestones in your steps.',
                value: _milestones,
                onChanged: (v) => setState(() => _milestones = v),
              ),
              _div(),
              _ToggleRow(
                title: 'Friends Activity',
                subtitle: 'When friends reach their milestones',
                value: _friends,
                onChanged: (v) => setState(() => _friends = v),
              ),
              _div(),
              _ToggleRow(
                title: 'Challenge Updates',
                subtitle: 'Leaderboard changes and deadlines',
                value: _challenges,
                onChanged: (v) => setState(() => _challenges = v),
              ),
              _div(),
              _ToggleRow(
                title: 'Likes & Comments',
                subtitle: 'When people interact with your posts',
                value: _comments,
                onChanged: (v) => setState(() => _comments = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRIVACY SETTINGS  (incl. hide activity data / achievements / recent activity)
// ═════════════════════════════════════════════════════════════════════════════

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(privacySettingsProvider);
    final notifier = ref.read(privacySettingsProvider.notifier);

    return _SettingsScaffold(
      title: 'Privacy Settings',
      children: [
        _SectionLabel('Visibility'),
        FlatCard(
          padding: EdgeInsets.zero,
          child: _ToggleRow(
            title: 'Public Profile',
            subtitle: 'Anyone can view your activity, achievements, and badges',
            value: p.publicProfile,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(publicProfile: v)),
          ),
        ),
        const SizedBox(height: AppTheme.spaceXL),
        _SectionLabel('Hide from your profile'),
        FlatCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ToggleRow(
                title: 'Hide Activity Data',
                subtitle: "Don't show steps, distance and calories",
                value: p.hideActivityData,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(hideActivityData: v)),
              ),
              _div(),
              _ToggleRow(
                title: 'Hide Achievements',
                subtitle: "Don't show your earned badges",
                value: p.hideAchievements,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(hideAchievements: v)),
              ),
              _div(),
              _ToggleRow(
                title: 'Hide Recent Activity',
                subtitle: "Don't show your recent steps and challenges",
                value: p.hideRecentActivity,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(hideRecentActivity: v)),
              ),
              _div(),
              _ToggleRow(
                title: 'Hide Location',
                subtitle: "Don't show your location",
                value: p.hideLocation,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(hideLocation: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS),
          child: Text(
            'These control what other people see when they open your profile.',
            style: AppTypography.labelS,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXXXL),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BLOCKED USERS
// ═════════════════════════════════════════════════════════════════════════════

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider).toList();

    return _SettingsScaffold(
      title: 'Blocked Users',
      children: [
        if (blocked.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spaceXXXL),
            child: Column(
              children: [
                Icon(
                  AppIcons.block,
                  color: AppColors.textMuted,
                  size: AppTheme.iconXXL,
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text('No blocked users', style: AppTypography.titleS),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  "People you block can't see your profile or posts, "
                  'and you won\'t see theirs.',
                  style: AppTypography.bodyS,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          FlatCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < blocked.length; i++) ...[
                  if (i != 0)
                    Divider(
                      height: 1,
                      indent: AppTheme.spaceL + 46,
                      color: AppColors.accentSecondary.withValues(alpha: 0.16),
                    ),
                  _BlockedTile(name: blocked[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSecondary.withValues(alpha: 0.22),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(child: Text(name, style: AppTypography.bodyL)),
          GestureDetector(
            onTap: () => ref.read(blockedUsersProvider.notifier).unblock(name),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM,
                vertical: AppTheme.spaceS,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Unblock',
                style: AppTypography.labelM.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UNITS
// ═════════════════════════════════════════════════════════════════════════════

class UnitsPage extends ConsumerWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(userProfileProvider).units;

    Widget option(UnitSystem unit, String title, String subtitle) {
      final selected = unit == current;
      return GestureDetector(
        onTap: () => ref
            .read(userProfileProvider.notifier)
            .update((p) => p.copyWith(units: unit)),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceL,
            vertical: AppTheme.spaceL,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyL),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodyS),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  AppIcons.goalReached,
                  color: AppColors.accent,
                  size: AppTheme.iconM,
                ),
            ],
          ),
        ),
      );
    }

    return _SettingsScaffold(
      title: 'Units',
      children: [
        FlatCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              option(UnitSystem.metric, 'Metric', 'Kilometres, kilograms, cm'),
              _div(),
              option(UnitSystem.imperial, 'Imperial', 'Miles, pounds, feet'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CONTACT US
// ═════════════════════════════════════════════════════════════════════════════

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Contact Us',
      children: [
        Text(
          "We'd love to hear from you. Reach the Strolla team anytime — "
          'questions, feedback, or just to say hello. 🌸',
          style: AppTypography.bodyM,
        ),
        const SizedBox(height: AppTheme.spaceL),
        FlatCard(
          padding: EdgeInsets.zero,
          child: _ContactRow(
            icon: AppIcons.email,
            title: 'Email us',
            value: 'info@strollahealth.com',
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: AppTheme.iconM),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyL),
                Text(value, style: AppTypography.bodyS),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LEGAL  (Terms / Privacy Policy)
// ═════════════════════════════════════════════════════════════════════════════

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: title,
      children: [
        FlatCard(
          child: Text(body, style: AppTypography.bodyM.copyWith(height: 1.6)),
        ),
        const SizedBox(height: AppTheme.spaceL),
        Center(
          child: Text('Last updated: June 2026', style: AppTypography.labelS),
        ),
        const SizedBox(height: AppTheme.spaceXXXL),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═════════════════════════════════════════════════════════════════════════════

Widget _div() => Divider(
  height: 1,
  indent: AppTheme.spaceL,
  endIndent: AppTheme.spaceL,
  color: AppColors.accentSecondary.withValues(alpha: 0.16),
);

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
          elevation: 0,
        ),
        child: Text(
          label,
          style: AppTypography.titleS.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

const String _kTermsBody =
    'Welcome to Strolla Health. By using this app you agree to use it for '
    'personal, non-commercial fitness tracking.\n\n'
    'Strolla provides step, distance and calorie estimates for informational '
    'purposes only and is not a medical device. Always consult a healthcare '
    'professional before making significant changes to your activity levels.\n\n'
    'You are responsible for keeping your account details secure and for the '
    'content you share in the community. Be kind and respectful to others.\n\n'
    'We may update these terms from time to time. Continued use of the app '
    'after changes means you accept the updated terms.';

const String _kPrivacyBody =
    'Your privacy matters to us. Strolla Health stores your profile and '
    'activity data on your device and, where you opt in, syncs it to power '
    'community and challenge features.\n\n'
    'We never sell your personal data. Activity you choose to share in the '
    'community is visible to other members according to your privacy settings.\n\n'
    'You can hide your activity data, achievements and recent activity from your '
    'profile at any time under Settings → Privacy Settings.\n\n'
    'You can delete your account and associated data at any time from Settings, '
    'or by contacting info@strollahealth.com.';

const String _kCommunityGuidelinesBody =
    "Strolla's community exists to encourage and celebrate every step of "
    "someone's journey — keep that spirit in everything you post.\n\n"
    'Be kind and supportive. Comments and posts should build people up, not '
    'tear them down. Constructive encouragement only — no shaming anyone for '
    "their pace, weight, or how far they've come.\n\n"
    "Be honest. Don't fabricate steps, distances, or achievements. "
    "Misrepresenting your activity undermines challenges and leaderboards "
    'for everyone else.\n\n'
    'Respect privacy. Only share photos and details about yourself — not '
    "other people, without their consent.\n\n"
    'No harassment, hate speech, or bullying of any kind. No spam, scams, '
    'or promotional content unrelated to fitness and wellbeing.\n\n'
    "This isn't medical advice. Strolla is a peer community, not a "
    'substitute for professional medical guidance.\n\n'
    "We may remove content or restrict accounts that don't follow these "
    'guidelines, to keep this a safe space for everyone.';
