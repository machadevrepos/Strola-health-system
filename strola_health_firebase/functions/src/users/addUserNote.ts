import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Append-only internal admin note on a user — never shown to the user
 * themselves (users/{uid}/notes is admin-read-only per firestore.rules). */
export const addUserNote = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, content } = (request.data ?? {}) as { userId?: string; content?: string };
  if (!userId || !content?.trim()) invalidArgument("userId and content are required.");

  const userSnap = await db.collection(Collections.users).doc(userId).get();
  if (!userSnap.exists) notFound("User not found.");

  const ref = db.collection(Collections.userNotes(userId)).doc();
  await ref.set({
    id: ref.id,
    user_id: userId,
    author_id: callerUid,
    content,
    created_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "add_user_note",
    target: userId,
  });

  return { success: true, noteId: ref.id };
});
