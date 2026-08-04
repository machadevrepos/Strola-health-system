import { onCall } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { UserProfile } from "../lib/types";

/**
 * Function #45a. The comp path — entirely independent of RevenueCat, only
 * ever touches `comp_until`/`comp_reason` (see revenueCatWebhook.ts). One
 * mechanism covers every non-paid premium grant: signup trial, Kickstarter
 * reward, admin comp, all just this field with a different reason string.
 */
export const grantPremium = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, untilMillis, reason } = (request.data ?? {}) as {
    userId?: string;
    untilMillis?: number;
    reason?: string;
  };
  if (!userId || !untilMillis) invalidArgument("userId and untilMillis are required.");

  const ref = db.collection(Collections.users).doc(userId);
  const snap = await ref.get();
  if (!snap.exists) notFound("User not found.");

  await ref.update({
    "subscription.comp_until": Timestamp.fromMillis(untilMillis),
    "subscription.comp_reason": reason ?? "admin_grant",
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "grant_premium",
    target: userId,
    metadata: { until_millis: untilMillis, reason: reason ?? "admin_grant" },
  });
  return { success: true };
});

/** Function #45b. Extends from the current comp_until if still in the
 * future, else from now — matching the admin panel's "Extend by 30 days" behavior. */
export const extendPremium = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, days } = (request.data ?? {}) as { userId?: string; days?: number };
  if (!userId || !days) invalidArgument("userId and days are required.");

  const ref = db.collection(Collections.users).doc(userId);
  const snap = await ref.get();
  if (!snap.exists) notFound("User not found.");
  const user = snap.data() as UserProfile;

  const now = Date.now();
  const currentUntilMs = user.subscription.comp_until ? user.subscription.comp_until.toMillis() : 0;
  const base = currentUntilMs > now ? currentUntilMs : now;
  const newUntil = base + days! * 24 * 3600 * 1000;

  await ref.update({ "subscription.comp_until": Timestamp.fromMillis(newUntil) });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "extend_premium",
    target: userId,
    metadata: { days },
  });
  return { success: true };
});

/** Function #45c. */
export const revokePremium = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId } = (request.data ?? {}) as { userId?: string };
  if (!userId) invalidArgument("userId is required.");

  const ref = db.collection(Collections.users).doc(userId);
  const snap = await ref.get();
  if (!snap.exists) notFound("User not found.");

  await ref.update({
    "subscription.comp_until": null,
    "subscription.comp_reason": null,
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "revoke_premium",
    target: userId,
  });
  return { success: true };
});
