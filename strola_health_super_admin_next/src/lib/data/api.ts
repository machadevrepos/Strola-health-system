import { api } from "@/lib/api-client";
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
function qs(params: Record<string, string | number | boolean | undefined>): string {
  const entries = Object.entries(params).filter(([, v]) => v !== undefined);
  if (entries.length === 0) return "";
  return "?" + entries.map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`).join("&");
}

export const fetchUsers = () => api.get<UserProfile[]>("/admin/users?limit=500");
export const fetchUser = (id: string) => api.get<UserProfile>(`/admin/users/${id}`);
export const fetchSessionsForUser = (id: string) => api.get<WorkoutSession[]>(`/admin/users/${id}/sessions?limit=200`);
export const fetchDevicesForUser = (id: string) => api.get<Device[]>(`/admin/users/${id}/devices`);
export const fetchBadgesForUser = (id: string) => api.get<UserBadge[]>(`/admin/users/${id}/badges`);
export const fetchChallengesForUser = (id: string) => api.get<ChallengeParticipant[]>(`/admin/users/${id}/challenges`);
export const fetchDailySummaryForUser = (id: string, days = 30) => api.get<DailyActivitySummary[]>(`/admin/users/${id}/daily-summaries${qs({ days })}`);

export const updateUser = (id: string, payload: object) => api.patch<UserProfile>(`/admin/users/${id}`, payload);
export const updateUserPrivacy = (id: string, payload: Record<string, boolean>) => api.patch<UserProfile>(`/admin/users/${id}/privacy`, payload);
export const banUser = (id: string, reason: string) => api.post<void>(`/admin/users/${id}/ban${qs({ reason })}`);
export const unbanUser = (id: string) => api.post<void>(`/admin/users/${id}/unban`);
export const deleteUser = (id: string) => api.delete<void>(`/admin/users/${id}`);
export const changeUserRole = (id: string, role: string) => api.post<void>(`/admin/users/${id}/role${qs({ role })}`);
// `until` must be an ISO 8601 datetime string — FastAPI parses it as a query-param datetime.
export const grantPremium = (id: string, untilIso: string, reason: string) => api.post<void>(`/admin/users/${id}/grant-premium${qs({ until: untilIso, reason })}`);
export const revokePremium = (id: string) => api.post<void>(`/admin/users/${id}/revoke-premium`);

export const fetchPosts = (includeHidden = true) => api.get<CommunityPost[]>(`/admin/posts${qs({ limit: 200, include_hidden: includeHidden })}`);
export const updatePost = (id: string, payload: { content?: string; step_count?: number; badge_emoji?: string }) => api.patch<CommunityPost>(`/admin/posts/${id}`, payload);
export const hidePost = (id: string, reason: string) => api.post<void>(`/admin/posts/${id}/hide${qs({ reason })}`);
export const unhidePost = (id: string) => api.post<void>(`/admin/posts/${id}/unhide`);
export const deletePost = (id: string) => api.delete<void>(`/admin/posts/${id}`);
export const removePostPhoto = (id: string) => api.delete<void>(`/admin/posts/${id}/photo`);

export const fetchReports = () => api.get<Report[]>("/admin/reports?limit=200");
export const resolveReport = (id: string, status: string, note?: string) => api.post<Report>(`/admin/reports/${id}/resolve`, { status, resolution_note: note ?? null });

export const fetchChallenges = () => api.get<Challenge[]>("/admin/challenges?limit=200");
export const fetchChallenge = (id: string) => api.get<Challenge>(`/admin/challenges/${id}`);
export const createChallenge = (payload: object) => api.post<Challenge>("/admin/challenges", payload);
export const updateChallenge = (id: string, payload: object) => api.patch<Challenge>(`/admin/challenges/${id}`, payload);
export const deleteChallenge = (id: string) => api.delete<void>(`/admin/challenges/${id}`);
export const removeParticipant = (challengeId: string, userId: string) => api.delete<void>(`/admin/challenges/${challengeId}/participants/${userId}`);
export const setOfficialMonthly = (id: string) => api.post<void>(`/admin/challenges/${id}/set-official-monthly`);
export const fetchLeaderboard = (challengeId: string) => api.get<ChallengeParticipant[]>(`/challenges/${challengeId}/leaderboard?limit=200`);

export const fetchBadges = () => api.get<Badge[]>("/admin/badges");
export const fetchAllAwards = () => api.get<UserBadge[]>("/admin/badges/awards");
export const createBadge = (payload: { name: string; description: string; emoji: string }) => api.post<Badge>("/admin/badges", payload);
export const updateBadge = (id: string, payload: Partial<{ name: string; description: string; emoji: string }>) => api.patch<Badge>(`/admin/badges/${id}`, payload);
export const deleteBadge = (id: string) => api.delete<void>(`/admin/badges/${id}`);
export const awardBadge = (badgeId: string, userId: string) => api.post<UserBadge>(`/admin/badges/${badgeId}/award/${userId}`);
export const revokeBadge = (badgeId: string, userId: string) => api.delete<void>(`/admin/badges/${badgeId}/award/${userId}`);

export const fetchAllDevices = () => api.get<Device[]>("/admin/devices?limit=500");
export const provisionDevice = (payload: { serial_number: string; manufacturing_batch?: string | null }) => api.post<Device>("/admin/devices", payload);
export const adminUnpairDevice = (id: string, reason?: string) => api.post<void>(`/admin/devices/${id}/unpair${qs({ reason })}`);

export const fetchFeatureFlags = () => api.get<FeatureFlag[]>("/admin/system/feature-flags");
export const updateFeatureFlag = (key: string, payload: { required_tier: string; description?: string | null }) => api.put<FeatureFlag>(`/admin/system/feature-flags/${key}`, payload);

export const fetchAnalyticsEvents = (sinceDays = 30) => api.get<AnalyticsEvent[]>(`/admin/analytics/events${qs({ since_days: sinceDays })}`);
