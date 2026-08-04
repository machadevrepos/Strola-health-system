import { limit, orderBy, where } from "firebase/firestore";
import { IS_MOCK_MODE } from "@/lib/mock-mode";
import * as mock from "@/lib/data/mock-api";
import { callFn, getCollectionData, getCollectionGroupData, getDocData, getDocDataOrThrow, refetchDoc } from "@/lib/firestore-helpers";
import { getOrFetch, invalidate, invalidateAfter } from "@/lib/data/cache";
import type {
  AccountDeletionRequest,
  AnalyticsEvent,
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
  LegalDocumentType,
  LegalDocumentVersion,
  PushLinkTarget,
  PushNotification,
  PushSegment,
  Report,
  SupportTicket,
  UserBadge,
  UserNote,
  UserProfile,
  WorkoutSession,
} from "@/lib/types";

// Real mode talks directly to Firebase: Firestore reads for anything
// firestore.rules lets an admin/super_admin read directly, Cloud Functions
// callables (via firestore-helpers.ts's callFn) for every mutation and for
// the handful of collections that are Functions-only even for admins (e.g.
// integrationConnections, which holds OAuth tokens). See
// ../../../../strola_health_firebase/README.md for what's deployed.
//
// Every export below still delegates to mock-api.ts when IS_MOCK_MODE is on
// (see lib/mock-mode.ts) — that's the one switch this whole app's data
// layer hangs off, so no page or component needs to know which mode it's in.
//
// Every read also goes through cache.ts's short-TTL in-memory cache, and
// every mutation invalidates the cache keys it can affect — see cache.ts
// for why. Cache keys are plain strings; a mutation invalidating "users"
// clears both "users:list" and any "users:doc:{id}" entries, since
// invalidate() matches on a ":"-delimited prefix.

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

export const fetchUsers = () =>
  getOrFetch("users:list", () => (IS_MOCK_MODE ? mock.fetchUsers() : getCollectionData<UserProfile>("users")));
export const fetchUser = (id: string) =>
  getOrFetch(`users:doc:${id}`, () =>
    IS_MOCK_MODE ? mock.fetchUser(id) : getDocDataOrThrow<UserProfile>(`users/${id}`, "User not found.")
  );
export const fetchSessionsForUser = (id: string) =>
  getOrFetch(`sessions:${id}`, () =>
    IS_MOCK_MODE
      ? mock.fetchSessionsForUser(id)
      : getCollectionData<WorkoutSession>("workoutSessions", where("user_id", "==", id), orderBy("start_time", "desc"), limit(200))
  );
export const fetchDevicesForUser = (id: string) =>
  getOrFetch(`devicesForUser:${id}`, () =>
    IS_MOCK_MODE ? mock.fetchDevicesForUser(id) : getCollectionData<Device>("devices", where("owner_user_id", "==", id))
  );
export const fetchBadgesForUser = (id: string) =>
  getOrFetch(`badgesForUser:${id}`, () =>
    IS_MOCK_MODE ? mock.fetchBadgesForUser(id) : getCollectionData<UserBadge>("userBadges", where("user_id", "==", id))
  );
export const fetchChallengesForUser = (id: string) =>
  getOrFetch(`challengesForUser:${id}`, () =>
    IS_MOCK_MODE
      ? mock.fetchChallengesForUser(id)
      : getCollectionGroupData<ChallengeParticipant>("participants", where("user_id", "==", id))
  );
export const fetchUserNotes = (id: string) =>
  getOrFetch(`userNotes:${id}`, () =>
    IS_MOCK_MODE ? mock.fetchUserNotes(id) : getCollectionData<UserNote>(`users/${id}/notes`, orderBy("created_at", "desc"))
  );
export const addUserNote = async (id: string, _authorId: string, body: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.addUserNote(id, _authorId, body), `userNotes:${id}`);
  const result = await callFn<{ success: true; noteId: string }>("addUserNote", { userId: id, content: body });
  invalidate(`userNotes:${id}`);
  return refetchDoc<UserNote>(`users/${id}/notes/${result.noteId}`);
};
export const fetchDailySummaryForUser = (id: string, days = 30) =>
  getOrFetch(`dailySummary:${id}:${days}`, () =>
    IS_MOCK_MODE
      ? mock.fetchDailySummaryForUser(id, days)
      : getCollectionData<DailyActivitySummary>("dailyActivity", where("user_id", "==", id), orderBy("date", "desc"), limit(days))
  );
