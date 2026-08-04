import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { Gender, UnitSystem } from "../lib/types";

/**
 * Admin's edit-profile action from a user's detail page — the fields the
 * user themselves could edit, plus admin-only cohort fields (is_ambassador,
 * tags) that never appear in a self-service profile form. A gap from the
 * original Part 3 plan (function #10, "adminUpdateUserProfile") that got
 * missed during the initial build — caught while wiring the admin panel.
 */
export const updateUserProfile = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, ...updates } = (request.data ?? {}) as {
    userId?: string;
    name?: string;
    username?: string;
    bio?: string | null;
    location?: string | null;
    country?: string | null;
    heightCm?: number;
    weightKg?: number | null;
    gender?: Gender;
    dailyGoalSteps?: number;
    units?: UnitSystem;
    isAmbassador?: boolean;
    tags?: string[];
  };
  if (!userId) invalidArgument("userId is required.");

  const ref = db.collection(Collections.users).doc(userId);
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
  if (updates.country !== undefined) patch.country = updates.country;
  if (updates.heightCm !== undefined) patch.height_cm = updates.heightCm;
  if (updates.weightKg !== undefined) patch.weight_kg = updates.weightKg;
  if (updates.gender !== undefined) patch.gender = updates.gender;
  if (updates.dailyGoalSteps !== undefined) patch.daily_goal_steps = updates.dailyGoalSteps;
  if (updates.units !== undefined) patch.units = updates.units;
  if (updates.isAmbassador !== undefined) patch.is_ambassador = updates.isAmbassador;
  if (updates.tags !== undefined) patch.tags = updates.tags;
  patch.updated_at = FieldValue.serverTimestamp();

  await ref.update(patch);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_user_profile",
    target: userId,
    metadata: patch,
  });

  return { success: true };
});
