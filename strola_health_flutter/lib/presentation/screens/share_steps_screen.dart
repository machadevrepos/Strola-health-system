import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/widgets/brand_logos.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/header_actions.dart';

class ShareStepsScreen extends ConsumerStatefulWidget {
  const ShareStepsScreen({super.key});

  @override
  ConsumerState<ShareStepsScreen> createState() => _ShareStepsScreenState();
}

class _ShareStepsScreenState extends ConsumerState<ShareStepsScreen> {
  // 0 = Community (default), 1–4 = social platforms.
  int _selectedIndex = 0;
  String _message = '';
  final _messageController = TextEditingController();

  static const _destinations = <_Destination>[
    _Destination(
      label: 'Community',
      brand: BrandType.community,
    ),
    _Destination(
      label: 'Instagram',
      brand: BrandType.instagram,
      tagline: 'I just hit',
      stepsLabel: 'steps today!',
      primaryTitle: 'Feed',
      primarySubtitle: 'Share to your Instagram feed',
      secondaryTitle: 'Stories',
      secondarySubtitle: 'Share to your Instagram story',
    ),
    _Destination(
      label: 'Facebook',
      brand: BrandType.facebook,
      tagline: 'I just hit',
      stepsLabel: 'steps today!',
      primaryTitle: 'Feed',
      primarySubtitle: 'Share to your Facebook feed',
      secondaryTitle: 'Stories',
      secondarySubtitle: 'Share to your Facebook story',
    ),
    _Destination(
      label: 'WhatsApp',
      brand: BrandType.whatsapp,
      tagline: 'Making every step count! ♡',
      stepsLabel: 'steps today',
      primaryTitle: 'Chats',
      primarySubtitle: 'Share with your WhatsApp contacts',
      secondaryTitle: 'Status',
      secondarySubtitle: 'Share to your WhatsApp status',
    ),
    _Destination(
      label: 'TikTok',
      brand: BrandType.tiktok,
      tagline: 'I just hit',
      stepsLabel: 'steps today!',
      primaryTitle: 'Feed',
      primarySubtitle: 'Share to your TikTok feed',
      secondaryTitle: 'Stories',
      secondarySubtitle: 'Share to your TikTok story',
    ),
  ];

  static const _quickCaptions = [
    'Keep moving! 💪',
    'One step at a time 👟',
    'Feeling strong today! 🔥',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _isCommunity => _selectedIndex == 0;
  _Destination get _selected => _destinations[_selectedIndex];

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    HapticsHelper.selection();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final steps     = ref.watch(stepCountProvider);
    final goal      = ref.watch(dailyGoalProvider);
    final calories  = ref.watch(caloriesProvider);
    final progress  = (steps / goal).clamp(0.0, 1.0);
    final distanceM = steps * 0.762;
    final distanceVal = distanceM >= 1000
        ? (distanceM / 1000).toStringAsFixed(1)
        : distanceM.toInt().toString();
    final distanceUnit = distanceM >= 1000 ? 'km' : 'm';

    final accent = _isCommunity ? AppColors.accent : brandColorOf(_selected.brand);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              // ── Persistent destination switcher ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceL,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share to', style: AppTypography.titleS),
                    const SizedBox(height: AppTheme.spaceM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_destinations.length, (i) {
                        return _DestinationPicker(
                          destination: _destinations[i],
                          isSelected: i == _selectedIndex,
                          onTap: () => _selectDestination(i),
                        );
                      }),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 60.ms),