export const fetchAllDailySummaries = () =>
  getOrFetch("allDailySummaries", () =>
    IS_MOCK_MODE ? mock.fetchAllDailySummaries() : getCollectionData<DailyActivitySummary>("dailyActivity", orderBy("date", "desc"), limit(5000))
  );
export const fetchAllSessions = () =>
  getOrFetch("allSessions", () =>
    IS_MOCK_MODE ? mock.fetchAllSessions() : getCollectionData<WorkoutSession>("workoutSessions", orderBy("start_time", "desc"), limit(5000))
  );

const PROFILE_FIELD_MAP: Record<string, string> = {
  name: "name",
  username: "username",
  bio: "bio",
  location: "location",
  country: "country",
  height_cm: "heightCm",
  weight_kg: "weightKg",
  gender: "gender",
  daily_goal_steps: "dailyGoalSteps",
  units: "units",
  is_ambassador: "isAmbassador",
  tags: "tags",
};

function toUpdateUserProfilePayload(payload: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(payload)) {
    const mapped = PROFILE_FIELD_MAP[key];
    if (mapped) out[mapped] = value;
  }
  return out;
}

export const updateUser = async (id: string, payload: object) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateUser(id, payload), "users");
  await callFn("updateUserProfile", { userId: id, ...toUpdateUserProfilePayload(payload as Record<string, unknown>) });
  invalidate("users");
  return refetchDoc<UserProfile>(`users/${id}`);
};
export const updateUserPrivacy = async (id: string, payload: Record<string, boolean>) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateUserPrivacy(id, payload), "users");
  await callFn("updateUserPrivacy", { userId: id, ...payload });
  invalidate("users");
  return refetchDoc<UserProfile>(`users/${id}`);
};
export const banUser = (id: string, reason: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.banUser(id, reason) : callFn<{ success: true }>("banUser", { userId: id, reason }), "users");
export const unbanUser = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.unbanUser(id) : callFn<{ success: true }>("unbanUser", { userId: id }), "users");
export const deleteUser = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.deleteUser(id) : callFn<{ success: true }>("deleteAccount", { userId: id }), "users");
export const purgeAccountNow = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.purgeUser(id) : callFn<{ success: true }>("purgeAccountNow", { userId: id }), "users");
export const changeUserRole = (id: string, role: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.changeUserRole(id, role) : callFn<{ success: true }>("setUserRole", { userId: id, role }), "users");
export const grantPremium = (id: string, untilIso: string, reason: string) =>
  invalidateAfter(
    IS_MOCK_MODE
      ? mock.grantPremium(id, untilIso, reason)
      : callFn<{ success: true }>("grantPremium", { userId: id, untilMillis: new Date(untilIso).getTime(), reason }),
    "users"
  );
export const revokePremium = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.revokePremium(id) : callFn<{ success: true }>("revokePremium", { userId: id }), "users");
export const resetUserPassword = (id: string) =>
  IS_MOCK_MODE ? mock.resetUserPassword(id) : callFn<{ success: true }>("sendPasswordResetForUser", { userId: id });
export const sendUserEmail = (id: string, payload: { subject: string; body: string }) =>
  IS_MOCK_MODE ? mock.sendUserEmail(id, payload) : callFn<{ success: true }>("sendAdminEmail", { userId: id, ...payload });
// No standalone "warn" callable exists (warning only happens today via
// resolveReport's `action: "warn"`, which needs a report to resolve) — this
// sends the same canned guidelines-reminder copy directly.
export const warnUser = (id: string, reason: string) =>
  IS_MOCK_MODE
    ? mock.warnUser(id, reason)
    : callFn<{ success: true }>("sendAdminEmail", {
        userId: id,
        subject: "Community guidelines reminder",
        body: `<p>We wanted to flag something about your recent activity: ${reason}</p><p>Please review our community guidelines — no other action has been taken.</p>`,
      });
export const banUserFromPosting = (id: string, reason: string, until?: string | null) =>
  invalidateAfter(
    IS_MOCK_MODE
      ? mock.banUserFromPosting(id, reason, until)
      : callFn<{ success: true }>("banUserFromPosting", { userId: id, reason, untilMillis: until ? new Date(until).getTime() : undefined }),
    "users"
  );
export const unbanUserFromPosting = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.unbanUserFromPosting(id) : callFn<{ success: true }>("unbanUserFromPosting", { userId: id }), "users");

