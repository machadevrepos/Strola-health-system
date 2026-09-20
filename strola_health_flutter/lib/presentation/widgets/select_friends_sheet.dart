import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/domain/entities/friend.dart';
import 'package:strola_health/presentation/providers/friend_providers.dart';

/// Lets the caller pick from their real, accepted friends. There's no
/// backend hook to directly notify a specific friend about a challenge (see
/// `CreateChallengeScreen`'s invite flow) — this only scopes who the caller
/// means to reach; the actual invite still goes out through the OS share
/// sheet afterward. Returns the selected [FriendSummary]s, or null if
/// dismissed without confirming.
Future<List<FriendSummary>?> showSelectFriendsSheet(
  BuildContext context, {
  required Set<String> initiallySelected,
}) {
  return showModalBottomSheet<List<FriendSummary>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectFriendsSheet(initiallySelected: initiallySelected),
  );
}

class _SelectFriendsSheet extends ConsumerStatefulWidget {
  const _SelectFriendsSheet({required this.initiallySelected});

  final Set<String> initiallySelected;

  @override
  ConsumerState<_SelectFriendsSheet> createState() =>
      _SelectFriendsSheetState();
}

class _SelectFriendsSheetState extends ConsumerState<_SelectFriendsSheet> {
  late final Set<String> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.75;
    final friendsAsync = ref.watch(friendshipsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Friends',
                    style: AppTypography.titleL.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    AppIcons.close,
                    color: AppColors.textSecondary,
                    size: AppTheme.iconM,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Flexible(
            child: friendsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTheme.spaceXXL),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXXL),
                child: Text(
                  'Could not load your friends.',
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              data: (friends) {
                final accepted = friends
                    .where((f) => f.status == FriendshipStatus.accepted)
                    .toList();
                if (accepted.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceXXL),
                    child: Text(
                      "You haven't added any friends yet — add some from "
                      'the Community tab first.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceS,
                  ),
                  itemCount: accepted.length,
                  itemBuilder: (_, i) {
                    final friend = accepted[i].profile;
                    final selected = _selected.contains(friend.id);
                    return ListTile(
                      onTap: () {
                        HapticsHelper.selection();
                        setState(() {
                          if (selected) {
                            _selected.remove(friend.id);
                          } else {
                            _selected.add(friend.id);
                          }
                        });
                      },
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.accentSecondary.withValues(
                          alpha: 0.25,
                        ),
                        backgroundImage: friend.photoUrl != null
                            ? NetworkImage(friend.photoUrl!)
                            : null,
                        child: friend.photoUrl == null
                            ? Text(
                                friend.initials,
                                style: AppTypography.labelM.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        friend.name.isNotEmpty ? friend.name : friend.username,
                        style: AppTypography.bodyL,
                      ),
                      trailing: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppColors.accent : null,
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : AppColors.textMuted,
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                AppIcons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spaceXL,
              AppTheme.spaceM,
              AppTheme.spaceXL,
              AppTheme.spaceL + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final friends = (friendsAsync.value ?? const [])
                      .where((f) => _selected.contains(f.profile.id))
                      .toList();
                  Navigator.of(context).pop(friends);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _selected.isEmpty ? 'Done' : 'Done (${_selected.length})',
                  style: AppTypography.bodyL.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
