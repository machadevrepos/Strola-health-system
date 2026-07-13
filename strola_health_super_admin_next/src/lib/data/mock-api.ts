// Mirrors every function in api.ts exactly (same names, same signatures) but
// reads/writes the in-memory mock-store.ts instead of calling the real
// backend. api.ts delegates here when IS_MOCK_MODE is on. Errors use the
// same ApiError shape the real client throws, so callers' try/catch blocks
// behave identically in either mode.
import { ApiError } from "@/lib/api-client";
import { segmentAudienceIds } from "@/lib/data/queries";
import {
  mockAnalyticsEvents,
  mockAnnouncements,
  mockAppContent,
  mockAppSettings,
  mockBadges,
  mockBetaOverrides,
  mockChallenges,
  mockComments,
  mockCrashReports,
  mockDailySummaries,
  mockDevices,
  mockFeatureFlags,
  mockIntegrationConnections,
  mockLegalDocuments,
  mockParticipants,
  mockPosts,
  mockPushNotifications,
  mockReports,
  mockSessions,
  mockUserBadges,
  mockUsers,
  nextId,
} from "@/lib/data/mock-store";
import type { Announcement, AppSettings, Badge, BetaOverride, Challenge, CommunityPost, Device, FeatureFlag, LegalDocumentType, PushNotification, PushSegment, Report, UserBadge, UserProfile } from "@/lib/types";

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
export async function fetchAllDailySummaries() {
  return ok(mockDailySummaries);
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

// Firebase Auth's own reset-email flow (same one the app's own "forgot
// password" screen triggers) — nothing to mutate on the user record itself,
// this just kicks off that email. No-op here beyond the artificial delay
// since there's no real Firebase project wired into mock mode.
export async function resetUserPassword(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  return ok(undefined);
}

// One-off admin-authored email to a single user — no email provider wired in
// yet, this just simulates the send.
export async function sendUserEmail(id: string, _payload: { subject: string; body: string }) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  return ok(undefined);
}

// A formal warning short of any account restriction — no persistent state on
// the user record (unlike banned/posting_banned), just an emailed notice and
// an audit-log entry via the caller's logAction.
export async function warnUser(id: string, _reason: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  return ok(undefined);
}

// --- Moderation -------------------------------------------------------------