// ---------------------------------------------------------------------------
// Community
// ---------------------------------------------------------------------------

export const fetchPosts = async (includeHidden = true) => {
  return getOrFetch(`posts:${includeHidden}`, async () => {
    if (IS_MOCK_MODE) return mock.fetchPosts(includeHidden);
    const posts = await getCollectionData<CommunityPost>("communityPosts", orderBy("timestamp", "desc"), limit(200));
    return includeHidden ? posts : posts.filter((p) => !p.moderation.hidden);
  });
};
export const createPost = async (payload: { author_id: string; content: string; image_url: string | null }) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.createPost(payload), "posts");
  const result = await callFn<{ success: true; postId: string }>("createPost", {
    content: payload.content,
    imageUrl: payload.image_url,
    authorId: payload.author_id,
  });
  invalidate("posts");
  return refetchDoc<CommunityPost>(`communityPosts/${result.postId}`);
};
export const updatePost = async (
  id: string,
  payload: Partial<Pick<CommunityPost, "content" | "step_count" | "badge_emoji" | "pinned" | "comments_locked">>
) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updatePost(id, payload), "posts");
  const { pinned, comments_locked, ...contentFields } = payload;
  if (Object.keys(contentFields).length > 0) {
    await callFn("editPost", {
      postId: id,
      content: contentFields.content,
      stepCount: contentFields.step_count,
      badgeEmoji: contentFields.badge_emoji,
    });
  }
  if (pinned !== undefined) await callFn("pinPost", { postId: id, pinned });
  if (comments_locked !== undefined) await callFn("lockComments", { postId: id, locked: comments_locked });
  invalidate("posts");
  return getDocData<CommunityPost>(`communityPosts/${id}`);
};
export const hidePost = (id: string, reason: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.hidePost(id, reason) : callFn<{ success: true }>("hidePost", { postId: id, hidden: true, reason }),
    "posts"
  );
export const unhidePost = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.unhidePost(id) : callFn<{ success: true }>("hidePost", { postId: id, hidden: false }), "posts");
export const deletePost = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.deletePost(id) : callFn<{ success: true }>("deletePost", { postId: id }), "posts");
export const removePostPhoto = (id: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.removePostPhoto(id) : callFn<{ success: true }>("editPost", { postId: id, imageUrl: null }),
    "posts"
  );
export const fetchComments = () =>
  getOrFetch("comments", () =>
    IS_MOCK_MODE ? mock.fetchComments() : getCollectionGroupData<CommunityComment>("comments", orderBy("timestamp", "desc"), limit(500))
  );

async function findCommentPostId(commentId: string): Promise<string | null> {
  const matches = await getCollectionGroupData<CommunityComment>("comments", where("id", "==", commentId), limit(1));
  return matches[0]?.post_id ?? null;
}

export const updateComment = async (id: string, content: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateComment(id, content), "comments");
  const postId = await findCommentPostId(id);
  if (!postId) throw new Error("Comment not found.");
  await callFn("editComment", { postId, commentId: id, content });
  invalidate("comments");
};
export const deleteComment = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.deleteComment(id), "comments");
  const postId = await findCommentPostId(id);
  if (!postId) throw new Error("Comment not found.");
  await callFn("deleteComment", { postId, commentId: id });
  invalidate("comments");
};

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

export const fetchReports = () =>
  getOrFetch("reports", () => (IS_MOCK_MODE ? mock.fetchReports() : getCollectionData<Report>("reports", orderBy("created_at", "desc"), limit(200))));

const ACTION_TAKEN_TO_RESOLVE_ACTION: Record<string, string> = {
  warned: "warn",
  muted: "mute_24h",
  banned: "ban",
  post_removed: "remove_post",
  account_deleted: "delete_account",
  posts_deleted: "delete_all_posts",
};

export const resolveReport = async (id: string, status: string, note?: string, actionTaken?: string | null) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.resolveReport(id, status, note, actionTaken), "reports");
  const report = await getDocDataOrThrow<Report>(`reports/${id}`, "Report not found.");
  const action = actionTaken ? (ACTION_TAKEN_TO_RESOLVE_ACTION[actionTaken] ?? "dismiss") : "dismiss";
  await callFn("resolveReport", {
    reportIds: [id],
    action,
    targetType: report.target_type,
    targetId: report.target_id,
    note,
  });
  invalidate("reports");
  return refetchDoc<Report>(`reports/${id}`);
};

// ---------------------------------------------------------------------------
// Challenges
// ---------------------------------------------------------------------------

