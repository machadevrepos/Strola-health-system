import type {
  AccountDeletionRequest,
  AnalyticsEvent,
  AnalyticsEventType,
  Announcement,
  AppContentEntry,
  AppSettings,
  Badge,
  BetaOverride,
  Challenge,
  ChallengeParticipant,
  CommunityComment,
  CommunityPost,
  CrashReport,
  DailyActivitySummary,
  Device,
  FeatureFlag,
  FirmwareUpdateFailure,
  IntegrationConnection,
  LegalAcceptance,
  LegalDocumentVersion,
  PushNotification,
  Report,
  SupportTicket,
  UserBadge,
  UserNote,
  UserProfile,
  WorkoutSession,
} from "@/lib/types";

// Deterministic "now" so the demo data (and relative timestamps in the UI)
// stay stable across reloads instead of drifting with the real clock.
const NOW = new Date("2026-06-21T09:00:00Z");

function daysAgo(n: number, hour = 9, minute = 0): string {
  const d = new Date(NOW);
  d.setUTCDate(d.getUTCDate() - n);
  d.setUTCHours(hour, minute, 0, 0);
  return d.toISOString();
}

function dateKey(n: number): string {
  return daysAgo(n).slice(0, 10);
}

// --- Users ------------------------------------------------------------------

interface UserSeed {
  id: string;
  email: string;
  username: string;
  name: string;
  location?: string;
  country?: string;
  bio?: string;
  gender: UserProfile["gender"];
  height_cm: number;
  weight_kg: number | null;
  daily_goal_steps: number;
  role: UserProfile["role"];
  createdDaysAgo: number;
  subscription: Partial<UserProfile["subscription"]>;
  banned?: boolean;
  ban_reason?: string;
  postingBanned?: boolean;
  postingBanReason?: string;
  isAmbassador?: boolean;
  platform?: "ios" | "android";
  deviceModel?: string;
  appVersion?: string;
  tags?: string[];
  deleted?: boolean;
  reasons?: UserProfile["reasons"];
}

const userSeeds: UserSeed[] = [
  { id: "usr_001", email: "priya.shah@gmail.com", username: "priya.walks", name: "Priya Shah", location: "Leeds, UK", country: "United Kingdom", bio: "Recovering from a knee injury, taking it one walk at a time.", gender: "female", height_cm: 163, weight_kg: 61, daily_goal_steps: 6000, role: "user", createdDaysAgo: 188, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-9) }, reasons: ["accurate_tracking"], platform: "ios", deviceModel: "iPhone 14" },
  { id: "usr_002", email: "tom.brennan@outlook.com", username: "tombrennan", name: "Tom Brennan", location: "Bristol, UK", country: "United Kingdom", gender: "male", height_cm: 179, weight_kg: 82, daily_goal_steps: 10000, role: "user", createdDaysAgo: 142, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-3), comp_reason: "signup_trial" }, platform: "android", deviceModel: "Samsung Galaxy S23", appVersion: "2.3.1" },
  { id: "usr_003", email: "sarah.mwangi@yahoo.com", username: "sarah.m", name: "Sarah Mwangi", location: "Manchester, UK", country: "United Kingdom", bio: "Stroller walks with a 7-month-old most mornings.", gender: "female", height_cm: 168, weight_kg: 64, daily_goal_steps: 8000, role: "user", createdDaysAgo: 96, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-21) }, reasons: ["stroller_wagon"], platform: "ios", deviceModel: "iPhone 13" },
  { id: "usr_004", email: "j.kowalczyk88@gmail.com", username: "jkowalczyk", name: "James Kowalczyk", location: "Sheffield, UK", country: "United Kingdom", gender: "male", height_cm: 174, weight_kg: 76, daily_goal_steps: 12000, role: "user", createdDaysAgo: 211, subscription: { tier: "free", status: "expired" }, platform: "android", deviceModel: "Google Pixel 7", appVersion: "2.2.0" },
  { id: "usr_005", email: "mei.lin.99@gmail.com", username: "mei.lin", name: "Mei Lin", location: "Birmingham, UK", country: "United Kingdom", bio: "Walking pad at my desk, every single day.", gender: "female", height_cm: 159, weight_kg: 55, daily_goal_steps: 9000, role: "user", createdDaysAgo: 64, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-26), comp_reason: "signup_trial" }, reasons: ["walking_pad"], platform: "ios", deviceModel: "iPhone 12" },
  { id: "usr_006", email: "dan.holloway@hotmail.com", username: "dan.h", name: "Dan Holloway", location: "Edinburgh, UK", country: "United Kingdom", gender: "male", height_cm: 183, weight_kg: 88, daily_goal_steps: 10000, role: "user", createdDaysAgo: 301, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-14) }, platform: "android", deviceModel: "Samsung Galaxy S22" },
  { id: "usr_007", email: "alex.reyes@gmail.com", username: "alex.r", name: "Alex Reyes", location: "Cardiff, UK", country: "United Kingdom", gender: "other", height_cm: 171, weight_kg: 69, daily_goal_steps: 15000, role: "user", createdDaysAgo: 47, subscription: { tier: "premium", status: "active", comp_until: daysAgo(-150), comp_reason: "kickstarter_backer" }, isAmbassador: true, platform: "ios", deviceModel: "iPhone 15 Pro", tags: ["kickstarter"] },
  { id: "usr_008", email: "fatima.hussain22@gmail.com", username: "fatima.h", name: "Fatima Hussain", location: "Glasgow, UK", country: "United Kingdom", bio: "Night-shift A&E nurse, can't wear a watch on the ward.", gender: "female", height_cm: 165, weight_kg: 60, daily_goal_steps: 7000, role: "user", createdDaysAgo: 33, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-4), comp_reason: "signup_trial" }, reasons: ["cant_wear_wearable"], platform: "android", deviceModel: "OnePlus 11", appVersion: "2.3.1" },
  { id: "usr_009", email: "ollie.fenwick@gmail.com", username: "ollie.fenwick", name: "Ollie Fenwick", location: "Toronto, Canada", country: "Canada", gender: "male", height_cm: 177, weight_kg: 79, daily_goal_steps: 10000, role: "user", createdDaysAgo: 19, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-26), comp_reason: "signup_trial" }, platform: "ios", deviceModel: "iPhone 13 Pro" },
  { id: "usr_010", email: "ruth.adeyemi@gmail.com", username: "ruth.a", name: "Ruth Adeyemi", location: "London, UK", country: "United Kingdom", gender: "female", height_cm: 170, weight_kg: 67, daily_goal_steps: 8500, role: "user", createdDaysAgo: 5, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-25), comp_reason: "signup_trial" }, platform: "ios", deviceModel: "iPhone 16" },
  { id: "usr_011", email: "marcus.webb@protonmail.com", username: "marcus.webb", name: "Marcus Webb", location: "Liverpool, UK", country: "United Kingdom", gender: "male", height_cm: 181, weight_kg: 91, daily_goal_steps: 10000, role: "user", createdDaysAgo: 220, subscription: { tier: "free", status: "expired" }, banned: true, ban_reason: "Repeated harassment in community comments after two prior warnings.", platform: "android", deviceModel: "Samsung Galaxy S21", appVersion: "2.2.0" },
  { id: "usr_012", email: "lena.kovac@gmail.com", username: "lena.k", name: "Lena Kovac", location: "Nottingham, UK", country: "United Kingdom", gender: "female", height_cm: 162, weight_kg: 58, daily_goal_steps: 9500, role: "user", createdDaysAgo: 78, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-2) }, platform: "ios", deviceModel: "iPhone 13 mini", appVersion: "2.3.1" },
  { id: "usr_013", email: "deleted-user-9f2@strolla.health", username: "deleted_9f2a8b1c", name: "Deleted User", gender: "prefer_not_to_say", height_cm: 170, weight_kg: null, daily_goal_steps: 10000, role: "user", createdDaysAgo: 260, subscription: { tier: "free", status: "expired" }, deleted: true },
  { id: "usr_014", email: "ben.okafor@gmail.com", username: "ben.okafor", name: "Ben Okafor", location: "Austin, USA", country: "United States", gender: "male", height_cm: 175, weight_kg: 73, daily_goal_steps: 11000, role: "user", createdDaysAgo: 13, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-17), comp_reason: "signup_trial" }, platform: "ios", deviceModel: "iPhone 15" },
  { id: "usr_015", email: "grace.tan@gmail.com", username: "grace.tan", name: "Grace Tan", location: "Southampton, UK", country: "United Kingdom", gender: "female", height_cm: 160, weight_kg: 54, daily_goal_steps: 7500, role: "user", createdDaysAgo: 156, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-30) }, isAmbassador: true, platform: "android", deviceModel: "Google Pixel 8 Pro", tags: ["beta_tester"] },
  { id: "usr_016", email: "support.maya@strollahealth.com", username: "maya.ops", name: "Maya Whitfield", location: "Remote", country: "United Kingdom", gender: "female", height_cm: 167, weight_kg: 63, daily_goal_steps: 8000, role: "admin", createdDaysAgo: 305, subscription: { tier: "free", status: "active" }, platform: "ios", deviceModel: "iPhone 15" },
  { id: "usr_017", email: "founder.sarah@strollahealth.com", username: "sarah.founder", name: "Sarah Pemberton", location: "Remote", country: "United Kingdom", gender: "female", height_cm: 165, weight_kg: 60, daily_goal_steps: 8000, role: "super_admin", createdDaysAgo: 365, subscription: { tier: "free", status: "active" }, platform: "android", deviceModel: "Samsung Galaxy S24" },
  // Official brand account — authors posts made from the Community section's
  // "Post as Strolla Health" composer. Role "admin" so it's excluded from
  // real-user metrics (signups, DAU, subscriptions) the same way staff are.
  { id: "usr_024", email: "hello@strollahealth.com", username: "strollahealth", name: "Strolla Health", location: "Remote", country: "United Kingdom", bio: "Official updates, tips, and challenges from the Strolla Health team.", gender: "prefer_not_to_say", height_cm: 170, weight_kg: null, daily_goal_steps: 8000, role: "admin", createdDaysAgo: 365, subscription: { tier: "free", status: "active" }, platform: "ios", deviceModel: "iPhone 15" },
  { id: "usr_018", email: "callum.ferris@gmail.com", username: "callum.f", name: "Callum Ferris", location: "Aberdeen, UK", country: "United Kingdom", gender: "male", height_cm: 178, weight_kg: 84, daily_goal_steps: 10000, role: "user", createdDaysAgo: 41, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-1), comp_reason: "signup_trial" }, postingBanned: true, postingBanReason: "Repeated 'free premium code' spam links across multiple posts (see rep_001, rep_006).", platform: "ios", deviceModel: "iPhone 12 mini" },
  { id: "usr_019", email: "isabel.cruz@gmail.com", username: "isabel.cruz", name: "Isabel Cruz", location: "Sydney, Australia", country: "Australia", gender: "female", height_cm: 158, weight_kg: 52, daily_goal_steps: 6500, role: "user", createdDaysAgo: 9, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-21), comp_reason: "signup_trial" }, platform: "android", deviceModel: "Samsung Galaxy S23 Ultra" },
  { id: "usr_020", email: "harvey.nash@gmail.com", username: "harvey.nash", name: "Harvey Nash", location: "Belfast, UK", country: "United Kingdom", gender: "male", height_cm: 172, weight_kg: 70, daily_goal_steps: 10000, role: "user", createdDaysAgo: 2, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-28), comp_reason: "signup_trial" }, platform: "ios", deviceModel: "iPhone 14 Pro" },
  // Genuinely free: trial already lapsed, never subscribed, never admin-granted.
  { id: "usr_021", email: "noah.sinclair@gmail.com", username: "noah.sinclair", name: "Noah Sinclair", location: "York, UK", country: "United Kingdom", gender: "male", height_cm: 180, weight_kg: 86, daily_goal_steps: 8000, role: "user", createdDaysAgo: 6, subscription: { tier: "free", status: "expired" }, platform: "android", deviceModel: "Google Pixel 6a" },
  { id: "usr_022", email: "aisha.begum@gmail.com", username: "aisha.begum", name: "Aisha Begum", location: "Bradford, UK", country: "United Kingdom", gender: "female", height_cm: 161, weight_kg: 57, daily_goal_steps: 7000, role: "user", createdDaysAgo: 15, subscription: { tier: "free", status: "expired" }, platform: "ios", deviceModel: "iPhone 11" },
  { id: "usr_023", email: "connor.walsh@gmail.com", username: "connor.walsh", name: "Connor Walsh", location: "Derby, UK", country: "United Kingdom", gender: "male", height_cm: 176, weight_kg: 80, daily_goal_steps: 9000, role: "user", createdDaysAgo: 24, subscription: { tier: "free", status: "expired" }, platform: "android", deviceModel: "Samsung Galaxy A54" },
];

