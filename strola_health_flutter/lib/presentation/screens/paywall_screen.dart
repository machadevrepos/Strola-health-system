import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/purchase_service.dart';
import 'package:strola_health/presentation/providers/purchase_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

const _kBenefits = [
  'Unlimited personal record tracking',
  'Full platform sync — Strava, Oura, Garmin, and more',
  'Advanced stats and trends',
  'Priority support',
];

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selected;
  bool _busy = false;

  Future<void> _purchase(Package package) async {
    setState(() => _busy = true);
    try {
      await PurchaseService.purchase(package);
      ref.invalidate(customerInfoProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showMessage('Purchase didn\'t go through: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await PurchaseService.restore();
      ref.invalidate(customerInfoProvider);
      if (mounted) _showMessage('Purchases restored.');
    } catch (e) {
      if (mounted) _showMessage('Could not restore purchases: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final offeringsAsync = ref.watch(offeringsProvider);

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
            child: const Icon(AppIcons.close, color: AppColors.textPrimary, size: AppTheme.iconM),
          ),
          title: Text('Strolla Premium', style: AppTypography.titleM),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isPremium
              ? const _AlreadyPremiumView()
              : offeringsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (_, _) => const _UnavailableView(),
                  data: (offerings) {
                    final packages = offerings?.current?.availablePackages ?? const <Package>[];
                    if (packages.isEmpty) return const _UnavailableView();
                    _selected ??= packages.first;
                    return _PaywallContent(
                      packages: packages,
                      selected: _selected!,
                      busy: _busy,
                      onSelect: (p) => setState(() => _selected = p),
                      onPurchase: () => _purchase(_selected!),
                      onRestore: _restore,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _PaywallContent extends StatelessWidget {
  const _PaywallContent({
    required this.packages,
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
  });

  final List<Package> packages;
  final Package selected;
  final bool busy;
  final ValueChanged<Package> onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.screenPaddingH),
      children: [
        Icon(AppIcons.premium, color: AppColors.accent, size: AppTheme.iconXXL),
        const SizedBox(height: AppTheme.spaceM),
        Text('Get the most out of Strolla', style: AppTypography.titleL),
        const SizedBox(height: AppTheme.spaceL),
        ..._kBenefits.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
            child: Row(
              children: [
                const Icon(AppIcons.goalReached, color: AppColors.accent, size: AppTheme.iconS),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(child: Text(b, style: AppTypography.bodyM)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        ...packages.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
            child: _PackageTile(
              package: p,
              selected: p.identifier == selected.identifier,
              onTap: () => onSelect(p),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : onPurchase,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Continue',
                    style: AppTypography.titleM.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        Center(
          child: TextButton(
            onPressed: busy ? null : onRestore,
            child: Text('Restore purchases', style: AppTypography.bodyS.copyWith(color: AppColors.accent)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppTheme.animSlow);
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.selected, required this.onTap});

  final Package package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FlatCard(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Row(
          children: [
            Icon(
              selected ? AppIcons.goalReached : Icons.radio_button_unchecked,
              color: selected ? AppColors.accent : AppColors.textMuted,
              size: AppTheme.iconM,
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Text(package.storeProduct.title, style: AppTypography.bodyL),
            ),
            Text(
              package.storeProduct.priceString,
              style: AppTypography.titleS.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyPremiumView extends StatelessWidget {
  const _AlreadyPremiumView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.premium, color: AppColors.accent, size: AppTheme.iconXXL),
            const SizedBox(height: AppTheme.spaceM),
            Text("You're already Premium", style: AppTypography.titleL),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Thanks for supporting Strolla — every feature is unlocked.',
              style: AppTypography.bodyM,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.info, color: AppColors.textMuted, size: AppTheme.iconXXL),
            const SizedBox(height: AppTheme.spaceM),
            Text('Premium isn\'t available yet', style: AppTypography.titleL, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Check back soon — we\'re still setting up purchases.',
              style: AppTypography.bodyM,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