export const fetchChallenges = () =>
  getOrFetch("challenges:list", () =>
    IS_MOCK_MODE ? mock.fetchChallenges() : getCollectionData<Challenge>("challenges", orderBy("created_at", "desc"), limit(200))
  );
export const fetchChallenge = (id: string) =>
  getOrFetch(`challenges:doc:${id}`, () =>
    IS_MOCK_MODE ? mock.fetchChallenge(id) : getDocDataOrThrow<Challenge>(`challenges/${id}`, "Challenge not found.")
  );
export const createChallenge = async (payload: object) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.createChallenge(payload), "challenges");
  const p = payload as Record<string, unknown>;
  const result = await callFn<{ success: true; challengeId: string }>("createChallenge", {
    title: p.title,
    description: p.description,
    goalSteps: p.goal_steps,
    startDate: p.start_date,
    endDate: p.end_date,
    badgeEmoji: p.badge_emoji,
    accentColorValue: p.accent_color_value,
    visibility: p.visibility,
    winnerType: p.winner_type,
    imageUrl: p.image_url,
  });
  invalidate("challenges");
  return refetchDoc<Challenge>(`challenges/${result.challengeId}`);
};
// Field edits, winner/notes, and publish/archive are three different
// callables server-side — this single entry point (matching the original
// generic PATCH-shaped signature every challenge form/dialog already calls)
// routes each field to the right one, then returns the fresh document.
export const updateChallenge = async (id: string, payload: object) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateChallenge(id, payload), "challenges");
  const p = payload as Record<string, unknown>;

  if ("winner_user_id" in p || "admin_notes" in p) {
    await callFn("setChallengeWinner", {
      challengeId: id,
      winnerUserId: p.winner_user_id,
      adminNotes: p.admin_notes,
    });
  }
  if (p.status === "published") await callFn("publishChallenge", { challengeId: id });
  if (p.status === "archived") await callFn("archiveChallenge", { challengeId: id });

  const fieldEdits: Record<string, unknown> = {};
  if (p.title !== undefined) fieldEdits.title = p.title;
  if (p.description !== undefined) fieldEdits.description = p.description;
  if (p.image_url !== undefined) fieldEdits.imageUrl = p.image_url;
  if (p.rules !== undefined) fieldEdits.rules = p.rules;
  if (p.start_date !== undefined) fieldEdits.startDate = p.start_date;
  if (p.end_date !== undefined) fieldEdits.endDate = p.end_date;
  if (p.badge_emoji !== undefined) fieldEdits.badgeEmoji = p.badge_emoji;
  if (p.accent_color_value !== undefined) fieldEdits.accentColorValue = p.accent_color_value;
  if (p.goal_steps !== undefined) fieldEdits.goalSteps = p.goal_steps;
  if (Object.keys(fieldEdits).length > 0) {
    await callFn("updateChallenge", { challengeId: id, ...fieldEdits });
  }

  invalidate("challenges");
  return refetchDoc<Challenge>(`challenges/${id}`);
};
export const deleteChallenge = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.deleteChallenge(id) : callFn<{ success: true }>("deleteChallenge", { challengeId: id }), "challenges");
export const removeParticipant = (challengeId: string, userId: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.removeParticipant(challengeId, userId) : callFn<{ success: true }>("removeParticipant", { challengeId, userId }),
    "challenges",
    `leaderboard:${challengeId}`
  );
export const setOfficialMonthly = (id: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.setOfficialMonthly(id) : callFn<{ success: true }>("setOfficialMonthlyChallenge", { challengeId: id }),
    "challenges"
  );
export const fetchLeaderboard = (challengeId: string) =>
  getOrFetch(`leaderboard:${challengeId}`, () =>
    IS_MOCK_MODE
      ? mock.fetchLeaderboard(challengeId)
      : getCollectionData<ChallengeParticipant>(`challenges/${challengeId}/participants`, orderBy("steps", "desc"), limit(200))
  );

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

