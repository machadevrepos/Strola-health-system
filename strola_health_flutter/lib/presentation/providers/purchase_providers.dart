import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:strola_health/core/services/purchase_service.dart';
import 'package:strola_health/data/datasources/backend_api.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';

/// Re-fetches whenever the signed-in user changes — logs the new user into
/// RevenueCat first, so the entitlement check that follows is for the right
/// account rather than whatever anonymous id was active before.
final customerInfoProvider = FutureProvider<CustomerInfo?>((ref) async {
  if (!PurchaseService.isConfigured) return null;
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    await PurchaseService.logIn(user.uid);
  }
  return PurchaseService.getCustomerInfo();
});

/// The backend's `subscription.tier`/`comp_until` — the cross-device source
/// of truth. Needed because not every entitlement is a RevenueCat purchase:
/// the signup trial and any admin-granted comp period are backend-only and
/// would never show up in `customerInfoProvider` alone.
final backendSubscriptionActiveProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  try {
    final me = await ref.read(backendApiProvider).getMe();
    final subscription = me['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return false;
    if (subscription['tier'] == 'premium') return true;
    final compUntil = subscription['comp_until'] as String?;
    if (compUntil == null) return false;
    final until = DateTime.tryParse(compUntil);
    return until != null && until.isAfter(DateTime.now());
  } catch (_) {
    return false;
  }
});

final isPremiumProvider = Provider<bool>((ref) {
  final fromRevenueCat =
      ref.watch(customerInfoProvider).value?.entitlements.active.isNotEmpty ??
      false;
  final fromBackend =
      ref.watch(backendSubscriptionActiveProvider).value ?? false;
  return fromRevenueCat || fromBackend;
});

final offeringsProvider = FutureProvider<Offerings?>(
  (ref) => PurchaseService.getOfferings(),
);
