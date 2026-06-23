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

export interface Badge {
  id: string;
  name: string;
  description: string;
  emoji: string;
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
