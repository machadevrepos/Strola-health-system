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
  // Named cohort for beta access — see BetaOverride's "ambassador" target
  // type, which grants a feature to every user with this set rather than
  // one at a time.
  is_ambassador: boolean;
  deleted: boolean;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
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
  created_at: string;
  // Set when a unit is retired via "Mark replaced" (warranty swap, lost
  // unit, etc.) — distinct from a never-assigned in-stock device, which has
  // this null and no owner either.
  replaced_at: string | null;
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

export interface Report {
  id: string;
  reporter_id: string;
  target_type: ReportTargetType;
  target_id: string;
  reason: string;
  status: ReportStatus;
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
  | "health_app_connected";

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

// Global defaults the app falls back to — a single row, not a list, since
// there's exactly one of these at a time (unlike feature flags, which are
// per-feature).
export interface AppSettings {
  default_daily_goal_steps: number;
  challenge_default_duration_days: number;
  challenge_default_goal_steps: number;
  notify_goal_reminder_default: boolean;
  notify_streak_default: boolean;
  notify_challenge_updates_default: boolean;
  max_image_size_mb: number;
  max_post_length: number;
  max_bio_length: number;
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
export interface Announcement {
  id: string;
  emoji: string;
  message: string;
  // Optional deep-link destination inside the app, e.g. "challenge_of_month"
  // or "community" — lets a "Join now" message actually take the user
  // somewhere.
  link_target: string | null;
  active: boolean;
  starts_at: string;
  // Null = show indefinitely until deactivated.
  ends_at: string | null;
  created_by: string | null;
  created_at: string;
}

export type LegalDocumentType = "privacy_policy" | "terms" | "community_guidelines";

export interface LegalDocument {
  type: LegalDocumentType;
  version: number;
  content: string;
  updated_at: string;
  // True only for the version that was published with a forced re-accept —
  // the app blocks usage until the user accepts again. A routine copy fix
  // doesn't need this; a material change to what users agreed to does.
  requires_reaccept: boolean;
}

// A single piece of app copy the client can edit without a developer or app
// release. `key` is what the Flutter app would look this up by — everything
// else is presentation for this editor.
export type AppContentCategory =
  | "welcome_messages"
  | "challenge_descriptions"
  | "motivational_quotes"
  | "notification_text"
  | "empty_states";

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
export interface PushNotification {
  id: string;
  segment: PushSegment;
  title: string;
  body: string;
  recipient_count: number;
  sent_by: string | null;
  sent_at: string;
}
