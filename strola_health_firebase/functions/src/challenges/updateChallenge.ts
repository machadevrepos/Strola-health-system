import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * General field editor for an existing challenge — title/description/
 * image/dates/rules/badge — distinct from the lifecycle-specific callables
 * (publishChallenge, archiveChallenge, setOfficialMonthlyChallenge,
 * setChallengeWinner). A gap from the original build: everything about a
 * challenge's *lifecycle* got a callable, but plain field edits (the
 * official monthly challenge's title/description/image/dates, per the
 * admin panel audit) didn't — caught while wiring the Challenges page.
 */
export const updateChallenge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId, ...updates } = (request.data ?? {}) as {
    challengeId?: string;
    title?: string;
    description?: string;
    imageUrl?: string | null;
    rules?: string | null;
    startDate?: string;
    endDate?: string;
    badgeEmoji?: string;
    accentColorValue?: number | null;
    goalSteps?: number;
  };
  if (!challengeId) invalidArgument("challengeId is required.");

  const ref = db.collection(Collections.challenges).doc(challengeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Challenge not found.");

  const patch: Record<string, unknown> = {};
  if (updates.title !== undefined) patch.title = updates.title;
  if (updates.description !== undefined) patch.description = updates.description;
  if (updates.imageUrl !== undefined) patch.image_url = updates.imageUrl;
  if (updates.rules !== undefined) patch.rules = updates.rules;
  if (updates.startDate !== undefined) patch.start_date = updates.startDate;
  if (updates.endDate !== undefined) patch.end_date = updates.endDate;
  if (updates.badgeEmoji !== undefined) patch.badge_emoji = updates.badgeEmoji;
  if (updates.accentColorValue !== undefined) patch.accent_color_value = updates.accentColorValue;
  if (updates.goalSteps !== undefined) patch.goal_steps = updates.goalSteps;
  if (Object.keys(patch).length === 0) invalidArgument("At least one field to update is required.");

  await ref.update(patch);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_challenge",
    target: challengeId,
    metadata: patch,
  });

  return { success: true };
});
