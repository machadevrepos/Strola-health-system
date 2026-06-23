import type {
  AnalyticsEvent,
  AnalyticsEventType,
  Badge,
  Challenge,
  ChallengeParticipant,
  CommunityPost,
  Device,
  Report,
  UserBadge,
  UserProfile,
} from "@/lib/types";

// Pure functions over already-fetched arrays — the actual fetching lives in
// `api.ts`. Pages fetch the raw collections they need once, then call these
// to sort/filter/enrich (e.g. attach the author to a post) exactly the way
// the real backend's response shapes require, since the API returns flat
// rows without joins.

export function findUserById(users: UserProfile[], id: string | null | undefined): UserProfile | undefined {
  return users.find((u) => u.id === id);
}

/**
 * True only for a comp period an admin actually granted (manual grant or a
 * Kickstarter reward) — NOT the automatic 30-day signup trial, which uses
 * the same `comp_until` mechanism under the hood (see SubscriptionService on
 * the backend) but isn't something an admin "granted" via this menu. Used to
 * decide whether a user row offers "Grant premium" or "Terminate premium".
 */
export function hasAdminGrantedPremium(user: UserProfile): boolean {
  const { comp_until, comp_reason } = user.subscription;
  return !!comp_until && new Date(comp_until) > new Date() && comp_reason !== "signup_trial";
}

export function userDisplayName(user: UserProfile | undefined | null): string {
  if (!user) return "Unknown user";
  return user.deleted ? "Deleted User" : user.name || user.username;
}

export function listStaff(users: UserProfile[]): UserProfile[] {
  return users.filter((u) => u.role === "admin" || u.role === "super_admin").sort((a, b) => +new Date(a.created_at) - +new Date(b.created_at));
}

export function listPromotableUsers(users: UserProfile[]): UserProfile[] {
  return users.filter((u) => u.role === "user" && !u.banned && !u.deleted);
}

export interface EnrichedPost extends CommunityPost {
  author: UserProfile | undefined;
}

export function enrichPosts(posts: CommunityPost[], users: UserProfile[]): EnrichedPost[] {
  return [...posts]
    .map((p) => ({ ...p, author: findUserById(users, p.author_id) }))
    .sort((a, b) => +new Date(b.timestamp) - +new Date(a.timestamp));
}

export interface EnrichedReport extends Report {
  reporter: UserProfile | undefined;
  targetPost?: EnrichedPost;
  targetUser?: UserProfile;
}

export function enrichReports(reports: Report[], users: UserProfile[], posts: CommunityPost[]): EnrichedReport[] {
  const enrichedPosts = enrichPosts(posts, users);
  return [...reports]
    .sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at))
    .map((r) => ({
      ...r,
      reporter: findUserById(users, r.reporter_id),
      targetPost: r.target_type === "post" ? enrichedPosts.find((p) => p.id === r.target_id) : undefined,
      targetUser: r.target_type === "user" ? findUserById(users, r.target_id) : undefined,
    }));
}

export function sortChallenges(challenges: Challenge[]): Challenge[] {
  return [...challenges].sort((a, b) => +new Date(b.start_date) - +new Date(a.start_date));
}

export interface EnrichedParticipant extends ChallengeParticipant {
  user: UserProfile | undefined;
}

export function enrichParticipants(participants: ChallengeParticipant[], users: UserProfile[]): EnrichedParticipant[] {
  return participants.map((p) => ({ ...p, user: findUserById(users, p.user_id) })).sort((a, b) => b.steps - a.steps);
}

export function challengeStatus(c: Challenge): "upcoming" | "active" | "ended" {
  const now = Date.now();
  const start = +new Date(c.start_date);
  const end = +new Date(c.end_date);
  if (now < start) return "upcoming";
  if (now > end) return "ended";
  return "active";
}

export interface EnrichedAward extends UserBadge {
  user: UserProfile | undefined;
  badge: Badge | undefined;
}

export function enrichAwards(awards: UserBadge[], users: UserProfile[], badges: Badge[]): EnrichedAward[] {
  return awards.map((a) => ({ ...a, user: findUserById(users, a.user_id), badge: badges.find((b) => b.id === a.badge_id) }));
}

export function listUnpairedDevices(devices: Device[]): Device[] {
  return devices.filter((d) => !d.owner_user_id);
}

// --- Analytics aggregation ----------------------------------------------------

function startOfDayKey(iso: string): string {
  return iso.slice(0, 10);
}

export function dailyActiveUsers(events: AnalyticsEvent[], days = 30): { date: string; count: number }[] {
  const byDay = new Map<string, Set<string>>();
  for (const e of events) {
    if (e.event_type !== "app_opened" || !e.user_id) continue;
    const key = startOfDayKey(e.created_at);
    if (!byDay.has(key)) byDay.set(key, new Set());
    byDay.get(key)!.add(e.user_id);
  }
  return Array.from(byDay.entries())
    .map(([date, users]) => ({ date, count: users.size }))
    .sort((a, b) => +new Date(a.date) - +new Date(b.date))
    .slice(-days);
}

export function eventCounts(events: AnalyticsEvent[], sinceDays = 30): Record<AnalyticsEventType, number> {
  const cutoff = Date.now() - sinceDays * 86_400_000;
  const counts = {} as Record<AnalyticsEventType, number>;
  for (const e of events) {
    if (+new Date(e.created_at) < cutoff) continue;
    counts[e.event_type] = (counts[e.event_type] ?? 0) + 1;
  }
  return counts;
}

export function workoutFunnel(events: AnalyticsEvent[], sinceDays = 30) {
  const counts = eventCounts(events, sinceDays);
  return [
    { stage: "App opened", count: counts.app_opened ?? 0 },
    { stage: "Workout started", count: counts.workout_started ?? 0 },
    { stage: "Workout completed", count: counts.workout_completed ?? 0 },
  ];
}

export function subscriptionMix(users: UserProfile[]) {
  const counts = { free: 0, trialing: 0, premium: 0 };
  for (const u of users) {
    if (u.role !== "user" || u.deleted) continue;
    if (u.subscription.tier === "premium" && u.subscription.status === "active") counts.premium++;
    else if (u.subscription.status === "trialing") counts.trialing++;
    else counts.free++;
  }
  return [
    { tier: "Premium", count: counts.premium },
    { tier: "Trial", count: counts.trialing },
    { tier: "Free", count: counts.free },
  ];
}

export function overviewTotals(data: {
  users: UserProfile[];
  reports: Report[];
  posts: CommunityPost[];
  challenges: Challenge[];
  devices: Device[];
  events: AnalyticsEvent[];
}) {
  const users = data.users.filter((u) => u.role === "user" && !u.deleted);
  const dau = dailyActiveUsers(data.events, 1);
  const openReports = data.reports.filter((r) => r.status === "open").length;
  const hiddenPosts = data.posts.filter((p) => p.moderation.hidden).length;
  const activeChallenges = data.challenges.filter((c) => challengeStatus(c) === "active").length;
  const pairedDevices = data.devices.filter((d) => d.owner_user_id).length;
  return {
    totalUsers: users.length,
    dauToday: dau.at(-1)?.count ?? 0,
    openReports,
    hiddenPosts,
    activeChallenges,
    pairedDevices,
    totalDevices: data.devices.length,
  };
}

export function fleetStats(devices: Device[]) {
  const paired = devices.filter((d) => d.owner_user_id).length;
  const lowBattery = devices.filter((d) => d.battery_level != null && d.battery_level < 15).length;
  return {
    total: devices.length,
    paired,
    inStock: devices.length - paired,
    lowBattery,
  };
}
