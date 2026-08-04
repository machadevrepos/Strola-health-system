import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { Collections } from "../lib/constants";
import { getTokensForUsers, sendPushToTokens } from "../lib/fcm";
import { resolveSegmentUserIds } from "./segments";
import type { Challenge } from "../lib/types";

/**
 * Broadcasts to every user the moment a challenge becomes the official
 * monthly one — `setOfficialMonthlyChallenge.ts` is the only place
 * `is_official` is ever set to `true` (a batch update, not a create), so
 * this watches for that specific transition rather than document creation.
 * Same `sendPushToTokens` pipeline as every other real push in this app
 * (see `notifyEvents.ts`) — not a separate/parallel mechanism.
 */
export const notifyOnOfficialChallenge = onDocumentWritten(
  `${Collections.challenges}/{challengeId}`,
  async (event) => {
    const before = event.data?.before.data() as Challenge | undefined;
    const after = event.data?.after.data() as Challenge | undefined;
    if (!after) return;
    if (before?.is_official === true || after.is_official !== true) return;

    const userIds = await resolveSegmentUserIds("everyone");
    const tokens = await getTokensForUsers(userIds);
    await sendPushToTokens(tokens, {
      title: "New challenge!",
      body: `"${after.title}" is this month's official challenge — join in!`,
      data: {
        link_target: "challenge",
        // Matches notifyEvents.ts's notifyOnChallengeJoin field name — was
        // previously `link_challenge_id` here, a naming mismatch that meant
        // the two challenge pushes couldn't share client-side handling.
        challenge_id: event.params.challengeId,
      },
    });
  }
);
