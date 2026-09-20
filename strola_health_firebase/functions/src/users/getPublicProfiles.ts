import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import type { Role, UserProfile } from "../lib/types";

const MAX_IDS = 100;

export interface PublicProfile {
  id: string;
  name: string;
  username: string;
  photo_url: string | null;
  show_stats: boolean;
  streak_current: number | null;
  streak_longest: number | null;
  lifetime_steps: number | null;
  // "user" for everyone except staff — lets the client give an
  // admin/super_admin's community posts and comments an official look
  // (see community_post.dart's PublicProfile.communityDisplayName).
  role: Role;
}

/**
 * `users/{uid}` is owner/admin-only in firestore.rules, so nothing lets a
 * client resolve a `author_id`/`user_id`/`requester_id` foreign key to a
 * name — a gap that blocks every community/challenge/friends screen (post
 * authorship, comment authorship, challenge leaderboards, friend request
 * lists) from rendering anything but a raw uid. Identity fields (name,
 * username, photo) are always returned for any requested uid, same as any
 * social app always showing the name of who posted/joined something public
 * — `privacy.public_profile` only gates the extra stats fields, matching
 * what that toggle already means in both admin panels.
 */
export const getPublicProfiles = onCall(async (request) => {
  requireAuth(request);
  const { userIds } = (request.data ?? {}) as { userIds?: string[] };
  if (!Array.isArray(userIds) || userIds.length === 0) invalidArgument("userIds is required.");

  const ids = [...new Set(userIds)].slice(0, MAX_IDS);
  // A single batched multi-get (one round trip to Firestore) rather than
  // `Promise.all(ids.map(id => ref.get()))` — that looked batched from the
  // caller's side (one callable invocation) but was actually up to
  // MAX_IDS separate document reads fired in parallel under the hood. Every
  // feed page, friend list, and comment thread funnels through this
  // function, so that was the real first-load cost the client-side
  // batching/caching in PublicProfileRepository couldn't see or fix.
  const refs = ids.map((id) => db.collection(Collections.users).doc(id));
  const snaps = refs.length > 0 ? await db.getAll(...refs) : [];

  const profiles: PublicProfile[] = [];
  for (const snap of snaps) {
    if (!snap.exists) continue;
    const user = snap.data() as UserProfile;
    if (user.banned || user.deleted) continue;
    const showStats = user.privacy.public_profile;
    profiles.push({
      id: snap.id,
      name: user.name,
      username: user.username,
      photo_url: user.photo_url,
      show_stats: showStats,
      streak_current: showStats ? user.stats.streak_current : null,
      streak_longest: showStats ? user.stats.streak_longest : null,
      lifetime_steps: showStats ? user.stats.lifetime_steps : null,
      role: user.role,
    });
  }

  return { profiles };
});
