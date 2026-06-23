import type {
  AnalyticsEvent,
  AnalyticsEventType,
  Badge,
  Challenge,
  ChallengeParticipant,
  CommunityPost,
  DailyActivitySummary,
  Device,
  FeatureFlag,
  Report,
  UserBadge,
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
  deleted?: boolean;
  reasons?: UserProfile["reasons"];
}

const userSeeds: UserSeed[] = [
  { id: "usr_001", email: "priya.shah@gmail.com", username: "priya.walks", name: "Priya Shah", location: "Leeds, UK", bio: "Recovering from a knee injury, taking it one walk at a time.", gender: "female", height_cm: 163, weight_kg: 61, daily_goal_steps: 6000, role: "user", createdDaysAgo: 188, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-9) }, reasons: ["accurate_tracking"] },
  { id: "usr_002", email: "tom.brennan@outlook.com", username: "tombrennan", name: "Tom Brennan", location: "Bristol, UK", gender: "male", height_cm: 179, weight_kg: 82, daily_goal_steps: 10000, role: "user", createdDaysAgo: 142, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-3), comp_reason: "signup_trial" } },
  { id: "usr_003", email: "sarah.mwangi@yahoo.com", username: "sarah.m", name: "Sarah Mwangi", location: "Manchester, UK", bio: "Stroller walks with a 7-month-old most mornings.", gender: "female", height_cm: 168, weight_kg: 64, daily_goal_steps: 8000, role: "user", createdDaysAgo: 96, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-21) }, reasons: ["stroller_wagon"] },
  { id: "usr_004", email: "j.kowalczyk88@gmail.com", username: "jkowalczyk", name: "James Kowalczyk", location: "Sheffield, UK", gender: "male", height_cm: 174, weight_kg: 76, daily_goal_steps: 12000, role: "user", createdDaysAgo: 211, subscription: { tier: "free", status: "expired" } },
  { id: "usr_005", email: "mei.lin.99@gmail.com", username: "mei.lin", name: "Mei Lin", location: "Birmingham, UK", bio: "Walking pad at my desk, every single day.", gender: "female", height_cm: 159, weight_kg: 55, daily_goal_steps: 9000, role: "user", createdDaysAgo: 64, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-26), comp_reason: "signup_trial" }, reasons: ["walking_pad"] },
  { id: "usr_006", email: "dan.holloway@hotmail.com", username: "dan.h", name: "Dan Holloway", location: "Edinburgh, UK", gender: "male", height_cm: 183, weight_kg: 88, daily_goal_steps: 10000, role: "user", createdDaysAgo: 301, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-14) } },
  { id: "usr_007", email: "alex.reyes@gmail.com", username: "alex.r", name: "Alex Reyes", location: "Cardiff, UK", gender: "other", height_cm: 171, weight_kg: 69, daily_goal_steps: 15000, role: "user", createdDaysAgo: 47, subscription: { tier: "premium", status: "active", comp_until: daysAgo(-150), comp_reason: "kickstarter_backer" } },
  { id: "usr_008", email: "fatima.hussain22@gmail.com", username: "fatima.h", name: "Fatima Hussain", location: "Glasgow, UK", bio: "Night-shift A&E nurse, can't wear a watch on the ward.", gender: "female", height_cm: 165, weight_kg: 60, daily_goal_steps: 7000, role: "user", createdDaysAgo: 33, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-4), comp_reason: "signup_trial" }, reasons: ["cant_wear_wearable"] },
  { id: "usr_009", email: "ollie.fenwick@gmail.com", username: "ollie.fenwick", name: "Ollie Fenwick", location: "Newcastle, UK", gender: "male", height_cm: 177, weight_kg: 79, daily_goal_steps: 10000, role: "user", createdDaysAgo: 19, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-26), comp_reason: "signup_trial" } },
  { id: "usr_010", email: "ruth.adeyemi@gmail.com", username: "ruth.a", name: "Ruth Adeyemi", location: "London, UK", gender: "female", height_cm: 170, weight_kg: 67, daily_goal_steps: 8500, role: "user", createdDaysAgo: 5, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-25), comp_reason: "signup_trial" } },
  { id: "usr_011", email: "marcus.webb@protonmail.com", username: "marcus.webb", name: "Marcus Webb", location: "Liverpool, UK", gender: "male", height_cm: 181, weight_kg: 91, daily_goal_steps: 10000, role: "user", createdDaysAgo: 220, subscription: { tier: "free", status: "expired" }, banned: true, ban_reason: "Repeated harassment in community comments after two prior warnings." },
  { id: "usr_012", email: "lena.kovac@gmail.com", username: "lena.k", name: "Lena Kovac", location: "Nottingham, UK", gender: "female", height_cm: 162, weight_kg: 58, daily_goal_steps: 9500, role: "user", createdDaysAgo: 78, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-2) } },
  { id: "usr_013", email: "deleted-user-9f2@strolla.health", username: "deleted_9f2a8b1c", name: "Deleted User", gender: "prefer_not_to_say", height_cm: 170, weight_kg: null, daily_goal_steps: 10000, role: "user", createdDaysAgo: 260, subscription: { tier: "free", status: "expired" }, deleted: true },
  { id: "usr_014", email: "ben.okafor@gmail.com", username: "ben.okafor", name: "Ben Okafor", location: "Leicester, UK", gender: "male", height_cm: 175, weight_kg: 73, daily_goal_steps: 11000, role: "user", createdDaysAgo: 13, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-17), comp_reason: "signup_trial" } },
  { id: "usr_015", email: "grace.tan@gmail.com", username: "grace.tan", name: "Grace Tan", location: "Southampton, UK", gender: "female", height_cm: 160, weight_kg: 54, daily_goal_steps: 7500, role: "user", createdDaysAgo: 156, subscription: { tier: "premium", status: "active", renews_at: daysAgo(-30) } },
  { id: "usr_016", email: "support.maya@strollahealth.com", username: "maya.ops", name: "Maya Whitfield", location: "Remote", gender: "female", height_cm: 167, weight_kg: 63, daily_goal_steps: 8000, role: "admin", createdDaysAgo: 305, subscription: { tier: "free", status: "active" } },
  { id: "usr_017", email: "founder.sarah@strollahealth.com", username: "sarah.founder", name: "Sarah Pemberton", location: "Remote", gender: "female", height_cm: 165, weight_kg: 60, daily_goal_steps: 8000, role: "super_admin", createdDaysAgo: 365, subscription: { tier: "free", status: "active" } },
  { id: "usr_018", email: "callum.ferris@gmail.com", username: "callum.f", name: "Callum Ferris", location: "Aberdeen, UK", gender: "male", height_cm: 178, weight_kg: 84, daily_goal_steps: 10000, role: "user", createdDaysAgo: 41, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-1), comp_reason: "signup_trial" } },
  { id: "usr_019", email: "isabel.cruz@gmail.com", username: "isabel.cruz", name: "Isabel Cruz", location: "Coventry, UK", gender: "female", height_cm: 158, weight_kg: 52, daily_goal_steps: 6500, role: "user", createdDaysAgo: 9, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-21), comp_reason: "signup_trial" } },
  { id: "usr_020", email: "harvey.nash@gmail.com", username: "harvey.nash", name: "Harvey Nash", location: "Belfast, UK", gender: "male", height_cm: 172, weight_kg: 70, daily_goal_steps: 10000, role: "user", createdDaysAgo: 2, subscription: { tier: "free", status: "trialing", comp_until: daysAgo(-28), comp_reason: "signup_trial" } },
  // Genuinely free: trial already lapsed, never subscribed, never admin-granted.
  { id: "usr_021", email: "noah.sinclair@gmail.com", username: "noah.sinclair", name: "Noah Sinclair", location: "York, UK", gender: "male", height_cm: 180, weight_kg: 86, daily_goal_steps: 8000, role: "user", createdDaysAgo: 6, subscription: { tier: "free", status: "expired" } },
  { id: "usr_022", email: "aisha.begum@gmail.com", username: "aisha.begum", name: "Aisha Begum", location: "Bradford, UK", gender: "female", height_cm: 161, weight_kg: 57, daily_goal_steps: 7000, role: "user", createdDaysAgo: 15, subscription: { tier: "free", status: "expired" } },
  { id: "usr_023", email: "connor.walsh@gmail.com", username: "connor.walsh", name: "Connor Walsh", location: "Derby, UK", gender: "male", height_cm: 176, weight_kg: 80, daily_goal_steps: 9000, role: "user", createdDaysAgo: 24, subscription: { tier: "free", status: "expired" } },
];

