// Mirrors app/models/*.py in strola_health_backend_fastApi exactly — field
// names, enum values, and shapes match the real API so swapping mock data
// for live fetches later is a data-source change, not a type rewrite.

export type Role = "user" | "admin" | "super_admin";
export type Gender = "male" | "female" | "other" | "prefer_not_to_say";
export type UnitSystem = "metric" | "imperial";
export type StrollaReason =
  | "stroller_wagon"
  | "walking_pad"
  | "cant_wear_wearable"
  | "accurate_tracking"
  | "other";

export type SubscriptionTier = "free" | "premium";
export type SubscriptionStatus = "trialing" | "active" | "cancelled" | "expired";

export interface Subscription {
  tier: SubscriptionTier;
  status: SubscriptionStatus;
  // When this trial or paid subscription first began — distinct from
  // `renews_at`/`comp_until`, which mark when the *current* period ends.
  started_at: string | null;
  comp_until: string | null;
  comp_reason: string | null;
  revenuecat_app_user_id: string | null;
  renews_at: string | null;
  cancelled_at: string | null;
}

export interface PrivacySettings {
  public_profile: boolean;
  share_activity: boolean;
  show_in_leaderboards: boolean;
  allow_friend_requests: boolean;
  hide_activity_data: boolean;
  hide_achievements: boolean;
  hide_recent_activity: boolean;
}

export interface UserProfile {
  id: string;
  email: string | null;
  username: string;
  name: string;
  location: string | null;
  // Separate from `location` (a free-text profile field) — this is a
  // normalized country used for admin filtering/segmentation.
  country: string | null;
  bio: string | null;
  photo_url: string | null;
  height_cm: number;
  gender: Gender;
  date_of_birth: string | null;
  reasons: StrollaReason[];
  units: UnitSystem;
  onboarding_complete: boolean;
  daily_goal_steps: number;
  weight_kg: number | null;
  role: Role;
  privacy: PrivacySettings;
  subscription: Subscription;
  banned: boolean;
  ban_reason: string | null;
  // Lighter than `banned` — the account itself stays active (still counts
  // steps, joins challenges, etc.) but can't create posts or comments.
  // Distinct action for a community-only problem that doesn't warrant a
  // full account suspension.
  posting_banned: boolean;
  posting_ban_reason: string | null;
  // Set when the posting ban came from a timed mute rather than an
  // indefinite ban — null means "until manually unbanned."
  posting_banned_until: string | null;
  // Named cohort for beta access — see BetaOverride's "ambassador" target
  // type, which grants a feature to every user with this set rather than
  // one at a time.
  is_ambassador: boolean;
  // Phone OS — used for platform-targeted announcements ("iPhone"/"Android").
  // Null until the mobile app actually reports in at least once (every
  // account starts this way — onUserCreate has no platform info available
  // at signup time, since account creation happens before any app-side call).
  platform: "ios" | "android" | null;
  // e.g. "iPhone 16 Pro" — the specific handset, not just the OS.
  device_model: string | null;
  // Last-known installed app version — used for update-nudge announcement
  // targeting ("2.2.0 or older"), not tied to any single session. Null for
  // the same reason `platform` is — nothing sets it until the app reports in.
  app_version: string | null;
  // Freeform admin cohort labels (e.g. "kickstarter", "beta_tester") — used
  // for filtering and for bulk actions like granting premium to a cohort.
  tags: string[];
  deleted: boolean;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
}

// An admin-authored note on a user's account — internal only, never shown to
// the user themself. Freeform, append-only (no edit/delete in v1).
export interface UserNote {
  id: string;
  user_id: string;
  author_id: string;
  body: string;
  created_at: string;
}

export type DeviceType = "strolla_nrf7002";

