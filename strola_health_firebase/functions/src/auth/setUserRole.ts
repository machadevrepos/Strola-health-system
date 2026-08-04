import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, authAdmin } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireSuperAdmin, actorLabelFromRequest, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { Role, UserProfile } from "../lib/types";

const VALID_ROLES: Role[] = ["user", "admin", "super_admin"];

/**
 * Function #2 (Part 3). Backs both panels' Users-page role change and the
 * super-admin panel's Staff & Roles promote/demote flow — same underlying
 * mutation either way, per the audit (staff are just UserProfile rows with
 * an elevated role, not a separate collection).
 *
 * super_admin only — this touches the admin/super_admin tier in either
 * direction (granting admin, granting super_admin, or demoting an existing
 * admin/super_admin), matching Staff & Roles' own "Super-admin only" page
 * copy. An earlier version only blocked *granting* super_admin, which left
 * a plain admin able to demote any super_admin (including stripping their
 * own oversight) or mint new admins freely — fixed here, not a deliberate
 * design choice.
 */
export const setUserRole = onCall(async (request) => {
  const { uid: callerUid } = requireSuperAdmin(request);
  const { userId, role: newRole } = (request.data ?? {}) as { userId?: string; role?: Role };

  if (!userId || !newRole || !VALID_ROLES.includes(newRole)) {
    invalidArgument("userId and a valid role are required.");
  }
  if (userId === callerUid) {
    failedPrecondition("You cannot change your own role.");
  }

  const userRef = db.collection(Collections.users).doc(userId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) notFound("User not found.");
    const current = snap.data() as UserProfile;

    if (current.role === "super_admin" && newRole !== "super_admin") {
      const superAdmins = await tx.get(
        db.collection(Collections.users).where("role", "==", "super_admin")
      );
      if (superAdmins.size <= 1) {
        failedPrecondition("Cannot remove the last super_admin.");
      }
    }

    tx.update(userRef, { role: newRole, updated_at: FieldValue.serverTimestamp() });
  });

  // Custom claims are the source of truth auth-context.tsx reads via
  // getIdTokenResult().claims.role — must stay in lockstep with the
  // Firestore field set above.
  await authAdmin.setCustomUserClaims(userId, { role: newRole });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "set_user_role",
    target: userId,
    metadata: { new_role: newRole },
  });

  return { success: true };
});