export const fetchBadges = () => getOrFetch("badges:list", () => (IS_MOCK_MODE ? mock.fetchBadges() : getCollectionData<Badge>("badges")));
export const fetchAllAwards = () => getOrFetch("allAwards", () => (IS_MOCK_MODE ? mock.fetchAllAwards() : getCollectionData<UserBadge>("userBadges")));
export const createBadge = async (payload: Partial<Badge> & { name: string; description: string; emoji: string }) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.createBadge(payload), "badges");
  const result = await callFn<{ success: true; badgeId: string }>("createBadge", {
    name: payload.name,
    description: payload.description,
    emoji: payload.emoji,
    requirementMetric: payload.requirement_metric,
    requirementValue: payload.requirement_value,
    enabled: payload.enabled,
    visible: payload.visible,
  });
  invalidate("badges");
  return refetchDoc<Badge>(`badges/${result.badgeId}`);
};
export const updateBadge = async (id: string, payload: Partial<Badge>) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateBadge(id, payload), "badges");
  await callFn("updateBadge", {
    badgeId: id,
    name: payload.name,
    description: payload.description,
    emoji: payload.emoji,
    requirementMetric: payload.requirement_metric,
    requirementValue: payload.requirement_value,
    enabled: payload.enabled,
    visible: payload.visible,
  });
  invalidate("badges");
  return refetchDoc<Badge>(`badges/${id}`);
};
export const deleteBadge = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.deleteBadge(id) : callFn<{ success: true }>("deleteBadge", { badgeId: id }), "badges");
export const awardBadge = async (badgeId: string, userId: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.awardBadge(badgeId, userId), "allAwards");
  await callFn("awardBadge", { userId, badgeId });
  invalidate("allAwards");
  return refetchDoc<UserBadge>(`userBadges/${userId}_${badgeId}`);
};
export const revokeBadge = (badgeId: string, userId: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.revokeBadge(badgeId, userId) : callFn<{ success: true }>("revokeBadge", { userId, badgeId }), "allAwards");

// ---------------------------------------------------------------------------
// Devices / Fleet
// ---------------------------------------------------------------------------

export const fetchAllDevices = () => getOrFetch("devices:list", () => (IS_MOCK_MODE ? mock.fetchAllDevices() : getCollectionData<Device>("devices")));
export const provisionDevice = async (payload: { serial_number: string; manufacturing_batch?: string | null }) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.provisionDevice(payload), "devices");
  const result = await callFn<{ success: true; deviceId: string }>("provisionDevice", {
    serialNumber: payload.serial_number,
    manufacturingBatch: payload.manufacturing_batch,
  });
  invalidate("devices");
  return refetchDoc<Device>(`devices/${result.deviceId}`);
};
export const adminUnpairDevice = async (id: string, _reason?: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.adminUnpairDevice(id), "devices");
  await callFn("forceUnpairDevice", { deviceId: id });
  invalidate("devices");
  return refetchDoc<Device>(`devices/${id}`);
};
export const reassignDevice = async (id: string, userId: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.reassignDevice(id, userId), "devices");
  await callFn("reassignDevice", { deviceId: id, userId });
  invalidate("devices");
  return refetchDoc<Device>(`devices/${id}`);
};
export const pushFirmwareUpdate = async (id: string, version: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.pushFirmwareUpdate(id, version), "devices");
  await callFn("pushFirmwareUpdate", { deviceId: id, version });
  invalidate("devices");
  return refetchDoc<Device>(`devices/${id}`);
};
export const markDeviceReplaced = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.markDeviceReplaced(id), "devices");
  await callFn("markDeviceReplaced", { deviceId: id });
  invalidate("devices");
  return refetchDoc<Device>(`devices/${id}`);
};
export const deleteDevice = (id: string) =>
  invalidateAfter(IS_MOCK_MODE ? mock.deleteDevice(id) : callFn<{ success: true }>("deleteDevice", { deviceId: id }), "devices");

// ---------------------------------------------------------------------------
// Feature flags
// ---------------------------------------------------------------------------

export const fetchFeatureFlags = () =>
  getOrFetch("featureFlags", () => (IS_MOCK_MODE ? mock.fetchFeatureFlags() : getCollectionData<FeatureFlag>("featureFlags")));
export const updateFeatureFlag = async (key: string, payload: { required_tier: string; description?: string | null }) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateFeatureFlag(key, payload), "featureFlags");
  await callFn("updateFeatureFlag", { key, requiredTier: payload.required_tier, description: payload.description });
  invalidate("featureFlags");
  return refetchDoc<FeatureFlag>(`featureFlags/${key}`);
};

// ---------------------------------------------------------------------------
// Analytics / telemetry
// ---------------------------------------------------------------------------

