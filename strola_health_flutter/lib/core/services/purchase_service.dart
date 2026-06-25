import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat API keys — public SDK keys (safe to embed in the client,
/// unlike the secret key used by the backend's webhook). Left blank until a
/// RevenueCat project exists; every method here degrades gracefully rather
/// than throwing when that's the case, since the rest of the app should stay
/// usable without monetization configured yet.
const _kIosApiKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
const _kAndroidApiKey = String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');

class PurchaseService {
  PurchaseService._();

  static bool get isConfigured =>
      Platform.isIOS ? _kIosApiKey.isNotEmpty : _kAndroidApiKey.isNotEmpty;

  /// Call once at app startup. Anonymous until [logIn] links it to the
  /// signed-in Firebase user.
  static Future<void> configure() async {
    if (!isConfigured) return;
    final apiKey = Platform.isIOS ? _kIosApiKey : _kAndroidApiKey;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  /// Links RevenueCat's anonymous id to this Firebase user, so entitlements
  /// follow them across devices/reinstalls rather than resetting.
  static Future<void> logIn(String firebaseUid) async {
    if (!isConfigured) return;
    await Purchases.logIn(firebaseUid);
  }

  /// Detaches the purchaser identity on sign-out, reverting to a fresh
  /// anonymous id. Without this, the next account signed in on this device
  /// would inherit the previous account's cached entitlements.
  static Future<void> logOut() async {
    if (!isConfigured) return;
    await Purchases.logOut();
  }

  static Future<Offerings?> getOfferings() async {
    if (!isConfigured) return null;
    return Purchases.getOfferings();
  }

  static Future<CustomerInfo> purchase(Package package) {
    return Purchases.purchasePackage(package);
  }

  static Future<CustomerInfo> restore() {
    return Purchases.restorePurchases();
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!isConfigured) return null;
    return Purchases.getCustomerInfo();
  }
}
