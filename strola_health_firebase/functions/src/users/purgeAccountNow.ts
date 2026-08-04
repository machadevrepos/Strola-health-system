import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { purgeUserData } from "./purgeUserData";

/**
 * Admin-triggered early purge — for compliance requests (GDPR erasure, etc.)
 * that can't wait out the normal 90-day retention window
 * (purgeDeletedAccounts.ts). Only ever acts on an account that's already
 * been through the normal soft-delete (deleteAccount.ts) — this isn't a
 * shortcut around that step, just a shortcut around the retention clock.
 */
export const purgeAccountNow = onCall(async (request) => {
  const { uid: adminUid } = requireAdmin(request);
  const { userId } = (request.data ?? {}) as { userId?: string };
  if (!userId) invalidArgument("userId is required.");

  const snap = await db.collection(Collections.users).doc(userId).get();
  if (!snap.exists) notFound("User not found.");
  if (snap.data()?.deleted !== true) {
    failedPrecondition("This account hasn't been deleted yet — soft-delete it first.");
  }

  await purgeUserData(userId);
  await writeAuditLog({
    actorUid: adminUid,
    actor: actorLabelFromRequest(request),
    action: "purge_account",
    target: userId,
    metadata: { early: true },
  });

  return { success: true };
});
