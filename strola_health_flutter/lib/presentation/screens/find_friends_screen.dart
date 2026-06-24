import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  static const _people = [
    _DiscoverUser('Olivia Bennett', 'olivia.b', 3),
    _DiscoverUser('Grace Thompson', 'grace.t', 1),
    _DiscoverUser('Mia Patel', 'mia.patel', 5),
    _DiscoverUser('Lucy Edwards', 'lucy.e', 2),
    _DiscoverUser('Sophie Clarke', 'sophie.c', 0),
    _DiscoverUser('Hannah Wright', 'hannah.w', 4),
    _DiscoverUser('Ruth Adeyemi', 'ruth.a', 1),
    _DiscoverUser('Chloe Davies', 'chloe.d', 0),
  ];

  final _controller = TextEditingController();
  final Set<String> _requested = {};
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleRequest(String username) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_requested.contains(username)) {
        _requested.remove(username);
      } else {
        _requested.add(username);
      }
    });
  }

  List<_DiscoverUser> get _results {
    if (_query.isEmpty) return _people;
    final q = _query.toLowerCase();
    return _people
        .where(
          (p) =>
              p.username.toLowerCase().contains(q) ||
              p.name.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

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
                              onChanged: (v) => setState(() => _query = v),
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
                              onTap: () => setState(() {
                                _controller.clear();
                                _query = '';
                              }),
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
                    Text(
                      _query.isEmpty
                          ? 'Suggested for you'
                          : '${results.length} result'
                                '${results.length == 1 ? '' : 's'}',
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
                              'No one found for "$_query"',
                              style: AppTypography.bodyS,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: AppTheme.animNormal)
                    else
                      ...results.asMap().entries.map((e) {
                        final user = e.value;
                        final requested = _requested.contains(user.username);
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spaceM,
                          ),
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
                                              user.name[0],
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
                                                user.name,
                                                style: AppTypography.titleS,
                                              ),
                                              const SizedBox(
                                                height: AppTheme.spaceXS / 2,
                                              ),
                                              Text(
                                                '@${user.username}'
                                                '${user.mutualFriends > 0 ? '  ·  ${user.mutualFriends} mutual' : ''}',
                                                style: AppTypography.labelS,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.spaceS),
                                        PressableScale(
                                          onTap: () =>
                                              _toggleRequest(user.username),
                                          child: AnimatedContainer(
                                            duration: AppTheme.animFast,
                                            curve: Curves.easeOut,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spaceL,
                                              vertical: AppTheme.spaceS,
                                            ),
                                            decoration: BoxDecoration(
                                              color: requested
                                                  ? AppColors.accentSecondary
                                                        .withValues(alpha: 0.25)
                                                  : AppColors.accent,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusFull,
                                                  ),
                                            ),
                                            child: Text(
                                              requested ? 'Requested' : 'Add',
                                              style: AppTypography.labelM
                                                  .copyWith(
                                                    color: requested
                                                        ? AppColors
                                                              .textSecondary
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

class _DiscoverUser {
  const _DiscoverUser(this.name, this.username, this.mutualFriends);

  final String name;
  final String username;
  final int mutualFriends;
}
