// Reference only, every integration a user can currently connect from the
// mobile app, regardless of whether anyone's actually connected one yet.
// Status here should track strola_health_firebase/README.md's secrets table,
// keep in sync if a provider's credentials change status.
export type IntegrationStatus = "live" | "pending_credentials" | "pending_approval" | "deferred" | "needs_partnership";

export const INTEGRATION_STATUS_LABEL: Record<IntegrationStatus, string> = {
  live: "Live",
  pending_credentials: "Ready, pending credentials",
  pending_approval: "Pending approval",
  deferred: "Deferred",
  needs_partnership: "Needs partnership",
};

export interface IntegrationCatalogEntry {
  provider: string;
  label: string;
  platform: string;
  status: IntegrationStatus;
  note: string;
}

export const INTEGRATION_CATALOG: IntegrationCatalogEntry[] = [
  {
    provider: "healthkit",
    label: "Apple Health",
    platform: "iOS",
    status: "live",
    note: "On-device read permission, no OAuth or secrets involved. Live for every iOS user.",
  },
  {
    provider: "health_connect",
    label: "Health Connect",
    platform: "Android",
    status: "live",
    note: "On-device read permission, Android's equivalent of Apple Health. Live for every Android user.",
  },
  {
    provider: "strava",
    label: "Strava",
    platform: "iOS & Android",
    status: "pending_credentials",
    note: "Client has real Strava app credentials ready to hand over, this goes live as soon as they're swapped in, no redeploy needed.",
  },
  {
    provider: "garmin",
    label: "Garmin",
    platform: "iOS & Android",
    status: "pending_approval",
    note: "Client has applied to the Garmin Connect Developer Program, awaiting approval.",
  },
  {
    provider: "oura",
    label: "Oura",
    platform: "iOS & Android",
    status: "deferred",
    note: "Deliberately deferred, Oura requires owning a ring to create a developer account. Client may revisit later.",
  },
  {
    provider: "myfitnesspal",
    label: "MyFitnessPal",
    platform: "iOS & Android",
    status: "needs_partnership",
    note: "No public developer signup exists (Under Armour closed it in 2019), needs a direct partnership with them.",
  },
];
