// Mutable, in-memory copies of the mock dataset — the backing store for
// mock-api.ts when IS_MOCK_MODE is on. Cloned once per page load (module
// scope), so mutations within a session persist across navigations but
// reset on refresh, same as the pre-wiring local-state demo behaved.
import {
  mockAnalyticsEvents as seedAnalyticsEvents,
  mockAnnouncements as seedAnnouncements,
  mockAppContent as seedAppContent,
  mockAppSettings as seedAppSettings,
  mockBadges as seedBadges,
  mockBetaOverrides as seedBetaOverrides,
  mockChallenges as seedChallenges,
  mockComments as seedComments,
  mockCrashReports as seedCrashReports,
  mockDailySummaries as seedDailySummaries,
  mockDevices as seedDevices,
  mockFeatureFlags as seedFeatureFlags,
  mockIntegrationConnections as seedIntegrationConnections,
  mockLegalDocuments as seedLegalDocuments,
  mockParticipants as seedParticipants,
  mockPosts as seedPosts,
  mockPushNotifications as seedPushNotifications,
  mockReports as seedReports,
  mockSessions as seedSessions,
  mockUserBadges as seedUserBadges,
  mockUsers as seedUsers,
} from "@/lib/data/mock-data";

function clone<T>(value: T): T {
  return typeof structuredClone === "function" ? structuredClone(value) : JSON.parse(JSON.stringify(value));
}

export const mockUsers = clone(seedUsers);
export const mockDevices = clone(seedDevices);
export const mockDailySummaries = clone(seedDailySummaries);
export const mockSessions = clone(seedSessions);
export const mockPosts = clone(seedPosts);
export const mockComments = clone(seedComments);
export const mockReports = clone(seedReports);
export const mockChallenges = clone(seedChallenges);
export const mockParticipants = clone(seedParticipants);
export const mockBadges = clone(seedBadges);
export const mockUserBadges = clone(seedUserBadges);
export const mockFeatureFlags = clone(seedFeatureFlags);
export const mockAnalyticsEvents = clone(seedAnalyticsEvents);
export const mockCrashReports = clone(seedCrashReports);
export const mockPushNotifications = clone(seedPushNotifications);
export const mockIntegrationConnections = clone(seedIntegrationConnections);
export const mockAppContent = clone(seedAppContent);
export const mockLegalDocuments = clone(seedLegalDocuments);
export const mockAppSettings = clone(seedAppSettings);
export const mockBetaOverrides = clone(seedBetaOverrides);
export const mockAnnouncements = clone(seedAnnouncements);

let counter = 0;
export function nextId(prefix: string): string {
  counter += 1;
  return `${prefix}_${Date.now()}_${counter}`;
}