export async function fetchPosts(includeHidden = true) {
  return ok(includeHidden ? mockPosts : mockPosts.filter((p) => !p.moderation.hidden));
}
export async function updatePost(
  id: string,
  payload: Partial<Pick<CommunityPost, "content" | "step_count" | "badge_emoji" | "pinned" | "comments_locked">>
) {
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

export async function fetchComments() {
  return ok(mockComments);
}
export async function updateComment(id: string, content: string) {
  const comment = mockComments.find((c) => c.id === id);
  if (!comment) notFound("Comment");
  comment.content = content;
  return ok(comment);
}
export async function deleteComment(id: string) {
  const index = mockComments.findIndex((c) => c.id === id);
  if (index === -1) notFound("Comment");
  const [removed] = mockComments.splice(index, 1);
  const post = mockPosts.find((p) => p.id === removed.post_id);
  if (post) post.comments_count = Math.max(0, post.comments_count - 1);
  return ok(undefined);
}

// Lighter than banUser/unbanUser below — leaves the account itself active,
// only blocks new posts/comments. See `posting_banned` on UserProfile.
export async function banUserFromPosting(id: string, reason: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.posting_banned = true;
  user.posting_ban_reason = reason;
  return ok(undefined);
}
export async function unbanUserFromPosting(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.posting_banned = false;
  user.posting_ban_reason = null;
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
    image_url: payload.image_url ?? null,
    rules: payload.rules ?? null,
    winner_type: payload.winner_type ?? "most_steps",
    // New challenges start as drafts — an admin explicitly publishes when
    // it's ready, rather than it going live the moment it's created.
    status: payload.status ?? "draft",
    winner_user_id: null,
    admin_notes: null,
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
export async function createBadge(payload: Partial<Badge> & { name: string; description: string; emoji: string }) {
  const badge: Badge = {
    id: nextId("badge"),
    name: payload.name,
    description: payload.description,
    emoji: payload.emoji,
    requirement_metric: payload.requirement_metric ?? "total_steps",
    requirement_value: payload.requirement_value ?? 0,
    enabled: payload.enabled ?? true,
    visible: payload.visible ?? true,
    created_at: new Date().toISOString(),
  };
  mockBadges.unshift(badge);
  return ok(badge);
}
export async function updateBadge(id: string, payload: Partial<Badge>) {
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
    replaced_at: null,
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
// Force-reassigns to a different user directly — a support-desk shortcut for
// e.g. a device physically handed to someone else, rather than making them
// unpair-then-repair themselves.
export async function reassignDevice(id: string, userId: string) {
  const device = mockDevices.find((d) => d.id === id);
  if (!device) notFound("Device");
  device.owner_user_id = userId;
  device.paired_at = new Date().toISOString();
  return ok(device);
}
export async function pushFirmwareUpdate(id: string, version: string) {
  const device = mockDevices.find((d) => d.id === id);
  if (!device) notFound("Device");
  device.firmware_version = version;
  return ok(device);
}
// Retires a unit permanently (lost, warranty swap) — distinct from a plain
// unpair, which just frees it up to be paired again.
export async function markDeviceReplaced(id: string) {
  const device = mockDevices.find((d) => d.id === id);
  if (!device) notFound("Device");
  device.owner_user_id = null;
  device.paired_at = null;
  device.replaced_at = new Date().toISOString();
  return ok(device);
}
// Real removal from the fleet — only for a device that was never paired
// (a mistaken provision). A device with any pairing history should be
// retired via markDeviceReplaced instead, so the ownership/warranty trail
// isn't lost.
export async function deleteDevice(id: string) {
  const index = mockDevices.findIndex((d) => d.id === id);
  if (index === -1) notFound("Device");
  mockDevices.splice(index, 1);
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

// --- Crash reports -------------------------------------------------------------

export async function fetchCrashReports(limit = 20) {
  return ok(
    [...mockCrashReports].sort((a, b) => +new Date(b.occurred_at) - +new Date(a.occurred_at)).slice(0, limit)
  );
}

// --- Push notifications ---------------------------------------------------------

export async function fetchPushNotifications() {
  return ok([...mockPushNotifications].sort((a, b) => +new Date(b.sent_at) - +new Date(a.sent_at)));
}

// --- Connected apps (per-user platform integrations) ----------------------------

export async function fetchIntegrationConnections() {
  return ok(mockIntegrationConnections);
}
// Admin-forced disconnect — e.g. clearing a stuck/errored token so the user
// can reconnect cleanly. Sets status rather than deleting the row, so the
// connection history (when it was first connected, etc.) isn't lost.
export async function disconnectIntegration(id: string) {
  const connection = mockIntegrationConnections.find((c) => c.id === id);
  if (!connection) notFound("Integration connection");
  connection.status = "disconnected";
  connection.error_message = null;
  return ok(connection);
}

// --- App content (editable copy) -------------------------------------------------

export async function fetchAppContent() {
  return ok(mockAppContent);
}
export async function updateAppContent(key: string, value: string) {
  const entry = mockAppContent.find((e) => e.key === key);
  if (!entry) notFound("App content entry");
  entry.value = value;
  entry.updated_at = new Date().toISOString();
  return ok(entry);
}

// --- Legal documents ---------------------------------------------------------------

export async function fetchLegalDocuments() {
  return ok(mockLegalDocuments);
}
export async function updateLegalDocument(type: LegalDocumentType, content: string, forceReaccept: boolean) {
  const doc = mockLegalDocuments.find((d) => d.type === type);
  if (!doc) notFound("Legal document");
  doc.content = content;
  doc.updated_at = new Date().toISOString();
  doc.requires_reaccept = forceReaccept;
  if (forceReaccept) doc.version += 1;
  return ok(doc);
}

// --- App settings (global defaults) -----------------------------------------------

export async function fetchAppSettings() {
  return ok(mockAppSettings);
}
export async function updateAppSettings(payload: Partial<AppSettings>) {
  Object.assign(mockAppSettings, payload, { updated_at: new Date().toISOString() });
  return ok(mockAppSettings);
}

// --- Beta overrides ------------------------------------------------------------

export async function fetchBetaOverrides() {
  return ok(mockBetaOverrides);
}
export async function createBetaOverride(payload: {
  feature_key: string;
  target_type: BetaOverride["target_type"];
  target_value: string;
  created_by: string | null;
}) {
  const override: BetaOverride = {
    id: nextId("beta"),
    feature_key: payload.feature_key,
    target_type: payload.target_type,
    target_value: payload.target_type === "ambassador" ? "" : payload.target_value,
    created_by: payload.created_by,
    created_at: new Date().toISOString(),
  };
  mockBetaOverrides.unshift(override);
  return ok(override);
}
export async function deleteBetaOverride(id: string) {
  const index = mockBetaOverrides.findIndex((o) => o.id === id);
  if (index === -1) notFound("Beta override");
  mockBetaOverrides.splice(index, 1);
  return ok(undefined);
}

// --- Announcements ---------------------------------------------------------------

export async function fetchAnnouncements() {
  return ok([...mockAnnouncements].sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at)));
}
export async function createAnnouncement(payload: Partial<Announcement> & { message: string; created_by: string | null }) {
  const announcement: Announcement = {
    id: nextId("ann"),
    emoji: payload.emoji ?? "📣",
    message: payload.message,
    link_target: payload.link_target ?? null,
    active: payload.active ?? true,
    starts_at: payload.starts_at ?? new Date().toISOString(),
    ends_at: payload.ends_at ?? null,
    created_by: payload.created_by,
    created_at: new Date().toISOString(),
  };
  mockAnnouncements.unshift(announcement);
  return ok(announcement);
}
export async function updateAnnouncement(id: string, payload: Partial<Announcement>) {
  const announcement = mockAnnouncements.find((a) => a.id === id);
  if (!announcement) notFound("Announcement");
  Object.assign(announcement, payload);
  return ok(announcement);
}
export async function deleteAnnouncement(id: string) {
  const index = mockAnnouncements.findIndex((a) => a.id === id);
  if (index === -1) notFound("Announcement");
  mockAnnouncements.splice(index, 1);
  return ok(undefined);
}

export async function sendPushNotification(payload: { segment: PushSegment; title: string; body: string; sentBy: string | null }) {
  const recipientCount = segmentAudienceIds(payload.segment, {
    users: mockUsers,
    events: mockAnalyticsEvents,
    participants: mockParticipants,
    devices: mockDevices,
  }).length;
  const record: PushNotification = {
    id: nextId("push"),
    segment: payload.segment,
    title: payload.title,
    body: payload.body,
    recipient_count: recipientCount,
    sent_by: payload.sentBy,
    sent_at: new Date().toISOString(),
  };
  mockPushNotifications.unshift(record);
  return ok(record);
}
