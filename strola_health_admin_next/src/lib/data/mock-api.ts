// Mirrors every function in api.ts exactly (same names, same signatures) but
// reads/writes the in-memory mock-store.ts instead of calling the real
// backend. api.ts delegates here when IS_MOCK_MODE is on. Errors use the
// same ApiError shape the real client throws, so callers' try/catch blocks
// behave identically in either mode.
import { ApiError } from "@/lib/api-client";
import { segmentAudienceIds } from "@/lib/data/queries";
import {
  mockAccountDeletionRequests,
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
  mockFirmwareFailures,
  mockIntegrationConnections,
  mockLegalAcceptances,
  mockLegalVersions,
  mockParticipants,
  mockPosts,
  mockPushNotifications,
  mockReports,
  mockSessions,
  mockSupportTickets,
  mockUserBadges,
  mockUserNotes,
  mockUsers,
  nextId,
} from "@/lib/data/mock-store";
import type { Announcement, AppSettings, Badge, BetaOverride, Challenge, CommunityPost, Device, FeatureFlag, LegalDocumentType, LegalDocumentVersion, PushLinkTarget, PushNotification, PushSegment, Report, UserBadge, UserProfile } from "@/lib/types";

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
export async function fetchAllSessions() {
  return ok(mockSessions);
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
// Deliberately does NOT touch tier/status — those mirror a real
// RevenueCat-driven purchase only. Effective access is `tier === premium
// && status === active` OR `comp_until` in the future (see the backend's
// `Subscription.has_premium_access`) — two independent paths, not one
// field mutating the other. See `classifySubscription` in queries.ts for
// the admin-panel side of that same check.
export async function grantPremium(id: string, untilIso: string, reason: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.subscription.comp_until = untilIso;
  user.subscription.comp_reason = reason;
  if (!user.subscription.started_at) user.subscription.started_at = new Date().toISOString();
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
// Admin-authored posts (e.g. from the official Strolla Health account) —
// same shape as a member post, just created directly rather than via the
// mobile app.
export async function createPost(payload: { author_id: string; content: string; image_url: string | null }) {
  const post: CommunityPost = {
    id: nextId("post"),
    author_id: payload.author_id,
    content: payload.content,
    timestamp: new Date().toISOString(),
    likes_count: 0,
    comments_count: 0,
    step_count: null,
    badge_emoji: null,
    image_url: payload.image_url,
    moderation: { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null },
    pinned: false,
    comments_locked: false,
  };
  mockPosts.unshift(post);
  return ok(post);
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
// `until` is set for a timed mute (e.g. "Mute 24 hours" from a report);
// omitted/null means an indefinite manual posting ban.
export async function banUserFromPosting(id: string, reason: string, until?: string | null) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.posting_banned = true;
  user.posting_ban_reason = reason;
  user.posting_banned_until = until ?? null;
  return ok(undefined);
}
export async function unbanUserFromPosting(id: string) {
  const user = mockUsers.find((u) => u.id === id);
  if (!user) notFound("User");
  user.posting_banned = false;
  user.posting_ban_reason = null;
  user.posting_banned_until = null;
  return ok(undefined);
}

export async function fetchReports() {
  return ok(mockReports);
}
export async function resolveReport(id: string, status: string, note?: string, actionTaken?: string | null) {
  const report = mockReports.find((r) => r.id === id);
  if (!report) notFound("Report");
  report.status = status as Report["status"];
  report.resolved_by = "usr_demo";
  report.resolved_at = new Date().toISOString();
  report.resolution_note = note ?? null;
  if (actionTaken !== undefined) report.action_taken = actionTaken as Report["action_taken"];
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
    last_synced_at: null,
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
  // Anchored to the mock dataset's own latest event, not the real wall
  // clock — mockAnalyticsEvents is a frozen demo timeline (see mock-data.ts'
  // `NOW`), so a Date.now() cutoff would drift further from it every day
  // this demo is left running, eventually filtering out everything.
  const latest = mockAnalyticsEvents.reduce((max, e) => Math.max(max, +new Date(e.created_at)), 0);
  const cutoff = latest - sinceDays * 86_400_000;
  return ok(mockAnalyticsEvents.filter((e) => +new Date(e.created_at) >= cutoff));
}

// --- Crash reports -------------------------------------------------------------

export async function fetchCrashReports(limit = 20) {
  return ok(
    [...mockCrashReports].sort((a, b) => +new Date(b.occurred_at) - +new Date(a.occurred_at)).slice(0, limit)
  );
}

// --- Internal user notes -----------------------------------------------------

export async function fetchUserNotes(userId: string) {
  return ok(mockUserNotes.filter((n) => n.user_id === userId).sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at)));
}
export async function addUserNote(userId: string, authorId: string, body: string) {
  const note = { id: nextId("note"), user_id: userId, author_id: authorId, body, created_at: new Date().toISOString() };
  mockUserNotes.push(note);
  return ok(note);
}

