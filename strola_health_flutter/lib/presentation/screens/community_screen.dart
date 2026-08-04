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
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/domain/entities/community_post.dart';
import 'package:strola_health/domain/entities/friend.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/friend_providers.dart';
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
      // MainShell's Scaffold reserves space for the real nav bar (no more
      // `extendBody`), so this nested Scaffold's own bottom edge already
      // stops right above it — Flutter positions the FAB correctly on its
      // own, no manual bottom padding needed.
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) =>
            _tabController.index == 0 ? _NewPostFab() : const SizedBox.shrink(),
      ),
    );
  }
}

// ── Feed tab ──────────────────────────────────────────────────────────────────

class _FeedTab extends ConsumerStatefulWidget {
  const _FeedTab({required this.sortMode, required this.onSortChanged});

  final String sortMode;
  final ValueChanged<String> onSortChanged;

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab> {
  final _scrollController = ScrollController();

  // How far from the bottom to trigger the next page — comfortably before
  // the user actually reaches the end, so the next page is (usually)
  // already loaded by the time they'd notice, rather than a visible pause.
  static const _loadMoreThreshold = 600.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final blocked = ref.watch(blockedUsersProvider).value ?? const <String>{};
    final loadingMore = ref.watch(feedLoadingMoreProvider);

    // Stale-while-revalidate: once we've ever had a feed, keep showing it
    // (RefreshIndicator already has its own spinner for "fetching now") —
    // only fall back to a full skeleton/error state before the first load.
    final allPosts = postsAsync.value;
    if (allPosts == null) {
      return postsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: PostFeedSkeleton(),
        ),
        error: (_, __) => const Center(
          child: Text('Could not load posts.', style: AppTypography.bodyM),
        ),
        data: (_) => const SizedBox.shrink(),
      );
    }
    {
      final posts = allPosts
          .where((p) => !blocked.contains(p.authorId))
          .toList();
      // Same RefreshIndicator + notifier.refresh() pattern as _FriendsTab —
      // this tab was missing it entirely, so a feed stuck showing stale/
      // empty results after a transient network hiccup (e.g. right after
      // posting) had no way to be manually retried short of leaving and
      // re-entering the screen.
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.read(postsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
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
                              widget.sortMode,
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
            if (posts.isEmpty)
              const SliverToBoxAdapter(child: _EmptyFeedState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PostCard(post: posts[i], index: i),
                ),
              ),

            // Next-page spinner — only while a background loadMore() is
            // actually in flight (triggered by scrolling near the bottom,
            // see _onScroll); nothing rendered once the feed is exhausted.
            if (posts.isNotEmpty && loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spaceL),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // Comfortable breathing room at the end of the scroll —
            // MainShell's Scaffold already reserves space for the nav bar
            // itself, so this is just visual padding, not a clearance guess.
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.sectionGap),
            ),
          ],
        ),
      );
    }
  }
}