export const fetchAnalyticsEvents = (sinceDays = 30) => {
  return getOrFetch(`analyticsEvents:${sinceDays}`, () => {
    if (IS_MOCK_MODE) return mock.fetchAnalyticsEvents(sinceDays);
    const since = new Date(Date.now() - sinceDays * 24 * 3600 * 1000);
    return getCollectionData<AnalyticsEvent>("analyticsEvents", where("created_at", ">=", since), orderBy("created_at", "desc"), limit(5000));
  });
};

// No real crash-reporting pipeline wired in (Part 4 decision #4: Firebase
// Crashlytics instead of a custom collection) — always empty in real mode
// until that Flutter-side integration exists.
export const fetchCrashReports = (limit_ = 20) => (IS_MOCK_MODE ? mock.fetchCrashReports(limit_) : Promise.resolve<CrashReport[]>([]));

export const fetchSupportTickets = () =>
  getOrFetch("supportTickets", () => (IS_MOCK_MODE ? mock.fetchSupportTickets() : getCollectionData<SupportTicket>("supportTickets")));
export const fetchFirmwareFailures = () =>
  getOrFetch("firmwareFailures", () =>
    IS_MOCK_MODE ? mock.fetchFirmwareFailures() : getCollectionData<FirmwareUpdateFailure>("firmwareUpdateFailures")
  );
export const fetchAccountDeletionRequests = () =>
  getOrFetch("accountDeletionRequests", () =>
    IS_MOCK_MODE ? mock.fetchAccountDeletionRequests() : getCollectionData<AccountDeletionRequest>("accountDeletionRequests")
  );

// ---------------------------------------------------------------------------
// Push notifications
// ---------------------------------------------------------------------------

export interface PushComposePayload {
  id?: string;
  segment: PushSegment;
  title: string;
  body: string;
  linkTarget: PushLinkTarget;
  linkChallengeId: string | null;
  linkCustomPath: string | null;
  sentBy: string | null;
}

function pushPayloadToCallable(payload: PushComposePayload) {
  return {
    notificationId: payload.id,
    segment: payload.segment,
    title: payload.title,
    body: payload.body,
    linkTarget: payload.linkTarget,
    linkChallengeId: payload.linkChallengeId,
    linkCustomPath: payload.linkCustomPath,
  };
}

export const fetchPushNotifications = () =>
  getOrFetch("pushNotifications", () =>
    IS_MOCK_MODE ? mock.fetchPushNotifications() : getCollectionData<PushNotification>("pushNotifications", orderBy("created_at", "desc"), limit(200))
  );
export const saveDraftPushNotification = async (payload: PushComposePayload) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.saveDraftPushNotification(payload), "pushNotifications");
  const result = await callFn<{ success: true; notificationId: string }>("savePushNotification", pushPayloadToCallable(payload));
  invalidate("pushNotifications");
  return refetchDoc<PushNotification>(`pushNotifications/${result.notificationId}`);
};
export const schedulePushNotification = async (payload: PushComposePayload & { scheduledAt: string }) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.schedulePushNotification(payload), "pushNotifications");
  const result = await callFn<{ success: true; notificationId: string }>("savePushNotification", {
    ...pushPayloadToCallable(payload),
    scheduledAtMillis: new Date(payload.scheduledAt).getTime(),
  });
  invalidate("pushNotifications");
  return refetchDoc<PushNotification>(`pushNotifications/${result.notificationId}`);
};
export const sendPushNotification = async (payload: PushComposePayload) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.sendPushNotification(payload), "pushNotifications");
  const result = await callFn<{ success: true; notificationId: string }>("sendPushNotification", pushPayloadToCallable(payload));
  invalidate("pushNotifications");
  return refetchDoc<PushNotification>(`pushNotifications/${result.notificationId}`);
};
export const sendScheduledPushNotificationNow = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.sendScheduledPushNotificationNow(id), "pushNotifications");
  await callFn("sendPushNotification", { notificationId: id });
  invalidate("pushNotifications");
  return refetchDoc<PushNotification>(`pushNotifications/${id}`);
};
export const deletePushNotification = (id: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.deletePushNotification(id) : callFn<{ success: true }>("deletePushNotification", { notificationId: id }),
    "pushNotifications"
  );
export const sendTestPushNotification = (payload: { userId: string; title: string; body: string }) =>
  IS_MOCK_MODE ? mock.sendTestPushNotification(payload) : callFn<{ success: true }>("sendTestPush", payload);

// ---------------------------------------------------------------------------
// Integrations
// ---------------------------------------------------------------------------

