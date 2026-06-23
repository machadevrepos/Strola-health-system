import { api } from "@/lib/api-client";
import { IS_MOCK_MODE } from "@/lib/mock-mode";
import * as mock from "@/lib/data/mock-api";
import type {
  AnalyticsEvent,
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

// Thin, one-to-one wrappers over the real FastAPI endpoints — no
// enrichment/sorting here (that lives in queries.ts as pure functions over
// already-fetched arrays). Swapping an endpoint shape only ever touches this
// file. Every path/param here is verified against the live OpenAPI spec, not
// guessed — this backend uses query params (not a JSON body) for any
// endpoint whose handler takes plain str/int/bool/datetime/enum arguments
// instead of a Pydantic model.
//
// Every export below delegates to mock-api.ts instead when IS_MOCK_MODE is
// on (see lib/mock-mode.ts) — that's the one switch this whole app's data
// layer hangs off, so no page or component needs to know which mode it's in.
function qs(params: Record<string, string | number | boolean | undefined>): string {
  const entries = Object.entries(params).filter(([, v]) => v !== undefined);
  if (entries.length === 0) return "";
  return "?" + entries.map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`).join("&");
}

export const fetchUsers = () => (IS_MOCK_MODE ? mock.fetchUsers() : api.get<UserProfile[]>("/admin/users?limit=500"));
export const fetchUser = (id: string) => (IS_MOCK_MODE ? mock.fetchUser(id) : api.get<UserProfile>(`/admin/users/${id}`));
export const fetchSessionsForUser = (id: string) => (IS_MOCK_MODE ? mock.fetchSessionsForUser(id) : api.get<WorkoutSession[]>(`/admin/users/${id}/sessions?limit=200`));
export const fetchDevicesForUser = (id: string) => (IS_MOCK_MODE ? mock.fetchDevicesForUser(id) : api.get<Device[]>(`/admin/users/${id}/devices`));
export const fetchBadgesForUser = (id: string) => (IS_MOCK_MODE ? mock.fetchBadgesForUser(id) : api.get<UserBadge[]>(`/admin/users/${id}/badges`));
export const fetchChallengesForUser = (id: string) => (IS_MOCK_MODE ? mock.fetchChallengesForUser(id) : api.get<ChallengeParticipant[]>(`/admin/users/${id}/challenges`));
export const fetchDailySummaryForUser = (id: string, days = 30) => (IS_MOCK_MODE ? mock.fetchDailySummaryForUser(id, days) : api.get<DailyActivitySummary[]>(`/admin/users/${id}/daily-summaries${qs({ days })}`));

export const updateUser = (id: string, payload: object) => (IS_MOCK_MODE ? mock.updateUser(id, payload) : api.patch<UserProfile>(`/admin/users/${id}`, payload));
export const updateUserPrivacy = (id: string, payload: Record<string, boolean>) => (IS_MOCK_MODE ? mock.updateUserPrivacy(id, payload) : api.patch<UserProfile>(`/admin/users/${id}/privacy`, payload));
export const banUser = (id: string, reason: string) => (IS_MOCK_MODE ? mock.banUser(id, reason) : api.post<void>(`/admin/users/${id}/ban${qs({ reason })}`));
export const unbanUser = (id: string) => (IS_MOCK_MODE ? mock.unbanUser(id) : api.post<void>(`/admin/users/${id}/unban`));
export const deleteUser = (id: string) => (IS_MOCK_MODE ? mock.deleteUser(id) : api.delete<void>(`/admin/users/${id}`));
export const changeUserRole = (id: string, role: string) => (IS_MOCK_MODE ? mock.changeUserRole(id, role) : api.post<void>(`/admin/users/${id}/role${qs({ role })}`));
// `until` must be an ISO 8601 datetime string — FastAPI parses it as a query-param datetime.
export const grantPremium = (id: string, untilIso: string, reason: string) => (IS_MOCK_MODE ? mock.grantPremium(id, untilIso, reason) : api.post<void>(`/admin/users/${id}/grant-premium${qs({ until: untilIso, reason })}`));
export const revokePremium = (id: string) => (IS_MOCK_MODE ? mock.revokePremium(id) : api.post<void>(`/admin/users/${id}/revoke-premium`));

export const fetchPosts = (includeHidden = true) => (IS_MOCK_MODE ? mock.fetchPosts(includeHidden) : api.get<CommunityPost[]>(`/admin/posts${qs({ limit: 200, include_hidden: includeHidden })}`));
export const updatePost = (id: string, payload: { content?: string; step_count?: number; badge_emoji?: string }) => (IS_MOCK_MODE ? mock.updatePost(id, payload) : api.patch<CommunityPost>(`/admin/posts/${id}`, payload));
export const hidePost = (id: string, reason: string) => (IS_MOCK_MODE ? mock.hidePost(id, reason) : api.post<void>(`/admin/posts/${id}/hide${qs({ reason })}`));
export const unhidePost = (id: string) => (IS_MOCK_MODE ? mock.unhidePost(id) : api.post<void>(`/admin/posts/${id}/unhide`));
export const deletePost = (id: string) => (IS_MOCK_MODE ? mock.deletePost(id) : api.delete<void>(`/admin/posts/${id}`));
export const removePostPhoto = (id: string) => (IS_MOCK_MODE ? mock.removePostPhoto(id) : api.delete<void>(`/admin/posts/${id}/photo`));

export const fetchReports = () => (IS_MOCK_MODE ? mock.fetchReports() : api.get<Report[]>("/admin/reports?limit=200"));
export const resolveReport = (id: string, status: string, note?: string) => (IS_MOCK_MODE ? mock.resolveReport(id, status, note) : api.post<Report>(`/admin/reports/${id}/resolve`, { status, resolution_note: note ?? null }));

export const fetchChallenges = () => (IS_MOCK_MODE ? mock.fetchChallenges() : api.get<Challenge[]>("/admin/challenges?limit=200"));
export const fetchChallenge = (id: string) => (IS_MOCK_MODE ? mock.fetchChallenge(id) : api.get<Challenge>(`/admin/challenges/${id}`));
export const createChallenge = (payload: object) => (IS_MOCK_MODE ? mock.createChallenge(payload) : api.post<Challenge>("/admin/challenges", payload));
export const updateChallenge = (id: string, payload: object) => (IS_MOCK_MODE ? mock.updateChallenge(id, payload) : api.patch<Challenge>(`/admin/challenges/${id}`, payload));
export const deleteChallenge = (id: string) => (IS_MOCK_MODE ? mock.deleteChallenge(id) : api.delete<void>(`/admin/challenges/${id}`));
export const removeParticipant = (challengeId: string, userId: string) => (IS_MOCK_MODE ? mock.removeParticipant(challengeId, userId) : api.delete<void>(`/admin/challenges/${challengeId}/participants/${userId}`));
export const setOfficialMonthly = (id: string) => (IS_MOCK_MODE ? mock.setOfficialMonthly(id) : api.post<void>(`/admin/challenges/${id}/set-official-monthly`));
export const fetchLeaderboard = (challengeId: string) => (IS_MOCK_MODE ? mock.fetchLeaderboard(challengeId) : api.get<ChallengeParticipant[]>(`/challenges/${challengeId}/leaderboard?limit=200`));

export const fetchBadges = () => (IS_MOCK_MODE ? mock.fetchBadges() : api.get<Badge[]>("/admin/badges"));
export const fetchAllAwards = () => (IS_MOCK_MODE ? mock.fetchAllAwards() : api.get<UserBadge[]>("/admin/badges/awards"));
export const createBadge = (payload: { name: string; description: string; emoji: string }) => (IS_MOCK_MODE ? mock.createBadge(payload) : api.post<Badge>("/admin/badges", payload));
export const updateBadge = (id: string, payload: Partial<{ name: string; description: string; emoji: string }>) => (IS_MOCK_MODE ? mock.updateBadge(id, payload) : api.patch<Badge>(`/admin/badges/${id}`, payload));
export const deleteBadge = (id: string) => (IS_MOCK_MODE ? mock.deleteBadge(id) : api.delete<void>(`/admin/badges/${id}`));
export const awardBadge = (badgeId: string, userId: string) => (IS_MOCK_MODE ? mock.awardBadge(badgeId, userId) : api.post<UserBadge>(`/admin/badges/${badgeId}/award/${userId}`));
export const revokeBadge = (badgeId: string, userId: string) => (IS_MOCK_MODE ? mock.revokeBadge(badgeId, userId) : api.delete<void>(`/admin/badges/${badgeId}/award/${userId}`));

export const fetchAllDevices = () => (IS_MOCK_MODE ? mock.fetchAllDevices() : api.get<Device[]>("/admin/devices?limit=500"));
export const provisionDevice = (payload: { serial_number: string; manufacturing_batch?: string | null }) => (IS_MOCK_MODE ? mock.provisionDevice(payload) : api.post<Device>("/admin/devices", payload));
export const adminUnpairDevice = (id: string, reason?: string) => (IS_MOCK_MODE ? mock.adminUnpairDevice(id) : api.post<void>(`/admin/devices/${id}/unpair${qs({ reason })}`));

export const fetchFeatureFlags = () => (IS_MOCK_MODE ? mock.fetchFeatureFlags() : api.get<FeatureFlag[]>("/admin/system/feature-flags"));
export const updateFeatureFlag = (key: string, payload: { required_tier: string; description?: string | null }) => (IS_MOCK_MODE ? mock.updateFeatureFlag(key, payload) : api.put<FeatureFlag>(`/admin/system/feature-flags/${key}`, payload));

export const fetchAnalyticsEvents = (sinceDays = 30) => (IS_MOCK_MODE ? mock.fetchAnalyticsEvents(sinceDays) : api.get<AnalyticsEvent[]>(`/admin/analytics/events${qs({ since_days: sinceDays })}`));
