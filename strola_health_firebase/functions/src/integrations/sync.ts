import { Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { OAUTH_PROVIDERS, isOAuthProvider } from "./providerConfig";
import { mergeDailyActivity, writeWorkoutSessionCore } from "../health/ingestCore";
import type { IntegrationConnection, WorkoutSession } from "../lib/types";

interface TokenResponse {
  access_token: string;
  refresh_token?: string;
  expires_in?: number;
}

async function getValidAccessToken(connection: IntegrationConnection): Promise<string> {
  const provider = connection.provider;
  if (!isOAuthProvider(provider)) throw new Error(`${provider} has no token refresh flow.`);
  const config = OAUTH_PROVIDERS[provider];

  const stillValid = connection.expires_at && connection.expires_at.toMillis() > Date.now() + 60_000;
  if (stillValid || !connection.refresh_token) {
    if (!connection.access_token) throw new Error("No access token on file.");
    return connection.access_token;
  }

  const res = await fetch(config.tokenUrl, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: config.clientId.value(),
      client_secret: config.clientSecret.value(),
      refresh_token: connection.refresh_token,
      grant_type: "refresh_token",
    }),
  });
  if (!res.ok) throw new Error(`Token refresh failed for ${provider} (${res.status}).`);
  const tokens = (await res.json()) as TokenResponse;

  await db
    .collection(Collections.integrationConnections)
    .doc(connection.id)
    .update({
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token ?? connection.refresh_token,
      expires_at: tokens.expires_in
        ? Timestamp.fromMillis(Date.now() + tokens.expires_in * 1000)
        : null,
    });

  return tokens.access_token;
}

const STRAVA_TYPE_MAP: Record<string, WorkoutSession["activity_type"]> = {
  Run: "outdoor_run",
  Walk: "outdoor_walk",
  Hike: "outdoor_walk",
  Ride: "biking",
  VirtualRide: "biking",
  Workout: "other",
};

interface StravaActivity {
  id: number;
  type: string;
  start_date: string;
  elapsed_time: number;
  distance: number;
  calories?: number;
  average_speed?: number;
}

async function syncStrava(connection: IntegrationConnection): Promise<void> {
  const accessToken = await getValidAccessToken(connection);
  const after = connection.last_synced_at
    ? Math.floor(connection.last_synced_at.toMillis() / 1000)
    : Math.floor(Date.now() / 1000) - 30 * 24 * 3600;

  const res = await fetch(
    `https://www.strava.com/api/v3/athlete/activities?after=${after}&per_page=50`,
    { headers: { Authorization: `Bearer ${accessToken}` } }
  );
  if (!res.ok) throw new Error(`Strava activities fetch failed (${res.status}).`);
  const activities = (await res.json()) as StravaActivity[];

  for (const activity of activities) {
    const startTime = new Date(activity.start_date);
    const endTime = new Date(startTime.getTime() + activity.elapsed_time * 1000);
    const activityType = STRAVA_TYPE_MAP[activity.type] ?? "other";

    await writeWorkoutSessionCore({
      id: `strava_${activity.id}`,
      user_id: connection.user_id,
      start_time: Timestamp.fromDate(startTime),
      end_time: Timestamp.fromDate(endTime),
      steps: 0, // Strava doesn't report steps, only distance/time
      distance_meters: activity.distance,
      duration_seconds: activity.elapsed_time,
      activity_type: activityType,
      custom_activity_name: activityType === "other" ? activity.type : null,
      route_polyline: null,
      avg_pace_sec_per_km: activity.average_speed ? Math.round(1000 / activity.average_speed) : null,
      calories_burned: activity.calories ?? null,
      source: "strava",
      external_id: String(activity.id),
    });

    await mergeDailyActivity({
      userId: connection.user_id,
      date: startTime.toISOString().slice(0, 10),
      source: "strava",
      distanceMeters: activity.distance,
      calories: activity.calories ?? 0,
    });
  }
}

interface OuraDailyActivity {
  day: string;
  steps: number;
  active_calories: number;
}

async function syncOura(connection: IntegrationConnection): Promise<void> {
  const accessToken = await getValidAccessToken(connection);
  const startDate = connection.last_synced_at
    ? new Date(connection.last_synced_at.toMillis()).toISOString().slice(0, 10)
    : new Date(Date.now() - 30 * 24 * 3600 * 1000).toISOString().slice(0, 10);
  const endDate = new Date().toISOString().slice(0, 10);

  const res = await fetch(
    `https://api.ouraring.com/v2/usercollection/daily_activity?start_date=${startDate}&end_date=${endDate}`,
    { headers: { Authorization: `Bearer ${accessToken}` } }
  );
  if (!res.ok) throw new Error(`Oura daily activity fetch failed (${res.status}).`);
  const body = (await res.json()) as { data: OuraDailyActivity[] };

  for (const day of body.data) {
    await mergeDailyActivity({
      userId: connection.user_id,
      date: day.day,
      source: "oura",
      steps: day.steps,
      calories: day.active_calories,
    });
  }
}

/** Function #59's per-connection worker — also called directly by
 * resyncIntegration (#57) for an on-demand pull. */
export async function syncProviderConnection(connectionId: string): Promise<void> {
  const snap = await db.collection(Collections.integrationConnections).doc(connectionId).get();
  if (!snap.exists) throw new Error("Connection not found.");
  const connection = { id: connectionId, ...(snap.data() as Omit<IntegrationConnection, "id">) };

  switch (connection.provider) {
    case "strava":
      return syncStrava(connection);
    case "oura":
      return syncOura(connection);
    case "garmin":
      throw new Error("Garmin integration is pending API approval — sync not available yet.");
    case "myfitnesspal":
      throw new Error(
        "MyFitnessPal integration is pending partner API access — MyFitnessPal has no public developer signup, sync not available yet."
      );
    default:
      throw new Error(`${connection.provider} has no OAuth sync path (on-device source).`);
  }
}