// Trial subscribers "started" at signup; paying subscribers are assumed to
// have upgraded partway through their tenure rather than on day one — both
// synthetic but a closer approximation than defaulting everyone to signup.
function subscriptionStartedAt(seed: UserSeed): string | null {
  const tier = seed.subscription.tier ?? "free";
  const status = seed.subscription.status ?? "trialing";
  if (status === "trialing") return daysAgo(seed.createdDaysAgo);
  if (tier === "premium" && status === "active") return daysAgo(Math.max(0, Math.round(seed.createdDaysAgo * 0.3)));
  return null;
}

export const mockUsers: UserProfile[] = userSeeds.map((seed) => ({
  id: seed.id,
  email: seed.deleted ? null : seed.email,
  username: seed.username,
  name: seed.deleted ? "Deleted User" : seed.name,
  location: seed.deleted ? null : seed.location ?? null,
  country: seed.deleted ? null : seed.country ?? null,
  bio: seed.deleted ? null : seed.bio ?? null,
  // Roughly half the seeded users have a profile photo, the other half
  // don't — mirrors a real user base (not everyone uploads one) and gives
  // the admin panel's "view photo" affordance something real to render
  // instead of only ever showing initials.
  photo_url: seed.deleted || Number(seed.id.slice(-3)) % 2 !== 0 ? null : `https://i.pravatar.cc/300?u=${seed.id}`,
  height_cm: seed.height_cm,
  gender: seed.gender,
  date_of_birth: seed.deleted ? null : daysAgo(365 * (24 + (seed.id.length % 12))).slice(0, 10),
  reasons: seed.reasons ?? [],
  units: "metric",
  onboarding_complete: true,
  daily_goal_steps: seed.daily_goal_steps,
  weight_kg: seed.weight_kg,
  role: seed.role,
  privacy: {
    public_profile: true,
    share_activity: true,
    show_in_leaderboards: !seed.banned,
    allow_friend_requests: true,
    hide_activity_data: false,
    hide_achievements: false,
    hide_recent_activity: false,
  },
  subscription: {
    tier: "free",
    status: "trialing",
    started_at: subscriptionStartedAt(seed),
    comp_until: null,
    comp_reason: null,
    revenuecat_app_user_id: seed.subscription.status === "active" ? `rc_${seed.id}` : null,
    renews_at: null,
    cancelled_at: null,
    ...seed.subscription,
  },
  banned: !!seed.banned,
  ban_reason: seed.ban_reason ?? null,
  posting_banned: !!seed.postingBanned,
  posting_ban_reason: seed.postingBanReason ?? null,
  posting_banned_until: null,
  is_ambassador: !!seed.isAmbassador,
  platform: seed.platform ?? "ios",
  device_model: seed.deleted ? null : seed.deviceModel ?? null,
  app_version: seed.appVersion ?? "2.4.0",
  tags: seed.deleted ? [] : seed.tags ?? [],
  deleted: !!seed.deleted,
  deleted_at: seed.deleted ? daysAgo(40) : null,
  created_at: daysAgo(seed.createdDaysAgo),
  updated_at: daysAgo(Math.min(seed.createdDaysAgo, 1)),
}));

export function getUser(id: string): UserProfile | undefined {
  return mockUsers.find((u) => u.id === id);
}

// --- Devices ------------------------------------------------------------------