              // ── Swappable content ──────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppTheme.animNormal,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  // Pin both the outgoing and incoming views to the top so the
                  // differing content heights don't cause a vertical jump.
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: SingleChildScrollView(
                    key: ValueKey(_selectedIndex),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.screenPaddingH,
                    ),
                    child: _isCommunity
                        ? _communityContent(
                            steps, goal, calories,
                            distanceVal, distanceUnit, progress)
                        : _socialContent(
                            _selected, steps, calories,
                            '$distanceVal $distanceUnit', progress),
                  ),
                ),
              ),

              // ── Share button ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceS,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceXXL,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _share(context, steps),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
                      elevation: 0,
                    ),
                    child: Text(
                      _isCommunity ? 'Share' : 'Share to ${_selected.label}',
                      style: AppTypography.titleS.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(AppIcons.back,
            color: AppColors.textPrimary, size: AppTheme.iconM),
      ),
      title: Text('Share Your Steps', style: AppTypography.titleM),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppTheme.spaceL),
          child: Center(child: HeaderActions()),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.accentSecondary.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  // ── Community content ─────────────────────────────────────────────────────
  Widget _communityContent(
    int steps,
    int goal,
    int calories,
    String distanceVal,
    String distanceUnit,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FlatCard(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.share,
                    color: AppColors.accent, size: AppTheme.iconL),
              ),
              const SizedBox(width: AppTheme.spaceM),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inspire others on their journey',
                        style: AppTypography.titleS),
                    SizedBox(height: 3),
                    Text(
                      'Share your steps, celebrate your progress, '
                      'and motivate your community.',
                      style: AppTypography.bodyS,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.sectionGap),

        Text("Today's Summary", style: AppTypography.titleS),
        const SizedBox(height: AppTheme.spaceS),
        FlatCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryStatCol(
                      icon: AppIcons.steps,
                      value: Formatters.stepCount(steps),
                      label: 'Steps',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStatCol(
                      icon: AppIcons.calories,
                      value: '$calories',
                      label: 'Active Calories',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStatCol(
                      icon: AppIcons.location,
                      value: distanceVal,
                      unit: distanceUnit,
                      label: 'Distance',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  Text(
                    '${(progress * 100).toInt()}% of daily goal',
                    style: AppTypography.labelM.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text('${Formatters.stepCount(goal)} steps',
                      style: AppTypography.labelS),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor:
                      AppColors.accentSecondary.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.sectionGap),

        Text('Add a message (optional)', style: AppTypography.titleS),
        const SizedBox(height: AppTheme.spaceS),
        _MessageField(
          controller: _messageController,
          onChanged: (v) => setState(() => _message = v),
        ),
        const SizedBox(height: AppTheme.spaceM),
        Wrap(
          spacing: AppTheme.spaceS,
          runSpacing: AppTheme.spaceS,
          children: _quickCaptions.map((cap) {
            final isActive = _message == cap;
            return GestureDetector(
              onTap: () {
                HapticsHelper.lightImpact();
                setState(() {
                  _message = isActive ? '' : cap;
                  _messageController.text = _message;
                });
              },
              child: AnimatedContainer(
                duration: AppTheme.animFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceM,
                  vertical: AppTheme.spaceXS + 2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent.withValues(alpha: 0.10)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: isActive
                        ? AppColors.accent.withValues(alpha: 0.40)
                        : AppColors.accentSecondary.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  cap,
                  style: AppTypography.labelM.copyWith(
                    color: isActive
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppTheme.sectionGap),

        Text('Preview', style: AppTypography.titleS),
        const SizedBox(height: AppTheme.spaceS),
        _PreviewCard(
          steps: steps,
          calories: calories,
          distanceVal: distanceVal,
          distanceUnit: distanceUnit,
          message: _message.isEmpty
              ? 'Just hit ${Formatters.stepCount(steps)} steps today! 💪'
              : _message,
        ),

        const SizedBox(height: AppTheme.spaceXXXL),
      ],
    );
  }

  // ── Social content ────────────────────────────────────────────────────────
  Widget _socialContent(
    _Destination dest,
    int steps,
    int calories,
    String distance,
    double progress,
  ) {
    final color = brandColorOf(dest.brand);
    final isWhatsApp = dest.brand == BrandType.whatsapp;

    return Column(
      children: [
        const SizedBox(height: AppTheme.spaceXS),

        // Branded share card
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.bgDeep, AppColors.bgSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.accentSecondary.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: Stack(
              children: [
                const Positioned(top: -28, left: -18, child: _Blob(size: 96)),
                const Positioned(bottom: -22, left: -10, child: _Blob(size: 64)),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceXXL),
                  child: Column(
                    children: [
                      Text('strolla', style: AppTypography.brand),
                      const SizedBox(height: AppTheme.spaceS),
                      Text(dest.tagline, style: AppTypography.bodyM),
                      const SizedBox(height: AppTheme.spaceS),
                      Text(
                        Formatters.stepCount(steps),
                        style: AppTypography.displayXL
                            .copyWith(color: AppColors.accent),
                      ),
                      Text(dest.stepsLabel, style: AppTypography.titleL),
                      const SizedBox(height: AppTheme.spaceXL),
                      Row(
                        children: [
                          _ShareStatItem(
                            icon: AppIcons.calories,
                            value: '$calories',
                            label: 'Active Calories',
                          ),
                          _ShareStatItem(
                            icon: AppIcons.location,
                            value: distance,
                            label: 'Distance',
                          ),
                          _ShareStatItem(
                            icon: AppIcons.target,
                            value: '${(progress * 100).toInt()}%',
                            label: 'of daily goal',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spaceXL),

        // Share options
        FlatCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ShareOptionTile(
                badge: BrandLogo(type: dest.brand, size: 36),
                title: dest.primaryTitle,
                subtitle: dest.primarySubtitle,
                initiallySelected: true,
              ),
              Divider(
                height: 1,
                color: AppColors.accentSecondary.withValues(alpha: 0.18),
              ),
              _ShareOptionTile(
                badge: _StoryBadge(color: color),
                title: dest.secondaryTitle,
                subtitle: dest.secondarySubtitle,
                initiallySelected: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spaceM),

        // Info note
        Row(
          children: [
            Icon(AppIcons.info,
                color: AppColors.textMuted, size: AppTheme.iconXS + 2),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Text(
                isWhatsApp
                    ? 'You can add a message after tapping "Share to WhatsApp".'
                    : 'We\'ll open ${dest.label} so you can add filters, tags, and share.',
                style: AppTypography.labelS,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spaceXXXL),
      ],
    );
  }

  // ── Share action ──────────────────────────────────────────────────────────
  void _share(BuildContext context, int steps) {
    HapticsHelper.goalReached();

    final String text;
    final Color color;
    if (_isCommunity) {
      text =
          'Shared to Community! Your ${Formatters.stepCount(steps)} steps are inspiring others 🌸';
      color = AppColors.accent;
    } else {
      text = 'Opening ${_selected.label}...';
      color = brandColorOf(_selected.brand);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      ),
    );
    Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESTINATION PICKER ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationPicker extends StatelessWidget {
  const _DestinationPicker({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final _Destination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = brandColorOf(destination.brand);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppTheme.animFast,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              color: isSelected
                  ? color.withValues(alpha: 0.06)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: BrandLogo(type: destination.brand, size: 42),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            destination.label,
            style: AppTypography.labelS.copyWith(
              color: isSelected ? color : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _MessageField extends StatefulWidget {
  const _MessageField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  State<_MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<_MessageField> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _charCount = widget.controller.text.length;
  }

  void _onText() {
    final c = widget.controller.text.length;
    if (c != _charCount) setState(() => _charCount = c);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: widget.controller,
          maxLength: 120,
          maxLines: 3,
          minLines: 3,
          onChanged: widget.onChanged,
          style: AppTypography.bodyM,
          decoration: InputDecoration(
            hintText: 'Share a thought with your steps...',
            hintStyle:
                AppTypography.bodyM.copyWith(color: AppColors.textMuted),
            counterText: '',
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: const EdgeInsets.fromLTRB(
              AppTheme.spaceL,
              AppTheme.spaceM,
              AppTheme.spaceL,
              AppTheme.spaceXXXL,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.28),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.28),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
        Positioned(
          bottom: AppTheme.spaceS,
          right: AppTheme.spaceM,
          child: Text('$_charCount/120', style: AppTypography.labelS),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY STAT COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryStatCol extends StatelessWidget {
  const _SummaryStatCol({
    required this.icon,
    required this.value,
    required this.label,
    this.unit = '',
  });

  final IconData icon;
  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: AppTheme.iconL),
        const SizedBox(height: AppTheme.spaceXS),
        unit.isEmpty
            ? Text(value, style: AppTypography.displayM.copyWith(fontSize: 20))
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value,
                      style: AppTypography.displayM.copyWith(fontSize: 20)),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(unit, style: AppTypography.labelS),
                  ),
                ],
              ),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.labelS,
            textAlign: TextAlign.center,
            maxLines: 2),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.steps,
    required this.calories,
    required this.distanceVal,
    required this.distanceUnit,
    required this.message,
  });

  final int steps;
  final int calories;
  final String distanceVal;
  final String distanceUnit;
  final String message;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentSecondary.withValues(alpha: 0.22),
                  border: Border.all(
                    color: AppColors.accentSecondary.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: const Icon(AppIcons.profile,
                    color: AppColors.accent, size: AppTheme.iconM),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sarah Abu-Ramadan', style: AppTypography.titleS),
                  Row(
                    children: [
                      Text('Just now', style: AppTypography.labelS),
                      const SizedBox(width: AppTheme.spaceXS),
                      const Icon(AppIcons.community,
                          color: AppColors.textMuted, size: AppTheme.iconXS),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(message, style: AppTypography.bodyM),
          const SizedBox(height: AppTheme.spaceM),
          Row(
            children: [
              _MiniStatItem(
                icon: AppIcons.steps,
                value: Formatters.stepCount(steps),
                label: 'Steps',
              ),
              _MiniStatItem(
                icon: AppIcons.calories,
                value: '$calories',
                label: 'Active Calories',
              ),
              _MiniStatItem(
                icon: AppIcons.location,
                value: '$distanceVal $distanceUnit',
                label: 'Distance',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  const _MiniStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: AppTheme.iconS),
          const SizedBox(width: AppTheme.spaceXS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: AppTypography.labelS),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARE STAT ITEM  (inside the branded social card)
// ─────────────────────────────────────────────────────────────────────────────

class _ShareStatItem extends StatelessWidget {
  const _ShareStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: AppTheme.iconL),
          const SizedBox(height: AppTheme.spaceXS),
          Text(value,
              style: AppTypography.titleL.copyWith(color: AppColors.accent)),
          Text(label, style: AppTypography.labelS, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARE OPTION TILE  (Feed / Stories · Chats / Status)
// ─────────────────────────────────────────────────────────────────────────────

class _ShareOptionTile extends StatefulWidget {
  const _ShareOptionTile({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.initiallySelected,
  });

  final Widget badge;
  final String title;
  final String subtitle;
  final bool initiallySelected;

  @override
  State<_ShareOptionTile> createState() => _ShareOptionTileState();
}

class _ShareOptionTileState extends State<_ShareOptionTile> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected;
  }

  @override
  void didUpdateWidget(covariant _ShareOptionTile old) {
    super.didUpdateWidget(old);
    if (old.initiallySelected != widget.initiallySelected) {
      _selected = widget.initiallySelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _selected = !_selected),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceL,
          vertical: AppTheme.spaceM,
        ),
        child: Row(
          children: [
            widget.badge,
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTypography.bodyL),
                  Text(widget.subtitle, style: AppTypography.bodyS),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.animFast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selected
                      ? AppColors.accent
                      : AppColors.accentSecondary.withValues(alpha: 0.45),
                  width: 2,
                ),
                color: _selected ? AppColors.accent : Colors.transparent,
              ),
              child: _selected
                  ? const Center(
                      child: Icon(AppIcons.check,
                          color: Colors.white, size: AppTheme.iconXS),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// STORY BADGE — outlined "+" for the secondary option (Stories / Status)
class _StoryBadge extends StatelessWidget {
  const _StoryBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Icon(AppIcons.add, color: color, size: AppTheme.iconS),
    );
  }
}

// DECORATIVE BLOB — soft blush circle bleeding into the share card corners
class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentSecondary.withValues(alpha: 0.16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESTINATION DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Destination {
  const _Destination({
    required this.label,
    required this.brand,
    this.tagline = '',
    this.stepsLabel = '',
    this.primaryTitle = '',
    this.primarySubtitle = '',
    this.secondaryTitle = '',
    this.secondarySubtitle = '',
  });

  final String label;
  final BrandType brand;
  final String tagline;
  final String stepsLabel;
  final String primaryTitle;
  final String primarySubtitle;
  final String secondaryTitle;
  final String secondarySubtitle;
}
