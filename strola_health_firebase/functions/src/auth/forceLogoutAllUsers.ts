import { onCall } from "firebase-functions/v2/https";
import { authAdmin } from "../lib/admin";
import { requireSuperAdmin, actorLabelFromRequest } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #6 (App Settings' standalone "Force logout everyone" action).
 * super_admin only — this is the single most destructive action in the
 * whole system (every signed-in user everywhere is kicked out immediately).
 * Revokes refresh tokens in listUsers' natural page batches so it scales
 * past the 1000-user default page size without loading the whole user base
 * into memory at once.
 */
export const forceLogoutAllUsers = onCall(async (request) => {
  const { uid: callerUid } = requireSuperAdmin(request);

  let revoked = 0;
  let pageToken: string | undefined;
  do {
    const page = await authAdmin.listUsers(1000, pageToken);
    await Promise.all(page.users.map((u) => authAdmin.revokeRefreshTokens(u.uid)));
    revoked += page.users.length;
    pageToken = page.pageToken;
  } while (pageToken);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "force_logout_all_users",
    metadata: { revoked_count: revoked },
  });

  return { success: true, revokedCount: revoked };
});