export const fetchIntegrationConnections = () =>
  getOrFetch("integrationConnections", () =>
    IS_MOCK_MODE
      ? mock.fetchIntegrationConnections()
      : callFn<{ connections: IntegrationConnection[] }>("listIntegrationConnections").then((r) => r.connections)
  );
export const resyncIntegration = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.resyncIntegration(id), "integrationConnections");
  const result = await callFn<{ success: true; connection: IntegrationConnection }>("resyncIntegration", { connectionId: id });
  invalidate("integrationConnections");
  return result.connection;
};
export const disconnectIntegration = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.disconnectIntegration(id), "integrationConnections");
  const result = await callFn<{ success: true; connection: IntegrationConnection }>("disconnectIntegration", { connectionId: id });
  invalidate("integrationConnections");
  return result.connection;
};

// ---------------------------------------------------------------------------
// App content
// ---------------------------------------------------------------------------

export const fetchAppContent = () =>
  getOrFetch("appContent", () => (IS_MOCK_MODE ? mock.fetchAppContent() : getCollectionData<AppContentEntry>("appContent")));
export const updateAppContent = async (key: string, value: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateAppContent(key, value), "appContent");
  const existing = await getDocData<AppContentEntry>(`appContent/${key}`);
  await callFn("updateAppContent", {
    key,
    value,
    category: existing?.category,
    label: existing?.label,
  });
  invalidate("appContent");
  return refetchDoc<AppContentEntry>(`appContent/${key}`);
};

// ---------------------------------------------------------------------------
// Legal
// ---------------------------------------------------------------------------

export const fetchLegalVersions = () =>
  getOrFetch("legalVersions", () =>
    IS_MOCK_MODE ? mock.fetchLegalVersions() : getCollectionData<LegalDocumentVersion>("legalDocumentVersions", orderBy("created_at", "desc"), limit(200))
  );
export const fetchLegalAcceptances = () =>
  getOrFetch("legalAcceptances", () =>
    IS_MOCK_MODE ? mock.fetchLegalAcceptances() : getCollectionData<LegalAcceptance>("legalAcceptances", limit(5000))
  );

export interface LegalDraftPayload {
  id?: string;
  doc_type: LegalDocumentType;
  content: string;
  effective_date: string;
  requires_reaccept: boolean;
  created_by: string | null;
}

export const saveLegalDraft = async (payload: LegalDraftPayload) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.saveLegalDraft(payload), "legalVersions");
  if (payload.id) {
    await callFn("updateLegalDraft", {
      versionId: payload.id,
      content: payload.content,
      effectiveDate: payload.effective_date,
      requiresReaccept: payload.requires_reaccept,
    });
    invalidate("legalVersions");
    return refetchDoc<LegalDocumentVersion>(`legalDocumentVersions/${payload.id}`);
  }
  const result = await callFn<{ success: true; versionId: string; version: number }>("createLegalDraft", {
    docType: payload.doc_type,
    content: payload.content,
  });
  invalidate("legalVersions");
  return refetchDoc<LegalDocumentVersion>(`legalDocumentVersions/${result.versionId}`);
};
export const deleteLegalDraft = (id: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.deleteLegalDraft(id) : callFn<{ success: true }>("discardLegalDraft", { versionId: id }),
    "legalVersions"
  );
export const publishLegalVersion = async (id: string, changelog: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.publishLegalVersion(id, changelog), "legalVersions");
  await callFn("publishLegalVersion", { versionId: id, changelog });
  invalidate("legalVersions");
  return refetchDoc<LegalDocumentVersion>(`legalDocumentVersions/${id}`);
};
export const restoreLegalVersion = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.restoreLegalVersion(id), "legalVersions");
  const result = await callFn<{ success: true; versionId: string; version: number }>("restoreLegalVersionAsDraft", { versionId: id });
  invalidate("legalVersions");
  return refetchDoc<LegalDocumentVersion>(`legalDocumentVersions/${result.versionId}`);
};

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

// The appSettings/singleton doc doesn't exist until the first
// updateAppSettings call — this is what a fresh project should show instead
// of every settings-dependent page crashing on a null value.
const DEFAULT_APP_SETTINGS: AppSettings = {
  default_daily_goal_steps: 10000,
  challenge_default_duration_days: 30,
  notify_goal_reminder_default: true,
  notify_streak_default: true,
  notify_challenge_updates_default: true,
  max_image_size_mb: 10,
  max_post_length: 1000,
  max_bio_length: 200,
  trial_period_days: 30,
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
  updated_at: new Date(0).toISOString(),
};

