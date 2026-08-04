import type { defineSecret } from "firebase-functions/params";
import {
  STRAVA_CLIENT_ID,
  STRAVA_CLIENT_SECRET,
  GARMIN_CLIENT_ID,
  GARMIN_CLIENT_SECRET,
  OURA_CLIENT_ID,
  OURA_CLIENT_SECRET,
  MYFITNESSPAL_CLIENT_ID,
  MYFITNESSPAL_CLIENT_SECRET,
} from "../lib/secrets";

export type OAuthProvider = "strava" | "garmin" | "oura" | "myfitnesspal";
export type OnDeviceProvider = "healthkit" | "health_connect";
export type IntegrationProvider = OAuthProvider | OnDeviceProvider;

type SecretParam = ReturnType<typeof defineSecret>;

export interface OAuthProviderConfig {
  authorizeUrl: string;
  tokenUrl: string;
  scope: string;
  clientId: SecretParam;
  clientSecret: SecretParam;
}

/**
 * Garmin is flagged "Pending approval" in the client's own UI copy (per the
 * Flutter audit) — wired here with the same shape as Strava/Oura so the rest
 * of the pipeline (connect/callback/resync/scheduled sync) is ready the
 * moment API access is granted, but its client id/secret will be empty
 * until then and startOAuthConnect will fail fast for it in the meantime.
 *
 * MyFitnessPal is the same situation but stronger: Under Armour closed
 * public self-serve API registration in 2019 — there is no public
 * authorize/token URL to point at without a signed partnership. `authorizeUrl`
 * / `tokenUrl` are deliberately left blank rather than guessed; fill them in
 * once the client has real partner credentials + endpoint docs from
 * MyFitnessPal, at which point this config (and startOAuthConnect's
 * fail-fast check) starts working with no other code changes needed.
 */
export const OAUTH_PROVIDERS: Record<OAuthProvider, OAuthProviderConfig> = {
  strava: {
    authorizeUrl: "https://www.strava.com/oauth/authorize",
    tokenUrl: "https://www.strava.com/oauth/token",
    scope: "activity:read_all",
    clientId: STRAVA_CLIENT_ID,
    clientSecret: STRAVA_CLIENT_SECRET,
  },
  oura: {
    authorizeUrl: "https://cloud.ouraring.com/oauth/authorize",
    tokenUrl: "https://api.ouraring.com/oauth/token",
    scope: "daily activity",
    clientId: OURA_CLIENT_ID,
    clientSecret: OURA_CLIENT_SECRET,
  },
  garmin: {
    authorizeUrl: "https://connect.garmin.com/oauth2Confirm",
    tokenUrl: "https://diauth.garmin.com/di-oauth2-service/oauth/token",
    scope: "",
    clientId: GARMIN_CLIENT_ID,
    clientSecret: GARMIN_CLIENT_SECRET,
  },
  myfitnesspal: {
    authorizeUrl: "", // TODO: fill in once a MyFitnessPal partnership grants real endpoints
    tokenUrl: "", // TODO: same
    scope: "",
    clientId: MYFITNESSPAL_CLIENT_ID,
    clientSecret: MYFITNESSPAL_CLIENT_SECRET,
  },
};

export function isOAuthProvider(provider: string): provider is OAuthProvider {
  return provider === "strava" || provider === "garmin" || provider === "oura" || provider === "myfitnesspal";
}

export function isOnDeviceProvider(provider: string): provider is OnDeviceProvider {
  return provider === "healthkit" || provider === "health_connect";
}
