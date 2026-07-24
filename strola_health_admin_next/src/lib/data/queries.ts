import type {
  AccountDeletionRequest,
  AnalyticsEvent,
  AnalyticsEventType,
  Announcement,
  AnnouncementAudience,
  Badge,
  Challenge,
  ChallengeParticipant,
  CommunityComment,
  CommunityPost,
  DailyActivitySummary,
  Device,
  FirmwareUpdateFailure,
  IntegrationConnection,
  LegalAcceptance,
  LegalDocumentType,
  LegalDocumentVersion,
  PushLinkTarget,
  PushNotification,
  PushSegment,
  Report,
  ReportTargetType,
  SupportTicket,
  UserBadge,
  UserProfile,
  WorkoutSession,
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
// A fixed far-future date, not `null` — `hasAdminGrantedPremium` and every
// "is this still active" check requires `comp_until` to be a real future
// date, so "forever" is modeled as one rather than changing that contract.
export const LIFETIME_ISO = "2099-12-31T00:00:00.000Z";

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

// --- Grouped reports (Moderation) ----------------------------------------------

export interface GroupedReport {
  targetType: ReportTargetType;
  targetId: string;
  // The account this group is actually about — the reported user directly,
  // or a reported post's author. Undefined only if that user's profile
  // couldn't be resolved (e.g. deleted).
  targetUser: UserProfile | undefined;
  targetPost: EnrichedPost | undefined;
  reports: EnrichedReport[];
  reporterCount: number;
  hasOpen: boolean;
  latestReportAt: string;
}

/** One card per reported thing (post or user), not one per report — a post
 * reported by 5 people should read as "reported by 5 users" with each of
 * their reasons listed, not as 5 separate rows. */
export function groupReportsByTarget(reports: EnrichedReport[]): GroupedReport[] {
  const groups = new Map<string, EnrichedReport[]>();
  for (const r of reports) {
    const key = `${r.target_type}:${r.target_id}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(r);
  }
  return Array.from(groups.values())
    .map((group) => {
      const sorted = [...group].sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at));
      const first = sorted[0];
      return {
        targetType: first.target_type,
        targetId: first.target_id,
        targetUser: first.target_type === "user" ? first.targetUser : first.targetPost?.author,
        targetPost: first.targetPost,
        reports: sorted,
        reporterCount: new Set(group.map((r) => r.reporter_id)).size,
        hasOpen: group.some((r) => r.status === "open"),
        latestReportAt: first.created_at,
      };
    })
    .sort((a, b) => +new Date(b.latestReportAt) - +new Date(a.latestReportAt));
}

// --- Reported-user moderation history --------------------------------------------

export interface ModerationHistorySummary {
  joinedAt: string;
  warnings: number;
  postsRemoved: number;
  previousSuspensions: number;
  currentlySuspended: boolean;
}

/** Everything relevant to deciding what to do about a reported account —
 * derived from existing reports/posts data rather than a separate audit
 * log, since every disciplinary action already flows through a report's
 * `action_taken` or a post's `moderation` state. */
export function moderationHistoryForUser(data: { user: UserProfile; reports: Report[]; posts: CommunityPost[] }): ModerationHistorySummary {
  const aboutThisUser = data.reports.filter(
    (r) =>
      (r.target_type === "user" && r.target_id === data.user.id) ||
      (r.target_type === "post" && data.posts.find((p) => p.id === r.target_id)?.author_id === data.user.id)
  );
  return {
    joinedAt: data.user.created_at,
    warnings: aboutThisUser.filter((r) => r.action_taken === "warned").length,
    postsRemoved: data.posts.filter((p) => p.author_id === data.user.id && p.moderation.hidden).length,
    previousSuspensions: aboutThisUser.filter((r) => r.action_taken === "banned").length,
    currentlySuspended: data.user.banned,
  };
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

// --- Users list & profile -----------------------------------------------------

/** Most recent app_opened event per user — the list view's "Last active"
 * column and the "Inactive users" filter both read from this. */
export function lastActiveMap(events: AnalyticsEvent[]): Map<string, string> {
  const map = new Map<string, string>();
  for (const e of events) {
    if (e.event_type !== "app_opened" || !e.user_id) continue;
    const prev = map.get(e.user_id);
    if (!prev || e.created_at > prev) map.set(e.user_id, e.created_at);
  }
  return map;
}

export type TrackerStatus = "connected" | "never_paired" | "offline";

export const TRACKER_STATUS_LABEL: Record<TrackerStatus, string> = {
  connected: "Connected",
  never_paired: "Never paired",
  offline: "Offline",
};

const TRACKER_OFFLINE_THRESHOLD_MS = 48 * 60 * 60 * 1000;

/** "Connected" needs a device that's checked in recently, "never paired"
 * means no device has ever been assigned to them, and anything paired but
 * stale in between is "offline". Anchored to the latest last_seen_at across
 * all devices, not Date.now() — same frozen-mock-timeline reasoning as the
 * analytics query helpers above. */
export function trackerStatusForUser(userId: string, devices: Device[]): TrackerStatus {
  const owned = devices.filter((d) => d.owner_user_id === userId);
  if (owned.length === 0) return "never_paired";
  const latestSeenOverall = devices.reduce((max, d) => (d.last_seen_at ? Math.max(max, +new Date(d.last_seen_at)) : max), 0);
  const mostRecentOwnSeen = owned.reduce((max, d) => (d.last_seen_at ? Math.max(max, +new Date(d.last_seen_at)) : max), 0);
  if (mostRecentOwnSeen === 0) return "offline";
  return latestSeenOverall - mostRecentOwnSeen <= TRACKER_OFFLINE_THRESHOLD_MS ? "connected" : "offline";
}

export interface LifetimeStats {
  lifetimeSteps: number;
  currentStreak: number;
  longestStreak: number;
  challengesCompleted: number;
  achievementsEarned: number;
}

/** Streaks are "consecutive days hitting their daily step goal", not just
 * "any steps recorded" — otherwise every user with any history would show a
 * maxed-out streak given how the mock daily-history generator works. */
export function lifetimeStats(data: {
  dailySummaries: DailyActivitySummary[];
  dailyGoalSteps: number;
  participations: ChallengeParticipant[];
  challenges: Challenge[];
  achievementsEarned: number;
}): LifetimeStats {
  const sorted = [...data.dailySummaries].sort((a, b) => a.date.localeCompare(b.date));
  const lifetimeSteps = sorted.reduce((sum, d) => sum + d.steps, 0);

  let longestStreak = 0;
  let running = 0;
  for (const d of sorted) {
    if (d.steps >= data.dailyGoalSteps) {
      running += 1;
      longestStreak = Math.max(longestStreak, running);
    } else {
      running = 0;
    }
  }
  let currentStreak = 0;
  for (let i = sorted.length - 1; i >= 0; i--) {
    if (sorted[i].steps >= data.dailyGoalSteps) currentStreak += 1;
    else break;
  }

  const challengesCompleted = data.participations.filter((p) => {
    const challenge = data.challenges.find((c) => c.id === p.challenge_id);
    return !!challenge && challengeStatus(challenge) === "ended" && !p.left_at;
  }).length;

  return { lifetimeSteps, currentStreak, longestStreak, challengesCompleted, achievementsEarned: data.achievementsEarned };
}

/** Reports where this user is the one being reported on — not reports they
 * filed themselves. */
export function reportsAboutUser(userId: string, reports: Report[]): Report[] {
  return reports
    .filter((r) => r.target_type === "user" && r.target_id === userId)
    .sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at));
}

export interface TimelineEvent {
  id: string;
  date: string;
  label: string;
}

/** A single chronological feed of everything notable that's happened on
 * this account — joined, paired a tracker, started Premium, challenge
 * joins, achievements won, support tickets filed. */
export function accountTimeline(data: {
  user: UserProfile;
  devices: Device[];
  participations: EnrichedParticipant[];
  challenges: Challenge[];
  badges: EnrichedAward[];
  tickets: SupportTicket[];
}): TimelineEvent[] {
  const events: TimelineEvent[] = [{ id: `${data.user.id}_joined`, date: data.user.created_at, label: "Joined" }];

  for (const d of data.devices) {
    if (d.paired_at) events.push({ id: `${d.id}_paired`, date: d.paired_at, label: "Paired tracker" });
  }
  if (data.user.subscription.started_at) {
    const label = data.user.subscription.status === "trialing" ? "Started free trial" : "Started Premium";
    events.push({ id: `${data.user.id}_premium_started`, date: data.user.subscription.started_at, label });
  }
  for (const p of data.participations) {
    const challenge = data.challenges.find((c) => c.id === p.challenge_id);
    events.push({ id: `${p.id}_joined`, date: p.joined_at, label: `Joined challenge "${challenge?.title ?? p.challenge_id}"` });
  }
  for (const b of data.badges) {
    events.push({ id: `${b.id}_awarded`, date: b.awarded_at, label: `Won achievement "${b.badge?.name ?? b.badge_id}"` });
  }
  for (const t of data.tickets) {
    events.push({ id: `${t.id}_ticket`, date: t.created_at, label: `Reported issue: ${t.subject}` });
  }

  return events.sort((a, b) => +new Date(a.date) - +new Date(b.date));
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
  // Anchored to the latest event actually present, not Date.now() — the
  // mock event set is a frozen timeline (see mock-data.ts's `NOW`), so a
  // wall-clock cutoff drifts further from it every day this demo runs.
  const latest = events.reduce((max, e) => Math.max(max, +new Date(e.created_at)), 0);
  const cutoff = latest - sinceDays * 86_400_000;
  const counts = {} as Record<AnalyticsEventType, number>;
  for (const e of events) {
    if (+new Date(e.created_at) < cutoff) continue;
    counts[e.event_type] = (counts[e.event_type] ?? 0) + 1;
  }
  return counts;
}

/** { date, count } for every day in `events` between `startDate` and
 * `endDate` (inclusive, "YYYY-MM-DD") — the custom-range counterpart to
 * `dailyActiveUsers`'s last-N-days window. */
export function dailyActiveUsersInRange(
  events: AnalyticsEvent[],
  startDate: string,
  endDate: string
): { date: string; count: number }[] {
  const byDay = new Map<string, Set<string>>();
  for (const e of events) {
    if (e.event_type !== "app_opened" || !e.user_id) continue;
    const key = startOfDayKey(e.created_at);
    if (key < startDate || key > endDate) continue;
    if (!byDay.has(key)) byDay.set(key, new Set());
    byDay.get(key)!.add(e.user_id);
  }
  return Array.from(byDay.entries())
    .map(([date, users]) => ({ date, count: users.size }))
    .sort((a, b) => +new Date(a.date) - +new Date(b.date));
}

/** % change in total (non-deleted) user count vs `days` days ago, anchored
 * on the dataset's own timeline (same reasoning as `newSignupsCount`). Null
 * when there's no prior-period baseline to compare against. */
export function userGrowthPct(users: UserProfile[], days: number): number | null {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return null;
  const latest = Math.max(...real.map((u) => +new Date(u.created_at)));
  const cutoff = latest - days * 86_400_000;
  const previousTotal = real.filter((u) => +new Date(u.created_at) < cutoff).length;
  if (previousTotal === 0) return null;
  return ((real.length - previousTotal) / previousTotal) * 100;
}

/** % change in new-signup count over the most recent `days`-day window vs
 * the `days`-day window immediately before it. Null when the prior window
 * had zero signups (percentage change is undefined). */
export function signupGrowthPct(users: UserProfile[], days = 7): number | null {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return null;
  const latest = Math.max(...real.map((u) => +new Date(u.created_at)));
  const currentCutoff = latest - days * 86_400_000;
  const previousCutoff = latest - days * 2 * 86_400_000;
  const current = real.filter((u) => +new Date(u.created_at) >= currentCutoff).length;
  const previous = real.filter(
    (u) => +new Date(u.created_at) >= previousCutoff && +new Date(u.created_at) < currentCutoff
  ).length;
  if (previous === 0) return null;
  return ((current - previous) / previous) * 100;
}

/** New premium starts vs cancellations in the most recent 30-day window
 * present in `events` — the flow behind the MRR number, not just its level. */
export function premiumMonthlyFlow(events: AnalyticsEvent[]) {
  const counts = eventCounts(events, 30);
  return {
    newSubscriptions: counts.premium_started ?? 0,
    cancellations: counts.premium_cancelled ?? 0,
  };
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

export function overviewTotals(
  data: {
    users: UserProfile[];
    reports: Report[];
    posts: CommunityPost[];
    challenges: Challenge[];
    devices: Device[];
    events: AnalyticsEvent[];
  },
  monthlyPriceGbp: number
) {
  const users = data.users.filter((u) => u.role === "user" && !u.deleted);
  const dau = dailyActiveUsers(data.events, 1);
  const openReports = data.reports.filter((r) => r.status === "open").length;
  // Includes private challenges — visibility doesn't affect whether a
  // challenge is currently running, only who can see/join it.
  const activeChallenges = data.challenges.filter((c) => challengeStatus(c) === "active").length;
  const pairedDevices = data.devices.filter((d) => d.owner_user_id).length;
  const premiumSubscribers = users.filter((u) => u.subscription.tier === "premium" && u.subscription.status === "active").length;
  const premiumFlow = premiumMonthlyFlow(data.events);
  return {
    totalUsers: users.length,
    totalUsersGrowthPct: userGrowthPct(users, 30),
    dauToday: dau.at(-1)?.count ?? 0,
    activeThisWeek: activeUsersInWindow(data.events, 7),
    activeThisMonth: activeUsersInWindow(data.events, 30),
    newSignups7d: newSignupsCount(users, 7),
    newSignupsGrowthPct: signupGrowthPct(users, 7),
    postsToday: postsToday(data.posts),
    openReports,
    activeChallenges,
    pairedDevices,
    totalDevices: data.devices.length,
    premiumSubscribers,
    mrr: premiumRevenueEstimate(users, monthlyPriceGbp),
    newPremiumThisMonth: premiumFlow.newSubscriptions,
    cancelledPremiumThisMonth: premiumFlow.cancellations,
  };
}

// --- Needs attention (Overview dashboard) ------------------------------------

export type NeedsAttentionCategory = "report" | "support_ticket" | "firmware_failure" | "deletion_request";

export interface NeedsAttentionItem {
  id: string;
  category: NeedsAttentionCategory;
  title: string;
  timestamp: string;
  // Where clicking the row should go — null when there's no dedicated page
  // to land on yet (e.g. support tickets have no admin page of their own).
  href: string | null;
}

export const NEEDS_ATTENTION_LABEL: Record<NeedsAttentionCategory, string> = {
  report: "Report",
  support_ticket: "Support ticket",
  firmware_failure: "Firmware update failed",
  deletion_request: "Deletion request",
};

/** Merges the four "needs attention" sources into one recency-sorted list —
 * open reports, open support tickets, unresolved firmware update failures,
 * and pending account deletion requests. */
export function needsAttentionItems(data: {
  reports: Report[];
  tickets: SupportTicket[];
  firmwareFailures: FirmwareUpdateFailure[];
  deletionRequests: AccountDeletionRequest[];
  devices: Device[];
}): NeedsAttentionItem[] {
  const items: NeedsAttentionItem[] = [];

  for (const r of data.reports) {
    if (r.status !== "open") continue;
    items.push({ id: r.id, category: "report", title: r.reason, timestamp: r.created_at, href: "/moderation" });
  }
  for (const t of data.tickets) {
    if (t.status !== "open") continue;
    items.push({
      id: t.id,
      category: "support_ticket",
      title: t.subject,
      timestamp: t.created_at,
      href: t.user_id ? `/users/${t.user_id}` : null,
    });
  }
  for (const f of data.firmwareFailures) {
    if (f.resolved) continue;
    const device = data.devices.find((d) => d.id === f.device_id);
    items.push({
      id: f.id,
      category: "firmware_failure",
      title: `${device?.serial_number ?? f.device_id} — ${f.error}`,
      timestamp: f.occurred_at,
      href: device?.owner_user_id ? `/users/${device.owner_user_id}` : null,
    });
  }
  for (const d of data.deletionRequests) {
    if (d.status !== "pending") continue;
    items.push({
      id: d.id,
      category: "deletion_request",
      title: d.reason ?? "Account deletion requested",
      timestamp: d.requested_at,
      href: `/users/${d.user_id}`,
    });
  }

  return items.sort((a, b) => +new Date(b.timestamp) - +new Date(a.timestamp));
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
 * on the notification once sent.
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
      return realUsers.filter((u) => u.country === "Canada").map((u) => u.id);
    case "usa":
      return realUsers.filter((u) => u.country === "United States").map((u) => u.id);
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

export const PUSH_LINK_TARGET_LABEL: Record<PushLinkTarget, string> = {
  none: "No link",
  challenge: "A challenge",
  community: "Community",
  stats: "Stats",
  profile: "Profile",
  premium: "Premium",
  custom: "Custom screen",
};

/** Short chip text for a notification's link destination, e.g. "10K Daily Streak" for a challenge link, "/settings/units" for a custom one. */
export function pushLinkDescription(
  n: Pick<PushNotification, "link_target" | "link_challenge_id" | "link_custom_path">,
  challenges: Challenge[]
): string | null {
  switch (n.link_target) {
    case "none":
      return null;
    case "challenge":
      return challenges.find((c) => c.id === n.link_challenge_id)?.title ?? "Challenge (deleted)";
    case "custom":
      return n.link_custom_path || null;
    default:
      return PUSH_LINK_TARGET_LABEL[n.link_target];
  }
}

/** Click-through rate as a 0-100 percentage of *delivered* devices that opened the notification — null before it's been sent. */
export function pushCTR(n: Pick<PushNotification, "status" | "delivered_count" | "opened_count">): number | null {
  if (n.status !== "sent" || n.delivered_count === 0) return null;
  return (n.opened_count / n.delivered_count) * 100;
}

// --- Premium overview -----------------------------------------------------------

/** Synthetic MRR — real paying subscribers only, comp'd ones aren't paying.
 * `monthlyPriceGbp` comes from `AppSettings.premium_monthly_price_gbp`
 * (Settings > App settings > Premium) — there's no real RevenueCat price
 * data in this mock set, so this is illustrative, not a real revenue
 * figure, but it does reflect whatever price is actually configured. */
export function premiumRevenueEstimate(users: UserProfile[], monthlyPriceGbp: number): number {
  const payingCount = users.filter(
    (u) =>
      u.role === "user" &&
      !u.deleted &&
      u.subscription.tier === "premium" &&
      u.subscription.status === "active" &&
      !hasAdminGrantedPremium(u)
  ).length;
  return Math.round(payingCount * monthlyPriceGbp * 100) / 100;
}

export type SubscriptionSegment = "paying" | "comp" | "trial" | "free";

/** Which of the four subscription segments a user is in — the single
 * classification every filter/stat on the Subscriptions page reads from,
 * so "paying" vs "comp" vs "trial" is never redefined slightly differently
 * in two places. */
export function classifySubscription(user: UserProfile): SubscriptionSegment {
  // Mirrors the backend's `Subscription.has_premium_access`: comp access is
  // an independent OR path, not something layered on top of tier/status —
  // a comp grant doesn't (and per the backend's own `revoke_comp` comment,
  // must not) touch tier/status, so it has to be checked first, regardless
  // of whatever tier/status this user happened to already be on.
  if (hasAdminGrantedPremium(user)) return "comp";
  if (user.subscription.status === "trialing") return "trial";
  if (user.subscription.tier === "premium" && user.subscription.status === "active") return "paying";
  return "free";
}

export interface SubscriptionOverviewStats {
  activePremium: number;
  mrr: number;
  trialUsers: number;
  freeUsers: number;
  // % of users whose trial has run its course who ended up paying — not a
  // true cohort conversion rate (the data doesn't retain "was trialing on
  // date X"), just paying ÷ (paying + lapsed-without-converting). Currently
  // trialing users are excluded since they haven't had a chance to convert
  // or lapse yet. Illustrative, like the synthetic MRR price above.
  conversionRatePct: number | null;
  // Cancellations in the most recent 30-day window as a % of the current
  // paying base — a monthly logo-churn proxy, not a cohort-tracked figure.
  churnRatePct: number | null;
}

export function subscriptionOverviewStats(users: UserProfile[], events: AnalyticsEvent[], monthlyPriceGbp: number): SubscriptionOverviewStats {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  const segments = new Map(real.map((u) => [u.id, classifySubscription(u)] as const));

  const payingCount = real.filter((u) => segments.get(u.id) === "paying").length;
  const compCount = real.filter((u) => segments.get(u.id) === "comp").length;
  const trialCount = real.filter((u) => segments.get(u.id) === "trial").length;
  const freeCount = real.filter((u) => segments.get(u.id) === "free").length;
  const lapsedCount = real.filter((u) => segments.get(u.id) === "free" && u.subscription.status === "expired").length;

  const flow = premiumMonthlyFlow(events);

  return {
    activePremium: payingCount + compCount,
    mrr: premiumRevenueEstimate(users, monthlyPriceGbp),
    trialUsers: trialCount,
    freeUsers: freeCount,
    conversionRatePct: payingCount + lapsedCount > 0 ? (payingCount / (payingCount + lapsedCount)) * 100 : null,
    churnRatePct: payingCount + flow.cancellations > 0 ? (flow.cancellations / (payingCount + flow.cancellations)) * 100 : null,
  };
}

export interface SubscriptionHistoryEntry {
  id: string;
  date: string;
  label: string;
}

/** Best-effort subscription timeline for one user — there's no persisted
 * log of past grants (a new grant just overwrites `comp_until`/`comp_reason`),
 * so this combines whatever the current state and `premium_started`/
 * `premium_cancelled` analytics events for this user can reconstruct. */
export function subscriptionHistoryForUser(user: UserProfile, events: AnalyticsEvent[]): SubscriptionHistoryEntry[] {
  const entries: SubscriptionHistoryEntry[] = [];
  const segment = classifySubscription(user);

  for (const e of events) {
    if (e.user_id !== user.id) continue;
    if (e.event_type === "premium_started") entries.push({ id: `${e.id}`, date: e.created_at, label: "Premium started (RevenueCat)" });
    if (e.event_type === "premium_cancelled") entries.push({ id: `${e.id}`, date: e.created_at, label: "Premium cancelled (RevenueCat)" });
  }

  if (user.subscription.started_at) {
    const label =
      segment === "trial"
        ? "Free trial started"
        : segment === "comp"
          ? `Comp access granted${user.subscription.comp_reason ? ` — ${user.subscription.comp_reason}` : ""}`
          : "Premium started";
    entries.push({ id: `${user.id}_started`, date: user.subscription.started_at, label });
  }
  if (user.subscription.cancelled_at) {
    entries.push({ id: `${user.id}_cancelled`, date: user.subscription.cancelled_at, label: "Subscription cancelled" });
  }

  return entries.sort((a, b) => +new Date(b.date) - +new Date(a.date));
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

// --- Announcement audiences -------------------------------------------------

export const ANNOUNCEMENT_AUDIENCE_LABEL: Record<AnnouncementAudience, string> = {
  everyone: "Everyone",
  free: "Free users",
  premium: "Premium users",
  new_users: "New users (joined this week)",
  beta_testers: "Beta testers",
  kickstarter_backers: "Kickstarter backers",
  iphone: "iPhone",
  android: "Android",
  canada: "Canada",
  usa: "USA",
  app_version: "App version",
};

function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const diff = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

/** Data-relative "now" (freshest real user signup) rather than the real wall
 * clock — same reasoning as `activeUserIdsInWindow`: the mock dataset is
 * anchored to a frozen `NOW` in mock-data.ts, so `Date.now()` would silently
 * drift "new users"/reach calculations toward zero as real time moves past
 * that anchor. */
function mockNow(users: UserProfile[]): number {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return Date.now();
  return Math.max(...real.map((u) => +new Date(u.created_at)));
}

/** Who an announcement's audience actually resolves to right now — same role as `segmentAudienceIds` for push segments. */
export function announcementAudienceIds(
  announcement: Pick<Announcement, "audience" | "audience_app_version" | "audience_app_version_mode">,
  users: UserProfile[]
): string[] {
  const realUsers = users.filter((u) => u.role === "user" && !u.deleted);
  const isPremium = (u: UserProfile) => u.subscription.tier === "premium" && u.subscription.status === "active";
  const now = mockNow(users);

  switch (announcement.audience) {
    case "everyone":
      return realUsers.map((u) => u.id);
    case "free":
      return realUsers.filter((u) => !isPremium(u)).map((u) => u.id);
    case "premium":
      return realUsers.filter(isPremium).map((u) => u.id);
    case "new_users":
      return realUsers.filter((u) => now - +new Date(u.created_at) <= 7 * 86_400_000).map((u) => u.id);
    case "beta_testers":
      return realUsers.filter((u) => u.tags.includes("beta_tester")).map((u) => u.id);
    case "kickstarter_backers":
      return realUsers.filter((u) => u.tags.includes("kickstarter")).map((u) => u.id);
    case "iphone":
      return realUsers.filter((u) => u.platform === "ios").map((u) => u.id);
    case "android":
      return realUsers.filter((u) => u.platform === "android").map((u) => u.id);
    case "canada":
      return realUsers.filter((u) => u.country === "Canada").map((u) => u.id);
    case "usa":
      return realUsers.filter((u) => u.country === "United States").map((u) => u.id);
    case "app_version": {
      const version = announcement.audience_app_version;
      if (!version) return [];
      const mode = announcement.audience_app_version_mode ?? "exact";
      return realUsers
        .filter((u) => (mode === "exact" ? u.app_version === version : compareVersions(u.app_version, version) <= 0))
        .map((u) => u.id);
    }
  }
}

/** "App version ≤ 2.2.0" for a version-targeted announcement, otherwise the plain audience label. */
export function announcementAudienceLabel(
  announcement: Pick<Announcement, "audience" | "audience_app_version" | "audience_app_version_mode">
): string {
  if (announcement.audience === "app_version" && announcement.audience_app_version) {
    const op = announcement.audience_app_version_mode === "exact" ? "=" : "≤";
    return `App version ${op} ${announcement.audience_app_version}`;
  }
  return ANNOUNCEMENT_AUDIENCE_LABEL[announcement.audience];
}

// Deterministic 0..1 fraction from a string (FNV-1a hash) — stable across
// re-renders (unlike Math.random) while still looking varied per announcement.
function seededFraction(seed: string): number {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return ((h >>> 0) % 10_000) / 10_000;
}

export interface AnnouncementStats {
  audience: number;
  seen: number;
  dismissed: number;
  clicked: number;
  seenRate: number | null;
  dismissRate: number | null;
  ctr: number | null;
}

/**
 * No real impression/dismiss/click pipeline is wired in yet. Reach grows
 * with how long the announcement has been active — a banner is only seen as
 * users open the app, so a same-day announcement has seen fewer people than
 * one that's been live a week — and dismiss/click fractions are deterministic
 * per announcement id (stable across renders, still reads as varied) rather
 * than measurements of anything real.
 */
export function announcementStats(announcement: Announcement, users: UserProfile[]): AnnouncementStats {
  const audience = announcementAudienceIds(announcement, users).length;
  const now = mockNow(users);
  const startMs = +new Date(announcement.starts_at);
  const endMs = announcement.ends_at ? +new Date(announcement.ends_at) : now;
  const daysActive = Math.max(0, Math.min(now, endMs) - startMs) / 86_400_000;
  const reachFraction = startMs > now ? 0 : Math.min(0.94, 0.3 + daysActive * 0.13);
  const seen = Math.round(audience * reachFraction);

  const dismissFraction = 0.25 + seededFraction(`${announcement.id}:dismiss`) * 0.3;
  const dismissed = Math.round(seen * dismissFraction);

  const hasLink = !!announcement.link_target;
  const clickFraction = 0.12 + seededFraction(`${announcement.id}:click`) * 0.28;
  const clicked = hasLink ? Math.round((seen - dismissed) * clickFraction) : 0;

  return {
    audience,
    seen,
    dismissed,
    clicked,
    seenRate: audience > 0 ? (seen / audience) * 100 : null,
    dismissRate: seen > 0 ? (dismissed / seen) * 100 : null,
    ctr: hasLink && seen > 0 ? (clicked / seen) * 100 : null,
  };
}

// --- Extended engagement analytics -----------------------------------------------

/** New signups per day — same {date,count} shape as `postsPerDay`/`eventCountsPerDay`, for a "New Users" trend chart distinct from cumulative DAU. */
export function newSignupsPerDay(users: UserProfile[], days = 30): { date: string; count: number }[] {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  const byDay = new Map<string, number>();
  for (const u of real) {
    const key = startOfDayKey(u.created_at);
    byDay.set(key, (byDay.get(key) ?? 0) + 1);
  }
  return Array.from(byDay.entries())
    .map(([date, count]) => ({ date, count }))
    .sort((a, b) => +new Date(a.date) - +new Date(b.date))
    .slice(-days);
}

/** Users active "today" (the most recent day present in the event log) who
 * didn't sign up that same day — i.e. actually came back, rather than
 * opening the app for the first time ever. */
export function returningUsersToday(users: UserProfile[], events: AnalyticsEvent[]): number {
  const opens = events.filter((e) => e.event_type === "app_opened" && e.user_id);
  if (opens.length === 0) return 0;
  const latestDay = opens.reduce((max, e) => (e.created_at > max ? e.created_at : max), opens[0].created_at).slice(0, 10);
  const todayOpeners = new Set(opens.filter((e) => e.created_at.slice(0, 10) === latestDay).map((e) => e.user_id!));
  const signupsToday = new Set(users.filter((u) => u.created_at.slice(0, 10) === latestDay).map((u) => u.id));
  let returning = 0;
  for (const id of todayOpeners) if (!signupsToday.has(id)) returning++;
  return returning;
}

export interface ChallengeParticipationStat {
  title: string;
  joined: number;
  activeUserPct: number | null;
}

/** The current official/featured challenge's participation — joined count
 * and that as a % of the last-30-day active user base. Falls back to the
 * most recently started challenge if none is marked official. */
export function currentChallengeParticipation(
  challenges: Challenge[],
  participants: ChallengeParticipant[],
  events: AnalyticsEvent[]
): ChallengeParticipationStat | null {
  const current = challenges.find((c) => c.is_official) ?? [...challenges].sort((a, b) => +new Date(b.start_date) - +new Date(a.start_date))[0];
  if (!current) return null;
  const joined = participants.filter((p) => p.challenge_id === current.id && !p.left_at).length;
  const activeUsers = activeUsersInWindow(events, 30);
  return { title: current.title, joined, activeUserPct: activeUsers > 0 ? Math.round((joined / activeUsers) * 100) : null };
}

/** Mean workout duration across every recorded session in the mock dataset
 * — small sample (only featured users have session history), same caveat
 * as `avgDailyStepsPerDay`. Seconds; format with `formatDuration`. */
export function averageSessionLength(sessions: WorkoutSession[]): number {
  if (sessions.length === 0) return 0;
  return Math.round(sessions.reduce((sum, s) => sum + s.duration_seconds, 0) / sessions.length);
}

const SCREEN_LABEL: Record<string, string> = {
  home: "Home",
  stats: "Stats",
  challenges: "Challenges",
  community: "Community",
  profile: "Profile",
};

/** Ranked screen-view counts — same {stage,count} shape as `featureUsageBreakdown`. */
export function screenViewBreakdown(events: AnalyticsEvent[], sinceDays = 30): { stage: string; count: number }[] {
  const latest = events.reduce((max, e) => Math.max(max, +new Date(e.created_at)), 0);
  const cutoff = latest - sinceDays * 86_400_000;
  const counts = new Map<string, number>();
  for (const e of events) {
    if (e.event_type !== "screen_viewed" || +new Date(e.created_at) < cutoff) continue;
    const screen = (e.metadata.screen as string) ?? "unknown";
    counts.set(screen, (counts.get(screen) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .map(([screen, count]) => ({ stage: SCREEN_LABEL[screen] ?? screen, count }))
    .sort((a, b) => b.count - a.count);
}

export interface FeatureAdoptionStat {
  feature: string;
  pct: number;
}

/** % of all real users who have EVER done each thing — distinct from
 * `featureUsageBreakdown`'s 30-day event volume, this is lifetime adoption. */
export function featureAdoptionRates(users: UserProfile[], events: AnalyticsEvent[]): FeatureAdoptionStat[] {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return [];
  const everDid = (type: AnalyticsEventType) => {
    const ids = new Set(events.filter((e) => e.event_type === type && e.user_id).map((e) => e.user_id));
    return real.filter((u) => ids.has(u.id)).length;
  };
  const rows: [string, number][] = [
    ["Community", everDid("community_post_created")],
    ["Challenges", everDid("challenge_joined")],
    ["Widgets", everDid("widget_enabled")],
    ["Health Connect", everDid("health_app_connected")],
    ["Sharing", everDid("steps_shared")],
  ];
  return rows.map(([feature, count]) => ({ feature, pct: Math.round((count / real.length) * 100) }));
}

export interface GoalCompletionRates {
  today: number | null;
  week: number | null;
  month: number | null;
}

/** % of (user, day) rows that met that user's own daily step goal, over
 * three trailing windows anchored to the most recent day present in the
 * summaries — not wall-clock "today", same frozen-mock-timeline reasoning
 * as everywhere else on this dashboard. */
export function goalCompletionRates(users: UserProfile[], summaries: DailyActivitySummary[]): GoalCompletionRates {
  if (summaries.length === 0) return { today: null, week: null, month: null };
  const goalByUser = new Map(users.map((u) => [u.id, u.daily_goal_steps] as const));
  const latestDate = summaries.reduce((max, s) => (s.date > max ? s.date : max), summaries[0].date);
  function rateForWindow(days: number): number | null {
    const cutoff = new Date(latestDate);
    cutoff.setUTCDate(cutoff.getUTCDate() - (days - 1));
    const cutoffKey = cutoff.toISOString().slice(0, 10);
    const rows = summaries.filter((s) => s.date >= cutoffKey && s.date <= latestDate);
    if (rows.length === 0) return null;
    const met = rows.filter((s) => s.steps >= (goalByUser.get(s.user_id) ?? Infinity)).length;
    return Math.round((met / rows.length) * 100);
  }
  return { today: rateForWindow(1), week: rateForWindow(7), month: rateForWindow(30) };
}

/** Each user's current consecutive-day streak (ending on the dataset's own
 * most recent day — a lapsed user's old streak doesn't count as current),
 * averaged across users who have any recorded activity. Derived from real
 * daily summaries, the same signal the app's own client-side streak counter
 * uses — there's no separately stored streak count anywhere server-side. */
export function averageStreak(summaries: DailyActivitySummary[]): number {
  if (summaries.length === 0) return 0;
  const byUser = new Map<string, Set<string>>();
  let latestDate = summaries[0].date;
  for (const s of summaries) {
    if (s.date > latestDate) latestDate = s.date;
    if (s.steps <= 0) continue;
    if (!byUser.has(s.user_id)) byUser.set(s.user_id, new Set());
    byUser.get(s.user_id)!.add(s.date);
  }
  const streaks: number[] = [];
  for (const [, days] of byUser) {
    if (!days.has(latestDate)) continue; // lapsed — not a *current* streak
    let streak = 0;
    const cursor = new Date(latestDate);
    while (days.has(cursor.toISOString().slice(0, 10))) {
      streak++;
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }
    streaks.push(streak);
  }
  if (streaks.length === 0) return 0;
  return Math.round((streaks.reduce((a, b) => a + b, 0) / streaks.length) * 10) / 10;
}

export interface CommunityHealthStats {
  posts: number;
  comments: number;
  likes: number;
}

/** Totals over the trailing `days` window, anchored to the latest post
 * timestamp present. Likes aren't individually timestamped in this data
 * model (no per-like log, just a running `likes_count` on the post), so
 * "likes" here sums that count across posts *created* in the window — a
 * reasonable proxy for engagement generated by recent content. There's no
 * "New Friends" figure alongside these: no friend/follow relationship
 * exists anywhere in the data model to count (see `AnalyticsView` for the
 * explicit "not tracked" state shown instead of a fabricated number). */
export function communityHealthStats(posts: CommunityPost[], comments: CommunityComment[], days = 30): CommunityHealthStats {
  if (posts.length === 0) return { posts: 0, comments: 0, likes: 0 };
  const latest = posts.reduce((max, p) => (p.timestamp > max ? p.timestamp : max), posts[0].timestamp);
  const cutoff = +new Date(latest) - days * 86_400_000;
  const recentPosts = posts.filter((p) => +new Date(p.timestamp) >= cutoff);
  const recentComments = comments.filter((c) => +new Date(c.timestamp) >= cutoff);
  return {
    posts: recentPosts.length,
    comments: recentComments.length,
    likes: recentPosts.reduce((sum, p) => sum + p.likes_count, 0),
  };
}

export interface PremiumAnalyticsStats {
  conversionRatePct: number | null;
  churnRatePct: number | null;
  renewalRatePct: number | null;
  ltv: number;
  arpu: number;
}

/** Extends `subscriptionOverviewStats` with the SaaS-standard trio, all
 * built from the same synthetic price (see `SYNTHETIC_MONTHLY_PRICE_GBP`):
 * renewal rate is churn's complement, LTV uses the standard
 * ARPU ÷ monthly-churn-rate approximation (falls back to a flat 12-month
 * estimate when churn is 0/unknown, to avoid dividing by zero). All
 * illustrative, not real revenue figures — same caveat as the MRR estimate
 * they're built on. */
export function premiumAnalyticsStats(users: UserProfile[], events: AnalyticsEvent[], monthlyPriceGbp: number): PremiumAnalyticsStats {
  const overview = subscriptionOverviewStats(users, events, monthlyPriceGbp);
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  const arpu = real.length > 0 ? overview.mrr / real.length : 0;
  const churnFraction = overview.churnRatePct !== null ? overview.churnRatePct / 100 : null;
  const ltv = churnFraction && churnFraction > 0 ? arpu / churnFraction : arpu * 12;
  return {
    conversionRatePct: overview.conversionRatePct,
    churnRatePct: overview.churnRatePct,
    renewalRatePct: overview.churnRatePct !== null ? 100 - overview.churnRatePct : null,
    ltv: Math.round(ltv * 100) / 100,
    arpu: Math.round(arpu * 100) / 100,
  };
}

/** Distinct-user funnel — each stage is "has this user EVER done X", not
 * event volume, so counts are monotonically meaningful as a real funnel
 * (unlike raw event counts, which could double-count repeat actions).
 * "Completed Onboarding" and "Started Premium" read straight off real
 * profile fields rather than an event, since both are already tracked
 * durably there; "Connected Apple Health" checks the specific `healthkit`
 * provider rather than the broader health-app-connected event, so the
 * label is literally accurate. */
export function userFunnel(users: UserProfile[], events: AnalyticsEvent[], connections: IntegrationConnection[]): { stage: string; count: number }[] {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  const idsWhoEverDid = (type: AnalyticsEventType) =>
    new Set(events.filter((e) => e.event_type === type && e.user_id).map((e) => e.user_id));
  const pairedIds = idsWhoEverDid("tracker_paired");
  const joinedChallengeIds = idsWhoEverDid("challenge_joined");
  const appleHealthIds = new Set(connections.filter((c) => c.provider === "healthkit").map((c) => c.user_id));

  // A true cumulative funnel — each stage is "made it this far, in this
  // exact order", not five independent adoption rates. Real usage isn't
  // strictly nested this way (a user can complete onboarding without ever
  // pairing a tracker, since the app also supports phone-only tracking),
  // but a funnel chart's stage-to-stage conversion % is only meaningful
  // against a monotonically non-increasing cohort, so each step narrows
  // the previous one rather than being computed independently.
  let cohort = real;
  const stages = [{ stage: "Users", count: cohort.length }];

  cohort = cohort.filter((u) => pairedIds.has(u.id));
  stages.push({ stage: "Paired Tracker", count: cohort.length });

  cohort = cohort.filter((u) => u.onboarding_complete);
  stages.push({ stage: "Completed Onboarding", count: cohort.length });

  cohort = cohort.filter((u) => joinedChallengeIds.has(u.id));
  stages.push({ stage: "Joined Challenge", count: cohort.length });

  cohort = cohort.filter((u) => appleHealthIds.has(u.id));
  stages.push({ stage: "Connected Apple Health", count: cohort.length });

  cohort = cohort.filter((u) => u.subscription.started_at !== null);
  stages.push({ stage: "Started Premium", count: cohort.length });

  return stages;
}

export interface TrackerUsageStats {
  connectedToday: number;
  syncedToday: number;
  averageBatteryPct: number | null;
  syncFailures: number;
  firmwareVersions: { stage: string; count: number }[];
}

/** "Today" here is the most recent day any paired device reports a
 * timestamp for — same frozen-mock-timeline anchoring as the rest of this
 * file. A sync failure is a device seen (BLE-connected) today whose last
 * *successful sync* is stale or missing — connected without its data
 * actually making it to the backend. */
export function trackerUsageStats(devices: Device[]): TrackerUsageStats {
  const paired = devices.filter((d) => d.owner_user_id && !d.replaced_at);
  const timestamps = paired.flatMap((d) => [d.last_seen_at, d.last_synced_at]).filter((t): t is string => !!t);
  if (timestamps.length === 0) {
    return { connectedToday: 0, syncedToday: 0, averageBatteryPct: null, syncFailures: 0, firmwareVersions: [] };
  }
  const latestDay = timestamps.reduce((max, t) => (t.slice(0, 10) > max ? t.slice(0, 10) : max), timestamps[0].slice(0, 10));
  const connectedToday = paired.filter((d) => d.last_seen_at?.slice(0, 10) === latestDay).length;
  const syncedToday = paired.filter((d) => d.last_synced_at?.slice(0, 10) === latestDay).length;
  const batteries = paired.map((d) => d.battery_level).filter((b): b is number => b !== null);
  const averageBatteryPct = batteries.length > 0 ? Math.round(batteries.reduce((a, b) => a + b, 0) / batteries.length) : null;
  const syncFailures = paired.filter((d) => {
    if (d.last_seen_at?.slice(0, 10) !== latestDay) return false;
    if (!d.last_synced_at) return true;
    return +new Date(d.last_seen_at) - +new Date(d.last_synced_at) > 86_400_000;
  }).length;
  const firmwareCounts = new Map<string, number>();
  for (const d of paired) {
    const version = d.firmware_version ?? "Unknown";
    firmwareCounts.set(version, (firmwareCounts.get(version) ?? 0) + 1);
  }
  const firmwareVersions = Array.from(firmwareCounts.entries())
    .map(([stage, count]) => ({ stage, count }))
    .sort((a, b) => b.count - a.count);
  return { connectedToday, syncedToday, averageBatteryPct, syncFailures, firmwareVersions };
}

export interface StepGoalDistribution {
  mostCommon: number | null;
  mostCommonPct: number | null;
  breakdown: { goal: number; count: number }[];
}

export function stepGoalDistribution(users: UserProfile[]): StepGoalDistribution {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return { mostCommon: null, mostCommonPct: null, breakdown: [] };
  const counts = new Map<number, number>();
  for (const u of real) counts.set(u.daily_goal_steps, (counts.get(u.daily_goal_steps) ?? 0) + 1);
  const breakdown = Array.from(counts.entries())
    .map(([goal, count]) => ({ goal, count }))
    .sort((a, b) => b.count - a.count);
  const top = breakdown[0];
  return { mostCommon: top.goal, mostCommonPct: Math.round((top.count / real.length) * 100), breakdown };
}

export interface AppVersionShare {
  version: string;
  count: number;
  pct: number;
}

/** Installed-version spread across real users, newest first — the basis
 * for both the "App version stats" display and deciding a sensible
 * `minimum_required_app_version` (see `usersBelowVersion`). */
export function appVersionDistribution(users: UserProfile[]): AppVersionShare[] {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  if (real.length === 0) return [];
  const counts = new Map<string, number>();
  for (const u of real) counts.set(u.app_version, (counts.get(u.app_version) ?? 0) + 1);
  return Array.from(counts.entries())
    .map(([version, count]) => ({ version, count, pct: Math.round((count / real.length) * 100) }))
    .sort((a, b) => compareVersions(b.version, a.version));
}

/** How many real users are running an older build than `minVersion` — what
 * a "force app update" gate would actually block right now. */
export function usersBelowVersion(users: UserProfile[], minVersion: string): number {
  const real = users.filter((u) => u.role === "user" && !u.deleted);
  return real.filter((u) => compareVersions(u.app_version, minVersion) < 0).length;
}

// --- Legal document versioning -----------------------------------------------

export function legalVersionHistory(docType: LegalDocumentType, versions: LegalDocumentVersion[]): LegalDocumentVersion[] {
  return versions.filter((v) => v.doc_type === docType).sort((a, b) => b.version - a.version);
}

export function currentLegalVersion(docType: LegalDocumentType, versions: LegalDocumentVersion[]): LegalDocumentVersion | undefined {
  return versions.find((v) => v.doc_type === docType && v.status === "published");
}

export function draftLegalVersion(docType: LegalDocumentType, versions: LegalDocumentVersion[]): LegalDocumentVersion | undefined {
  return versions.find((v) => v.doc_type === docType && v.status === "draft");
}

export interface LegalAcceptanceStats {
  accepted: number;
  pending: number;
  declined: number;
  total: number;
  acceptedPct: number;
  pendingPct: number;
  declinedPct: number;
}

/** Null when this exact version never required re-accept (or hasn't
 * published yet) — nobody was asked, so there's nothing to report, not 0%. */
export function legalAcceptanceStats(
  docType: LegalDocumentType,
  version: number,
  acceptances: LegalAcceptance[]
): LegalAcceptanceStats | null {
  const relevant = acceptances.filter((a) => a.doc_type === docType && a.version === version);
  if (relevant.length === 0) return null;
  const accepted = relevant.filter((a) => a.status === "accepted").length;
  const pending = relevant.filter((a) => a.status === "pending").length;
  const declined = relevant.filter((a) => a.status === "declined").length;
  const total = relevant.length;
  return {
    accepted,
    pending,
    declined,
    total,
    acceptedPct: Math.round((accepted / total) * 100),
    pendingPct: Math.round((pending / total) * 100),
    declinedPct: Math.round((declined / total) * 100),
  };
}