// --- Support tickets -------------------------------------------------------------

export async function fetchSupportTickets() {
  return ok([...mockSupportTickets].sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at)));
}

// --- Firmware update failures ----------------------------------------------------

export async function fetchFirmwareFailures() {
  return ok([...mockFirmwareFailures].sort((a, b) => +new Date(b.occurred_at) - +new Date(a.occurred_at)));
}

// --- Account deletion requests ----------------------------------------------------

export async function fetchAccountDeletionRequests() {
  return ok([...mockAccountDeletionRequests].sort((a, b) => +new Date(b.requested_at) - +new Date(a.requested_at)));
}

// --- Push notifications ---------------------------------------------------------

export async function fetchPushNotifications() {
  return ok([...mockPushNotifications].sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at)));
}

type PushComposePayload = {
  id?: string;
  segment: PushSegment;
  title: string;
  body: string;
  linkTarget: PushLinkTarget;
  linkChallengeId: string | null;
  linkCustomPath: string | null;
  sentBy: string | null;
};

function pushAudienceCount(segment: PushSegment): number {
  return segmentAudienceIds(segment, {
    users: mockUsers,
    events: mockAnalyticsEvents,
    participants: mockParticipants,
    devices: mockDevices,
  }).length;
}

// No real provider reports delivery/open events back to us, so a sent
// notification's stats are simulated once at send time: 90-99% delivery,
// then 15-45% of *delivered* devices open it — realistic push-notification
// ranges, not measurements of anything real.
function simulateDeliveryStats(recipientCount: number): { delivered: number; opened: number } {
  const delivered = Math.round(recipientCount * (0.9 + Math.random() * 0.09));
  const opened = Math.round(delivered * (0.15 + Math.random() * 0.3));
  return { delivered, opened };
}

function findPushNotification(id: string): PushNotification {
  const record = mockPushNotifications.find((p) => p.id === id);
  if (!record) notFound("Notification");
  return record;
}

function upsertPushNotification(payload: PushComposePayload, fields: Partial<PushNotification>): PushNotification {
  if (payload.id) {
    const existing = mockPushNotifications.find((p) => p.id === payload.id);
    if (existing) {
      Object.assign(existing, {
        segment: payload.segment,
        title: payload.title,
        body: payload.body,
        link_target: payload.linkTarget,
        link_challenge_id: payload.linkChallengeId,
        link_custom_path: payload.linkCustomPath,
        ...fields,
      });
      return existing;
    }
  }
  const record: PushNotification = {
    id: nextId("push"),
    segment: payload.segment,
    title: payload.title,
    body: payload.body,
    link_target: payload.linkTarget,
    link_challenge_id: payload.linkChallengeId,
    link_custom_path: payload.linkCustomPath,
    status: "draft",
    scheduled_at: null,
    recipient_count: 0,
    delivered_count: 0,
    opened_count: 0,
    sent_by: payload.sentBy,
    created_at: new Date().toISOString(),
    sent_at: null,
    ...fields,
  };
  mockPushNotifications.unshift(record);
  return record;
}

export async function saveDraftPushNotification(payload: PushComposePayload) {
  const record = upsertPushNotification(payload, { status: "draft", scheduled_at: null, sent_at: null, recipient_count: 0, delivered_count: 0, opened_count: 0 });
  return ok(record);
}

