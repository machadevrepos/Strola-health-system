import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Registered synchronously here, before `super.application(...)` starts
    // the Flutter engine (and with it, Dart's `main()`) — the classic,
    // battle-tested ordering. Previously this used the newer "implicit
    // engine" delegate hook (`didInitializeImplicitFlutterEngine`), which in
    // this project deterministically never registered plugins in time: every
    // cold start hit `[core/not-initialized]` on `Firebase.initializeApp()`
    // even after retrying for 7+ seconds — not a timing race, the hook
    // simply wasn't firing before Dart code needed the plugins.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
