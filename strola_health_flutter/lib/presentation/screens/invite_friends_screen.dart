import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  static const _inviteLink = 'strolla.app/invite/AMARA-WK24';

  static const _contacts = [
    _Contact('Olivia Bennett', 'olivia.b'),
    _Contact('Grace Thompson', 'grace.t'),
    _Contact('Mia Patel', 'mia.patel'),
    _Contact('Lucy Edwards', 'lucy.e'),
    _Contact('Sophie Clarke', 'sophie.c'),
    _Contact('Hannah Wright', 'hannah.w'),
  ];

  final Set<String> _invited = {};

  void _copyLink() {
    HapticFeedback.selectionClick();
    Clipboard.setData(const ClipboardData(text: _inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite link copied'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  void _invite(String username) {
    HapticFeedback.selectionClick();
    setState(() => _invited.add(username));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite sent'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                    // Invite link card
                    FlatCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    AppIcons.link,
                                    color: AppColors.accent,
                                    size: AppTheme.iconS,
                                  ),
                                  const SizedBox(width: AppTheme.spaceS),
                                  Text(
                                    'Your invite link',
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
                                        _inviteLink,
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
                                  onPressed: _copyLink,
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
                                        AppIcons.share,
                                        color: Colors.white,
                                        size: AppTheme.iconS,
                                      ),
                                      const SizedBox(width: AppTheme.spaceS),
                                      Text(
                                        'Copy Invite Link',
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

                    const SizedBox(height: AppTheme.spaceXXL),
                    Text('Suggested contacts', style: AppTypography.titleS),
                    const SizedBox(height: AppTheme.spaceM),

                    ..._contacts.asMap().entries.map((e) {
                      final contact = e.value;
                      final invited = _invited.contains(contact.username);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                        child:
                            FlatCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spaceM,
                                    vertical: AppTheme.spaceM,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: AppTheme.statChipCircleSize,
                                        height: AppTheme.statChipCircleSize,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentSecondary
                                              .withValues(alpha: 0.25),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.accentSecondary
                                                .withValues(alpha: 0.4),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            contact.name[0],
                                            style: AppTypography.titleM
                                                .copyWith(
                                                  color: AppColors.accent,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceM),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              contact.name,
                                              style: AppTypography.titleS,
                                            ),
                                            const SizedBox(
                                              height: AppTheme.spaceXS / 2,
                                            ),
                                            Text(
                                              '@${contact.username}',
                                              style: AppTypography.labelS,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceS),
                                      PressableScale(
                                        onTap: invited
                                            ? null
                                            : () => _invite(contact.username),
                                        child: AnimatedContainer(
                                          duration: AppTheme.animFast,
                                          curve: Curves.easeOut,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.spaceL,
                                            vertical: AppTheme.spaceS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: invited
                                                ? AppColors.accentSecondary
                                                      .withValues(alpha: 0.25)
                                                : AppColors.accent,
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusFull,
                                            ),
                                          ),
                                          child: Text(
                                            invited ? 'Invited' : 'Invite',
                                            style: AppTypography.labelM
                                                .copyWith(
                                                  color: invited
                                                      ? AppColors.textSecondary
                                                      : Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(
                                  delay: Duration(milliseconds: 60 * e.key),
                                )
                                .fadeIn(duration: AppTheme.animSlow)
                                .slideY(begin: 0.12),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contact {
  const _Contact(this.name, this.username);

  final String name;
  final String username;
}