export interface Device {
  id: string;
  serial_number: string;
  device_type: DeviceType;
  ble_mac: string | null;
  firmware_version: string | null;
  manufacturing_batch: string | null;
  owner_user_id: string | null;
  paired_at: string | null;
  last_seen_at: string | null;
  battery_level: number | null;
  // Last time this device's step/activity data actually finished syncing to
  // the backend — distinct from `last_seen_at` (BLE presence/heartbeat): a
  // device can be connected without its latest data having synced yet, and
  // a large enough gap between the two is what "sync failures" are derived
  // from on the Analytics dashboard.
  last_synced_at: string | null;
  created_at: string;
  // Set when a unit is retired via "Mark replaced" (warranty swap, lost
  // unit, etc.) — distinct from a never-assigned in-stock device, which has
  // this null and no owner either.
  replaced_at: string | null;
}

// No real OTA failure telemetry wired in yet — this type exists purely so a
// device that reported (or was reported as) a failed firmware push has a
// real shape to point at once one is. Distinct from `Device.firmware_version`,
// which only tracks the version currently installed, not failed attempts.
export interface FirmwareUpdateFailure {
  id: string;
  device_id: string;
  attempted_version: string;
  error: string;
  occurred_at: string;
  resolved: boolean;
}

// Self-service "delete my account" request awaiting admin action — distinct
// from `UserProfile.deleted`, which is the end state once an admin (or a
// backend job) has actually carried it out.
export interface AccountDeletionRequest {
  id: string;
  user_id: string;
  reason: string | null;
  requested_at: string;
  status: "pending" | "completed" | "cancelled";
}

export type ActivityType =
  | "outdoor_walk"
  | "outdoor_run"
  | "treadmill"
  | "strength_training"
  | "yoga"
  | "pilates"
  | "cardio"
  | "other";

export type DataSource =
  | "strolla_app"
  | "strolla_device"
  | "healthkit"
  | "health_connect"
  | "oura"
  | "garmin"
  | "strava"
  | "myfitnesspal"
  | "manual";

export interface RoutePoint {
  lat: number;
  lng: number;
  speed_mps: number;
}

export interface WorkoutSession {
  id: string;
  user_id: string;
  start_time: string;
  end_time: string;
  steps: number;
  distance_meters: number;
  duration_seconds: number;
  activity_type: ActivityType;
  custom_activity_name: string | null;
  route_points: RoutePoint[];
  avg_pace_sec_per_km: number | null;
  calories_burned: number | null;
  source: DataSource;
  external_id: string | null;
  created_at: string;
}

export interface SourceMetrics {
  steps: number;
  distance_meters: number;
  calories: number;
}

export interface DailyActivitySummary {
  id: string;
  user_id: string;
  date: string;
  by_source: Record<string, SourceMetrics>;
  steps: number;
  distance_meters: number;
  calories: number;
  primary_source: DataSource | null;
  updated_at: string;
}

export type ConnectionStatus = "connected" | "disconnected" | "error";

export interface IntegrationConnection {
  id: string;
  user_id: string;
  provider: DataSource;
  status: ConnectionStatus;
  scopes: string[];
  external_athlete_id: string | null;
  last_synced_at: string | null;
  connected_at: string | null;
  error_message: string | null;
}

export interface ModerationInfo {
  hidden: boolean;
  hidden_by: string | null;
  hidden_reason: string | null;
  hidden_at: string | null;
}

export interface CommunityPost {
  id: string;
  author_id: string;
  content: string;
  timestamp: string;
  likes_count: number;
  comments_count: number;
  step_count: number | null;
  badge_emoji: string | null;
  image_url: string | null;
  moderation: ModerationInfo;
  pinned: boolean;
  comments_locked: boolean;
}

export interface CommunityComment {
  id: string;
  post_id: string;
  author_id: string;
  content: string;
  timestamp: string;
  hidden: boolean;
}

export type ReportTargetType = "post" | "user";
export type ReportStatus = "open" | "resolved" | "dismissed";

export type ReportCategory =
  | "spam"
  | "harassment"
  | "misinformation"
  | "offensive_language"
  | "bullying"
  | "advertising"
  | "copyright"
  | "other";

// What actually happened as a result of this report — distinct from
// `status` (open/resolved/dismissed), which only says whether the report
// itself is closed out. Backs the reported user's moderation-history
// summary without parsing `resolution_note` text.
export type ModerationAction = "warned" | "muted" | "banned" | "post_removed" | "account_deleted" | "posts_deleted";

