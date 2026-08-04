import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/data/repositories/community_repository.dart';

/// Opens the report form as a bottom sheet, wired to the real
/// `reportContent` callable.
///
/// [subject] names what is being reported, e.g. "this post" or a user's
/// name — it appears in the sheet subtitle and the confirmation snackbar.
/// [targetType] is `'post'` or `'user'`; [targetId] is that post's or
/// user's real id — both required so the report is actionable, not just
/// cosmetic.
void showReportSheet(
  BuildContext context, {
  required String subject,
  required String targetType,
  required String targetId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(
      subject: subject,
      targetType: targetType,
      targetId: targetId,
    ),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.subject,
    required this.targetType,
    required this.targetId,
  });

  final String subject;
  final String targetType;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  static const _reasons = [
    'Spam',
    'Harassment or bullying',
    'Inappropriate content',
    'False information',
    'Other',
  ];

  static const _categorySlugs = {
    'Spam': 'spam',
    'Harassment or bullying': 'harassment',
    'Inappropriate content': 'inappropriate_content',
    'False information': 'false_information',
    'Other': 'other',
  };

  String? _selected;
  final _otherCtrl = TextEditingController();
  bool _submitting = false;

  bool get _isOther => _selected == 'Other';

  bool get _canSubmit {
    if (_submitting || _selected == null) return false;
    if (_isOther) return _otherCtrl.text.trim().isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    HapticsHelper.lightImpact();
    setState(() => _submitting = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .reportContent(
            targetType: widget.targetType,
            targetId: widget.targetId,
            category: _categorySlugs[_selected] ?? 'other',
            reason: _isOther ? _otherCtrl.text.trim() : _selected!,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reported ${widget.subject}. Thanks for keeping things safe.',
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not submit report. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusSheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPaddingH,
              AppTheme.spaceM,
              AppTheme.screenPaddingH,
              AppTheme.spaceL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),

                Row(
                  children: [
                    Icon(
                      AppIcons.milestone,
                      color: AppColors.error,
                      size: AppTheme.iconM,
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    Text('Report', style: AppTypography.titleL),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Why are you reporting ${widget.subject}? '
                  'Your report is anonymous.',
                  style: AppTypography.bodyM,
                ),
                const SizedBox(height: AppTheme.spaceL),

                // Common reasons
                ..._reasons.map((reason) {
                  final selected = _selected == reason;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                    child: GestureDetector(
                      onTap: () {
                        HapticsHelper.selection();
                        setState(() => _selected = reason);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: AppTheme.animFast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceL,
                          vertical: AppTheme.spaceM,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent.withValues(alpha: 0.06)
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.45)
                                : AppColors.accentSecondary.withValues(
                                    alpha: 0.30,
                                  ),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reason,
                                style: AppTypography.bodyL.copyWith(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                AppIcons.check,
                                color: AppColors.accent,
                                size: AppTheme.iconM,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // "Other" free-text reason
                AnimatedSize(
                  duration: AppTheme.animFast,
                  curve: Curves.easeOut,
                  child: _isOther
                      ? Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spaceS,
                          ),
                          child: TextField(
                            controller: _otherCtrl,
                            autofocus: true,
                            maxLines: 3,
                            minLines: 2,
                            maxLength: 250,
                            onChanged: (_) => setState(() {}),
                            style: AppTypography.bodyM,
                            decoration: InputDecoration(
                              hintText: 'Tell us what happened...',
                              hintStyle: AppTypography.bodyM.copyWith(
                                color: AppColors.textMuted,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.bgSurface,
                              contentPadding: const EdgeInsets.all(
                                AppTheme.spaceL,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.accentSecondary.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.accentSecondary.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.accent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: AppTheme.spaceM),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      disabledBackgroundColor: AppColors.accentSecondary
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceL,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit Report',
                      style: AppTypography.titleS.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