export const mockDevices: Device[] = [
  { id: "dev_001", serial_number: "STR-10042", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:11", firmware_version: "1.4.2", manufacturing_batch: "B-2025-11", owner_user_id: "usr_001", paired_at: daysAgo(180), last_seen_at: daysAgo(0, 7, 40), battery_level: 62, last_synced_at: daysAgo(0, 7, 42), created_at: daysAgo(190), replaced_at: null },
  { id: "dev_002", serial_number: "STR-10043", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:12", firmware_version: "1.4.2", manufacturing_batch: "B-2025-11", owner_user_id: "usr_003", paired_at: daysAgo(90), last_seen_at: daysAgo(0, 6, 12), battery_level: 88, last_synced_at: daysAgo(0, 6, 15), created_at: daysAgo(190), replaced_at: null },
  { id: "dev_003", serial_number: "STR-10044", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:13", firmware_version: "1.3.0", manufacturing_batch: "B-2025-11", owner_user_id: "usr_006", paired_at: daysAgo(295), last_seen_at: daysAgo(3, 18, 0), battery_level: 14, last_synced_at: daysAgo(6, 10, 0), created_at: daysAgo(300), replaced_at: null },
  { id: "dev_004", serial_number: "STR-10045", device_type: "strolla_nrf7002", ble_mac: null, firmware_version: null, manufacturing_batch: "B-2025-12", owner_user_id: null, paired_at: null, last_seen_at: null, battery_level: null, last_synced_at: null, created_at: daysAgo(60), replaced_at: null },
  { id: "dev_005", serial_number: "STR-10046", device_type: "strolla_nrf7002", ble_mac: null, firmware_version: null, manufacturing_batch: "B-2025-12", owner_user_id: null, paired_at: null, last_seen_at: null, battery_level: null, last_synced_at: null, created_at: daysAgo(60), replaced_at: null },
  { id: "dev_006", serial_number: "STR-10047", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:16", firmware_version: "1.4.2", manufacturing_batch: "B-2025-12", owner_user_id: "usr_012", paired_at: daysAgo(70), last_seen_at: daysAgo(0, 8, 5), battery_level: 45, last_synced_at: daysAgo(2, 14, 0), created_at: daysAgo(75), replaced_at: null },
  { id: "dev_007", serial_number: "STR-10048", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:17", firmware_version: "1.2.1", manufacturing_batch: "B-2025-09", owner_user_id: "usr_015", paired_at: daysAgo(150), last_seen_at: daysAgo(12, 9, 0), battery_level: 3, last_synced_at: daysAgo(12, 9, 0), created_at: daysAgo(160), replaced_at: null },
  { id: "dev_008", serial_number: "STR-10039", device_type: "strolla_nrf7002", ble_mac: null, firmware_version: "1.1.0", manufacturing_batch: "B-2025-08", owner_user_id: null, paired_at: null, last_seen_at: daysAgo(80, 10, 0), battery_level: null, last_synced_at: daysAgo(80, 10, 0), created_at: daysAgo(200), replaced_at: daysAgo(75) },
];

// --- Workout sessions + daily summaries (featured users only) ---------------

function buildDailyHistory(userId: string, baseSteps: number, variance: number, days: number): DailyActivitySummary[] {
  const out: DailyActivitySummary[] = [];
  for (let i = 0; i < days; i++) {
    const wobble = Math.sin(i * 1.3 + userId.length) * variance + (i % 7 === 0 ? -variance * 0.6 : 0);
    const steps = Math.max(800, Math.round(baseSteps + wobble));
    const distance = Math.round(steps * 0.682 * 10) / 10;
    const calories = Math.round(steps * 0.041);
    out.push({
      id: `${userId}_${dateKey(i)}`,
      user_id: userId,
      date: dateKey(i),
      by_source: {
        strolla_device: { steps, distance_meters: distance, calories },
      },
      steps,
      distance_meters: distance,
      calories,
      primary_source: "strolla_device",
      updated_at: daysAgo(i, 21, 0),
    });
  }
  return out;
}

export const mockDailySummaries: DailyActivitySummary[] = [
  ...buildDailyHistory("usr_001", 7400, 1800, 30),
  ...buildDailyHistory("usr_003", 9200, 2200, 30),
  ...buildDailyHistory("usr_006", 11400, 2600, 30),
  ...buildDailyHistory("usr_012", 8800, 1500, 30),
];

export const mockSessions: WorkoutSession[] = [
  { id: "sess_001", user_id: "usr_001", start_time: daysAgo(0, 7, 5), end_time: daysAgo(0, 7, 38), steps: 4120, distance_meters: 2810.6, duration_seconds: 1980, activity_type: "outdoor_walk", custom_activity_name: null, route_points: [], avg_pace_sec_per_km: 705, calories_burned: 98, source: "strolla_app", external_id: null, created_at: daysAgo(0, 7, 38) },
  { id: "sess_002", user_id: "usr_003", start_time: daysAgo(0, 6, 0), end_time: daysAgo(0, 6, 41), steps: 5230, distance_meters: 3568.9, duration_seconds: 2460, activity_type: "outdoor_walk", custom_activity_name: null, route_points: [], avg_pace_sec_per_km: 689, calories_burned: 134, source: "strolla_app", external_id: null, created_at: daysAgo(0, 6, 41) },
  { id: "sess_003", user_id: "usr_006", start_time: daysAgo(1, 18, 10), end_time: daysAgo(1, 18, 52), steps: 6890, distance_meters: 5240.2, duration_seconds: 2520, activity_type: "outdoor_run", custom_activity_name: null, route_points: [], avg_pace_sec_per_km: 481, calories_burned: 412, source: "strolla_app", external_id: null, created_at: daysAgo(1, 18, 52) },
  { id: "sess_004", user_id: "usr_012", start_time: daysAgo(2, 12, 30), end_time: daysAgo(2, 13, 1), steps: 0, distance_meters: 0, duration_seconds: 1860, activity_type: "yoga", custom_activity_name: null, route_points: [], avg_pace_sec_per_km: null, calories_burned: 64, source: "strolla_app", external_id: null, created_at: daysAgo(2, 13, 1) },
  { id: "sess_005", user_id: "usr_001", start_time: daysAgo(3, 19, 0), end_time: daysAgo(3, 19, 47), steps: 3980, distance_meters: 2714.0, duration_seconds: 2820, activity_type: "other", custom_activity_name: "Garden circuits", route_points: [], avg_pace_sec_per_km: null, calories_burned: 159, source: "strolla_app", external_id: null, created_at: daysAgo(3, 19, 47) },
];

// --- Community posts ----------------------------------------------------------

interface PostSeed {
  id: string;
  author_id: string;
  content: string;
  daysAgo: number;
  likes: number;
  comments: number;
  step_count?: number;
  badge_emoji?: string;
  image_url?: string;
  hidden?: { by: string; reason: string; daysAgo: number };
  pinned?: boolean;
  commentsLocked?: boolean;
}

const postSeeds: PostSeed[] = [
  { id: "post_001", author_id: "usr_003", content: "Morning stroller walk before the school run, 5.2km and the baby's already asleep. Small wins.", daysAgo: 0, likes: 24, comments: 6, step_count: 6820, image_url: "https://picsum.photos/seed/strolla-park-morning/800/500" },
  { id: "post_002", author_id: "usr_007", content: "Hit 70,400 steps this week, new personal best. The 10K Daily Streak challenge is brutal but it works.", daysAgo: 0, likes: 41, comments: 11, step_count: 70400, badge_emoji: "🔥", pinned: true },
  { id: "post_003", author_id: "usr_015", content: "Finally back to my pre-injury pace. 8 weeks of physio and walking pads, worth every minute.", daysAgo: 1, likes: 58, comments: 19, step_count: 5320, badge_emoji: "⭐" },
  { id: "post_004", author_id: "usr_006", content: "Rainy Edinburgh run this morning, route through the Meadows. Strolla device didn't drop connection once.", daysAgo: 1, likes: 19, comments: 4, step_count: 9120, image_url: "https://picsum.photos/seed/strolla-edinburgh-run/800/500" },
  { id: "post_005", author_id: "usr_011", content: "This app is a scam and everyone posting here is fake, unsubscribe before they take your money", daysAgo: 1, likes: 2, comments: 3 },
  { id: "post_006", author_id: "usr_012", content: "Yoga + 9k steps day. Strolla counts the steps, my knees handle the rest.", daysAgo: 2, likes: 33, comments: 8, step_count: 9450 },
  { id: "post_007", author_id: "usr_002", content: "Week one done. Honestly didn't think I'd stick with it past day 3.", daysAgo: 2, likes: 14, comments: 2 },
  { id: "post_008", author_id: "usr_008", content: "Twelve hour shift, no watch allowed on the ward, Strolla in my pocket still caught 11,200 steps.", daysAgo: 3, likes: 67, comments: 15, step_count: 11200, badge_emoji: "🏥" },
  { id: "post_009", author_id: "usr_001", content: "Someone in the comments keeps posting links to a 'free premium' site, please don't click that, report it instead.", daysAgo: 3, likes: 22, comments: 9 },
  { id: "post_010", author_id: "usr_005", content: "Walking pad under the standing desk, 14k steps and I never left my office. Wild.", daysAgo: 4, likes: 29, comments: 7, step_count: 14080 },
  { id: "post_011", author_id: "usr_018", content: "DM me for a free Strolla premium code, link in bio", daysAgo: 4, likes: 1, comments: 0, hidden: { by: "usr_016", reason: "Spam / scam link in a post impersonating an official promotion.", daysAgo: 4 } },
  { id: "post_012", author_id: "usr_009", content: "First week with the tracker. Already 3,000 steps ahead of where I was on my phone alone.", daysAgo: 5, likes: 16, comments: 3, step_count: 8100 },
  { id: "post_013", author_id: "usr_019", content: "Cardiff Bay loop, perfect evening for it.", daysAgo: 5, likes: 21, comments: 2, image_url: "https://picsum.photos/seed/strolla-cardiff-bay/800/500" },
  { id: "post_014", author_id: "usr_011", content: "anyone else think the leaderboard is rigged lol staff accounts always at the top", daysAgo: 6, likes: 4, comments: 6, hidden: { by: "usr_016", reason: "Unsubstantiated accusation against staff, escalating in comments. Hidden pending review.", daysAgo: 6 }, commentsLocked: true },
  { id: "post_015", author_id: "usr_014", content: "Day 1. Goal is 11,000. Let's see how this goes.", daysAgo: 7, likes: 9, comments: 1 },
  { id: "post_016", author_id: "usr_003", content: "Two months postpartum and the stroller walks are genuinely the best part of my day.", daysAgo: 8, likes: 71, comments: 23, step_count: 6200, image_url: "https://picsum.photos/seed/strolla-stroller-path/800/500" },
  { id: "post_017", author_id: "usr_020", content: "Just paired my device, the setup took two minutes. Impressed.", daysAgo: 1, likes: 6, comments: 1 },
];

export const mockPosts: CommunityPost[] = postSeeds.map((seed) => ({
  id: seed.id,
  author_id: seed.author_id,
  content: seed.content,
  timestamp: daysAgo(seed.daysAgo, 8 + (seed.id.length % 10), 15),
  likes_count: seed.likes,
  comments_count: seed.comments,
  step_count: seed.step_count ?? null,
  badge_emoji: seed.badge_emoji ?? null,
  image_url: seed.image_url ?? null,
  moderation: seed.hidden
    ? {
        hidden: true,
        hidden_by: seed.hidden.by,
        hidden_reason: seed.hidden.reason,
        hidden_at: daysAgo(seed.hidden.daysAgo, 14, 0),
      }
    : { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null },
  pinned: !!seed.pinned,
  comments_locked: !!seed.commentsLocked,
}));

// --- Comments ------------------------------------------------------------------

interface CommentSeed {
  id: string;
  post_id: string;
  author_id: string;
  content: string;
  daysAgo: number;
  hidden?: boolean;
}

const commentSeeds: CommentSeed[] = [
  { id: "cmt_001", post_id: "post_001", author_id: "usr_012", content: "That's such a lovely way to start the day. My little one is a bit older now, cherish this time!", daysAgo: 0 },
  { id: "cmt_002", post_id: "post_001", author_id: "usr_008", content: "5.2km before the school run is no joke, well done.", daysAgo: 0 },
  { id: "cmt_003", post_id: "post_002", author_id: "usr_006", content: "That's an insane week. What's your secret to the streak?", daysAgo: 0 },
  { id: "cmt_004", post_id: "post_002", author_id: "usr_001", content: "70k in a week?! Absolute legend.", daysAgo: 0 },
  { id: "cmt_005", post_id: "post_002", author_id: "usr_015", content: "This is exactly the motivation I needed today.", daysAgo: 0 },
  { id: "cmt_006", post_id: "post_003", author_id: "usr_003", content: "So happy for you, physio recovery is no joke. Keep going!", daysAgo: 1 },
  { id: "cmt_007", post_id: "post_005", author_id: "usr_016", content: "Hi there — sorry to hear you feel that way. Happy to talk through any concerns directly, just DM us.", daysAgo: 1 },
  { id: "cmt_008", post_id: "post_005", author_id: "usr_009", content: "Been using it for 3 months, definitely not a scam for me — maybe try contacting support?", daysAgo: 1 },
  {
    id: "cmt_009",
    post_id: "post_014",
    author_id: "usr_004",
    content: "Pretty sure that's not how the leaderboard works, staff steps count the same as anyone else's.",
    daysAgo: 6,
  },
  {
    id: "cmt_010",
    post_id: "post_014",
    author_id: "usr_011",
    content: "convenient that you'd say that though isn't it",
    daysAgo: 6,
    hidden: true,
  },
  { id: "cmt_011", post_id: "post_008", author_id: "usr_003", content: "Nurses are unstoppable, respect.", daysAgo: 3 },
  { id: "cmt_012", post_id: "post_016", author_id: "usr_010", content: "This made my morning, thank you for sharing.", daysAgo: 8 },
];

export const mockComments: CommunityComment[] = commentSeeds.map((seed) => ({
  id: seed.id,
  post_id: seed.post_id,
  author_id: seed.author_id,
  content: seed.content,
  timestamp: daysAgo(seed.daysAgo, 10 + (seed.id.length % 8), 30),
  hidden: !!seed.hidden,
}));

// --- Reports -------------------------------------------------------------------

export const mockReports: Report[] = [
  { id: "rep_001", reporter_id: "usr_001", target_type: "post", target_id: "post_011", category: "spam", reason: "This post is advertising a fake 'free premium' link, looks like a phishing attempt.", status: "resolved", action_taken: "warned", resolved_by: "usr_016", resolved_at: daysAgo(4, 15, 0), resolution_note: "Post hidden, author warned via email.", created_at: daysAgo(4, 13, 30) },
  { id: "rep_002", reporter_id: "usr_007", target_type: "user", target_id: "usr_011", category: "harassment", reason: "Keeps leaving harassing comments on other people's step posts, this is the third time I've reported him.", status: "resolved", action_taken: "banned", resolved_by: "usr_016", resolved_at: daysAgo(2, 10, 0), resolution_note: "Account banned after third confirmed incident.", created_at: daysAgo(2, 9, 0) },
  { id: "rep_003", reporter_id: "usr_003", target_type: "post", target_id: "post_014", category: "misinformation", reason: "Unfounded accusation that's stirring up the comment section, feels like it's heading toward a pile-on.", status: "open", action_taken: null, resolved_by: null, resolved_at: null, resolution_note: null, created_at: daysAgo(6, 11, 20) },
  { id: "rep_004", reporter_id: "usr_012", target_type: "post", target_id: "post_005", category: "misinformation", reason: "Calling the app a scam with no basis, discouraging other users in the thread.", status: "open", action_taken: null, resolved_by: null, resolved_at: null, resolution_note: null, created_at: daysAgo(1, 16, 40) },
  { id: "rep_005", reporter_id: "usr_015", target_type: "user", target_id: "usr_009", category: "other", reason: "Profile photo looks like it might not be theirs, possible impersonation, wanted to flag just in case.", status: "dismissed", action_taken: null, resolved_by: "usr_016", resolved_at: daysAgo(3, 9, 0), resolution_note: "Checked, no impersonation, just a stock-style profile photo. No action needed.", created_at: daysAgo(4, 8, 0) },
  { id: "rep_006", reporter_id: "usr_002", target_type: "post", target_id: "post_011", category: "spam", reason: "Same spam link as another report, posting again under a new comment.", status: "open", action_taken: null, resolved_by: null, resolved_at: null, resolution_note: null, created_at: daysAgo(0, 9, 0) },
];

// --- Challenges + participants -----------------------------------------------

export const mockChallenges: Challenge[] = [
  { id: "chal_001", title: "10K Daily Streak", description: "Hit 10,000 steps every day for 7 days straight.", goal_steps: 70000, start_date: dateKey(10), end_date: dateKey(-4), badge_emoji: "🔥", accent_color_value: null, visibility: "public", is_official: true, invite_code: null, created_by: null, created_at: daysAgo(11), image_url: "https://picsum.photos/seed/strolla-challenge-10k/800/500", rules: "Steps must be recorded by a paired Strolla device or a connected health app — manual entries don't count toward the goal.", winner_type: "most_steps", status: "published", winner_user_id: "usr_007", admin_notes: null },
  { id: "chal_002", title: "50km This Month", description: "Walk or run 50 kilometres before the month ends.", goal_steps: 65616, start_date: dateKey(20), end_date: dateKey(-9), badge_emoji: "🗺️", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: "usr_016", created_at: daysAgo(21), image_url: null, rules: "Distance is calculated from steps using each participant's stride length — GPS-tracked sessions are not required.", winner_type: "most_steps", status: "published", winner_user_id: "usr_002", admin_notes: null },
  { id: "chal_003", title: "Weekend Warrior", description: "Get 25,000 steps over Saturday and Sunday.", goal_steps: 25000, start_date: dateKey(4), end_date: dateKey(-2), badge_emoji: "⚡", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: "usr_016", created_at: daysAgo(5), image_url: null, rules: "Winner is whoever clears the highest percentage of their own personal daily goal, not raw steps — keeps it fair across different fitness levels.", winner_type: "goal_completion_pct", status: "published", winner_user_id: "usr_001", admin_notes: null },
  { id: "chal_004", title: "Office Walking Club", description: "Private challenge for the Leeds office crew, 40k steps each over two weeks.", goal_steps: 40000, start_date: dateKey(13), end_date: dateKey(-1), badge_emoji: "🏢", accent_color_value: null, visibility: "private", is_official: false, invite_code: "LDS-WALK-22", created_by: "usr_001", created_at: daysAgo(14), image_url: null, rules: "Invite-only — steps count the same as any public challenge.", winner_type: "most_steps", status: "published", winner_user_id: "usr_001", admin_notes: null },
  { id: "chal_005", title: "May Step Sprint", description: "Last month's official challenge, archived for reference.", goal_steps: 60000, start_date: "2026-05-01", end_date: "2026-05-31", badge_emoji: "🏆", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: null, created_at: "2026-04-29T09:00:00Z", image_url: null, rules: null, winner_type: "most_steps", status: "archived", winner_user_id: null, admin_notes: "Archived before per-challenge winner tracking existed — no leaderboard data retained for this one." },
  { id: "chal_006", title: "August Boost", description: "Early draft for next month's official challenge — not visible to users yet.", goal_steps: 80000, start_date: dateKey(-11), end_date: dateKey(-41), badge_emoji: "🚀", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: "usr_016", created_at: daysAgo(0), image_url: null, rules: null, winner_type: "most_steps", status: "draft", winner_user_id: null, admin_notes: null },
];

function participant(challengeId: string, userId: string, steps: number, lockedGoal: number, joinedDaysAgo: number, left?: number): ChallengeParticipant {
  return {
    id: `${challengeId}_${userId}`,
    challenge_id: challengeId,
    user_id: userId,
    steps,
    locked_daily_goal: lockedGoal,
    joined_at: daysAgo(joinedDaysAgo),
    left_at: left !== undefined ? daysAgo(left) : null,
  };
}

export const mockParticipants: ChallengeParticipant[] = [
  participant("chal_001", "usr_007", 42100, 15000, 10),
  participant("chal_001", "usr_006", 38500, 10000, 10),
  participant("chal_001", "usr_001", 31200, 6000, 10),
  participant("chal_001", "usr_003", 28900, 8000, 9),
  participant("chal_001", "usr_015", 21000, 7500, 9),
  participant("chal_001", "usr_011", 9400, 10000, 9, 6),
  participant("chal_002", "usr_002", 52400, 10000, 20),
  participant("chal_002", "usr_009", 48900, 10000, 19),
  participant("chal_002", "usr_005", 41200, 9000, 18),
  participant("chal_003", "usr_006", 22800, 10000, 4),
  participant("chal_003", "usr_001", 14300, 6000, 4),
  participant("chal_003", "usr_012", 12100, 9500, 3),
  participant("chal_004", "usr_001", 31200, 6000, 13),
  participant("chal_004", "usr_004", 24800, 12000, 13),
];

// --- Badges --------------------------------------------------------------------

export const mockBadges: Badge[] = [
  { id: "badge_001", name: "First Steps", description: "Completed onboarding and logged your first day of steps.", emoji: "👟", requirement_metric: "total_steps", requirement_value: 1, enabled: true, visible: true, created_at: daysAgo(300) },
  { id: "badge_002", name: "Early Bird", description: "Logged a walk before 7am, five times.", emoji: "🌅", requirement_metric: "early_morning_sessions", requirement_value: 5, enabled: true, visible: true, created_at: daysAgo(280) },
  { id: "badge_003", name: "Streak Master", description: "Hit your daily goal 30 days in a row.", emoji: "🔥", requirement_metric: "streak_days", requirement_value: 30, enabled: true, visible: true, created_at: daysAgo(260) },
  { id: "badge_004", name: "Marathon Mile", description: "Walked or ran a cumulative 42.2km in a single week.", emoji: "🏃", requirement_metric: "total_steps", requirement_value: 59000, enabled: true, visible: true, created_at: daysAgo(240) },
  { id: "badge_005", name: "Community Champion", description: "Posted 25 times and helped others stay motivated.", emoji: "💬", requirement_metric: "community_posts", requirement_value: 25, enabled: true, visible: true, created_at: daysAgo(200) },
  // Kickstarter window has long closed — no one can newly earn this, but past awards stand and it stays visible in the catalog.
  { id: "badge_006", name: "Founding Walker", description: "Joined during the Kickstarter launch window.", emoji: "🚀", requirement_metric: "total_steps", requirement_value: 0, enabled: false, visible: true, created_at: daysAgo(360) },
];

export const mockUserBadges: UserBadge[] = [
  { id: "usr_001_badge_001", user_id: "usr_001", badge_id: "badge_001", awarded_at: daysAgo(187), awarded_by: null },
  { id: "usr_001_badge_003", user_id: "usr_001", badge_id: "badge_003", awarded_at: daysAgo(60), awarded_by: null },
  { id: "usr_006_badge_001", user_id: "usr_006", badge_id: "badge_001", awarded_at: daysAgo(300), awarded_by: null },
  { id: "usr_006_badge_004", user_id: "usr_006", badge_id: "badge_004", awarded_at: daysAgo(40), awarded_by: null },
  { id: "usr_006_badge_006", user_id: "usr_006", badge_id: "badge_006", awarded_at: daysAgo(295), awarded_by: "usr_017" },
  { id: "usr_007_badge_006", user_id: "usr_007", badge_id: "badge_006", awarded_at: daysAgo(46), awarded_by: "usr_017" },
  { id: "usr_003_badge_002", user_id: "usr_003", badge_id: "badge_002", awarded_at: daysAgo(50), awarded_by: null },
  { id: "usr_003_badge_005", user_id: "usr_003", badge_id: "badge_005", awarded_at: daysAgo(12), awarded_by: "usr_016" },
];

// --- Feature flags ---------------------------------------------------------------

export const mockFeatureFlags: FeatureFlag[] = [
  { key: "widget", required_tier: "premium", description: "Home/lock screen step widget.", updated_at: daysAgo(40) },
  { key: "challenges", required_tier: "free", description: "Join public step challenges.", updated_at: daysAgo(40) },
  { key: "private_challenges", required_tier: "premium", description: "Create invite-only challenges.", updated_at: daysAgo(40) },
  { key: "activity_insights", required_tier: "premium", description: "Extra stats tabs beyond the overview.", updated_at: daysAgo(40) },
  { key: "extra_stats_tabs", required_tier: "premium", description: "Day/week/month breakdown views.", updated_at: daysAgo(40) },
];

// --- Analytics events (30-day synthetic series for charts) ---------------------

function pick<T>(arr: T[], seed: number): T {
  return arr[seed % arr.length];
}

function buildAnalyticsEvents(): AnalyticsEvent[] {
  const events: AnalyticsEvent[] = [];
  let counter = 0;
  const activeUserPool = mockUsers.filter((u) => u.role === "user" && !u.deleted).map((u) => u.id);

  for (let day = 29; day >= 0; day--) {
    // Weekly rhythm: lower on Sun/Mon (day index churns through a 7-cycle), gentle upward trend over the month.
    const weekday = (day + 3) % 7;
    const weekendDip = weekday === 0 || weekday === 6 ? 0.78 : 1;
    const trend = 1 + (29 - day) * 0.01;
    const baseDau = Math.round(11 * weekendDip * trend);

    const openedBy = new Set<string>();
    for (let i = 0; i < baseDau; i++) {
      const userId = pick(activeUserPool, counter * 7 + i + day);
      openedBy.add(userId);
    }
    for (const userId of openedBy) {
      events.push({ id: `evt_${counter++}`, event_type: "app_opened", user_id: userId, metadata: {}, created_at: daysAgo(day, 8 + (counter % 12), counter % 60) });
    }

    // Weighted toward Home (every session lands there) down to Profile
    // (rarely visited) — screens a user might look at in one sitting.
    const SCREEN_WEIGHTS: { screen: string; weight: number }[] = [
      { screen: "home", weight: 5 },
      { screen: "stats", weight: 3 },
      { screen: "challenges", weight: 2 },
      { screen: "community", weight: 2 },
      { screen: "profile", weight: 1 },
    ];
    const screenPool = SCREEN_WEIGHTS.flatMap((s) => Array(s.weight).fill(s.screen) as string[]);
    for (const userId of openedBy) {
      const visitCount = 1 + (counter % 3);
      for (let v = 0; v < visitCount; v++) {
        const screen = pick(screenPool, counter + v * 13);
        events.push({ id: `evt_${counter++}`, event_type: "screen_viewed", user_id: userId, metadata: { screen }, created_at: daysAgo(day, 8 + (counter % 12), counter % 60) });
      }
    }

    const startedCount = Math.max(1, Math.round(openedBy.size * 0.55));
    const startedUsers = Array.from(openedBy).slice(0, startedCount);
    for (const userId of startedUsers) {
      events.push({ id: `evt_${counter++}`, event_type: "workout_started", user_id: userId, metadata: {}, created_at: daysAgo(day, 7, counter % 60) });
    }
    const completedUsers = startedUsers.slice(0, Math.round(startedUsers.length * 0.82));
    for (const userId of completedUsers) {
      events.push({ id: `evt_${counter++}`, event_type: "workout_completed", user_id: userId, metadata: { steps: 3000 + (counter % 9) * 700 }, created_at: daysAgo(day, 7, (counter % 60) + 20) });
    }

    if (day % 4 === 0) {
      events.push({ id: `evt_${counter++}`, event_type: "account_created", user_id: pick(activeUserPool, counter), metadata: {}, created_at: daysAgo(day, 11, 0) });
    }
    if (day % 6 === 0) {
      events.push({ id: `evt_${counter++}`, event_type: "tracker_paired", user_id: pick(activeUserPool, counter + 3), metadata: {}, created_at: daysAgo(day, 12, 0) });
    }
    if (day % 3 === 0) {
      events.push({ id: `evt_${counter++}`, event_type: "community_post_created", user_id: pick(activeUserPool, counter + 5), metadata: {}, created_at: daysAgo(day, 14, 0) });
    }
    if (day % 5 === 0) {
      events.push({ id: `evt_${counter++}`, event_type: "challenge_joined", user_id: pick(activeUserPool, counter + 8), metadata: {}, created_at: daysAgo(day, 15, 0) });
    }
    if (day % 9 === 0) {
      events.push({ id: `evt_${counter++}`, event_type: "challenge_completed", user_id: pick(activeUserPool, counter + 11), metadata: {}, created_at: daysAgo(day, 16, 0) });
    }
    if (day % 7 === 1) {
      events.push({ id: `evt_${counter++}`, event_type: "premium_started", user_id: pick(activeUserPool, counter + 13), metadata: {}, created_at: daysAgo(day, 17, 0) });
    }
    if (day % 11 === 2) {
      events.push({ id: `evt_${counter++}`, event_type: "premium_cancelled", user_id: pick(activeUserPool, counter + 17), metadata: {}, created_at: daysAgo(day, 18, 0) });
    }
    if (day % 4 === 2) {
      events.push({ id: `evt_${counter++}`, event_type: "widget_enabled", user_id: pick(activeUserPool, counter + 19), metadata: {}, created_at: daysAgo(day, 19, 0) });
    }
    if (day % 8 === 3) {
      events.push({ id: `evt_${counter++}`, event_type: "health_app_connected", user_id: pick(activeUserPool, counter + 23), metadata: { provider: pick(["healthkit", "health_connect"], day) }, created_at: daysAgo(day, 20, 0) });
    }
    if (day % 6 === 4) {
      events.push({ id: `evt_${counter++}`, event_type: "steps_shared", user_id: pick(activeUserPool, counter + 29), metadata: {}, created_at: daysAgo(day, 21, 0) });
    }
  }
  return events;
}

export const mockAnalyticsEvents: AnalyticsEvent[] = buildAnalyticsEvents();

export type EventTypeFilter = AnalyticsEventType;

// --- Crash reports (synthetic — no real Crashlytics/Sentry pipeline yet) ------

export const mockCrashReports: CrashReport[] = [
  { id: "crash_001", user_id: "usr_009", platform: "android", app_version: "1.4.2", summary: "NullPointerException in BleStepService.onCharacteristicChanged", occurred_at: daysAgo(0, 6, 52) },
  { id: "crash_002", user_id: "usr_014", platform: "ios", app_version: "1.4.2", summary: "Fatal: index out of range in WeeklyChart bar rendering", occurred_at: daysAgo(1, 19, 10) },
  { id: "crash_003", user_id: null, platform: "android", app_version: "1.4.1", summary: "OutOfMemoryError loading route polyline on session summary", occurred_at: daysAgo(2, 8, 5) },
  { id: "crash_004", user_id: "usr_005", platform: "ios", app_version: "1.4.2", summary: "Fatal: unexpectedly found nil unwrapping HealthKit authorization result", occurred_at: daysAgo(3, 21, 40) },
  { id: "crash_005", user_id: "usr_020", platform: "android", app_version: "1.4.2", summary: "IllegalStateException: fragment not attached to activity (session screen)", occurred_at: daysAgo(4, 7, 15) },
];

// --- Support tickets (synthetic — no real Zendesk/Intercom pipeline yet) -----

export const mockSupportTickets: SupportTicket[] = [
  { id: "tix_001", user_id: "usr_003", subject: "Tracker won't pair after firmware update", status: "open", priority: "high", created_at: daysAgo(0, 9, 20) },
  { id: "tix_002", user_id: "usr_014", subject: "Charged for premium but app still shows free tier", status: "open", priority: "high", created_at: daysAgo(1, 15, 5) },
  { id: "tix_003", user_id: "usr_009", subject: "Steps not syncing from Apple Health", status: "open", priority: "medium", created_at: daysAgo(2, 11, 40) },
  { id: "tix_004", user_id: "usr_005", subject: "How do I export my walking data?", status: "resolved", priority: "low", created_at: daysAgo(6, 10, 0) },
];

// --- Firmware update failures (synthetic — no real OTA telemetry yet) --------

export const mockFirmwareFailures: FirmwareUpdateFailure[] = [
  { id: "fw_001", device_id: "dev_003", attempted_version: "1.4.2", error: "Connection dropped mid-flash at 62%", occurred_at: daysAgo(3, 18, 5), resolved: false },
  { id: "fw_002", device_id: "dev_002", attempted_version: "1.4.2", error: "Battery too low to start update (11%)", occurred_at: daysAgo(5, 8, 30), resolved: true },
];

// --- Pending account deletion requests (synthetic — self-service delete flow
// isn't wired to the admin queue yet; admins currently action deletions
// directly from the user's profile instead) --------------------------------

export const mockAccountDeletionRequests: AccountDeletionRequest[] = [
  { id: "del_001", user_id: "usr_021", reason: "No longer using the app", requested_at: daysAgo(1, 20, 0), status: "pending" },
  { id: "del_002", user_id: "usr_022", reason: null, requested_at: daysAgo(4, 13, 15), status: "pending" },
];

// --- Internal admin notes on user accounts (never shown to the user) ---------

export const mockUserNotes: UserNote[] = [
  { id: "note_001", user_id: "usr_007", author_id: "usr_016", body: "Kickstarter backer — comp premium is a lifetime perk, don't let it lapse on renewal cleanup scripts.", created_at: daysAgo(45, 10, 0) },
  { id: "note_002", user_id: "usr_011", author_id: "usr_016", body: "Second harassment complaint filed even before the ban — flag if they ever try to sign up again under a new email.", created_at: daysAgo(220, 9, 30) },
  { id: "note_003", user_id: "usr_018", author_id: "usr_017", body: "Posting ban was a judgment call — spam links were borderline promotional rather than malicious. Revisit if they appeal.", created_at: daysAgo(40, 15, 0) },
];

// --- Push notification send history --------------------------------------------

export const mockPushNotifications: PushNotification[] = [
  {
    id: "push_001", segment: "everyone", title: "10K Daily Streak is live!", body: "Join now and compete for the top spot this week.",
    link_target: "challenge", link_challenge_id: "chal_001", link_custom_path: null,
    status: "sent", scheduled_at: null, recipient_count: 20, delivered_count: 19, opened_count: 9,
    sent_by: "usr_016", created_at: daysAgo(10, 9, 0), sent_at: daysAgo(10, 9, 0),
  },
  {
    id: "push_002", segment: "premium", title: "New: extra stats tabs", body: "Day/week/month breakdowns are now live in your Stats tab.",
    link_target: "stats", link_challenge_id: null, link_custom_path: null,
    status: "sent", scheduled_at: null, recipient_count: 8, delivered_count: 8, opened_count: 5,
    sent_by: "usr_017", created_at: daysAgo(25, 14, 30), sent_at: daysAgo(25, 14, 30),
  },
  {
    id: "push_003", segment: "inactive_30d", title: "We miss you 👋", body: "Your streak is waiting — even a short walk today keeps it alive.",
    link_target: "none", link_challenge_id: null, link_custom_path: null,
    status: "sent", scheduled_at: null, recipient_count: 4, delivered_count: 4, opened_count: 1,
    sent_by: "usr_016", created_at: daysAgo(6, 11, 0), sent_at: daysAgo(6, 11, 0),
  },
  {
    id: "push_004", segment: "tracker_owners", title: "Firmware update available", body: "A small battery-life improvement is ready for your Strolla tracker.",
    link_target: "none", link_challenge_id: null, link_custom_path: null,
    status: "sent", scheduled_at: null, recipient_count: 7, delivered_count: 7, opened_count: 4,
    sent_by: "usr_016", created_at: daysAgo(45, 10, 15), sent_at: daysAgo(45, 10, 15),
  },
  {
    id: "push_005", segment: "everyone", title: "🎉 August Challenge is Live!", body: "Join now and compete for the top spot.",
    link_target: "challenge", link_challenge_id: "chal_001", link_custom_path: null,
    status: "draft", scheduled_at: null, recipient_count: 0, delivered_count: 0, opened_count: 0,
    sent_by: null, created_at: daysAgo(1, 16, 0), sent_at: null,
  },
  {
    id: "push_006", segment: "free", title: "Go premium for extra insights", body: "Unlock day/week/month breakdowns and activity insights this weekend only.",
    link_target: "premium", link_challenge_id: null, link_custom_path: null,
    status: "scheduled", scheduled_at: daysAgo(-2, 9, 0), recipient_count: 12, delivered_count: 0, opened_count: 0,
    sent_by: "usr_016", created_at: daysAgo(2, 13, 0), sent_at: null,
  },
];

// --- Connected apps (per-user platform integrations) ---------------------------

function integration(
  userId: string,
  provider: IntegrationConnection["provider"],
  connectedDaysAgo: number,
  syncedHoursAgo = 6
): IntegrationConnection {
  return {
    id: `int_${userId}_${provider}`,
    user_id: userId,
    provider,
    status: "connected",
    scopes: provider === "healthkit" || provider === "health_connect" ? ["steps", "distance", "calories"] : ["activity:read"],
    external_athlete_id: provider === "healthkit" || provider === "health_connect" ? null : `${provider}_${userId.slice(-3)}`,
    last_synced_at: daysAgo(0, 24 - syncedHoursAgo, 0),
    connected_at: daysAgo(connectedDaysAgo),
    error_message: null,
  };
}

export const mockIntegrationConnections: IntegrationConnection[] = [
  integration("usr_001", "healthkit", 120),
  integration("usr_002", "health_connect", 80),
  integration("usr_003", "healthkit", 60),
  integration("usr_005", "health_connect", 40),
  integration("usr_006", "strava", 200),
  integration("usr_006", "healthkit", 200),
  integration("usr_007", "strava", 30),
  integration("usr_008", "health_connect", 20),
  integration("usr_009", "healthkit", 15),
  integration("usr_012", "oura", 90),
  integration("usr_012", "healthkit", 90),
  integration("usr_015", "garmin", 110),
  { id: "int_usr_018_strava", user_id: "usr_018", provider: "strava", status: "error", scopes: ["activity:read"], external_athlete_id: "strava_018", last_synced_at: daysAgo(9, 10, 0), connected_at: daysAgo(50), error_message: "Token expired — user needs to reconnect." },
];

// --- App content (editable copy, no app release needed) ------------------------

export const mockAppContent: AppContentEntry[] = [
  // --- Onboarding ---------------------------------------------------------
  { key: "onboarding.intro_slide_1", category: "onboarding", label: "Welcome carousel — slide 1 headline", value: "Every step counts", updated_at: daysAgo(90) },
  { key: "onboarding.welcome_heading", category: "onboarding", label: "Post-signup welcome heading", value: "Welcome to Strolla, {FirstName}!", updated_at: daysAgo(40) },
  { key: "onboarding.goal_step_subtitle", category: "onboarding", label: "Daily goal step — subtitle", value: "What's your daily step goal?", updated_at: daysAgo(90) },

  // --- Home -----------------------------------------------------------------
  { key: "home.greeting", category: "home", label: "Home screen greeting header", value: "Good morning, {FirstName}", updated_at: daysAgo(20) },
  { key: "home.steps_remaining", category: "home", label: "Steps-remaining subtitle", value: "Only {StepsRemaining} steps left today!", updated_at: daysAgo(20) },
  { key: "home.milestone_reached", category: "home", label: "Daily goal milestone toast", value: "Nice! You just crossed {StepGoal} steps.", updated_at: daysAgo(20) },

  // --- Challenges -------------------------------------------------------------
  { key: "challenges.nav_label", category: "challenges", label: "Bottom-nav tab / section title", value: "Challenges", updated_at: daysAgo(200) },
  { key: "challenges.of_the_month_banner", category: "challenges", label: "Challenge of the Month banner", value: "This month's challenge is live — join now and compete for the top spot.", updated_at: daysAgo(10) },
  { key: "challenges.days_left", category: "challenges", label: "Days-remaining chip on a challenge card", value: "{DaysLeft} days left to hit the goal", updated_at: daysAgo(60) },

  // --- Community -----------------------------------------------------------
  { key: "community.nav_label", category: "community", label: "Bottom-nav tab / section title", value: "Community", updated_at: daysAgo(200) },
  { key: "community.empty_feed", category: "community", label: "Empty feed message", value: "Nothing here yet — be the first to share how your walk went today.", updated_at: daysAgo(70) },
  { key: "community.post_composer_placeholder", category: "community", label: "Post composer placeholder", value: "Share how today's walk went...", updated_at: daysAgo(70) },

  // --- Errors --------------------------------------------------------------
  { key: "errors.generic_network", category: "errors", label: "Generic network error", value: "Something went wrong. Check your connection and try again.", updated_at: daysAgo(50) },
  { key: "errors.session_save_failed", category: "errors", label: "Workout session failed to save", value: "We couldn't save that session. Your data is safe on this device — try again in a moment.", updated_at: daysAgo(50) },
  { key: "errors.notifications_load_failed", category: "errors", label: "Notifications feed failed to load", value: "Could not load notifications.", updated_at: daysAgo(50) },

  // --- Buttons ---------------------------------------------------------------
  { key: "buttons.join_challenge", category: "buttons", label: "Join a challenge", value: "Join Challenge", updated_at: daysAgo(200) },
  { key: "buttons.save", category: "buttons", label: "Generic save action", value: "Save", updated_at: daysAgo(200) },
  { key: "buttons.upgrade_to_premium", category: "buttons", label: "Premium upsell CTA", value: "Upgrade to Premium", updated_at: daysAgo(90) },

  // --- Settings --------------------------------------------------------------
  { key: "settings.nav_label", category: "settings", label: "Bottom-nav tab / section title", value: "Settings", updated_at: daysAgo(200) },
  { key: "settings.edit_profile_row", category: "settings", label: "\"Edit Profile\" row", value: "Edit Profile", updated_at: daysAgo(200) },
  { key: "settings.units_row", category: "settings", label: "\"Units\" row", value: "Units", updated_at: daysAgo(200) },

  // --- Premium ---------------------------------------------------------------
  { key: "premium.paywall_headline", category: "premium", label: "Paywall headline", value: "Unlock Strolla Premium", updated_at: daysAgo(90) },
  { key: "premium.paywall_body", category: "premium", label: "Paywall body copy", value: "Get day/week/month breakdowns, activity insights, and more.", updated_at: daysAgo(90) },
  { key: "premium.trial_reminder", category: "premium", label: "Trial-ending reminder", value: "Your trial ends in {DaysLeft} days.", updated_at: daysAgo(30) },

  // --- Notifications -----------------------------------------------------
  { key: "notifications.goal_reminder", category: "notifications", label: "Goal reminder push (75%+ of the way there)", value: "You're only {StepsRemaining} steps away from today's goal.", updated_at: daysAgo(30) },
  { key: "notifications.streak", category: "notifications", label: "Streak push", value: "{StreakDays}-day streak! Keep it going.", updated_at: daysAgo(30) },
  { key: "notifications.low_battery", category: "notifications", label: "Low battery push", value: "Your Strolla tracker is at {DeviceBattery} — charge it soon.", updated_at: daysAgo(30) },

  // --- Widget ------------------------------------------------------------------
  { key: "widget.steps_label", category: "widget", label: "Widget steps-today label", value: "Steps today", updated_at: daysAgo(120) },
  { key: "widget.goal_reached", category: "widget", label: "Widget goal-reached state", value: "Goal reached! 🎉", updated_at: daysAgo(120) },
  { key: "widget.tap_to_open", category: "widget", label: "Widget footer prompt", value: "Tap to open Strolla", updated_at: daysAgo(120) },

  // --- Device pairing --------------------------------------------------------
  { key: "device_pairing.scanning", category: "device_pairing", label: "Scanning for a tracker", value: "Looking for your Strolla tracker...", updated_at: daysAgo(90) },
  { key: "device_pairing.success", category: "device_pairing", label: "Pairing succeeded", value: "You're all set — your Strolla tracker is live.", updated_at: daysAgo(90) },
  { key: "device_pairing.failed", category: "device_pairing", label: "Pairing failed", value: "Couldn't find a tracker nearby. Make sure it's charged and close by.", updated_at: daysAgo(90) },

  // --- Firmware ----------------------------------------------------------------
  { key: "firmware.update_available", category: "firmware", label: "Update-available prompt", value: "A new firmware update is available for your Strolla tracker.", updated_at: daysAgo(45) },
  { key: "firmware.updating", category: "firmware", label: "Update in progress", value: "Updating firmware — keep your tracker nearby and don't close the app.", updated_at: daysAgo(45) },
  { key: "firmware.update_complete", category: "firmware", label: "Update complete", value: "Firmware updated! A small battery-life improvement is ready for your Strolla tracker.", updated_at: daysAgo(45) },
];

// --- Legal documents -------------------------------------------------------------

export const mockLegalVersions: LegalDocumentVersion[] = [
  // --- Privacy Policy ---------------------------------------------------------
  {
    id: "priv_v1", doc_type: "privacy_policy", version: 1, status: "archived",
    content: "# Privacy Policy\n\nStrolla Health collects the step and distance data you record while using the app.\n\nWe never sell your personal data.",
    changelog: null, effective_date: dateKey(400), requires_reaccept: true,
    created_by: "usr_017", created_at: daysAgo(400), published_at: daysAgo(400),
  },
  {
    id: "priv_v2", doc_type: "privacy_policy", version: 2, status: "archived",
    content: "# Privacy Policy\n\nStrolla Health collects the step, distance, and location data you choose to share in order to power your step ring and session tracking.\n\nWe never sell your personal data.\n\n## Your rights\n\n- Request a full export of your data\n- Request deletion of your data\n- Contact us at [privacy@strollahealth.com](mailto:privacy@strollahealth.com)",
    changelog: "- Added a dedicated \"Your rights\" section\n- Clarified that location data is opt-in",
    effective_date: dateKey(180), requires_reaccept: true,
    created_by: "usr_017", created_at: daysAgo(182), published_at: daysAgo(180),
  },
  {
    id: "priv_v3", doc_type: "privacy_policy", version: 3, status: "published",
    content: "# Privacy Policy\n\nStrolla Health collects the step, distance, and location data you choose to share in order to power your step ring, session tracking, and challenges.\n\nWe never sell your personal data.\n\n## Your rights\n\nYou can request a full export or deletion of your data at any time from **Settings > Privacy**, or by contacting [privacy@strollahealth.com](mailto:privacy@strollahealth.com).\n\n## Challenges and leaderboards\n\nIf you join a challenge, your step count and display name are visible to other participants on that challenge's leaderboard.",
    changelog: "- Added the \"Challenges and leaderboards\" section covering leaderboard visibility\n- Minor wording clarifications throughout",
    effective_date: dateKey(45), requires_reaccept: false,
    created_by: "usr_016", created_at: daysAgo(47), published_at: daysAgo(45),
  },
  {
    id: "priv_v4_draft", doc_type: "privacy_policy", version: 4, status: "draft",
    content: "# Privacy Policy\n\nStrolla Health collects the step, distance, and location data you choose to share in order to power your step ring, session tracking, and challenges.\n\nWe never sell your personal data.\n\n## Your rights\n\nYou can request a full export or deletion of your data at any time from **Settings > Privacy**, or by contacting [privacy@strollahealth.com](mailto:privacy@strollahealth.com).\n\n## Challenges and leaderboards\n\nIf you join a challenge, your step count and display name are visible to other participants on that challenge's leaderboard.\n\n## Connected health apps\n\nIf you connect Apple Health, Health Connect, Oura, Garmin, or Strava, we only read the activity data needed to power your dashboard. You can disconnect any app at any time from **Settings > Connected Apps**.\n\n## Data retention\n\nWe keep your activity history for as long as your account is active. If you delete your account, we anonymize your profile but retain workout and challenge history for platform integrity — see our full retention policy for details.",
    changelog: null, effective_date: dateKey(-14), requires_reaccept: true,
    created_by: "usr_016", created_at: daysAgo(3), published_at: null,
  },

  // --- Terms of Service ---------------------------------------------------------
  {
    id: "terms_v1", doc_type: "terms", version: 1, status: "archived",
    content: "# Terms of Service\n\nBy using Strolla Health you agree to use the app for personal, non-commercial fitness tracking.",
    changelog: null, effective_date: dateKey(500), requires_reaccept: true,
    created_by: "usr_017", created_at: daysAgo(500), published_at: daysAgo(500),
  },
  {
    id: "terms_v2", doc_type: "terms", version: 2, status: "published",
    content: "# Terms of Service\n\nBy using Strolla Health you agree to use the app and any paired Strolla tracker for personal, non-commercial fitness tracking.\n\n## Premium subscriptions\n\n- Premium subscriptions **renew automatically** unless cancelled at least 24 hours before the renewal date\n- Refunds are handled by the app store you subscribed through (Apple App Store or Google Play)\n- Comp/trial access granted by Strolla Health can be revoked at any time and doesn't affect a real paid subscription\n\nQuestions? Contact [support@strollahealth.com](mailto:support@strollahealth.com).",
    changelog: "- Added the \"Premium subscriptions\" section covering auto-renewal and refunds\n- Clarified that comp access doesn't affect real paid subscriptions",
    effective_date: dateKey(120), requires_reaccept: false,
    created_by: "usr_016", created_at: daysAgo(122), published_at: daysAgo(120),
  },

  // --- Community Guidelines ----------------------------------------------------
  {
    id: "cg_v1", doc_type: "community_guidelines", version: 1, status: "archived",
    content: "# Community Guidelines\n\nBe kind. No harassment or spam.",
    changelog: null, effective_date: dateKey(300), requires_reaccept: true,
    created_by: "usr_017", created_at: daysAgo(300), published_at: daysAgo(300),
  },
  {
    id: "cg_v2", doc_type: "community_guidelines", version: 2, status: "archived",
    content: "# Community Guidelines\n\nBe kind. No harassment, spam, or scam links.\n\nCelebrate other people's progress the way you'd want your own celebrated.",
    changelog: "- Explicitly called out scam/spam links",
    effective_date: dateKey(200), requires_reaccept: false,
    created_by: "usr_016", created_at: daysAgo(202), published_at: daysAgo(200),
  },
  {
    id: "cg_v3", doc_type: "community_guidelines", version: 3, status: "archived",
    content: "# Community Guidelines\n\nBe kind. No harassment, spam, or scam links.\n\nCelebrate other people's progress the way you'd want your own celebrated.\n\n## What happens if you break these\n\n1. First violation: post removed, warning issued\n2. Second violation: 7-day posting ban\n3. Serious or repeat violations: permanent account suspension",
    changelog: "- Added the enforcement ladder (\"What happens if you break these\")",
    effective_date: dateKey(60), requires_reaccept: true,
    created_by: "usr_016", created_at: daysAgo(62), published_at: daysAgo(60),
  },
  {
    id: "cg_v4", doc_type: "community_guidelines", version: 4, status: "published",
    content: "# Community Guidelines\n\nBe kind. No harassment, spam, or scam links. Celebrate other people's progress the way you'd want your own celebrated.\n\n## What happens if you break these\n\n1. First violation: post removed, warning issued\n2. Second violation: 7-day posting ban\n3. Serious or repeat violations: permanent account suspension\n\n## Reporting\n\nIf you see something that breaks these guidelines, report it directly from the post or profile — our moderation team reviews every report.",
    changelog: "- Added the \"Reporting\" section explaining how to flag content\n- Clarified support email",
    effective_date: dateKey(6), requires_reaccept: true,
    created_by: "usr_016", created_at: daysAgo(8), published_at: daysAgo(6),
  },
];

// Seeded only for versions that required re-accept — a version nobody was
// ever asked to accept has no acceptance rows at all (see
// `legalAcceptanceStats`, which reads an empty result as "not applicable"
// rather than 0%). One row per real user at the time that version
// published.
function buildLegalAcceptances(): LegalAcceptance[] {
  const realUsers = mockUsers.filter((u) => u.role === "user" && !u.deleted);
  const rows: LegalAcceptance[] = [];
  let n = 0;
  for (const u of realUsers) {
    // Deterministic per-user spread rather than random — stable across reloads.
    const bucket = n % 20;
    const status: LegalAcceptance["status"] = bucket < 17 ? "accepted" : bucket < 19 ? "pending" : "declined";
    rows.push({
      id: `la_cg4_${n}`,
      user_id: u.id,
      doc_type: "community_guidelines",
      version: 4,
      status,
      responded_at: status === "pending" ? null : daysAgo((n % 5) + 1),
    });
    n++;
  }
  return rows;
}

export const mockLegalAcceptances: LegalAcceptance[] = buildLegalAcceptances();

// --- App settings (global defaults) ----------------------------------------------

// --- Beta overrides (per-user/email/ambassador feature access) ------------------

export const mockBetaOverrides: BetaOverride[] = [
  { id: "beta_001", feature_key: "extra_stats_tabs", target_type: "ambassador", target_value: "", created_by: "usr_016", created_at: daysAgo(20) },
  { id: "beta_002", feature_key: "widget", target_type: "user_id", target_value: "usr_009", created_by: "usr_016", created_at: daysAgo(5) },
  { id: "beta_003", feature_key: "activity_insights", target_type: "email", target_value: "beta.tester@strollahealth.com", created_by: "usr_017", created_at: daysAgo(2) },
];

// --- Announcements (in-app banner shown once per user on open) -----------------

export const mockAnnouncements: Announcement[] = [
  {
    id: "ann_001",
    emoji: "🎉",
    message: "July Challenge is Live! Join now and compete for the top spot.",
    link_target: "challenge_of_the_month",
    audience: "everyone",
    audience_app_version: null,
    audience_app_version_mode: null,
    active: true,
    starts_at: daysAgo(10),
    ends_at: daysAgo(-20),
    created_by: "usr_016",
    created_at: daysAgo(10),
  },
  {
    id: "ann_002",
    emoji: "🚀",
    message: "New Feature: Share your steps to Instagram! You're seeing this early as a beta tester — let us know what you think.",
    link_target: "share_steps",
    audience: "beta_testers",
    audience_app_version: null,
    audience_app_version_mode: null,
    active: false,
    starts_at: daysAgo(35),
    ends_at: daysAgo(21),
    created_by: "usr_017",
    created_at: daysAgo(36),
  },
  {
    id: "ann_003",
    emoji: "⬆️",
    message: "A new version of Strolla is available with battery-life improvements and bug fixes. Please update from your app store.",
    link_target: null,
    audience: "app_version",
    audience_app_version: "2.2.0",
    audience_app_version_mode: "at_or_below",
    active: true,
    starts_at: daysAgo(4),
    ends_at: null,
    created_by: "usr_016",
    created_at: daysAgo(4),
  },
];

export const mockAppSettings: AppSettings = {
  default_daily_goal_steps: 10000,
  challenge_default_duration_days: 7,
  notify_goal_reminder_default: true,
  notify_streak_default: true,
  notify_challenge_updates_default: true,
  max_image_size_mb: 10,
  max_post_length: 500,
  max_bio_length: 160,
  trial_period_days: 14,
  premium_monthly_price_gbp: 4.99,
  premium_annual_price_gbp: 39.99,
  default_privacy: {
    public_profile: true,
    share_activity: true,
    show_in_leaderboards: true,
    allow_friend_requests: true,
    hide_activity_data: false,
    hide_achievements: false,
    hide_recent_activity: false,
  },
  minimum_required_app_version: null,
  updated_at: daysAgo(30),
};
