import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import type { AnalyticsEventType } from "../lib/types";

const VALID_EVENT_TYPES: AnalyticsEventType[] = [
  "account_created",
  "app_opened",
  "tracker_paired",
  "workout_started",
  "workout_completed",
  "steps_shared",
  "community_post_created",
  "challenge_joined",
  "challenge_completed",
  "premium_started",
  "premium_cancelled",
  "widget_enabled",
  "health_app_connected",
  "screen_viewed",
];

/**
 * Function #60. Master event log every rollup (#61/#62) derives from —
 * Part 4 decision #3: a real Cloud Function write path (validated,
 * abuse-resistant) rather than a direct client write to Firestore.
 */
export const logAnalyticsEvent = onCall(async (request) => {
  const uid = requireAuth(request);
  const { eventType, metadata } = (request.data ?? {}) as {
    eventType?: AnalyticsEventType;
    metadata?: Record<string, unknown>;
  };
  if (!eventType || !VALID_EVENT_TYPES.includes(eventType)) {
    invalidArgument(`eventType must be one of: ${VALID_EVENT_TYPES.join(", ")}.`);
  }

  const ref = db.collection(Collections.analyticsEvents).doc();
  await ref.set({
    id: ref.id,
    event_type: eventType,
    user_id: uid,
    metadata: metadata ?? {},
    created_at: FieldValue.serverTimestamp(),
  });

  return { success: true };
});
