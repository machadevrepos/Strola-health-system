// Mirrors every function in api.ts exactly (same names, same signatures) but
// reads/writes the in-memory mock-store.ts instead of calling the real
// backend. api.ts delegates here when IS_MOCK_MODE is on. Errors use the
// same ApiError shape the real client throws, so callers' try/catch blocks
// behave identically in either mode.
import { ApiError } from "@/lib/api-client";
import {
  mockAnalyticsEvents,
  mockBadges,
  mockChallenges,
  mockDailySummaries,
  mockDevices,
  mockFeatureFlags,
  mockParticipants,
  mockPosts,
  mockReports,
  mockSessions,
  mockUserBadges,
  mockUsers,
  nextId,
} from "@/lib/data/mock-store";
import type { Badge, Challenge, Device, FeatureFlag, Report, UserBadge, UserProfile } from "@/lib/types";

const delay = () => new Promise((resolve) => setTimeout(resolve, 150 + Math.random() * 200));

function notFound(what: string): never {
  throw new ApiError(404, `${what} not found`);
}

async function ok<T>(value: T): Promise<T> {
  await delay();
  return value;
}

// --- Users ----------------------------------------------------------------

export async function fetchUsers() {
  return ok(mockUsers);
}
export async function fetchUser(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  return ok(user);
}
export async function fetchSessionsForUser(id: string) {
  return ok(mockSessions.filter((s) => s.user_id === id).sort((a, b) => +new Date(b.start_time) - +new Date(a.start_time)));
}
export async function fetchDevicesForUser(id: string) {
  return ok(mockDevices.filter((d) => d.owner_user_id === id));
}
export async function fetchBadgesForUser(id: string) {
  return ok(mockUserBadges.filter((a) => a.user_id === id));
}
export async function fetchChallengesForUser(id: string) {
  return ok(mockParticipants.filter((p) => p.user_id === id));
}
export async function fetchDailySummaryForUser(id: string, days = 30) {
  return ok(
    mockDailySummaries
      .filter((d) => d.user_id === id)
      .sort((a, b) => +new Date(a.date) - +new Date(b.date))
      .slice(-days)
  );
}

export async function updateUser(id: string, payload: Partial<UserProfile>) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  Object.assign(user, payload, { updated_at: new Date().toISOString() });
  return ok(user);
}
export async function updateUserPrivacy(id: string, payload: Record<string, boolean>) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  Object.assign(user.privacy, payload);
  return ok(user);
}
export async function banUser(id: string, reason: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.banned = true;
  user.ban_reason = reason;
  return ok(undefined);
}
export async function unbanUser(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.banned = false;
  user.ban_reason = null;
  return ok(undefined);
}
export async function deleteUser(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.deleted = true;
  user.deleted_at = new Date().toISOString();
  user.name = "Deleted User";
  user.username = `deleted_${user.id.slice(0, 8)}`;
  user.email = null;
  user.bio = null;
  user.photo_url = null;
  user.location = null;
  return ok(undefined);
}
export async function changeUserRole(id: string, role: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.role = role as UserProfile["role"];
  return ok(undefined);
}
export async function grantPremium(id: string, untilIso: string, reason: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.subscription.comp_until = untilIso;
  user.subscription.comp_reason = reason;
  return ok(undefined);
}
export async function revokePremium(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.subscription.comp_until = null;
  user.subscription.comp_reason = null;
  return ok(undefined);
}

// --- Moderation -------------------------------------------------------------

export async function fetchPosts(includeHidden = true) {
  return ok(includeHidden ? mockPosts : mockPosts.filter((p) => !p.moderation.hidden));
}
export async function updatePost(id: string, payload: { content?: string; step_count?: number; badge_emoji?: string }) {
  const post = mockPosts.find((p) => p.id === id);
  if (!post) notFound("Post");
  Object.assign(post, payload);
  return ok(post);
}
export async function hidePost(id: string, reason: string) {
  const post = mockPosts.find((p) => p.id === id);
  if (!post) notFound("Post");
  post.moderation = { hidden: true, hidden_by: "usr_demo", hidden_reason: reason, hidden_at: new Date().toISOString() };
  return ok(undefined);
}
export async function unhidePost(id: string) {
  const post = mockPosts.find((p) => p.id === id);
  if (!post) notFound("Post");
  post.moderation = { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null };
  return ok(undefined);
}
export async function deletePost(id: string) {
  const index = mockPosts.findIndex((p) => p.id === id);
  if (index === -1) notFound("Post");
  mockPosts.splice(index, 1);
  return ok(undefined);
}
export async function removePostPhoto(id: string) {
  const post = mockPosts.find((p) => p.id === id);
  if (!post) notFound("Post");
  post.image_url = null;
  return ok(undefined);
}

export async function fetchReports() {
  return ok(mockReports);
}
export async function resolveReport(id: string, status: string, note?: string) {
  const report = mockReports.find((r) => r.id === id);
  if (!report) notFound("Report");
  report.status = status as Report["status"];
  report.resolved_by = "usr_demo";
  report.resolved_at = new Date().toISOString();
  report.resolution_note = note ?? null;
  return ok(report);
}

// --- Challenges --------------------------------------------------------------

