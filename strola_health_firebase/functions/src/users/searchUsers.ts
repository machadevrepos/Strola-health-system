import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import type { UserProfile } from "../lib/types";

const MAX_RESULTS = 20;

/** Powers the Find Friends screen's search box. Prefix-matches on
 * `username_lower` (case-sensitive Firestore range query, hence the
 * lowercased mirror field — see updateMyProfile.ts). */
export const searchUsers = onCall(async (request) => {
  const uid = requireAuth(request);
  const { query } = (request.data ?? {}) as { query?: string };
  if (!query?.trim()) invalidArgument("query is required.");

  const q = query.trim().toLowerCase();
  const snap = await db
    .collection(Collections.users)
    .orderBy("username_lower")
    .startAt(q)
    .endAt(q + "")
    .limit(MAX_RESULTS)
    .get();

  const profiles = snap.docs
    .filter((doc) => doc.id !== uid)
    .map((doc) => doc.data() as UserProfile)
    .filter((user) => !user.banned && !user.deleted && user.username_lower)
    .map((user) => ({
      id: user.id,
      name: user.name,
      username: user.username,
      photo_url: user.photo_url,
    }));

  return { profiles };
});
