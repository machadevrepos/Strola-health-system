import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";

/** Keeps CommunityPost.comments_count denormalized and correct regardless
 * of which callable (addComment/deleteComment, or a future admin action)
 * touched the subcollection. */
export const onCommentWrite = onDocumentWritten(
  `${Collections.communityPosts}/{postId}/comments/{commentId}`,
  async (event) => {
    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;
    if (existedBefore === existsAfter) return;

    const postRef = db.collection(Collections.communityPosts).doc(event.params.postId);
    await postRef.update({
      comments_count: FieldValue.increment(existsAfter ? 1 : -1),
    });
  }
);