export interface Report {
  id: string;
  reporter_id: string;
  target_type: ReportTargetType;
  target_id: string;
  category: ReportCategory;
  reason: string;
  status: ReportStatus;
  action_taken: ModerationAction | null;
  resolved_by: string | null;
  resolved_at: string | null;
  resolution_note: string | null;
  created_at: string;
}

export type ChallengeVisibility = "public" | "private";

// Draft: being set up, not visible to users yet. Published: live — every
// challenge that existed before this field was added is backfilled as
// published in mock-data.ts. Archived: kept for the "Completed Public
// Challenges" historical record, no longer editable in the normal flow.
export type ChallengeLifecycleStatus = "draft" | "published" | "archived";

// How a winner is determined once the challenge ends. Most-steps is the raw
// cumulative total; goal-completion-% relates each participant's steps to
// their own locked_daily_goal, so someone with a lower personal goal can
// still "win" by comfortably clearing it, not just whoever walked most in
// absolute terms.
export type ChallengeWinnerType = "most_steps" | "goal_completion_pct";

export interface Challenge {
  id: string;
  title: string;
  description: string;
  goal_steps: number;
  start_date: string;
  end_date: string;
  badge_emoji: string;
  accent_color_value: number | null;
  visibility: ChallengeVisibility;
  is_official: boolean;
  invite_code: string | null;
  created_by: string | null;
  created_at: string;
  image_url: string | null;
  rules: string | null;
  winner_type: ChallengeWinnerType;
  status: ChallengeLifecycleStatus;
  // Defaults to whoever leads by `winner_type` once the challenge ends —
  // editable afterward for "edit winner information if needed" (e.g. a
  // disqualification discovered after the fact).
  winner_user_id: string | null;
  // Free-text, admin-only — never shown to users.
  admin_notes: string | null;
}

export interface ChallengeParticipant {
  id: string;
  challenge_id: string;
  user_id: string;
  steps: number;
  locked_daily_goal: number;
  joined_at: string;
  left_at: string | null;
}

// The metric a badge's requirement is checked against — kept small and
// closed rather than free text, so the app can actually evaluate "has this
// user met the requirement" instead of a description that only means
// something to a human reader. Extend this list (not the description) when
// the client wants a new kind of requirement.
export type BadgeRequirementMetric =
  | "total_steps"
  | "session_steps"
  | "streak_days"
  | "challenges_completed"
  | "early_morning_sessions"
  | "community_posts";

export interface Badge {
  id: string;
  name: string;
  description: string;
  emoji: string;
  requirement_metric: BadgeRequirementMetric;
  // Threshold for requirement_metric, e.g. 100_000 for "100k Steps" —
  // editable so the client can raise "100k Steps" to "150k Steps" without an
  // app release, per her own example.
  requirement_value: number;
  // Whether the badge can currently be earned at all.
  enabled: boolean;
  // Whether an unearned badge is shown to users as a locked/upcoming goal —
  // a badge can be enabled (past awards stand) but hidden from the catalog
  // while still being decided on.
  visible: boolean;
  created_at: string;
}

export interface UserBadge {
  id: string;
  user_id: string;
  badge_id: string;
  awarded_at: string;
  awarded_by: string | null;
}

export type AnalyticsEventType =
  | "account_created"
  | "app_opened"
  | "tracker_paired"
  | "workout_started"
  | "workout_completed"
  | "steps_shared"
  | "community_post_created"
  | "challenge_joined"
  | "challenge_completed"
  | "premium_started"
  | "premium_cancelled"
  | "widget_enabled"
  | "health_app_connected"
  // No real screen-view analytics SDK wired in yet (Mixpanel/Amplitude/
  // Firebase Analytics etc.) — same "mock data only for now" status as
  // CrashReport/SupportTicket, exists so the Analytics dashboard's "Screen
  // Usage" chart has a real shape to render once one is. `metadata.screen`
  // holds the screen name.
  | "screen_viewed";

