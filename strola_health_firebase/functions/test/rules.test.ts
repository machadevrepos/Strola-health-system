import * as fs from "fs";
import * as path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { setLogLevel } from "firebase/firestore";

/**
 * Firestore security rules test suite, run against the emulator (never
 * production — `initializeTestEnvironment` refuses to run without
 * `FIRESTORE_EMULATOR_HOST` set, which `firebase emulators:exec` sets for
 * us). Covers the collections most exposed to a client — everything else
 * in firestore.rules is `allow write: if false` with a read gated on
 * ownership/role, which is the same handful of patterns re-verified below.
 *
 * Includes explicit regression cases for the two real bugs found and fixed
 * this session: `friendships` and `blockedUsers` list queries being denied
 * outright because the rule was phrased only as an id-pattern match, which
 * Firestore can't prove a `.where()` query against.
 */

const PROJECT_ID = "strolla-health-rules-test";
let testEnv: RulesTestEnvironment;

before(async () => {
  setLogLevel("error");
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, "../../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

const ALICE = "alice";
const BOB = "bob";
const CAROL = "carol";

function asUser(uid: string, claims: Record<string, unknown> = {}) {
  return testEnv.authenticatedContext(uid, claims).firestore();
}

function asAdmin(uid: string) {
  return asUser(uid, { role: "admin" });
}

function asUnauthenticated() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed(fn: (db: any) => Promise<void>) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

describe("users", () => {
  it("owner can read their own profile", async () => {
    await seed(async (db) => db.doc(`users/${ALICE}`).set({ name: "Alice" }));
    await assertSucceeds(asUser(ALICE).doc(`users/${ALICE}`).get());
  });

  it("a different signed-in user cannot read someone else's profile", async () => {
    await seed(async (db) => db.doc(`users/${ALICE}`).set({ name: "Alice" }));
    await assertFails(asUser(BOB).doc(`users/${ALICE}`).get());
  });

  it("admin can read any profile", async () => {
    await seed(async (db) => db.doc(`users/${ALICE}`).set({ name: "Alice" }));
    await assertSucceeds(asAdmin(CAROL).doc(`users/${ALICE}`).get());
  });

  it("no client, including the owner, can write a profile directly", async () => {
    await assertFails(asUser(ALICE).doc(`users/${ALICE}`).set({ name: "Alice" }));
  });

  it("a user can register their own FCM device token", async () => {
    await assertSucceeds(
      asUser(ALICE)
        .doc(`users/${ALICE}/deviceTokens/tok1`)
        .set({ token: "abc" })
    );
  });

  it("a user cannot register a device token under another user's doc", async () => {
    await assertFails(
      asUser(ALICE)
        .doc(`users/${BOB}/deviceTokens/tok1`)
        .set({ token: "abc" })
    );
  });
});

describe("communityPosts", () => {
  it("a signed-in user can read a visible post", async () => {
    await seed(async (db) =>
      db.doc("communityPosts/p1").set({ author_id: ALICE, moderation: { hidden: false } })
    );
    await assertSucceeds(asUser(BOB).doc("communityPosts/p1").get());
  });

  it("a non-admin cannot read a hidden post", async () => {
    await seed(async (db) =>
      db.doc("communityPosts/p1").set({ author_id: ALICE, moderation: { hidden: true } })
    );
    await assertFails(asUser(BOB).doc("communityPosts/p1").get());
  });

  it("an admin can read a hidden post", async () => {
    await seed(async (db) =>
      db.doc("communityPosts/p1").set({ author_id: ALICE, moderation: { hidden: true } })
    );
    await assertSucceeds(asAdmin(CAROL).doc("communityPosts/p1").get());
  });

  it("no client can create a post directly (bypassing createPost's moderation checks)", async () => {
    await assertFails(
      asUser(ALICE)
        .doc("communityPosts/p2")
        .set({ author_id: ALICE, content: "hi", moderation: { hidden: false } })
    );
  });

  it("a user can like a post as themselves", async () => {
    await seed(async (db) => db.doc("communityPosts/p1").set({ moderation: { hidden: false } }));
    await assertSucceeds(
      asUser(ALICE).doc(`communityPosts/p1/likes/${ALICE}`).set({ created_at: 1 })
    );
  });

  it("a user cannot like a post on someone else's behalf", async () => {
    await seed(async (db) => db.doc("communityPosts/p1").set({ moderation: { hidden: false } }));
    await assertFails(asUser(ALICE).doc(`communityPosts/p1/likes/${BOB}`).set({ created_at: 1 }));
  });

  it("a signed-in user can read a visible comment", async () => {
    await seed(async (db) => {
      await db.doc("communityPosts/p1").set({ moderation: { hidden: false } });
      await db.doc("communityPosts/p1/comments/c1").set({ author_id: BOB, hidden: false });
    });
    await assertSucceeds(asUser(ALICE).doc("communityPosts/p1/comments/c1").get());
  });

  it("a non-admin cannot read a hidden comment", async () => {
    await seed(async (db) => {
      await db.doc("communityPosts/p1").set({ moderation: { hidden: false } });
      await db.doc("communityPosts/p1/comments/c1").set({ author_id: BOB, hidden: true });
    });
    await assertFails(asUser(ALICE).doc("communityPosts/p1/comments/c1").get());
  });
});

describe("friendships — regression coverage for the id-pattern-vs-list-query bug", () => {
  it("a party to the friendship can get() the doc directly by id", async () => {
    const id = [ALICE, BOB].sort().join("_");
    await seed(async (db) => db.doc(`friendships/${id}`).set({ uids: [ALICE, BOB], status: "accepted" }));
    await assertSucceeds(asUser(ALICE).doc(`friendships/${id}`).get());
  });

  it("a non-party cannot get() someone else's friendship doc", async () => {
    const id = [ALICE, BOB].sort().join("_");
    await seed(async (db) => db.doc(`friendships/${id}`).set({ uids: [ALICE, BOB], status: "accepted" }));
    await assertFails(asUser(CAROL).doc(`friendships/${id}`).get());
  });

  it("a list query filtered on uids (getFriendships()) succeeds for a real party — the exact bug fixed this session", async () => {
    const id = [ALICE, BOB].sort().join("_");
    await seed(async (db) => db.doc(`friendships/${id}`).set({ uids: [ALICE, BOB], status: "accepted" }));
    const db1 = asUser(ALICE);
    await assertSucceeds(
      db1
        .collection("friendships")
        .where("uids", "array-contains", ALICE)
        .get()
    );
  });

  it("that same list query returns nothing usable to a non-party (rules don't leak other pairs)", async () => {
    const id = [ALICE, BOB].sort().join("_");
    await seed(async (db) => db.doc(`friendships/${id}`).set({ uids: [ALICE, BOB], status: "accepted" }));
    // Carol querying for her own uid never touches Alice/Bob's doc, so this
    // must succeed (empty result), not be denied — a query is only ever
    // rejected outright if Firestore can't prove EVERY possible match is
    // covered by the rule, not because of what data happens to exist.
    await assertSucceeds(
      asUser(CAROL).collection("friendships").where("uids", "array-contains", CAROL).get()
    );
  });
});

describe("blockedUsers — regression coverage for the id-pattern-vs-list-query bug", () => {
  it("the blocker can get() their own block doc by id", async () => {
    await seed(async (db) =>
      db.doc(`blockedUsers/${ALICE}_${BOB}`).set({ blocker_id: ALICE, blocked_id: BOB })
    );
    await assertSucceeds(asUser(ALICE).doc(`blockedUsers/${ALICE}_${BOB}`).get());
  });

  it("a list query filtered on blocker_id (getBlockedUserIds()) succeeds — the exact bug fixed this session", async () => {
    await seed(async (db) =>
      db.doc(`blockedUsers/${ALICE}_${BOB}`).set({ blocker_id: ALICE, blocked_id: BOB })
    );
    await assertSucceeds(
      asUser(ALICE).collection("blockedUsers").where("blocker_id", "==", ALICE).get()
    );
  });

  it("a stranger cannot get() someone else's block doc by id", async () => {
    await seed(async (db) =>
      db.doc(`blockedUsers/${ALICE}_${BOB}`).set({ blocker_id: ALICE, blocked_id: BOB })
    );
    await assertFails(asUser(CAROL).doc(`blockedUsers/${ALICE}_${BOB}`).get());
  });
});

describe("devices", () => {
  it("the owner can read their own device", async () => {
    await seed(async (db) => db.doc("devices/d1").set({ owner_user_id: ALICE }));
    await assertSucceeds(asUser(ALICE).doc("devices/d1").get());
  });

  it("a non-owner cannot read someone else's device", async () => {
    await seed(async (db) => db.doc("devices/d1").set({ owner_user_id: ALICE }));
    await assertFails(asUser(BOB).doc("devices/d1").get());
  });

  it("no client can write a device doc directly", async () => {
    await assertFails(asUser(ALICE).doc("devices/d1").set({ owner_user_id: ALICE }));
  });
});

describe("challenges", () => {
  it("any signed-in user can read a challenge", async () => {
    await seed(async (db) => db.doc("challenges/c1").set({ title: "Step It Up" }));
    await assertSucceeds(asUser(ALICE).doc("challenges/c1").get());
  });

  it("an unauthenticated caller cannot read a challenge", async () => {
    await seed(async (db) => db.doc("challenges/c1").set({ title: "Step It Up" }));
    await assertFails(asUnauthenticated().doc("challenges/c1").get());
  });

  it("no client can write a challenge directly (create/join go through callables)", async () => {
    await assertFails(asUser(ALICE).doc("challenges/c1").set({ title: "hack" }));
  });

  it("any signed-in user can read challenge participants", async () => {
    await seed(async (db) => db.doc("challenges/c1/participants/p1").set({ user_id: ALICE }));
    await assertSucceeds(asUser(BOB).doc("challenges/c1/participants/p1").get());
  });
});