export const fetchAppSettings = () =>
  getOrFetch("appSettings", async () => {
    if (IS_MOCK_MODE) return mock.fetchAppSettings();
    const settings = await getDocData<AppSettings>("appSettings/singleton");
    return settings ?? DEFAULT_APP_SETTINGS;
  });
export const updateAppSettings = async (payload: Partial<AppSettings>) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateAppSettings(payload), "appSettings");
  await callFn("updateAppSettings", payload);
  invalidate("appSettings");
  const settings = await getDocData<AppSettings>("appSettings/singleton");
  return settings ?? DEFAULT_APP_SETTINGS;
};
export const forceLogoutAllUsers = async () => {
  if (IS_MOCK_MODE) return mock.forceLogoutAllUsers();
  const result = await callFn<{ success: true; revokedCount: number }>("forceLogoutAllUsers", {});
  return { loggedOut: result.revokedCount };
};

// ---------------------------------------------------------------------------
// Beta overrides
// ---------------------------------------------------------------------------

export const fetchBetaOverrides = () =>
  getOrFetch("betaOverrides", () => (IS_MOCK_MODE ? mock.fetchBetaOverrides() : getCollectionData<BetaOverride>("betaOverrides")));
export const createBetaOverride = async (payload: {
  feature_key: string;
  target_type: BetaOverride["target_type"];
  target_value: string;
  created_by: string | null;
}) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.createBetaOverride(payload), "betaOverrides");
  const result = await callFn<{ success: true; overrideId: string }>("grantBetaOverride", {
    featureKey: payload.feature_key,
    targetType: payload.target_type,
    targetValue: payload.target_value,
  });
  invalidate("betaOverrides");
  return refetchDoc<BetaOverride>(`betaOverrides/${result.overrideId}`);
};
export const deleteBetaOverride = (id: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.deleteBetaOverride(id) : callFn<{ success: true }>("revokeBetaOverride", { overrideId: id }),
    "betaOverrides"
  );

// ---------------------------------------------------------------------------
// Announcements
// ---------------------------------------------------------------------------

function announcementPayloadToCallable(payload: Partial<Announcement>) {
  return {
    emoji: payload.emoji,
    message: payload.message,
    linkTarget: payload.link_target,
    audience: payload.audience,
    audienceAppVersion: payload.audience_app_version,
    audienceAppVersionMode: payload.audience_app_version_mode,
    startsAtMillis: payload.starts_at ? new Date(payload.starts_at).getTime() : undefined,
    endsAtMillis: payload.ends_at ? new Date(payload.ends_at).getTime() : undefined,
  };
}

export const fetchAnnouncements = () =>
  getOrFetch("announcements", () =>
    IS_MOCK_MODE ? mock.fetchAnnouncements() : getCollectionData<Announcement>("announcements", orderBy("created_at", "desc"), limit(200))
  );
export const createAnnouncement = async (payload: Partial<Announcement> & { message: string; created_by: string | null }) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.createAnnouncement(payload), "announcements");
  const result = await callFn<{ success: true; announcementId: string }>("createAnnouncement", announcementPayloadToCallable(payload));
  invalidate("announcements");
  return refetchDoc<Announcement>(`announcements/${result.announcementId}`);
};
export const updateAnnouncement = async (id: string, payload: Partial<Announcement>) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.updateAnnouncement(id, payload), "announcements");
  const { active, ...rest } = payload;
  if (Object.keys(rest).length > 0) {
    await callFn("updateAnnouncement", { announcementId: id, ...announcementPayloadToCallable(rest) });
  }
  if (active !== undefined) {
    await callFn("toggleAnnouncement", { announcementId: id, active });
  }
  invalidate("announcements");
  return refetchDoc<Announcement>(`announcements/${id}`);
};
export const duplicateAnnouncement = async (id: string) => {
  if (IS_MOCK_MODE) return invalidateAfter(mock.duplicateAnnouncement(id), "announcements");
  const result = await callFn<{ success: true; announcementId: string }>("duplicateAnnouncement", { announcementId: id });
  invalidate("announcements");
  return refetchDoc<Announcement>(`announcements/${result.announcementId}`);
};
export const deleteAnnouncement = (id: string) =>
  invalidateAfter(
    IS_MOCK_MODE ? mock.deleteAnnouncement(id) : callFn<{ success: true }>("deleteAnnouncement", { announcementId: id }),
    "announcements"
  );