export interface AnalyticsEvent {
  id: string;
  event_type: AnalyticsEventType;
  user_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface FeatureFlag {
  key: string;
  required_tier: SubscriptionTier;
  description: string | null;
  updated_at: string;
}

// There's no real crash-reporting pipeline (Crashlytics/Sentry) wired in
// yet — this type exists purely so the Dashboard's "Recent app crashes" stat
// has a real shape to point at once one is. Mock data only for now.
export interface CrashReport {
  id: string;
  user_id: string | null;
  platform: "ios" | "android";
  app_version: string;
  summary: string;
  occurred_at: string;
}

// No real support-ticket pipeline (Zendesk/Intercom) wired in yet — same
// "mock data only for now" status as CrashReport, exists so a user's
// account timeline has a real shape to point at once one is.
export interface SupportTicket {
  id: string;
  user_id: string | null;
  subject: string;
  status: "open" | "resolved";
  priority: "low" | "medium" | "high";
  created_at: string;
}

// Global defaults the app falls back to — a single row, not a list, since
// there's exactly one of these at a time (unlike feature flags, which are
// per-feature).
export interface AppSettings {
  default_daily_goal_steps: number;
  challenge_default_duration_days: number;
  // No "challenge_default_goal_steps" — challenges are leaderboard/
  // most-steps-based (see official-challenge-form-dialog.tsx), there's no
  // step goal to default.
  notify_goal_reminder_default: boolean;
  notify_streak_default: boolean;
  notify_challenge_updates_default: boolean;
  max_image_size_mb: number;
  max_post_length: number;
  max_bio_length: number;
  // Mirrors the backend's own `trial_period_days` config (SubscriptionService)
  // — the length of the automatic signup trial, in days.
  trial_period_days: number;
  premium_monthly_price_gbp: number;
  premium_annual_price_gbp: number;
  // Applied to a new signup server-side — same shape as UserProfile.privacy,
  // just the defaults rather than one user's current values.
  default_privacy: PrivacySettings;
  // Below this version, the app should prompt/force an update. Null = no
  // minimum enforced. No real update-gate is wired into the client yet —
  // this is the config a future version-check screen would read.
  minimum_required_app_version: string | null;
  updated_at: string;
}

// Grants a feature to a specific slice of users without touching the global
// FeatureFlag gate everyone else sees — the client's "enable beta features
// for specific users/emails/ambassadors without affecting everyone else."
export type BetaOverrideTargetType = "user_id" | "email" | "ambassador";

export interface BetaOverride {
  id: string;
  feature_key: string; // matches FeatureFlag.key
  target_type: BetaOverrideTargetType;
  // A user id or an email for the first two target types; unused (empty) for
  // "ambassador", since that grants every is_ambassador user at once.
  target_value: string;
  created_by: string | null;
  created_at: string;
}

// A message the app shows once per user on open — the client's own examples
// are a challenge launch and a new-feature announcement, so this is
// deliberately simple free text + emoji rather than a structured template
// system.
export type AnnouncementAudience =
  | "everyone"
  | "free"
  | "premium"
  | "new_users"
  | "beta_testers"
  | "kickstarter_backers"
  | "iphone"
  | "android"
  | "canada"
  | "usa"
  | "app_version";

export type AppVersionAudienceMode = "exact" | "at_or_below";

export interface Announcement {
  id: string;
  emoji: string;
  message: string;
  // Optional deep-link destination inside the app, e.g. "challenge_of_month"
  // or "community" — lets a "Join now" message actually take the user
  // somewhere.
  link_target: string | null;
  audience: AnnouncementAudience;
  // Set only when audience === "app_version" — "at_or_below" is the useful
  // one in practice (nudge everyone still on an old build to update).
  audience_app_version: string | null;
  audience_app_version_mode: AppVersionAudienceMode | null;
  active: boolean;
  starts_at: string;
  // Null = show indefinitely until deactivated.
  ends_at: string | null;
  created_by: string | null;
  created_at: string;
}

export type LegalDocumentType = "privacy_policy" | "terms" | "community_guidelines";

// "draft" = being edited, never shown to users. "published" = the single
// live version of this doc_type users see/must accept. "archived" =
// formerly published, kept for Version History and "Restore".
export type LegalVersionStatus = "draft" | "published" | "archived";

export interface LegalDocumentVersion {
  id: string;
  doc_type: LegalDocumentType;
  version: number;
  status: LegalVersionStatus;
  // Structured text — headings (# / ##), **bold**, "- " bullet lists,
  // "1. " numbered lists, and [text](url) links are the only supported
  // syntax; see components/legal/legal-markdown.tsx for the renderer.
  content: string;
  // Bullet-point "what's changed" summary, set when a draft is published —
  // null for drafts and for a doc's original v1 (nothing to summarize yet).
  changelog: string | null;
  // When this version takes effect — distinct from `published_at` (when an
  // admin actually hit Publish), since legal changes are often announced
  // ahead of when they bind.
  effective_date: string;
  // True only for a version that blocks app usage until the user accepts
  // again. A routine copy fix doesn't need this; a material change to what
  // users agreed to does.
  requires_reaccept: boolean;
  created_by: string | null;
  created_at: string;
  published_at: string | null;
}

export type LegalAcceptanceStatus = "accepted" | "pending" | "declined";

// No real acceptance-tracking pipeline is wired in yet — the app doesn't
// even fetch legal documents remotely today (LegalPage in the Flutter
// source renders fully hardcoded text), so there's nowhere upstream this
// would come from yet. Mock data only, same "ahead of the backend" status
// as CrashReport/SupportTicket — exists so Acceptance Analytics has a real
// shape to point at once an in-app accept/decline gate exists. One row per
// (user, doc_type, version) that required re-accept.
export interface LegalAcceptance {
  id: string;
  user_id: string;
  doc_type: LegalDocumentType;
  version: number;
  status: LegalAcceptanceStatus;
  responded_at: string | null;
}

// A single piece of app copy the client can edit without a developer or app
// release. `key` is what the Flutter app would look this up by — everything
// else is presentation for this editor.
export type AppContentCategory =
  | "onboarding"
  | "home"
  | "challenges"
  | "community"
  | "errors"
  | "buttons"
  | "settings"
  | "premium"
  | "notifications"
  | "widget"
  | "device_pairing"
  | "firmware";

export interface AppContentEntry {
  key: string;
  category: AppContentCategory;
  label: string;
  value: string;
  updated_at: string;
}

// Every audience the client asked to be able to target. "everyone" and the
// tier/geography ones are derived straight from UserProfile; the last two
// (challenge_participants, tracker_owners) need the participant/device
// collections too — see `segmentAudienceIds` in queries.ts.
export type PushSegment =
  | "everyone"
  | "premium"
  | "free"
  | "canada"
  | "usa"
  | "inactive_30d"
  | "challenge_participants"
  | "tracker_owners";

// No real push provider (FCM) wired in yet — sending just records history
// and reports the audience size it would have reached, computed at send
// time from the same mock collections the segment picker itself reads.
// Where a tap on the notification takes the user inside the app. "challenge"
// needs `link_challenge_id`; "custom" needs `link_custom_path` (a raw
// in-app route the client resolves); the rest are fixed top-level screens.
export type PushLinkTarget =
  | "none"
  | "challenge"
  | "community"
  | "stats"
  | "profile"
  | "premium"
  | "custom";

export type PushNotificationStatus = "draft" | "scheduled" | "sent";

// No real push provider (FCM) wired in yet — sending just records history
// and reports the audience size it would have reached, computed at send
// time from the same mock collections the segment picker itself reads.
// `delivered_count`/`opened_count` are likewise simulated at send time
// rather than reported back asynchronously by a real provider.
export interface PushNotification {
  id: string;
  segment: PushSegment;
  title: string;
  body: string;
  link_target: PushLinkTarget;
  link_challenge_id: string | null;
  link_custom_path: string | null;
  status: PushNotificationStatus;
  // Set once, when a draft is scheduled — null for drafts and already-sent notifications.
  scheduled_at: string | null;
  recipient_count: number;
  delivered_count: number;
  opened_count: number;
  sent_by: string | null;
  created_at: string;
  // Null until `status` is "sent".
  sent_at: string | null;
}