export async function schedulePushNotification(payload: PushComposePayload & { scheduledAt: string }) {
  const recipientCount = pushAudienceCount(payload.segment);
  const record = upsertPushNotification(payload, {
    status: "scheduled",
    scheduled_at: payload.scheduledAt,
    sent_at: null,
    recipient_count: recipientCount,
    delivered_count: 0,
    opened_count: 0,
  });
  return ok(record);
}

export async function sendPushNotification(payload: PushComposePayload) {
  const recipientCount = pushAudienceCount(payload.segment);
  const { delivered, opened } = simulateDeliveryStats(recipientCount);
  const record = upsertPushNotification(payload, {
    status: "sent",
    scheduled_at: null,
    recipient_count: recipientCount,
    delivered_count: delivered,
    opened_count: opened,
    sent_at: new Date().toISOString(),
  });
  return ok(record);
}

export async function sendScheduledPushNotificationNow(id: string) {
  const record = findPushNotification(id);
  const recipientCount = pushAudienceCount(record.segment);
  const { delivered, opened } = simulateDeliveryStats(recipientCount);
  Object.assign(record, {
    status: "sent" as const,
    scheduled_at: null,
    recipient_count: recipientCount,
    delivered_count: delivered,
    opened_count: opened,
    sent_at: new Date().toISOString(),
  });
  return ok(record);
}

export async function deletePushNotification(id: string) {
  const index = mockPushNotifications.findIndex((p) => p.id === id);
  if (index === -1) notFound("Notification");
  mockPushNotifications.splice(index, 1);
  return ok(undefined);
}

// Sends immediately to one device, outside any segment/history — a "does
// this actually look right" check before committing to a real send.
export async function sendTestPushNotification(payload: { userId: string; title: string; body: string }) {
  await delay();
  return ok({ sent: true as const, userId: payload.userId });
}

// --- Connected apps (per-user platform integrations) ----------------------------

export async function fetchIntegrationConnections() {
  return ok(mockIntegrationConnections);
}
// Admin-forced disconnect — e.g. clearing a stuck/errored token so the user
// can reconnect cleanly. Sets status rather than deleting the row, so the
// connection history (when it was first connected, etc.) isn't lost.
// Admin-triggered manual sync — pulls the latest data from the provider
// right now instead of waiting for its next scheduled/webhook sync. Also the
// practical fix for a connection stuck in an error state that the user
// hasn't reconnected themselves yet: a successful resync clears it.
export async function resyncIntegration(id: string) {
  const connection = mockIntegrationConnections.find((c) => c.id === id);
  if (!connection) notFound("Integration connection");
  connection.status = "connected";
  connection.error_message = null;
  connection.last_synced_at = new Date().toISOString();
  return ok(connection);
}
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

export async function fetchLegalVersions() {
  return ok(mockLegalVersions);
}
export async function fetchLegalAcceptances() {
  return ok(mockLegalAcceptances);
}

type LegalDraftPayload = {
  id?: string;
  doc_type: LegalDocumentType;
  content: string;
  effective_date: string;
  requires_reaccept: boolean;
  created_by: string | null;
};

function nextLegalVersionNumber(docType: LegalDocumentType): number {
  const existing = mockLegalVersions.filter((v) => v.doc_type === docType);
  return Math.max(0, ...existing.map((v) => v.version)) + 1;
}

export async function saveLegalDraft(payload: LegalDraftPayload) {
  if (payload.id) {
    const existing = mockLegalVersions.find((v) => v.id === payload.id && v.status === "draft");
    if (existing) {
      existing.content = payload.content;
      existing.effective_date = payload.effective_date;
      existing.requires_reaccept = payload.requires_reaccept;
      return ok(existing);
    }
  }
  const draft: LegalDocumentVersion = {
    id: nextId("legal"),
    doc_type: payload.doc_type,
    version: nextLegalVersionNumber(payload.doc_type),
    status: "draft",
    content: payload.content,
    changelog: null,
    effective_date: payload.effective_date,
    requires_reaccept: payload.requires_reaccept,
    created_by: payload.created_by,
    created_at: new Date().toISOString(),
    published_at: null,
  };
  mockLegalVersions.unshift(draft);
  return ok(draft);
}

