import { onCall } from "firebase-functions/v2/https";
import { requireAdmin, invalidArgument } from "../lib/auth-helpers";
import { getTokensForUsers, sendPushToTokens } from "../lib/fcm";

/** Function #42. Sends to one specific user's registered tokens only —
 * outside audience resolution and outside the sent-history/counts. */
export const sendTestPush = onCall(async (request) => {
  requireAdmin(request);
  const { userId, title, body } = (request.data ?? {}) as {
    userId?: string;
    title?: string;
    body?: string;
  };
  if (!userId || !title?.trim() || !body?.trim()) {
    invalidArgument("userId, title, and body are required.");
  }

  const tokens = await getTokensForUsers([userId!]);
  const result = await sendPushToTokens(tokens, { title: title!, body: body! });

  return { success: true, tokensTargeted: tokens.length, ...result };
});
