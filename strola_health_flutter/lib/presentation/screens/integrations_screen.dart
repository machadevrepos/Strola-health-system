import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/health_service.dart';
import 'package:strola_health/data/datasources/backend_api.dart';
import 'package:strola_health/presentation/widgets/brand_logos.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

/// The scheme registered natively (AndroidManifest.xml / Info.plist) that
/// the backend's OAuth callback redirects to once Strava/Oura/Garmin finish
/// — see `app/api/v1/integrations.py`'s `_APP_CALLBACK_SCHEME`.
const _kOAuthCallbackScheme = 'strolahealth';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  Set<String> _connected = {};
  bool _loading = true;
  String? _busyProvider;

  IntegrationProvider get _onDeviceProvider => Platform.isIOS
      ? IntegrationProvider.healthkit
      : IntegrationProvider.healthConnect;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    try {
      final integrations = await ref.read(backendApiProvider).getIntegrations();
      if (!mounted) return;
      setState(() {
        _connected = integrations.map((i) => i['provider'] as String).toSet();
        _loading = false;
      });
    } catch (_) {
      // No backend reachable / not signed in yet — show everything as not
      // connected rather than blocking the screen.
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectOnDevice() async {
    final provider = _onDeviceProvider;
    setState(() => _busyProvider = provider.apiValue);
    try {
      final granted = await ref.read(healthServiceProvider).connect();
      if (!mounted) return;
      if (granted) {
        setState(() => _connected = {..._connected, provider.apiValue});
      } else {
        _showMessage('Permission was not granted.');
      }
    } catch (e) {
      if (mounted) _showMessage('Could not connect: $e');
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  Future<void> _connectOAuth(
    IntegrationProvider provider,
    String displayName,
  ) async {
    setState(() => _busyProvider = provider.apiValue);
    try {
      final url = await ref
          .read(backendApiProvider)
          .getOAuthAuthorizationUrl(provider);
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: _kOAuthCallbackScheme,
      );
      final status = Uri.parse(result).queryParameters['status'];
      if (!mounted) return;
      switch (status) {
        case 'success':
          setState(() => _connected = {..._connected, provider.apiValue});
        case 'pending_credentials':
          _showMessage(
            '$displayName isn\'t fully live yet — pending API credentials.',
          );
        default:
          _showMessage('Could not connect to $displayName.');
      }
    } catch (e) {
      if (mounted) _showMessage('Could not connect to $displayName: $e');
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final onDevice = _onDeviceProvider;

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
          title: Text('Connected Apps', style: AppTypography.titleM),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : ListView(
                padding: const EdgeInsets.all(AppTheme.screenPaddingH),
                children: [
                  Text(
                    'Sync steps, distance, and workouts automatically by connecting a platform below.',
                    style: AppTypography.bodyM,
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  _IntegrationTile(
                    brand: Platform.isIOS
                        ? BrandType.healthkit
                        : BrandType.healthConnect,
                    name: Platform.isIOS ? 'Apple Health' : 'Health Connect',
                    subtitle: Platform.isIOS
                        ? 'Two-way sync — also writes back so other apps can prefer Strolla'
                        : 'Also covers Samsung Health and Google Fit — set Strolla as the preferred source in Health Connect',
                    connected: _connected.contains(onDevice.apiValue),
                    busy: _busyProvider == onDevice.apiValue,
                    onTap: _connectOnDevice,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.strava,
                    name: 'Strava',
                    subtitle: 'Import runs, rides, and walks',
                    connected: _connected.contains(
                      IntegrationProvider.strava.apiValue,
                    ),
                    busy: _busyProvider == IntegrationProvider.strava.apiValue,
                    onTap: () =>
                        _connectOAuth(IntegrationProvider.strava, 'Strava'),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.oura,
                    name: 'Oura',
                    subtitle: 'Sync daily activity from your Oura Ring',
                    connected: _connected.contains(
                      IntegrationProvider.oura.apiValue,
                    ),
                    busy: _busyProvider == IntegrationProvider.oura.apiValue,
                    onTap: () =>
                        _connectOAuth(IntegrationProvider.oura, 'Oura'),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.garmin,
                    name: 'Garmin',
                    subtitle: 'Sync activity from a connected Garmin device',
                    connected: _connected.contains(
                      IntegrationProvider.garmin.apiValue,
                    ),
                    busy: _busyProvider == IntegrationProvider.garmin.apiValue,
                    onTap: () =>
                        _connectOAuth(IntegrationProvider.garmin, 'Garmin'),
                    pendingApproval: true,
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: AppColors.accentSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          AppIcons.info,
                          color: AppColors.accent,
                          size: AppTheme.iconM,
                        ),
                        const SizedBox(width: AppTheme.spaceM),
                        Expanded(
                          child: Text(
                            'These show a neutral icon while each platform\'s official badge is pending approval — syncing itself isn\'t affected.',
                            style: AppTypography.bodyS,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: AppTheme.animSlow),
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.brand,
    required this.name,
    required this.subtitle,
    required this.connected,
    required this.busy,
    required this.onTap,
    this.pendingApproval = false,
  });

  final BrandType brand;
  final String name;
  final String subtitle;
  final bool connected;
  final bool busy;
  final VoidCallback onTap;
  final bool pendingApproval;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: [
          BrandLogo(type: brand, size: 40),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTypography.bodyL),
                    if (pendingApproval) ...[
                      const SizedBox(width: AppTheme.spaceS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Pending approval',
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.accent,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(subtitle, style: AppTypography.bodyS),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceM,
                  vertical: AppTheme.spaceS,
                ),
                decoration: BoxDecoration(
                  color: connected
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  connected ? 'Connected' : 'Connect',
                  style: AppTypography.labelM.copyWith(
                    color: connected ? AppColors.success : AppColors.accent,
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
