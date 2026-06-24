import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/domain/entities/community_post.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/find_friends_screen.dart';
import 'package:strola_health/presentation/screens/invite_friends_screen.dart';
import 'package:strola_health/presentation/screens/profile_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/header_actions.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';
import 'package:strola_health/presentation/widgets/report_sheet.dart';
import 'package:strola_health/presentation/widgets/skeleton_loaders.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _sortMode = 'Latest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPaddingH,
                AppTheme.spaceL,
                AppTheme.screenPaddingH,
                0,
              ),
              child: Row(
                children: [
                  Text(
                        'Community',
                        style: AppTypography.displayM.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppTheme.animSlow)
                      .slideX(begin: -0.1),
                  const Spacer(),
                  const HeaderActions().animate().fadeIn(
                    delay: 100.ms,
                    duration: AppTheme.animSlow,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.sectionGap),

            // ── Pill tab bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.screenPaddingH,
              ),
              child: FlatCard(
                padding: const EdgeInsets.all(AppTheme.spaceXS),
                borderRadius: 16,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: AppTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: AppTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Feed'),
                    Tab(text: 'Friends'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: AppTheme.animSlow),

            const SizedBox(height: AppTheme.spaceS),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _FeedTab(
                    sortMode: _sortMode,
                    onSortChanged: (s) => setState(() => _sortMode = s),
                  ),
                  const _FriendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (_, __) => _tabController.index == 0
              ? _NewPostFab()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ── Feed tab ──────────────────────────────────────────────────────────────────

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.sortMode, required this.onSortChanged});

  final String sortMode;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final blocked = ref.watch(blockedUsersProvider);

    return postsAsync.when(
      loading: () =>
          const Padding(padding: EdgeInsets.all(20), child: PostFeedSkeleton()),
      error: (_, __) => const Center(
        child: Text('Could not load posts.', style: AppTypography.bodyM),
      ),
      data: (allPosts) {
        final posts = allPosts
            .where((p) => !blocked.contains(p.authorName))
            .toList();
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Motivational banner + Invite Friends
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceXS,
                  AppTheme.screenPaddingH,
                  0,
                ),
                child: Column(
                  children: [
                    _MotivationBanner()
                        .animate()
                        .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),
                    const SizedBox(height: AppTheme.spaceM),
                  ],
                ),
              ),
            ),

            // Post composer teaser
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.screenPaddingH,
                ),
                child: _PostComposerTeaser()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: AppTheme.animSlow)
                    .slideY(begin: 0.12),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceM)),

            // Sort row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  0,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceS,
                ),
                child: Row(
                  children: [
                    Text(
                      'Community Feed',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    PressableScale(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: AppColors.accentSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              sortMode,
                              style: AppTypography.labelM.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceXS),
                            const Icon(
                              AppIcons.expandMore,
                              color: AppColors.textMuted,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Post list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _PostCard(post: posts[i], index: i),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDeep,
            AppColors.accentSecondary.withValues(alpha: 0.30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay motivated together',
                  style: AppTypography.titleM.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect with others, share your progress, '
                  'and achieve your goals together.',
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                PressableScale(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InviteFriendsScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceL,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.addFriend,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Invite Friends',
                          style: AppTypography.bodyS.copyWith(
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
          ),
          const SizedBox(width: AppTheme.spaceM),
          const _FriendsCluster(),
        ],
      ),
    );
  }
}

/// Decorative "friends together" motif on the motivation banner.
/// (Placeholder for a real illustration / Lottie asset.)
class _FriendsCluster extends StatelessWidget {
  const _FriendsCluster();

  @override
  Widget build(BuildContext context) {
    Widget avatar(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(AppIcons.profile, color: Colors.white, size: size * 0.55),
    );

    return SizedBox(
      width: 76,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 18,
            child: avatar(38, AppColors.accentSecondary),
          ),
          Positioned(right: 0, top: 18, child: avatar(38, AppColors.goalAmber)),
          Positioned(left: 19, top: 0, child: avatar(40, AppColors.accent)),
        ],
      ),
    );
  }
}

