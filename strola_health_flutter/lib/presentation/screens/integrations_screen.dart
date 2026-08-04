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
  /// Provider apiValue → its connection doc (id/status/etc, see
  /// listMyIntegrationConnections.ts's sanitizeConnection) — kept as full
  /// maps rather than just a connected-providers set because disconnecting
  /// needs the connection's real `id`.
  Map<String, Map<String, dynamic>> _connections = {};
  bool _loading = true;
  String? _busyProvider;

  IntegrationProvider get _onDeviceProvider => Platform.isIOS
      ? IntegrationProvider.healthkit
      : IntegrationProvider.healthConnect;

  bool _isConnected(String providerApiValue) =>
      _connections[providerApiValue]?['status'] == 'connected';

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
        _connections = {
          for (final i in integrations) i['provider'] as String: i,
        };
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
        await _loadConnections();
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
          await _loadConnections();
        case 'pending_credentials':
          _showMessage(
            '$displayName isn\'t fully live yet, pending API credentials.',
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

  Future<void> _confirmDisconnect(
    IntegrationProvider provider,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Disconnect $displayName?',
          style: AppTypography.titleM.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Strolla will stop syncing new data from $displayName. Your existing history stays as-is.",
          style: AppTypography.bodyS,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Disconnect',
              style: AppTypography.bodyL.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _disconnect(provider, displayName);
  }

  Future<void> _disconnect(
    IntegrationProvider provider,
    String displayName,
  ) async {
    final connectionId = _connections[provider.apiValue]?['id'] as String?;
    if (connectionId == null) return;
    setState(() => _busyProvider = provider.apiValue);
    try {
      await ref.read(backendApiProvider).disconnectIntegration(connectionId);
      if (mounted) {
        setState(() {
          _connections = {..._connections}..remove(provider.apiValue);
        });
      }
    } catch (e) {
      if (mounted) _showMessage('Could not disconnect $displayName: $e');
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
                        ? 'Two-way sync, also writes back so other apps can prefer Strolla'
                        : 'Also covers Samsung Health and Google Fit. Set Strolla as the preferred source in Health Connect',
                    connected: _isConnected(onDevice.apiValue),
                    busy: _busyProvider == onDevice.apiValue,
                    onTap: _connectOnDevice,
                    onDisconnect: () => _confirmDisconnect(
                      onDevice,
                      Platform.isIOS ? 'Apple Health' : 'Health Connect',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.strava,
                    name: 'Strava',
                    subtitle: 'Import runs, rides, and walks',
                    connected: _isConnected(
                      IntegrationProvider.strava.apiValue,
                    ),
                    busy: _busyProvider == IntegrationProvider.strava.apiValue,
                    onTap: () =>
                        _connectOAuth(IntegrationProvider.strava, 'Strava'),
                    onDisconnect: () => _confirmDisconnect(
                      IntegrationProvider.strava,
                      'Strava',
                    ),
                    comingSoon: true,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.oura,
                    name: 'Oura',
                    subtitle: 'Sync daily activity from your Oura Ring',
                    connected: _isConnected(IntegrationProvider.oura.apiValue),
                    busy: _busyProvider == IntegrationProvider.oura.apiValue,
                    onTap: () =>
                        _connectOAuth(IntegrationProvider.oura, 'Oura'),
                    onDisconnect: () =>
                        _confirmDisconnect(IntegrationProvider.oura, 'Oura'),
                    comingSoon: true,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.garmin,
                    name: 'Garmin',
                    subtitle: 'Sync activity from a connected Garmin device',
                    connected: _isConnected(
                      IntegrationProvider.garmin.apiValue,
                    ),
                    busy: _busyProvider == IntegrationProvider.garmin.apiValue,
                    onTap: () =>
                        _connectOAuth(IntegrationProvider.garmin, 'Garmin'),
                    onDisconnect: () => _confirmDisconnect(
                      IntegrationProvider.garmin,
                      'Garmin',
                    ),
                    pendingApproval: true,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _IntegrationTile(
                    brand: BrandType.myFitnessPal,
                    name: 'MyFitnessPal',
                    subtitle: 'Sync logged meals and calorie totals',
                    connected: _isConnected(
                      IntegrationProvider.myfitnesspal.apiValue,
                    ),
                    busy:
                        _busyProvider ==
                        IntegrationProvider.myfitnesspal.apiValue,
                    onTap: () => _connectOAuth(
                      IntegrationProvider.myfitnesspal,
                      'MyFitnessPal',
                    ),
                    onDisconnect: () => _confirmDisconnect(
                      IntegrationProvider.myfitnesspal,
                      'MyFitnessPal',
                    ),
                    comingSoon: true,
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
                            'These show a neutral icon while each platform\'s official badge is pending approval. Syncing itself isn\'t affected.',
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
    required this.onDisconnect,
    this.pendingApproval = false,
    this.comingSoon = false,
  });

  final BrandType brand;
  final String name;
  final String subtitle;
  final bool connected;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onDisconnect;
  final bool pendingApproval;

  /// Not open to users yet (backend integration still being built/verified)
  /// — shows a static "Coming soon" pill instead of an active Connect
  /// button, and the tile itself isn't tappable.
  final bool comingSoon;

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
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.bodyL,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pendingApproval || comingSoon) ...[
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
                          comingSoon ? 'Coming soon' : 'Pending approval',
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
          if (comingSoon)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM,
                vertical: AppTheme.spaceS,
              ),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Coming soon',
                style: AppTypography.labelM.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (busy)
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
              onTap: connected ? onDisconnect : onTap,
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
