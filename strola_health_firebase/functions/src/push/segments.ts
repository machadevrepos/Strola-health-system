import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Device, PushSegment } from "../lib/types";

/** Server-side equivalent of the admin panel's live audience-count preview
 * (`announcementAudienceIds`-style resolution) — same segment vocabulary,
 * now actually queryable instead of scanning an in-memory array. */
export async function resolveSegmentUserIds(
  segment: PushSegment,
  opts?: { challengeId?: string }
): Promise<string[]> {
  switch (segment) {
    case "everyone": {
      const snap = await db.collection(Collections.users).where("deleted", "==", false).get();
      return snap.docs.map((d) => d.id);
    }
    case "premium": {
      const snap = await db
        .collection(Collections.users)
        .where("subscription.tier", "==", "premium")
        .get();
      return snap.docs.map((d) => d.id);
    }
    case "free": {
      const snap = await db.collection(Collections.users).where("subscription.tier", "==", "free").get();
      return snap.docs.map((d) => d.id);
    }
    case "canada": {
      const snap = await db.collection(Collections.users).where("country", "==", "CA").get();
      return snap.docs.map((d) => d.id);
    }
    case "usa": {
      const snap = await db.collection(Collections.users).where("country", "==", "US").get();
      return snap.docs.map((d) => d.id);
    }
    case "inactive_30d": {
      const cutoff = new Date(Date.now() - 30 * 24 * 3600 * 1000).toISOString().slice(0, 10);
      const snap = await db
        .collection(Collections.users)
        .where("stats.last_active_date", "<", cutoff)
        .get();
      return snap.docs.map((d) => d.id);
    }
    case "challenge_participants": {
      if (!opts?.challengeId) return [];
      const snap = await db
        .collection(Collections.challengeParticipants(opts.challengeId))
        .where("left_at", "==", null)
        .get();
      return snap.docs.map((d) => d.id);
    }
    case "tracker_owners": {
      const snap = await db.collection(Collections.devices).where("owner_user_id", "!=", null).get();
      return snap.docs
        .map((d) => (d.data() as Device).owner_user_id)
        .filter((id): id is string => !!id);
    }
    default:
      return [];
  }
}