export const mockUsers: UserProfile[] = userSeeds.map((seed) => ({
  id: seed.id,
  email: seed.deleted ? null : seed.email,
  username: seed.username,
  name: seed.deleted ? "Deleted User" : seed.name,
  location: seed.deleted ? null : seed.location ?? null,
  bio: seed.deleted ? null : seed.bio ?? null,
  photo_url: null,
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
    comp_until: null,
    comp_reason: null,
    revenuecat_app_user_id: seed.subscription.status === "active" ? `rc_${seed.id}` : null,
    renews_at: null,
    cancelled_at: null,
    ...seed.subscription,
  },
  banned: !!seed.banned,
  ban_reason: seed.ban_reason ?? null,
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
  { id: "dev_001", serial_number: "STR-10042", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:11", firmware_version: "1.4.2", manufacturing_batch: "B-2025-11", owner_user_id: "usr_001", paired_at: daysAgo(180), last_seen_at: daysAgo(0, 7, 40), battery_level: 62, created_at: daysAgo(190) },
  { id: "dev_002", serial_number: "STR-10043", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:12", firmware_version: "1.4.2", manufacturing_batch: "B-2025-11", owner_user_id: "usr_003", paired_at: daysAgo(90), last_seen_at: daysAgo(0, 6, 12), battery_level: 88, created_at: daysAgo(190) },
  { id: "dev_003", serial_number: "STR-10044", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:13", firmware_version: "1.3.0", manufacturing_batch: "B-2025-11", owner_user_id: "usr_006", paired_at: daysAgo(295), last_seen_at: daysAgo(3, 18, 0), battery_level: 14, created_at: daysAgo(300) },
  { id: "dev_004", serial_number: "STR-10045", device_type: "strolla_nrf7002", ble_mac: null, firmware_version: null, manufacturing_batch: "B-2025-12", owner_user_id: null, paired_at: null, last_seen_at: null, battery_level: null, created_at: daysAgo(60) },
  { id: "dev_005", serial_number: "STR-10046", device_type: "strolla_nrf7002", ble_mac: null, firmware_version: null, manufacturing_batch: "B-2025-12", owner_user_id: null, paired_at: null, last_seen_at: null, battery_level: null, created_at: daysAgo(60) },
  { id: "dev_006", serial_number: "STR-10047", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:16", firmware_version: "1.4.2", manufacturing_batch: "B-2025-12", owner_user_id: "usr_012", paired_at: daysAgo(70), last_seen_at: daysAgo(0, 8, 5), battery_level: 45, created_at: daysAgo(75) },
  { id: "dev_007", serial_number: "STR-10048", device_type: "strolla_nrf7002", ble_mac: "F2:3A:91:0C:88:17", firmware_version: "1.2.1", manufacturing_batch: "B-2025-09", owner_user_id: "usr_015", paired_at: daysAgo(150), last_seen_at: daysAgo(12, 9, 0), battery_level: 3, created_at: daysAgo(160) },
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
}

const postSeeds: PostSeed[] = [
  { id: "post_001", author_id: "usr_003", content: "Morning stroller walk before the school run, 5.2km and the baby's already asleep. Small wins.", daysAgo: 0, likes: 24, comments: 6, step_count: 6820, image_url: "https://picsum.photos/seed/strolla-park-morning/800/500" },
  { id: "post_002", author_id: "usr_007", content: "Hit 70,400 steps this week, new personal best. The 10K Daily Streak challenge is brutal but it works.", daysAgo: 0, likes: 41, comments: 11, step_count: 70400, badge_emoji: "🔥" },
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
  { id: "post_014", author_id: "usr_011", content: "anyone else think the leaderboard is rigged lol staff accounts always at the top", daysAgo: 6, likes: 4, comments: 6, hidden: { by: "usr_016", reason: "Unsubstantiated accusation against staff, escalating in comments. Hidden pending review.", daysAgo: 6 } },
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
}));

// --- Reports -------------------------------------------------------------------

export const mockReports: Report[] = [
  { id: "rep_001", reporter_id: "usr_001", target_type: "post", target_id: "post_011", reason: "This post is advertising a fake 'free premium' link, looks like a phishing attempt.", status: "resolved", resolved_by: "usr_016", resolved_at: daysAgo(4, 15, 0), resolution_note: "Post hidden, author warned via email.", created_at: daysAgo(4, 13, 30) },
  { id: "rep_002", reporter_id: "usr_007", target_type: "user", target_id: "usr_011", reason: "Keeps leaving harassing comments on other people's step posts, this is the third time I've reported him.", status: "resolved", resolved_by: "usr_016", resolved_at: daysAgo(2, 10, 0), resolution_note: "Account banned after third confirmed incident.", created_at: daysAgo(2, 9, 0) },
  { id: "rep_003", reporter_id: "usr_003", target_type: "post", target_id: "post_014", reason: "Unfounded accusation that's stirring up the comment section, feels like it's heading toward a pile-on.", status: "open", resolved_by: null, resolved_at: null, resolution_note: null, created_at: daysAgo(6, 11, 20) },
  { id: "rep_004", reporter_id: "usr_012", target_type: "post", target_id: "post_005", reason: "Calling the app a scam with no basis, discouraging other users in the thread.", status: "open", resolved_by: null, resolved_at: null, resolution_note: null, created_at: daysAgo(1, 16, 40) },
  { id: "rep_005", reporter_id: "usr_015", target_type: "user", target_id: "usr_009", reason: "Profile photo looks like it might not be theirs, possible impersonation, wanted to flag just in case.", status: "dismissed", resolved_by: "usr_016", resolved_at: daysAgo(3, 9, 0), resolution_note: "Checked, no impersonation, just a stock-style profile photo. No action needed.", created_at: daysAgo(4, 8, 0) },
  { id: "rep_006", reporter_id: "usr_002", target_type: "post", target_id: "post_011", reason: "Same spam link as another report, posting again under a new comment.", status: "open", resolved_by: null, resolved_at: null, resolution_note: null, created_at: daysAgo(0, 9, 0) },
];

// --- Challenges + participants -----------------------------------------------

export const mockChallenges: Challenge[] = [
  { id: "chal_001", title: "10K Daily Streak", description: "Hit 10,000 steps every day for 7 days straight.", goal_steps: 70000, start_date: dateKey(10), end_date: dateKey(-4), badge_emoji: "🔥", accent_color_value: null, visibility: "public", is_official: true, invite_code: null, created_by: null, created_at: daysAgo(11) },
  { id: "chal_002", title: "50km This Month", description: "Walk or run 50 kilometres before the month ends.", goal_steps: 65616, start_date: dateKey(20), end_date: dateKey(-9), badge_emoji: "🗺️", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: "usr_016", created_at: daysAgo(21) },
  { id: "chal_003", title: "Weekend Warrior", description: "Get 25,000 steps over Saturday and Sunday.", goal_steps: 25000, start_date: dateKey(4), end_date: dateKey(-2), badge_emoji: "⚡", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: "usr_016", created_at: daysAgo(5) },
  { id: "chal_004", title: "Office Walking Club", description: "Private challenge for the Leeds office crew, 40k steps each over two weeks.", goal_steps: 40000, start_date: dateKey(13), end_date: dateKey(-1), badge_emoji: "🏢", accent_color_value: null, visibility: "private", is_official: false, invite_code: "LDS-WALK-22", created_by: "usr_001", created_at: daysAgo(14) },
  { id: "chal_005", title: "May Step Sprint", description: "Last month's official challenge, archived for reference.", goal_steps: 60000, start_date: "2026-05-01", end_date: "2026-05-31", badge_emoji: "🏆", accent_color_value: null, visibility: "public", is_official: false, invite_code: null, created_by: null, created_at: "2026-04-29T09:00:00Z" },
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
  { id: "badge_001", name: "First Steps", description: "Completed onboarding and logged your first day of steps.", emoji: "👟", created_at: daysAgo(300) },
  { id: "badge_002", name: "Early Bird", description: "Logged a walk before 7am, five times.", emoji: "🌅", created_at: daysAgo(280) },
  { id: "badge_003", name: "Streak Master", description: "Hit your daily goal 30 days in a row.", emoji: "🔥", created_at: daysAgo(260) },
  { id: "badge_004", name: "Marathon Mile", description: "Walked or ran a cumulative 42.2km in a single week.", emoji: "🏃", created_at: daysAgo(240) },
  { id: "badge_005", name: "Community Champion", description: "Posted 25 times and helped others stay motivated.", emoji: "💬", created_at: daysAgo(200) },
  { id: "badge_006", name: "Founding Walker", description: "Joined during the Kickstarter launch window.", emoji: "🚀", created_at: daysAgo(360) },
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