class _EmptyFeedState extends ConsumerWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.community,
              color: AppColors.accent,
              size: 36,
            ),
          ).animate().fadeIn().scale(
            begin: const Offset(0.7, 0.7),
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: AppTypography.titleM.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Be the first to share your progress\nwith the community.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyM.copyWith(letterSpacing: 0),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 20),
          PressableScale(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _NewPostSheet(
                onSubmit: (content, steps, imageUrl) {
                  ref
                      .read(postsProvider.notifier)
                      .createPost(
                        content,
                        stepCount: steps,
                        imageUrl: imageUrl,
                      );
                },
                currentSteps: ref.read(stepCountProvider),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.edit, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Create a post',
                    style: AppTypography.bodyM.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
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
        onSubmit: (content, steps, imageUrl) {
          ref
              .read(postsProvider.notifier)
              .createPost(content, stepCount: steps, imageUrl: imageUrl);
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
    const color = AppColors.accent;

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
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: AppColors.accentSecondary.withValues(
                          alpha: 0.15,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  _ActionBtn(
                    icon: AppIcons.like,
                    label: '${post.likesCount}',
                    color: post.isLiked ? AppColors.error : AppColors.textMuted,
                    onTap: () {
                      HapticsHelper.lightImpact();
                      ref.read(postsProvider.notifier).likePost(post.id);
                    },
                  ),
                  const SizedBox(width: AppTheme.spaceL),
                  _ActionBtn(
                    icon: AppIcons.comment,
                    label: '${post.commentsCount}',
                    color: AppColors.textMuted,
                    onTap: () => _showComments(context),
                  ),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: post.authorId),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: post.id),
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
                  showReportSheet(
                    context,
                    subject: 'this post',
                    targetType: 'post',
                    targetId: post.id,
                  );
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

// ── Comments sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.postId});

  final String postId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(commentsProvider(widget.postId).notifier)
          .addComment(content);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not post comment. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusSheet),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceM),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text('Comments', style: AppTypography.titleM),
            const SizedBox(height: AppTheme.spaceM),
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Could not load comments.',
                    style: AppTypography.bodyM,
                  ),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'No comments yet. Be the first to reply.',
                        style: AppTypography.bodyS.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.screenPaddingH,
                    ),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spaceM),
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.25,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                c.initials,
                                style: AppTypography.labelM.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.authorName,
                                  style: AppTypography.bodyS.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(c.content, style: AppTypography.bodyM),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceS,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: AppTypography.bodyM,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: AppTypography.bodyM.copyWith(
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.bgDeep,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceM,
                            vertical: AppTheme.spaceS,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    PressableScale(
                      onTap: _submitting ? null : _submit,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
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

// ── Friends tab ───────────────────────────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendshipsAsync = ref.watch(friendshipsProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(friendshipsProvider.notifier).refresh(),
      child: ListView(
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
          PressableScale(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FindFriendsScreen()),
            ),
            child: Container(
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
                  const Icon(
                    AppIcons.search,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
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
            ),
          ).animate().fadeIn(delay: 120.ms, duration: AppTheme.animSlow),
          const SizedBox(height: AppTheme.spaceL),

          // Stale-while-revalidate: once we've ever loaded the list, keep
          // showing it during a refresh instead of a blank spinner.
          if (friendshipsAsync.value != null)
            _FriendsContent(friendships: friendshipsAsync.value!)
          else
            friendshipsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spaceXXL,
                ),
                child: Center(
                  child: Text(
                    'Could not load friends.',
                    style: AppTypography.bodyM.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              data: (_) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _FriendsContent extends StatelessWidget {
  const _FriendsContent({required this.friendships});

  final List<FriendSummary> friendships;

  @override
  Widget build(BuildContext context) {
    final requests = friendships.where((f) => f.isIncomingRequest).toList();
    final accepted = friendships
        .where((f) => f.status == FriendshipStatus.accepted)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requests.isNotEmpty) ...[
          Text(
            'Friend Requests',
            style: AppTypography.bodyL.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          ...requests.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FriendRequestCard(request: e.value)
                  .animate(delay: Duration(milliseconds: 60 * e.key))
                  .fadeIn(duration: AppTheme.animSlow)
                  .slideY(begin: 0.12),
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
        ],

        Text(
          'Your Friends',
          style: AppTypography.bodyL.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        if (accepted.isEmpty)
          SizedBox(
            width: double.infinity,
            child: FlatCard(
              child: Column(
                children: [
                  const Icon(
                    AppIcons.people,
                    color: AppColors.textMuted,
                    size: AppTheme.iconXL,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    "You haven't added any friends yet.",
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...accepted.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FriendCard(friend: e.value)
                  .animate(delay: Duration(milliseconds: 60 * e.key))
                  .fadeIn(duration: AppTheme.animSlow)
                  .slideY(begin: 0.12),
            ),
          ),
      ],
    );
  }
}

class _FriendRequestCard extends ConsumerStatefulWidget {
  const _FriendRequestCard({required this.request});

  final FriendSummary request;

  @override
  ConsumerState<_FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends ConsumerState<_FriendRequestCard> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(friendshipsProvider.notifier)
          .respondRequest(widget.request.profile.id, accept);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.request.profile;
    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: 10,
      ),
      child: Row(
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
                profile.initials,
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              profile.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyS.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          else ...[
            PressableScale(
              onTap: () => _respond(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  'Decline',
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PressableScale(
              onTap: () => _respond(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  'Accept',
                  style: AppTypography.labelM.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final FriendSummary friend;

  @override
  Widget build(BuildContext context) {
    final profile = friend.profile;
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: profile.id),
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
                  profile.initials,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (profile.showStats && (profile.streakCurrent ?? 0) > 0) ...[
              const Icon(AppIcons.streak, color: AppColors.accent, size: 13),
              const SizedBox(width: 1),
              Text(
                '${profile.streakCurrent}',
                style: AppTypography.labelM.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 6),
            ],
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
              onSubmit: (content, steps, imageUrl) {
                ref
                    .read(postsProvider.notifier)
                    .createPost(content, stepCount: steps, imageUrl: imageUrl);
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

  final void Function(String content, int? steps, String? imageUrl) onSubmit;
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
    if (_controller.text.trim().isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await FirebaseClient.uploadCommunityPostImage(
          File(_imageFile!.path),
        );
      }
      widget.onSubmit(
        _controller.text.trim(),
        _shareSteps ? widget.currentSteps : null,
        imageUrl,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload image. Please try again.'),
          ),
        );
        setState(() => _submitting = false);
      }
    }
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
