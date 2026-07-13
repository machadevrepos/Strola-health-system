import type {
  AnalyticsEvent,
  AnalyticsEventType,
  Badge,
  Challenge,
  ChallengeParticipant,
  CommunityComment,
  CommunityPost,
  DailyActivitySummary,
  Device,
  IntegrationConnection,
  PushSegment,
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
    // Pinned posts lead regardless of recency — that's the point of pinning
    // — then newest first within each group.
    .sort((a, b) => {
      if (a.pinned !== b.pinned) return a.pinned ? -1 : 1;
      return +new Date(b.timestamp) - +new Date(a.timestamp);
    });
}

export interface EnrichedComment extends CommunityComment {
  author: UserProfile | undefined;
  post: CommunityPost | undefined;
}

export function enrichComments(comments: CommunityComment[], users: UserProfile[], posts: CommunityPost[]): EnrichedComment[] {
  return [...comments]
    .map((c) => ({ ...c, author: findUserById(users, c.author_id), post: posts.find((p) => p.id === c.post_id) }))
    .sort((a, b) => +new Date(b.timestamp) - +new Date(a.timestamp));
}

export interface EnrichedReport extends Report {
  reporter: UserProfile | undefined;
  resolvedByUser: UserProfile | undefined;
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
      resolvedByUser: r.resolved_by ? findUserById(users, r.resolved_by) : undefined,
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

/**
 * Distinct users active over the most recent `days`-day window — unions the
 * daily-active-user sets already present in the data rather than comparing
 * against wall-clock `Date.now()`. The mock event data is anchored to a
 * frozen `NOW` in mock-data.ts, so a real-time cutoff would silently drift
 * toward zero as real time moves past that anchor; working from the data's
 * own most-recent day instead keeps this correct regardless of when the demo
 * is actually run.
 */
export function activeUserIdsInWindow(events: AnalyticsEvent[], days: number): Set<string> {
  const byDay = new Map<string, Set<string>>();
  for (const e of events) {
    if (e.event_type !== "app_opened" || !e.user_id) continue;
    const key = startOfDayKey(e.created_at);
    if (!byDay.has(key)) byDay.set(key, new Set());
    byDay.get(key)!.add(e.user_id);
  }
  const recentDays = Array.from(byDay.keys()).sort().slice(-days);
  const union = new Set<string>();
  for (const day of recentDays) {
    for (const id of byDay.get(day)!) union.add(id);
  }
  return union;
}

export function activeUsersInWindow(events: AnalyticsEvent[], days: number): number {
  return activeUserIdsInWindow(events, days).size;
}

/** New signups within the most recent `days`-day window of the dataset's own
 * timeline — same data-relative reasoning as `activeUsersInWindow`. */
export function newSignupsCount(users: UserProfile[], days = 7): number {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return 0;
  const latest = Math.max(...real.map((u) => +new Date(u.created_at)));
  const cutoff = latest - days * 86_400_000;
  return real.filter((u) => +new Date(u.created_at) >= cutoff).length;
}

/** Posts on the most recent calendar day present in the data — mirrors how
 * `dailyActiveUsers`'s last bucket stands in for "today" elsewhere on this
 * dashboard, for the same frozen-mock-timeline reason. */
export function postsToday(posts: CommunityPost[]): number {
  if (posts.length === 0) return 0;
  const latestDay = posts.reduce((max, p) => (p.timestamp > max ? p.timestamp : max), posts[0].timestamp).slice(0, 10);
  return posts.filter((p) => p.timestamp.slice(0, 10) === latestDay).length;
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
  const premiumSubscribers = users.filter((u) => u.subscription.tier === "premium" && u.subscription.status === "active").length;
  return {
    totalUsers: users.length,
    dauToday: dau.at(-1)?.count ?? 0,
    activeThisWeek: activeUsersInWindow(data.events, 7),
    activeThisMonth: activeUsersInWindow(data.events, 30),
    newSignups7d: newSignupsCount(users, 7),
    postsToday: postsToday(data.posts),
    openReports,
    hiddenPosts,
    activeChallenges,
    pairedDevices,
    totalDevices: data.devices.length,
    premiumSubscribers,
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

// --- Push notification segments -------------------------------------------------

export const PUSH_SEGMENT_LABEL: Record<PushSegment, string> = {
  everyone: "Everyone",
  premium: "Premium users",
  free: "Free users",
  canada: "Users in Canada",
  usa: "Users in USA",
  inactive_30d: "Haven't opened app in 30 days",
  challenge_participants: "Challenge participants",
  tracker_owners: "Tracker owners",
};

/**
 * Who a segment actually resolves to right now — used both to show a live
 * "~N recipients" estimate before sending, and to record `recipient_count`
 * on the notification once sent. All seeded users are UK-based today, so
 * "canada"/"usa" legitimately resolve to 0 here — that's the real answer for
 * this user base, not a bug, and will start returning results the moment
 * international users sign up.
 */
export function segmentAudienceIds(
  segment: PushSegment,
  data: { users: UserProfile[]; events: AnalyticsEvent[]; participants: ChallengeParticipant[]; devices: Device[] }
): string[] {
  const realUsers = data.users.filter((u) => u.role === "user" && !u.deleted);
  const isPremium = (u: UserProfile) => u.subscription.tier === "premium" && u.subscription.status === "active";

  switch (segment) {
    case "everyone":
      return realUsers.map((u) => u.id);
    case "premium":
      return realUsers.filter(isPremium).map((u) => u.id);
    case "free":
      return realUsers.filter((u) => !isPremium(u)).map((u) => u.id);
    case "canada":
      return realUsers.filter((u) => (u.location ?? "").toLowerCase().includes("canada")).map((u) => u.id);
    case "usa":
      return realUsers.filter((u) => /\b(usa|united states)\b/i.test(u.location ?? "")).map((u) => u.id);
    case "inactive_30d": {
      const active = activeUserIdsInWindow(data.events, 30);
      return realUsers.filter((u) => !active.has(u.id)).map((u) => u.id);
    }
    case "challenge_participants":
      return Array.from(new Set(data.participants.filter((p) => !p.left_at).map((p) => p.user_id)));
    case "tracker_owners":
      return Array.from(new Set(data.devices.filter((d) => d.owner_user_id).map((d) => d.owner_user_id!)));
  }
}

// --- Premium overview -----------------------------------------------------------

// Placeholder monthly price for the revenue estimate below — there's no real
// RevenueCat price data in this mock set. Swap for the actual price (or a
// real RevenueCat MRR figure) once that's wired in; until then this number
// is illustrative only, not a real revenue figure.
const SYNTHETIC_MONTHLY_PRICE_GBP = 4.99;

export interface PremiumSubscriberRow {
  user: UserProfile;
  isComp: boolean;
  // renews_at for a real paying subscriber, comp_until for an admin-granted
  // one — whichever actually governs when their access lapses.
  expiresAt: string | null;
}

export function premiumSubscribers(users: UserProfile[]): PremiumSubscriberRow[] {
  const rows: PremiumSubscriberRow[] = users
    .filter((u) => u.role === "user" && !u.deleted && u.subscription.tier === "premium" && u.subscription.status === "active")
    .map((u) => {
      const isComp = hasAdminGrantedPremium(u);
      return { user: u, isComp, expiresAt: isComp ? u.subscription.comp_until : u.subscription.renews_at };
    });
  return rows.sort((a, b) => {
    if (!a.expiresAt && !b.expiresAt) return 0;
    if (!a.expiresAt) return 1;
    if (!b.expiresAt) return -1;
    return +new Date(a.expiresAt) - +new Date(b.expiresAt);
  });
}

/** Synthetic MRR — real paying subscribers only, comp'd ones aren't paying. */
export function premiumRevenueEstimate(users: UserProfile[]): number {
  const payingCount = users.filter(
    (u) =>
      u.role === "user" &&
      !u.deleted &&
      u.subscription.tier === "premium" &&
      u.subscription.status === "active" &&
      !hasAdminGrantedPremium(u)
  ).length;
  return Math.round(payingCount * SYNTHETIC_MONTHLY_PRICE_GBP * 100) / 100;
}

// --- Connected apps ---------------------------------------------------------------

// `IntegrationConnection["provider"]` is really the full `DataSource` union
// (it also covers strolla_app/strolla_device/manual, which aren't "connected
// apps" in the client's sense) — this is the narrower slice of it we render.
export type ConnectedAppProvider = "healthkit" | "health_connect" | "oura" | "garmin" | "strava";

export const CONNECTED_APP_LABEL: Record<ConnectedAppProvider, string> = {
  healthkit: "Apple Health",
  health_connect: "Health Connect",
  oura: "Oura",
  garmin: "Garmin",
  strava: "Strava",
};

const CONNECTED_APP_PROVIDERS = Object.keys(CONNECTED_APP_LABEL) as ConnectedAppProvider[];

/** Distinct users currently connected, per provider — same {stage, count}
 * shape FunnelChart already renders, so this reuses it directly. */
export function connectedAppsBreakdown(connections: IntegrationConnection[]): { stage: string; count: number }[] {
  return CONNECTED_APP_PROVIDERS.map((provider) => ({
    stage: CONNECTED_APP_LABEL[provider],
    count: new Set(connections.filter((c) => c.provider === provider && c.status === "connected").map((c) => c.user_id)).size,
  })).sort((a, b) => b.count - a.count);
}

// --- Extra analytics charts -------------------------------------------------------

/** Raw event count per day for a single event type — the right semantic for
 * "workout starts", "shares", "health app connections" trend charts, unlike
 * `dailyActiveUsers`'s distinct-user counting. */
export function eventCountsPerDay(events: AnalyticsEvent[], type: AnalyticsEventType, days = 30): { date: string; count: number }[] {
  const byDay = new Map<string, number>();
  for (const e of events) {
    if (e.event_type !== type) continue;
    const key = startOfDayKey(e.created_at);
    byDay.set(key, (byDay.get(key) ?? 0) + 1);
  }
  return Array.from(byDay.entries())
    .map(([date, count]) => ({ date, count }))
    .sort((a, b) => +new Date(a.date) - +new Date(b.date))
    .slice(-days);
}

/** Real post timestamps, not synthetic events — more accurate than deriving
 * this from `community_post_created` analytics events since the posts
 * themselves are the source of truth. */
export function postsPerDay(posts: CommunityPost[], days = 30): { date: string; count: number }[] {
  const byDay = new Map<string, number>();
  for (const p of posts) {
    const key = startOfDayKey(p.timestamp);
    byDay.set(key, (byDay.get(key) ?? 0) + 1);
  }
  return Array.from(byDay.entries())
    .map(([date, count]) => ({ date, count }))
    .sort((a, b) => +new Date(a.date) - +new Date(b.date))
    .slice(-days);
}

/** Same {stage, count} shape FunnelChart renders — a simple ranked bar
 * breakdown of which core actions are actually being used. */
export function featureUsageBreakdown(events: AnalyticsEvent[], sinceDays = 30): { stage: string; count: number }[] {
  const counts = eventCounts(events, sinceDays);
  return [
    { stage: "Workouts started", count: counts.workout_started ?? 0 },
    { stage: "Community posts", count: counts.community_post_created ?? 0 },
    { stage: "Challenges joined", count: counts.challenge_joined ?? 0 },
    { stage: "Steps shared", count: counts.steps_shared ?? 0 },
    { stage: "Widgets enabled", count: counts.widget_enabled ?? 0 },
    { stage: "Health app connected", count: counts.health_app_connected ?? 0 },
  ].sort((a, b) => b.count - a.count);
}

/** Average recorded steps per day across whichever users have daily-summary
 * history in the mock dataset — real arithmetic, just over a small sample
 * (only a handful of seeded users have 30 days of history), not the full
 * user base. */
export function avgDailyStepsPerDay(summaries: DailyActivitySummary[], days = 30): { date: string; count: number }[] {
  const byDay = new Map<string, number[]>();
  for (const s of summaries) {
    const key = s.date.slice(0, 10);
    if (!byDay.has(key)) byDay.set(key, []);
    byDay.get(key)!.push(s.steps);
  }
  return Array.from(byDay.entries())
    .map(([date, values]) => ({ date, count: Math.round(values.reduce((a, b) => a + b, 0) / values.length) }))
    .sort((a, b) => +new Date(a.date) - +new Date(b.date))
    .slice(-days);
}

export interface RetentionPoint {
  offsetDays: number;
  pct: number;
  // Cohort size this point is actually based on — small samples (common at
  // wider offsets, since only users who signed up early enough to have
  // reached that offset within the observed event window qualify) are
  // flagged in the UI rather than presented as a confident percentage.
  eligible: number;
}

/**
 * % of users who opened the app again `offsetDays` after signing up.
 * Restricted to users whose signup+offset actually falls inside the
 * observed event window — the mock event log only covers ~30 days, so
 * checking a date outside that range would silently read as churn rather
 * than "no data either way".
 */
export function retentionCurve(users: UserProfile[], events: AnalyticsEvent[]): RetentionPoint[] {
  const offsets = [0, 1, 3, 7, 14, 30];
  if (events.length === 0) return offsets.map((offsetDays) => ({ offsetDays, pct: 0, eligible: 0 }));

  const opensByUser = new Map<string, Set<string>>();
  let minTs = Infinity;
  let maxTs = -Infinity;
  for (const e of events) {
    const ts = +new Date(e.created_at);
    if (ts < minTs) minTs = ts;
    if (ts > maxTs) maxTs = ts;
    if (e.event_type !== "app_opened" || !e.user_id) continue;
    if (!opensByUser.has(e.user_id)) opensByUser.set(e.user_id, new Set());
    opensByUser.get(e.user_id)!.add(startOfDayKey(e.created_at));
  }

  const cohort = users.filter((u) => u.role === "user" && !u.deleted);
  return offsets.map((offsetDays) => {
    let eligible = 0;
    let retained = 0;
    for (const u of cohort) {
      const checkTs = +new Date(u.created_at) + offsetDays * 86_400_000;
      if (checkTs < minTs || checkTs > maxTs) continue;
      eligible++;
      const key = startOfDayKey(new Date(checkTs).toISOString());
      if (opensByUser.get(u.id)?.has(key)) retained++;
    }
    return { offsetDays, pct: eligible > 0 ? Math.round((retained / eligible) * 100) : 0, eligible };
  });
}