class _PostComposerTeaser extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.profile,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: PressableScale(
              onTap: () => _showNewPostSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "What's on your mind?",
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PressableScale(
            onTap: () => _showNewPostSheet(context, ref),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: const Icon(
                AppIcons.camera,
                color: AppColors.accent,
                size: AppTheme.iconS,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewPostSheet(
        onSubmit: (content, steps, imagePath) {
          ref
              .read(postsProvider.notifier)
              .createPost(content, stepCount: steps, imagePath: imagePath);
        },
        currentSteps: ref.read(stepCountProvider),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.index});

  final CommunityPost post;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = post.avatarColor != null
        ? Color(post.avatarColor!)
        : AppColors.accent;

    return FlatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PressableScale(
                    onTap: () => _openProfile(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          post.initials,
                          style: AppTypography.bodyM.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressableScale(
                      onTap: () => _openProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: AppTypography.bodyS.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (post.badgeEmoji != null) ...[
                                const SizedBox(width: AppTheme.spaceXS),
                                Text(
                                  post.badgeEmoji!,
                                  style: AppTypography.labelM.copyWith(
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                timeago.format(post.timestamp),
                                style: AppTypography.labelS.copyWith(
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceXS),
                              const Icon(
                                AppIcons.public,
                                color: AppColors.textMuted,
                                size: 11,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (post.stepCount != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceS,
                        vertical: AppTheme.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.steps,
                            color: AppColors.accent,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            Formatters.stepCount(post.stepCount!),
                            style: AppTypography.labelS.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  PressableScale(
                    onTap: () => _showPostMenu(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      AppIcons.more,
                      color: AppColors.textMuted,
                      size: AppTheme.iconM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.content,
                style: AppTypography.bodyM.copyWith(height: 1.4),
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: Image.file(
                    File(post.imageUrl!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  _ActionBtn(
                    icon: AppIcons.like,
                    label: '${post.likes}',
                    color: post.isLiked ? AppColors.error : AppColors.textMuted,
                    onTap: () {
                      HapticsHelper.lightImpact();
                      ref.read(postsProvider.notifier).likePost(post.id);
                    },
                  ),
                  const SizedBox(width: AppTheme.spaceL),
                  _ActionBtn(
                    icon: AppIcons.comment,
                    label: '${post.comments}',
                    color: AppColors.textMuted,
                    onTap: () {},
                  ),
                  const Spacer(),
                  _Reactors(count: post.likes),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: AppTheme.animSlow)
        .slideY(begin: 0.12, curve: Curves.easeOut);
  }

  void _openProfile(BuildContext context) {
    final handle = post.authorName.toLowerCase().replaceAll(' ', '.');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          name: post.authorName,
          username: handle,
          stepsToday: post.stepCount ?? 8240,
          distanceKm: (post.stepCount ?? 8240) * 0.000762,
          streak: 12,
        ),
      ),
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        void act(String message) {
          Navigator.pop(sheetCtx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(AppTheme.spaceL),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              ListTile(
                leading: const Icon(
                  AppIcons.bookmark,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  'Save post',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => act('Post saved'),
              ),
              ListTile(
                leading: const Icon(
                  AppIcons.link,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  'Copy link',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => act('Link copied'),
              ),
              ListTile(
                leading: const Icon(AppIcons.report, color: AppColors.error),
                title: Text(
                  'Report post',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showReportSheet(context, subject: 'this post');
                },
              ),
              const SizedBox(height: AppTheme.spaceM),
            ],
          ),
        );
      },
    );
  }
}

/// Overlapping reactor avatars + "+N" shown on the right of a post's action row.
class _Reactors extends StatelessWidget {
  const _Reactors({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.accent,
      AppColors.accentSecondary,
      AppColors.goalAmber,
    ];
    final extra = (count / 8).round().clamp(1, 999);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 22,
          child: Stack(
            children: List.generate(3, (i) {
              return Positioned(
                left: i * 12.0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    AppIcons.profile,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppTheme.spaceXS),
        Text(
          '+$extra',
          style: AppTypography.labelM.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppTheme.iconS),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            label,
            style: AppTypography.labelM.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Friends tab ───────────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  static const _friends = [
    _Friend('Sarah J.', 'Active now', true, 12842, '9.4 km', 24),
    _Friend('Alex M.', 'Active now', true, 10128, '7.8 km', 18),
    _Friend('Priya K.', '2h ago', false, 8732, '6.2 km', 15),
    _Friend('James L.', '5h ago', false, 7345, '5.6 km', 12),
    _Friend('Emily R.', '1d ago', false, 6214, '4.3 km', 10),
  ];

  static const _activity = [
    (
      'Alex M.',
      'achieved a new personal best',
      '15,892 steps in a day',
      AppIcons.steps,
      '2h ago',
    ),
    (
      'Sarah J.',
      'is on a 24 day streak!',
      'Keep it up!',
      AppIcons.streak,
      '3h ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPaddingH,
        AppTheme.spaceXS,
        AppTheme.screenPaddingH,
        120,
      ),
      children: [
        _FriendsBanner()
            .animate()
            .fadeIn(delay: 80.ms, duration: AppTheme.animSlow)
            .slideY(begin: 0.12),
        const SizedBox(height: AppTheme.spaceM),

        // Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppColors.accentSecondary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.search, color: AppColors.textMuted, size: 18),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  'Search friends',
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Icon(
                AppIcons.addFriend,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 120.ms, duration: AppTheme.animSlow),
        const SizedBox(height: AppTheme.spaceL),

        // Your Friends header
        Row(
          children: [
            Text(
              'Your Friends',
              style: AppTypography.bodyL.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Text(
              'Sort by: Most Active',
              style: AppTypography.labelS.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            const Icon(
              AppIcons.expandMore,
              color: AppColors.textMuted,
              size: AppTheme.iconXS,
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._friends.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FriendCard(friend: e.value)
                .animate(delay: Duration(milliseconds: 60 * e.key))
                .fadeIn(duration: AppTheme.animSlow)
                .slideY(begin: 0.12),
          ),
        ),

        const SizedBox(height: AppTheme.spaceS),

        // Friend Challenges
        Row(
          children: [
            Text(
              'Friend Challenges',
              style: AppTypography.bodyL.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            _viewAll(),
          ],
        ),
        const SizedBox(height: 10),
        const _FriendChallengeCard()
            .animate()
            .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.spaceXL),

        // Friend Activity
        Row(
          children: [
            Text(
              'Friend Activity',
              style: AppTypography.bodyL.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            _viewAll(),
          ],
        ),
        const SizedBox(height: 10),
        FlatCard(
              child: Column(
                children: [
                  for (var i = 0; i < _activity.length; i++) ...[
                    if (i != 0)
                      Divider(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        height: AppTheme.spaceXL,
                      ),
                    _FriendActivityRow(
                      name: _activity[i].$1,
                      action: _activity[i].$2,
                      detail: _activity[i].$3,
                      icon: _activity[i].$4,
                      time: _activity[i].$5,
                    ),
                  ],
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 150.ms, duration: AppTheme.animSlow)
            .slideY(begin: 0.12),
      ],
    );
  }

  static Widget _viewAll() => Text(
    'View All',
    style: AppTypography.labelM.copyWith(
      color: AppColors.accent,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
  );
}

class _Friend {
  const _Friend(
    this.name,
    this.status,
    this.online,
    this.steps,
    this.distance,
    this.streak,
  );

  final String name;
  final String status;
  final bool online;
  final int steps;
  final String distance;
  final int streak;
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final _Friend friend;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            name: friend.name,
            username: friend.name.toLowerCase().replaceAll(
              RegExp(r'[^a-z]'),
              '',
            ),
            stepsToday: friend.steps,
            distanceKm: double.tryParse(friend.distance.split(' ').first) ?? 0,
            streak: friend.streak,
            isConnected: true,
          ),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: FlatCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Avatar + status dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accentSecondary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentSecondary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      friend.name[0],
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (friend.online)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            // Name + status
            Expanded(
              flex: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    friend.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelS.copyWith(
                      color: friend.online
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: friend.online
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 26,
              child: _FriendStat(
                label: 'Steps (Today)',
                icon: AppIcons.steps,
                value: Formatters.stepCount(friend.steps),
              ),
            ),
            Expanded(
              flex: 24,
              child: _FriendStat(
                label: 'Distance (Today)',
                icon: AppIcons.location,
                value: friend.distance,
              ),
            ),
            // Streak
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.streak,
                      color: AppColors.accent,
                      size: 13,
                    ),
                    const SizedBox(width: 1),
                    Text(
                      '${friend.streak}',
                      style: AppTypography.labelM.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                Text(
                  'day streak',
                  style: AppTypography.labelS.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 2),
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppTheme.iconS,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendStat extends StatelessWidget {
  const _FriendStat({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelS.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 12),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FriendChallengeCard extends StatelessWidget {
  const _FriendChallengeCard();

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.challenge,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step Squad',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '7-day step challenge',
                      style: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '3 days left',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const _ChallengeMetric(label: 'Your Rank', value: '2 of 6'),
              const SizedBox(width: 14),
              const _ChallengeMetric(label: 'Total Steps', value: '68,432'),
              const SizedBox(width: 6),
              const Icon(
                AppIcons.chevronRight,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXS),
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 6,
              backgroundColor: AppColors.accentSecondary.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeMetric extends StatelessWidget {
  const _ChallengeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTypography.labelS.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.bodyS.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _FriendActivityRow extends StatelessWidget {
  const _FriendActivityRow({
    required this.name,
    required this.action,
    required this.detail,
    required this.icon,
    required this.time,
  });

  final String name;
  final String action;
  final String detail;
  final IconData icon;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: AppTheme.iconS),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyS,
                  children: [
                    TextSpan(
                      text: '$name ',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: action),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                detail,
                style: AppTypography.labelS.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spaceS),
        Text(
          time,
          style: AppTypography.labelS.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _FriendsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDeep,
            AppColors.accentSecondary.withValues(alpha: 0.30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay connected and\nreach your goals together',
                  style: AppTypography.titleM.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'See how your friends are doing and cheer each other on!',
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                PressableScale(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FindFriendsScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceL,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.addFriend,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add Friends',
                          style: AppTypography.bodyS.copyWith(
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
          ),
          const SizedBox(width: 10),
          const _FriendsCluster(),
        ],
      ),
    );
  }
}

// ── New post FAB + sheet ──────────────────────────────────────────────────────

class _NewPostFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _NewPostSheet(
              onSubmit: (content, steps, imagePath) {
                ref
                    .read(postsProvider.notifier)
                    .createPost(
                      content,
                      stepCount: steps,
                      imagePath: imagePath,
                    );
              },
              currentSteps: ref.read(stepCountProvider),
            ),
          ),
          backgroundColor: AppColors.accent,
          elevation: 0,
          icon: const Icon(AppIcons.edit, color: Colors.white, size: 18),
          label: Text(
            'Post',
            style: AppTypography.bodyM.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms)
        .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack);
  }
}

class _NewPostSheet extends StatefulWidget {
  const _NewPostSheet({required this.onSubmit, required this.currentSteps});

  final void Function(String content, int? steps, String? imagePath) onSubmit;
  final int currentSteps;

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _controller = TextEditingController();
  bool _shareSteps = true;
  bool _submitting = false;
  XFile? _imageFile;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _imageFile = picked);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.all(AppTheme.spaceL),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            ListTile(
              leading: const Icon(
                AppIcons.gallery,
                color: AppColors.textSecondary,
              ),
              title: Text(
                'Choose from gallery',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                AppIcons.camera,
                color: AppColors.textSecondary,
              ),
              title: Text(
                'Take a photo',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppTheme.spaceM),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    widget.onSubmit(
      _controller.text.trim(),
      _shareSteps ? widget.currentSteps : null,
      _imageFile?.path,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spaceM),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceXL,
              AppTheme.spaceL,
              AppTheme.spaceXL,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Post',
                  style: AppTypography.titleM.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                FlatCard(
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: 1000,
                    style: AppTypography.bodyL.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Share a win, challenge, question, or tip with the community…',
                      hintStyle: AppTypography.bodyL.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      counterStyle: AppTypography.labelM,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_imageFile!.path),
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: PressableScale(
                            onTap: () => setState(() => _imageFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spaceXS),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.close,
                                color: Colors.white,
                                size: AppTheme.iconS,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                    child: PressableScale(
                      onTap: _showImageSourceSheet,
                      child: FlatCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: AppTheme.spaceM,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.addPhoto,
                              color: AppColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: AppTheme.spaceS),
                            const Expanded(
                              child: Text(
                                'Add a photo',
                                style: AppTypography.bodyS,
                              ),
                            ),
                            const Icon(
                              AppIcons.chevronRight,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                FlatCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: AppTheme.spaceM,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.steps,
                        color: AppColors.accent,
                        size: AppTheme.iconS,
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                      Expanded(
                        child: Text(
                          'Share today\'s step count (${Formatters.stepCount(widget.currentSteps)})',
                          style: AppTypography.bodyS,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: _shareSteps,
                          onChanged: (v) => setState(() => _shareSteps = v),
                          activeTrackColor: AppColors.accent,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _submitting ? 'Posting...' : 'Post to Community',
                      style: AppTypography.bodyL.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