export async function fetchChallenges() {
  return ok(mockChallenges);
}
export async function fetchChallenge(id: string) {
  const challenge = mockChallenges.find((c) => c.id === id);
  if (!challenge) notFound("Challenge");
  return ok(challenge);
}
export async function createChallenge(payload: Partial<Challenge> & { created_by?: string }) {
  const challenge: Challenge = {
    id: nextId("chal"),
    title: payload.title ?? "",
    description: payload.description ?? "",
    goal_steps: payload.goal_steps ?? 10000,
    start_date: payload.start_date ?? new Date().toISOString().slice(0, 10),
    end_date: payload.end_date ?? new Date().toISOString().slice(0, 10),
    badge_emoji: payload.badge_emoji ?? "🏆",
    accent_color_value: null,
    visibility: payload.visibility ?? "public",
    is_official: false,
    invite_code: payload.visibility === "private" ? `INV-${Math.random().toString(36).slice(2, 8).toUpperCase()}` : null,
    created_by: payload.created_by ?? null,
    created_at: new Date().toISOString(),
  };
  mockChallenges.unshift(challenge);
  return ok(challenge);
}
export async function updateChallenge(id: string, payload: Partial<Challenge>) {
  const challenge = mockChallenges.find((c) => c.id === id);
  if (!challenge) notFound("Challenge");
  Object.assign(challenge, payload);
  return ok(challenge);
}
export async function deleteChallenge(id: string) {
  const index = mockChallenges.findIndex((c) => c.id === id);
  if (index === -1) notFound("Challenge");
  mockChallenges.splice(index, 1);
  return ok(undefined);
}
export async function removeParticipant(challengeId: string, userId: string) {
  const index = mockParticipants.findIndex((p) => p.challenge_id === challengeId && p.user_id === userId);
  if (index !== -1) mockParticipants.splice(index, 1);
  return ok(undefined);
}
export async function setOfficialMonthly(id: string) {
  mockChallenges.forEach((c) => (c.is_official = c.id === id));
  return ok(undefined);
}
export async function fetchLeaderboard(challengeId: string) {
  return ok(mockParticipants.filter((p) => p.challenge_id === challengeId).sort((a, b) => b.steps - a.steps));
}

// --- Badges --------------------------------------------------------------------

export async function fetchBadges() {
  return ok(mockBadges);
}
export async function fetchAllAwards() {
  return ok(mockUserBadges);
}
export async function createBadge(payload: { name: string; description: string; emoji: string }) {
  const badge: Badge = { id: nextId("badge"), name: payload.name, description: payload.description, emoji: payload.emoji, created_at: new Date().toISOString() };
  mockBadges.unshift(badge);
  return ok(badge);
}
export async function updateBadge(id: string, payload: Partial<{ name: string; description: string; emoji: string }>) {
  const badge = mockBadges.find((b) => b.id === id);
  if (!badge) notFound("Badge");
  Object.assign(badge, payload);
  return ok(badge);
}
export async function deleteBadge(id: string) {
  const index = mockBadges.findIndex((b) => b.id === id);
  if (index === -1) notFound("Badge");
  mockBadges.splice(index, 1);
  for (let i = mockUserBadges.length - 1; i >= 0; i--) {
    if (mockUserBadges[i].badge_id === id) mockUserBadges.splice(i, 1);
  }
  return ok(undefined);
}
export async function awardBadge(badgeId: string, userId: string) {
  const award: UserBadge = { id: `${userId}_${badgeId}`, user_id: userId, badge_id: badgeId, awarded_at: new Date().toISOString(), awarded_by: null };
  mockUserBadges.push(award);
  return ok(award);
}
export async function revokeBadge(badgeId: string, userId: string) {
  const index = mockUserBadges.findIndex((a) => a.badge_id === badgeId && a.user_id === userId);
  if (index !== -1) mockUserBadges.splice(index, 1);
  return ok(undefined);
}

// --- Fleet -----------------------------------------------------------------

export async function fetchAllDevices() {
  return ok(mockDevices);
}
export async function provisionDevice(payload: { serial_number: string; manufacturing_batch?: string | null }) {
  const device: Device = {
    id: nextId("dev"),
    serial_number: payload.serial_number,
    device_type: "strolla_nrf7002",
    ble_mac: null,
    firmware_version: null,
    manufacturing_batch: payload.manufacturing_batch ?? null,
    owner_user_id: null,
    paired_at: null,
    last_seen_at: null,
    battery_level: null,
    created_at: new Date().toISOString(),
  };
  mockDevices.unshift(device);
  return ok(device);
}
export async function adminUnpairDevice(id: string) {
  const device = mockDevices.find((d) => d.id === id);
  if (!device) notFound("Device");
  device.owner_user_id = null;
  device.paired_at = null;
  return ok(undefined);
}

// --- Settings ----------------------------------------------------------------

export async function fetchFeatureFlags() {
  return ok(mockFeatureFlags);
}
export async function updateFeatureFlag(key: string, payload: { required_tier: string; description?: string | null }) {
  const flag = mockFeatureFlags.find((f) => f.key === key);
  if (!flag) notFound("Feature flag");
  flag.required_tier = payload.required_tier as FeatureFlag["required_tier"];
  if (payload.description !== undefined) flag.description = payload.description;
  flag.updated_at = new Date().toISOString();
  return ok(flag);
}

export async function fetchAnalyticsEvents(sinceDays = 30) {
  const cutoff = Date.now() - sinceDays * 86_400_000;
  return ok(mockAnalyticsEvents.filter((e) => +new Date(e.created_at) >= cutoff));
}
