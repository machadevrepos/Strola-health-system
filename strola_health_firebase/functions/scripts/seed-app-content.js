/**
 * One-off seed for the appContent collection (super_admin_next's "App
 * Content" staging library, see updateAppContent.ts). Every value below was
 * pulled directly from strola_health_flutter's actual source (file:line
 * verified), not invented, this is a spec/staging catalog ahead of the app
 * fetching it remotely, so it should reflect what's really in the app today,
 * not placeholder copy.
 *
 * Categories/keys with no real equivalent in the app (no dedicated pairing
 * success/fail toast, no firmware-update flow, no empty-community-feed
 * message, no literal "Save"/"Upgrade to Premium" button) are deliberately
 * left out rather than invented, see the audit notes inline.
 *
 * Usage (run from strola_health_firebase/functions/):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node scripts/seed-app-content.js
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const entries = [
  // --- Onboarding — lib/presentation/screens/auth/*, onboarding/onboarding_screen.dart ---
  { key: "onboarding.intro_slide_1_title", category: "onboarding", label: "Welcome carousel — slide 1 headline", value: "Track Every Step" },
  { key: "onboarding.intro_slide_1_body", category: "onboarding", label: "Welcome carousel — slide 1 body", value: "Never miss steps because your hands are busy. Pair your Strolla device for accurate tracking wherever life takes you." },
  { key: "onboarding.signup_heading", category: "onboarding", label: "Sign-up screen heading", value: "Create your account" },
  { key: "onboarding.signup_subtitle", category: "onboarding", label: "Sign-up screen subtitle", value: "We'll set up your profile right after this." },
  { key: "onboarding.signin_heading", category: "onboarding", label: "Sign-in screen heading", value: "Welcome back" },
  { key: "onboarding.profile_step_heading", category: "onboarding", label: "Onboarding wizard — profile step heading", value: "Let's set up your profile" },
  { key: "onboarding.profile_step_subtitle", category: "onboarding", label: "Onboarding wizard — profile step subtitle", value: "Just a few details to personalize your experience and keep your stats accurate." },
  { key: "onboarding.goal_step_heading", category: "onboarding", label: "Daily goal step — heading", value: "Your daily goal" },
  { key: "onboarding.goal_step_subtitle", category: "onboarding", label: "Daily goal step — subtitle", value: "How many steps are you aiming for each day?" },

  // --- Home — lib/presentation/widgets/step_ring.dart (home screen has almost no static copy otherwise) ---
  { key: "home.step_ring_goal_reached", category: "home", label: "Step ring — goal reached label", value: "Goal achieved! 🎉" },
  { key: "home.step_ring_steps_label", category: "home", label: "Step ring — 'Steps' unit label", value: "Steps" },

  // --- Challenges — lib/presentation/screens/challenges_screen.dart ---
  { key: "challenges.of_the_month_eyebrow", category: "challenges", label: "Challenge-of-the-month banner — eyebrow label", value: "Challenge of the Month" },
  { key: "challenges.of_the_month_body", category: "challenges", label: "Challenge-of-the-month banner — body copy", value: "Step more, move together, and finish May stronger than you started!" },

  // --- Community — lib/presentation/screens/community_screen.dart ---
  { key: "community.post_composer_placeholder", category: "community", label: "Post composer input placeholder", value: "Share a win, challenge, question, or tip with the community…" },
  { key: "community.composer_teaser", category: "community", label: "Composer teaser row (opens composer sheet)", value: "What's on your mind?" },

  // --- Errors — lib/presentation/providers/auth_providers.dart, activity_screen.dart, community_screen.dart ---
  { key: "errors.network", category: "errors", label: "Network error (sign-in)", value: "Couldn't reach the network. Check your connection and try again." },
  { key: "errors.generic_auth", category: "errors", label: "Generic account/sign-in error", value: "Couldn't connect to your account right now. Please try again shortly." },
  { key: "errors.generic_fallback", category: "errors", label: "Generic fallback error", value: "Something went wrong. Please try again." },
  { key: "errors.fatal_boundary", category: "errors", label: "Fatal error boundary", value: "Something went wrong.\nPlease restart the app." },
  { key: "errors.community_feed_load_failed", category: "errors", label: "Community feed failed to load", value: "Could not load posts." },

  // --- Buttons — various screens ---
  { key: "buttons.join_challenge", category: "buttons", label: "Join a challenge", value: "Join Challenge" },
  { key: "buttons.joined_challenge", category: "buttons", label: "Already-joined state", value: "Joined" },
  { key: "buttons.save_changes", category: "buttons", label: "Save changes (editing an existing profile)", value: "Save Changes" },
  { key: "buttons.complete_setup", category: "buttons", label: "Complete onboarding (new profile)", value: "Complete Setup" },
  { key: "buttons.confirm", category: "buttons", label: "Generic wheel-picker confirm", value: "Confirm" },
  { key: "buttons.continue_purchase", category: "buttons", label: "Paywall purchase button", value: "Continue" },
  { key: "buttons.premium_upgrade_row", category: "buttons", label: "Settings row — Premium upsell trailing label", value: "Upgrade" },

  // --- Settings — lib/presentation/screens/settings_screen.dart ---
  { key: "settings.edit_profile_row", category: "settings", label: "\"Edit Profile\" row", value: "Edit Profile" },
  { key: "settings.units_row", category: "settings", label: "\"Units\" row", value: "Units" },
  { key: "settings.push_notifications_row", category: "settings", label: "Notification setting — \"Push Notifications\"", value: "Push Notifications" },
  { key: "settings.milestone_alerts_row", category: "settings", label: "Notification setting — \"Milestone Alerts\"", value: "Milestone Alerts" },
  { key: "settings.friends_activity_row", category: "settings", label: "Notification setting — \"Friends Activity\"", value: "Friends Activity" },
  { key: "settings.challenge_updates_row", category: "settings", label: "Notification setting — \"Challenge Updates\"", value: "Challenge Updates" },
  { key: "settings.likes_comments_row", category: "settings", label: "Notification setting — \"Likes & Comments\"", value: "Likes & Comments" },

  // --- Premium — lib/presentation/screens/paywall_screen.dart ---
  { key: "premium.paywall_headline", category: "premium", label: "Paywall headline", value: "Get the most out of Strolla" },
  { key: "premium.benefit_1", category: "premium", label: "Paywall benefit 1", value: "Unlimited personal record tracking" },
  { key: "premium.benefit_2", category: "premium", label: "Paywall benefit 2", value: "Full platform sync — Strava, Oura, Garmin, and more" },
  { key: "premium.benefit_3", category: "premium", label: "Paywall benefit 3", value: "Advanced stats and trends" },
  { key: "premium.benefit_4", category: "premium", label: "Paywall benefit 4", value: "Priority support" },
  { key: "premium.already_premium_title", category: "premium", label: "Already-Premium state — title", value: "You're already Premium" },
  { key: "premium.already_premium_body", category: "premium", label: "Already-Premium state — body", value: "Thanks for supporting Strolla — every feature is unlocked." },
  { key: "premium.unavailable_title", category: "premium", label: "Offerings-unavailable state — title", value: "Premium isn't available yet" },
  { key: "premium.unavailable_body", category: "premium", label: "Offerings-unavailable state — body", value: "Check back soon — we're still setting up purchases." },

  // --- Notifications — lib/core/constants/notification_copy.dart ---
  { key: "notifications.goal_reminder", category: "notifications", label: "Goal reminder push (75%+ of the way there)", value: "You're only {StepsRemaining} steps away from today's goal." },
  { key: "notifications.goal_achieved", category: "notifications", label: "Goal achieved push", value: "Goal achieved! Way to go!" },
  { key: "notifications.streak", category: "notifications", label: "Streak push (generic day count)", value: "{StreakDays} days in a row! Amazing consistency." },
  { key: "notifications.low_battery", category: "notifications", label: "Low battery push", value: "Your Strolla battery is running low." },

  // --- Widget — lib/presentation/widgets/widget_preview_card.dart, add_widget_sheet.dart ---
  { key: "widget.steps_today_label", category: "widget", label: "Home-screen widget — steps unit label", value: "steps today" },
  { key: "widget.goal_reached", category: "widget", label: "Widget — goal reached state", value: "Goal achieved! 🎉" },
  { key: "widget.keep_going", category: "widget", label: "Widget — goal not yet reached state", value: "Keep going,\nyou've got this!" },
  { key: "widget.add_widget_title", category: "widget", label: "Add-widget prompt sheet — title", value: "Add the Strolla widget" },
  { key: "widget.add_widget_body", category: "widget", label: "Add-widget prompt sheet — body", value: "See your steps right on your home screen" },
  { key: "widget.add_widget_cta", category: "widget", label: "Add-widget prompt sheet — button", value: "Add to Home Screen" },
  { key: "widget.add_widget_dismiss", category: "widget", label: "Add-widget prompt sheet — dismiss", value: "Maybe later" },

  // --- Device pairing — lib/presentation/screens/device_screen.dart ---
  // No real pairing-success/failed toast exists yet (BLE errors are caught
  // and silently discarded), so those two keys are deliberately not seeded.
  { key: "device_pairing.status_connected", category: "device_pairing", label: "Status pill — connected", value: "Connected" },
  { key: "device_pairing.status_scanning", category: "device_pairing", label: "Status pill — scanning", value: "Scanning for device…" },
  { key: "device_pairing.status_not_connected", category: "device_pairing", label: "Status pill — not connected", value: "Not connected" },
  { key: "device_pairing.connect_button", category: "device_pairing", label: "Connect button label", value: "Connect to Device" },
  { key: "device_pairing.disconnect_button", category: "device_pairing", label: "Disconnect button label", value: "Disconnect" },

  // --- Firmware — no real firmware-update flow exists in the app yet, so
  // nothing is seeded for this category. Not an oversight, see README.
];

async function main() {
  const batch = db.batch();
  for (const entry of entries) {
    const ref = db.collection("appContent").doc(entry.key);
    batch.set(
      ref,
      {
        key: entry.key,
        category: entry.category,
        label: entry.label,
        value: entry.value,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  await batch.commit();
  console.log(`Seeded ${entries.length} appContent entries.`);
}

main().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
