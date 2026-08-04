import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { Gender, StrollaReason, UnitSystem } from "../lib/types";

/**
 * Self-service counterpart to updateUserProfile (which is admin-only, for
 * editing *other* users from the admin panel). The mobile app's own profile
 * edit screen needs this — found missing during the Flutter migration audit,
 * every self-service profile field the app's UI lets a user change, minus
 * the admin-only cohort fields (is_ambassador, tags, country) that never
 * appear in a self-service form. Always operates on the caller's own uid,
 * never takes a userId — there's no path for editing anyone else through
 * this callable, by design.
 */
export const updateMyProfile = onCall(async (request) => {
  const uid = requireAuth(request);
  const updates = (request.data ?? {}) as {
    name?: string;
    username?: string;
    bio?: string | null;
    location?: string | null;
    heightCm?: number;
    weightKg?: number | null;
    gender?: Gender;
    dateOfBirth?: string | null;
    reasons?: StrollaReason[];
    units?: UnitSystem;
    dailyGoalSteps?: number;
    onboardingComplete?: boolean;
  };

  const ref = db.collection(Collections.users).doc(uid);
  const snap = await ref.get();
  if (!snap.exists) notFound("User not found.");

  const patch: Record<string, unknown> = {};
  if (updates.name !== undefined) patch.name = updates.name;
  if (updates.username !== undefined) {
    patch.username = updates.username;
    patch.username_lower = updates.username.toLowerCase();
  }
  if (updates.bio !== undefined) patch.bio = updates.bio;
  if (updates.location !== undefined) patch.location = updates.location;
  if (updates.heightCm !== undefined) patch.height_cm = updates.heightCm;
  if (updates.weightKg !== undefined) patch.weight_kg = updates.weightKg;
  if (updates.gender !== undefined) patch.gender = updates.gender;
  if (updates.dateOfBirth !== undefined) patch.date_of_birth = updates.dateOfBirth;
  if (updates.reasons !== undefined) patch.reasons = updates.reasons;
  if (updates.units !== undefined) patch.units = updates.units;
  if (updates.dailyGoalSteps !== undefined) patch.daily_goal_steps = updates.dailyGoalSteps;
  if (updates.onboardingComplete !== undefined) patch.onboarding_complete = updates.onboardingComplete;
  if (Object.keys(patch).length === 0) invalidArgument("At least one field is required.");
  patch.updated_at = FieldValue.serverTimestamp();

  await ref.update(patch);

  await writeAuditLog({
    actorUid: uid,
    actor: "self",
    action: "update_my_profile",
    target: uid,
    metadata: patch,
  });

  return { success: true };
});