export async function deleteLegalDraft(id: string) {
  const index = mockLegalVersions.findIndex((v) => v.id === id && v.status === "draft");
  if (index === -1) notFound("Draft");
  mockLegalVersions.splice(index, 1);
  return ok(undefined);
}

// Promotes a draft to the live version for its doc_type — archives whatever
// was previously published (never deleted, stays in Version History), and
// if this version requires re-accept, immediately seeds a "pending"
// acceptance row for every real user, simulating the rollout an in-app
// accept/decline gate would drive once one exists.
export async function publishLegalVersion(id: string, changelog: string) {
  const draft = mockLegalVersions.find((v) => v.id === id);
  if (!draft) notFound("Legal document version");
  const previouslyPublished = mockLegalVersions.find((v) => v.doc_type === draft.doc_type && v.status === "published");
  if (previouslyPublished) previouslyPublished.status = "archived";

  draft.status = "published";
  draft.changelog = changelog.trim() || null;
  draft.published_at = new Date().toISOString();

  if (draft.requires_reaccept) {
    const realUsers = mockUsers.filter((u) => u.role === "user" && !u.deleted);
    for (const u of realUsers) {
      mockLegalAcceptances.push({
        id: nextId("la"),
        user_id: u.id,
        doc_type: draft.doc_type,
        version: draft.version,
        status: "pending",
        responded_at: null,
      });
    }
  }
  return ok(draft);
}

// "Restore" never overwrites history — it seeds a brand-new draft from an
// old version's content, so the admin reviews/re-publishes it deliberately
// rather than a past version silently going live again.
export async function restoreLegalVersion(id: string) {
  const source = mockLegalVersions.find((v) => v.id === id);
  if (!source) notFound("Legal document version");
  const draft: LegalDocumentVersion = {
    id: nextId("legal"),
    doc_type: source.doc_type,
    version: nextLegalVersionNumber(source.doc_type),
    status: "draft",
    content: source.content,
    changelog: null,
    effective_date: new Date().toISOString().slice(0, 10),
    requires_reaccept: source.requires_reaccept,
    created_by: null,
    created_at: new Date().toISOString(),
    published_at: null,
  };
  mockLegalVersions.unshift(draft);
  return ok(draft);
}

// --- App settings (global defaults) -----------------------------------------------

export async function fetchAppSettings() {
  return ok(mockAppSettings);
}
export async function updateAppSettings(payload: Partial<AppSettings>) {
  Object.assign(mockAppSettings, payload, { updated_at: new Date().toISOString() });
  return ok(mockAppSettings);
}

// A real implementation would revoke every user's Firebase refresh token
// (iterating `admin.auth().revokeRefreshTokens(uid)`, or bumping a global
// "tokens issued before this instant are invalid" cutoff the backend
// checks on every request) — no session store exists in this mock to
// actually revoke, so this just simulates the outcome.
export async function forceLogoutAllUsers() {
  await delay();
  return ok({ loggedOut: mockUsers.filter((u) => u.role === "user" && !u.deleted).length });
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
    audience: payload.audience ?? "everyone",
    audience_app_version: payload.audience_app_version ?? null,
    audience_app_version_mode: payload.audience_app_version_mode ?? null,
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
export async function duplicateAnnouncement(id: string) {
  const source = mockAnnouncements.find((a) => a.id === id);
  if (!source) notFound("Announcement");
  const copy: Announcement = {
    ...source,
    id: nextId("ann"),
    active: false,
    starts_at: new Date().toISOString(),
    ends_at: null,
    created_at: new Date().toISOString(),
  };
  mockAnnouncements.unshift(copy);
  return ok(copy);
}
export async function deleteAnnouncement(id: string) {
  const index = mockAnnouncements.findIndex((a) => a.id === id);
  if (index === -1) notFound("Announcement");
  mockAnnouncements.splice(index, 1);
  return ok(undefined);
}

