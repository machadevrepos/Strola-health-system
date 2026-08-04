/// Maps a notification's `link_target` (sent identically by the backend's
/// push data payload — see notifyEvents.ts/notifyOnOfficialChallenge.ts —
/// and by locally-created [AppNotification]s) to the tab index MainShell's
/// `mainTabIndexProvider` expects. One shared mapping so a server push and
/// an in-app notification tap land on the same screen for the same target
/// string, used by both notifications_screen.dart (foreground tap, has a
/// BuildContext) and push_message_listener.dart (background/terminated tap,
/// doesn't).
///
/// Keys match the backend's actual `link_target` values exactly — singular
/// `'challenge'`, not `'challenges'`.
const Map<String, int> pushLinkTargetTabIndex = {
  'home': 0,
  'stats': 1,
  'community': 2,
  'challenge': 3,
};

int? tabIndexForLinkTarget(String? linkTarget) =>
    linkTarget == null ? null : pushLinkTargetTabIndex[linkTarget];
