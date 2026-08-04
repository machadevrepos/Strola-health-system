import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";

/**
 * Function #33's other half. Likes themselves are a direct client write
 * (firestore.rules: owner-only create/delete on `likes/{uid}`, low risk,
 * idempotent toggle) — this trigger is what keeps `likes_count` correct.
 */
export const onLikeWrite = onDocumentWritten(
  `${Collections.communityPosts}/{postId}/likes/{userId}`,
  async (event) => {
    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;
    if (existedBefore === existsAfter) return;

    const postRef = db.collection(Collections.communityPosts).doc(event.params.postId);
    await postRef.update({
      likes_count: FieldValue.increment(existsAfter ? 1 : -1),
    });
  }
);
