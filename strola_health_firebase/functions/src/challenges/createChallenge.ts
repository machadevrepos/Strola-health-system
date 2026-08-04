import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import { generateUniqueInviteCode } from "./inviteCode";
import { joinChallengeCore } from "./joinLeave";
import type { ChallengeVisibility, UserProfile, WinnerType } from "../lib/types";

/**
 * Function #21. The Flutter app's CreateChallengeScreen form (name/duration/
 * dates/winner-method/invite) was UI-only per the audit — this is what makes
 * it actually persist. Creator auto-joins their own challenge.
 */
export const createChallenge = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "createChallenge", RateLimits.createChallenge);
  const {
    title,
    description,
    goalSteps,
    startDate,
    endDate,
    badgeEmoji,
    accentColorValue,
    visibility,
    winnerType,
    imageUrl,
  } = (request.data ?? {}) as {
    title?: string;
    description?: string;
    goalSteps?: number;
    startDate?: string;
    endDate?: string;
    badgeEmoji?: string;
    accentColorValue?: number;
    visibility?: ChallengeVisibility;
    winnerType?: WinnerType;
    imageUrl?: string;
  };

  if (!title?.trim() || !goalSteps || !startDate || !endDate) {
    invalidArgument("title, goalSteps, startDate, and endDate are required.");
  }
  if (title!.length > 40) invalidArgument("title must be 40 characters or fewer.");

  const visibilityValue: ChallengeVisibility = visibility === "public" ? "public" : "private";
  const inviteCode = visibilityValue === "private" ? await generateUniqueInviteCode() : null;

  const ref = db.collection(Collections.challenges).doc();
  await ref.set({
    id: ref.id,
    type: "private",
    title,
    description: description ?? "",
    goal_steps: goalSteps,
    start_date: startDate,
    end_date: endDate,
    badge_emoji: badgeEmoji ?? "🏆",
    accent_color_value: accentColorValue ?? null,
    visibility: visibilityValue,
    is_official: false,
    invite_code: inviteCode,
    created_by: uid,
    created_at: FieldValue.serverTimestamp(),
    image_url: imageUrl ?? null,
    rules: null,
    winner_type: winnerType === "goal_completion_pct" ? "goal_completion_pct" : "most_steps",
    status: "published",
    winner_user_id: null,
    admin_notes: null,
    leaderboard_top: [],
  });

  const userSnap = await db.collection(Collections.users).doc(uid).get();
  const dailyGoal = (userSnap.data() as UserProfile | undefined)?.daily_goal_steps ?? 10000;
  await joinChallengeCore(ref.id, uid, dailyGoal);

  return { success: true, challengeId: ref.id, inviteCode };
});
