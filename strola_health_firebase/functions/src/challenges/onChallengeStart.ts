import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { writeAuditLog } from "../lib/audit";
import type { Challenge } from "../lib/types";

/**
 * Function #28. Auto-promotes a prepared-ahead-of-time official challenge on
 * its start date — the other half of the admin workflow createChallenge's
 * `status: "draft"` path enables: an admin preps next month's challenge
 * whenever they like (doesn't touch the current one or its participants,
 * isn't visible to members yet), and this picks it up on the day it's
 * supposed to start rather than requiring an admin to be online right at
 * midnight to flip it over manually. Same "one is_official at a time" batch
 * pattern as setOfficialMonthlyChallenge, which an admin can still call
 * directly to promote a draft early if they don't want to wait.
 *
 * The `visibility == "public"` filter is what distinguishes a prepped
 * official-track draft from an ordinary member's private challenge draft
 * (there isn't one today — createChallenge only allows "draft" for an admin
 * creating a public challenge — but this filter is the same signal the
 * admin panel's "Other public challenges" grouping already uses, so it
 * stays correct if that ever changes).
 */
export const onChallengeStart = onSchedule("every day 00:05", async () => {
  const today = new Date().toISOString().slice(0, 10);

  const dueSnap = await db
    .collection(Collections.challenges)
    .where("status", "==", "draft")
    .where("visibility", "==", "public")
    .where("is_official", "==", false)
    .where("start_date", "<=", today)
    .get();
  if (dueSnap.empty) return;

  // If more than one is somehow due (shouldn't normally happen — an admin
  // preps one at a time), promote only the earliest-starting one; the rest
  // stay as drafts for the admin to deal with by hand rather than silently
  // picking a second official challenge.
  const due = dueSnap.docs
    .map((doc) => ({ id: doc.id, data: doc.data() as Challenge }))
    .sort((a, b) => a.data.start_date.localeCompare(b.data.start_date));
  const next = due[0];

  const currentlyOfficial = await db.collection(Collections.challenges).where("is_official", "==", true).get();

  const batch = db.batch();
  currentlyOfficial.forEach((doc) => batch.update(doc.ref, { is_official: false }));
  batch.update(db.collection(Collections.challenges).doc(next.id), {
    is_official: true,
    status: "published",
    type: "official_monthly",
  });
  await batch.commit();

  await writeAuditLog({
    actorUid: "system",
    actor: "Scheduled function (onChallengeStart)",
    action: "set_official_monthly_challenge",
    target: next.id,
  });
});
