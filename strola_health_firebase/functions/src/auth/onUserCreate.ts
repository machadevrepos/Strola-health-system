import * as functionsV1 from "firebase-functions/v1";
import { FieldValue } from "firebase-admin/firestore";
import { db, authAdmin } from "../lib/admin";
import { Collections } from "../lib/constants";

/**
 * Non-blocking v1 Auth trigger (v2 only offers blocking beforeUserCreated,
 * which requires the project to be upgraded to Identity Platform — avoided
 * here to keep setup simple). The claims-propagation delay this implies is
 * already accounted for: both admin panels use `onIdTokenChanged` (not
 * `onAuthStateChanged`) specifically so a claim picked up on next token
 * refresh updates the UI without a re-login.
 */
export const onUserCreate = functionsV1.auth.user().onCreate(async (user) => {
  await authAdmin.setCustomUserClaims(user.uid, { role: "user" });

  const userRef = db.collection(Collections.users).doc(user.uid);
  const now = FieldValue.serverTimestamp();

  await userRef.set(
    {
      id: user.uid,
      email: user.email ?? null,
      username: "",
      username_lower: "",
      name: user.displayName ?? "",
      location: null,
      country: null,
      bio: null,
      photo_url: user.photoURL ?? null,
      height_cm: 170,
      gender: "prefer_not_to_say",
      date_of_birth: null,
      reasons: [],
      units: "metric",
      onboarding_complete: false,
      daily_goal_steps: 10000,
      weight_kg: null,
      role: "user",
      privacy: {
        public_profile: true,
        share_activity: true,
        show_in_leaderboards: true,
        allow_friend_requests: true,
        hide_activity_data: false,
        hide_achievements: false,
        hide_recent_activity: false,
        hide_location: false,
      },
      subscription: {
        tier: "free",
        status: "trialing",
        comp_until: null,
        comp_reason: null,
        revenuecat_app_user_id: null,
        renews_at: null,
        cancelled_at: null,
      },
      stats: {
        streak_current: 0,
        streak_longest: 0,
        last_active_date: null,
        lifetime_steps: 0,
      },
      banned: false,
      ban_reason: null,
      posting_banned: false,
      posting_ban_reason: null,
      posting_banned_until: null,
      is_ambassador: false,
      platform: null,
      device_model: null,
      app_version: null,
      tags: [],
      deleted: false,
      deleted_at: null,
      created_at: now,
      updated_at: now,
    },
    { merge: true }
  );
});
