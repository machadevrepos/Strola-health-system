import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/data/repositories/friend_repository.dart';
import 'package:strola_health/domain/entities/friend.dart';
import 'package:strola_health/domain/entities/public_profile.dart';
import 'package:strola_health/presentation/providers/friend_providers.dart';
import 'package:strola_health/presentation/screens/profile_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

enum _SearchState { idle, loading, error, results }

class FindFriendsScreen extends ConsumerStatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  ConsumerState<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends ConsumerState<FindFriendsScreen> {
  static const _debounceDelay = Duration(milliseconds: 350);

  final _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';
  _SearchState _state = _SearchState.idle;
  List<PublicProfile> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    setState(() => _query = value);

    if (trimmed.isEmpty) {
      setState(() {
        _state = _SearchState.idle;
        _results = const [];
      });
      return;
    }

    _debounce = Timer(_debounceDelay, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _state = _SearchState.loading);
    try {
      final results = await ref
          .read(friendRepositoryProvider)
          .searchUsers(query);
      if (!mounted || query != _query.trim()) return;
      setState(() {
        _results = results;
        _state = _SearchState.results;
      });
    } catch (_) {
      if (!mounted || query != _query.trim()) return;
      setState(() => _state = _SearchState.error);
    }
  }

  void _clear() {
    _debounce?.cancel();
    setState(() {
      _controller.clear();
      _query = '';
      _state = _SearchState.idle;
      _results = const [];
    });
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
              title: Text('Add Friends', style: AppTypography.titleM),
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
                      'Find people by username',
                      style: AppTypography.titleL,
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Search for friends already on Strolla and send '
                      'them a friend request.',
                      style: AppTypography.bodyS,
                    ),
                    const SizedBox(height: AppTheme.spaceL),

                    // Search field
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceM,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.search,
                            color: AppColors.textMuted,
                            size: AppTheme.iconS,
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onChanged: _onChanged,
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Search by username',
                                hintStyle: AppTypography.bodyM.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            PressableScale(
                              onTap: _clear,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppTheme.spaceM,
                                ),
                                child: Icon(
                                  AppIcons.close,
                                  color: AppColors.textMuted,
                                  size: AppTheme.iconS,
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppTheme.spaceM,
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(
                      delay: 60.ms,
                      duration: AppTheme.animSlow,
                    ),

                    const SizedBox(height: AppTheme.spaceXL),
                    _buildBody(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SearchState.idle:
        return _PromptState();
      case _SearchState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        );
      case _SearchState.error:
        return FlatCard(
          child: Column(
            children: [
              const Icon(
                AppIcons.error,
                color: AppColors.textMuted,
                size: AppTheme.iconXL,
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Could not search right now. Please try again.',
                style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppTheme.animNormal);
      case _SearchState.results:
        final results = _results;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: AppTypography.titleS,
            ),
            const SizedBox(height: AppTheme.spaceM),
            if (results.isEmpty)
              FlatCard(
                child: Column(
                  children: [
                    const Icon(
                      AppIcons.personSearch,
                      color: AppColors.textMuted,
                      size: AppTheme.iconXL,
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Text(
                      'No one found for "${_query.trim()}"',
                      style: AppTypography.bodyS,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: AppTheme.animNormal)
            else
              ...results.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                  child: _SearchResultCard(profile: e.value)
                      .animate(delay: Duration(milliseconds: 60 * e.key))
                      .fadeIn(duration: AppTheme.animSlow)
                      .slideY(begin: 0.12),
                );
              }),
          ],
        );
    }
  }
}

class _PromptState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Column(
        children: [
          const Icon(
            AppIcons.personSearch,
            color: AppColors.textMuted,
            size: AppTheme.iconXL,
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Search for a friend by username',
            style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.animNormal);
  }
}

class _SearchResultCard extends ConsumerStatefulWidget {
  const _SearchResultCard({required this.profile});

  final PublicProfile profile;

  @override
  ConsumerState<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends ConsumerState<_SearchResultCard> {
  bool _busy = false;

  Future<void> _handleTap(FriendshipStatus? status) async {
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      if (status == FriendshipStatus.pending ||
          status == FriendshipStatus.accepted) {
        await ref
            .read(friendRepositoryProvider)
            .removeFriend(widget.profile.id);
      } else {
        await ref.read(friendRepositoryProvider).sendRequest(widget.profile.id);
      }
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
      ref.invalidate(friendshipWithProvider(widget.profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final statusAsync = ref.watch(friendshipWithProvider(profile.id));
    final status = statusAsync.value;
    final resolving = statusAsync.isLoading;
    final accepted = status == FriendshipStatus.accepted;
    final pending = status == FriendshipStatus.pending;

    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(userId: profile.id),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: AppTheme.statChipCircleSize,
                    height: AppTheme.statChipCircleSize,
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
                        style: AppTypography.titleM.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleS,
                        ),
                        const SizedBox(height: AppTheme.spaceXS / 2),
                        if (profile.username.trim().isNotEmpty)
                          Text(
                            '@${profile.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelS,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
          if (_busy || resolving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          else
            PressableScale(
              onTap: accepted ? null : () => _handleTap(status),
              child: AnimatedContainer(
                duration: AppTheme.animFast,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceL,
                  vertical: AppTheme.spaceS,
                ),
                decoration: BoxDecoration(
                  color: (accepted || pending)
                      ? AppColors.accentSecondary.withValues(alpha: 0.25)
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  accepted ? 'Friends' : (pending ? 'Requested' : 'Add'),
                  style: AppTypography.labelM.copyWith(
                    color: (accepted || pending)
                        ? AppColors.textSecondary
                        : Colors.white,
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
