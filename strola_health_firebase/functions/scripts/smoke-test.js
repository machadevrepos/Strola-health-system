/**
 * Post-deploy smoke test. Exercises real deployed Cloud Functions end to
 * end (not the emulator) using a throwaway test user:
 *   1. Create an Auth user -> confirm onUserCreate fired (Firestore doc + role claim)
 *   2. Call a plain-user callable (logAnalyticsEvent) -> should succeed
 *   3. Call an admin-only callable (getAnalyticsDashboard) as a plain user -> should be rejected
 *   4. Promote to super_admin, re-mint token, retry -> should succeed
 *   5. ingestWorkoutSession -> confirm onDailyActivityWrite trigger updated users/{uid}.stats
 *   6. createChallenge -> confirm updateChallengeLeaderboard trigger populated leaderboard_top
 *   7. provisionDevice + pairDevice -> confirm onDeviceWrite trigger wrote a devicePairingEvents doc
 * Cleans up the test user and its Firestore docs at the end either way.
 *
 * Usage: node scripts/smoke-test.js
 * Needs GOOGLE_APPLICATION_CREDENTIALS pointing at the service account key.
 */

const admin = require("firebase-admin");
const { execFileSync } = require("child_process");

const PROJECT_ID = "strolla-health-4c93b";
const REGION = "us-central1";
const WEB_API_KEY = "AIzaSyBB3lV4opSVuTzo7OKsDRIa9SLIHmDzyFY";
const TEST_EMAIL = `smoketest-${Date.now()}@strolla.internal`;

// Node's built-in fetch (undici) intermittently hangs indefinitely on this
// machine after a few requests (connection-reuse issue) — curl, tested
// directly, is fast and reliable, so every HTTP call in this script shells
// out to it instead of using fetch().
function curlJson(url, { method = "GET", headers = {}, body } = {}) {
  const args = ["-sS", "--max-time", "25", "-X", method];
  for (const [key, value] of Object.entries(headers)) args.push("-H", `${key}: ${value}`);
  if (body !== undefined) args.push("-d", JSON.stringify(body));
  args.push("-w", "\n%{http_code}", url);
  const output = execFileSync("curl", args, { encoding: "utf8" });
  const lastNewline = output.lastIndexOf("\n");
  const status = Number(output.slice(lastNewline + 1).trim());
  const raw = output.slice(0, lastNewline);
  let json;
  try {
    json = JSON.parse(raw);
  } catch {
    json = { raw };
  }
  return { status, body: json };
}

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

let pass = 0;
let fail = 0;
function report(name, ok, detail) {
  if (ok) {
    pass++;
    console.log(`  PASS - ${name}`);
  } else {
    fail++;
    console.log(`  FAIL - ${name}${detail ? ` (${detail})` : ""}`);
  }
}

async function idTokenFor(uid) {
  const customToken = await admin.auth().createCustomToken(uid);
  const { status, body } = curlJson(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${WEB_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: { token: customToken, returnSecureToken: true },
    }
  );
  if (status !== 200) throw new Error(`Custom token exchange failed: ${JSON.stringify(body)}`);
  return body.idToken;
}

async function callFunction(name, idToken, data) {
  return curlJson(`https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}),
    },
    body: { data: data ?? {} },
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  console.log(`Creating test user ${TEST_EMAIL}...`);
  const user = await admin.auth().createUser({ email: TEST_EMAIL, password: "SmokeTest123!" });
  const uid = user.uid;

  try {
    console.log("Waiting for onUserCreate trigger...");
    await sleep(5000);
    const userDoc = await db.collection("users").doc(uid).get();
    report("onUserCreate created users/{uid} doc", userDoc.exists);
    const claims = (await admin.auth().getUser(uid)).customClaims;
    report("onUserCreate set role=user custom claim", claims?.role === "user", JSON.stringify(claims));

    let idToken = await idTokenFor(uid);

    const analyticsCall = await callFunction("logAnalyticsEvent", idToken, { eventType: "app_opened" });
    report("logAnalyticsEvent succeeds for a plain user", analyticsCall.status === 200, JSON.stringify(analyticsCall.body));

    const deniedCall = await callFunction("getAnalyticsDashboard", idToken, {
      startDate: "2026-01-01",
      endDate: "2026-01-31",
    });
    report(
      "getAnalyticsDashboard rejects a plain user",
      deniedCall.status !== 200,
      `status=${deniedCall.status}`
    );

    console.log("Promoting test user to super_admin...");
    await admin.auth().setCustomUserClaims(uid, { role: "super_admin" });
    await db.collection("users").doc(uid).set({ role: "super_admin" }, { merge: true });
    idToken = await idTokenFor(uid);

    const allowedCall = await callFunction("getAnalyticsDashboard", idToken, {
      startDate: "2026-01-01",
      endDate: "2026-01-31",
    });
    report(
      "getAnalyticsDashboard succeeds for super_admin",
      allowedCall.status === 200,
      JSON.stringify(allowedCall.body)
    );

    console.log("Testing ingestWorkoutSession -> onDailyActivityWrite trigger...");
    const sessionId = `smoketest_${Date.now()}`;
    const now = Date.now();
    const ingestCall = await callFunction("ingestWorkoutSession", idToken, {
      id: sessionId,
      startTimeMillis: now - 30 * 60 * 1000,
      endTimeMillis: now,
      steps: 4000,
      durationSeconds: 1800,
      activityType: "outdoor_walk",
      source: "strolla_app",
    });
    report("ingestWorkoutSession succeeds", ingestCall.status === 200, JSON.stringify(ingestCall.body));
    await sleep(6000);
    const userAfterIngest = (await db.collection("users").doc(uid).get()).data();
    report(
      "onDailyActivityWrite trigger updated stats.lifetime_steps",
      userAfterIngest?.stats?.lifetime_steps === 4000,
      JSON.stringify(userAfterIngest?.stats)
    );

    console.log("Testing createChallenge -> updateChallengeLeaderboard trigger...");
    const challengeCall = await callFunction("createChallenge", idToken, {
      title: "Smoke Test Challenge",
      description: "temporary",
      goalSteps: 10000,
      startDate: "2026-01-01",
      endDate: "2026-12-31",
    });
    report("createChallenge succeeds", challengeCall.status === 200, JSON.stringify(challengeCall.body));
    const challengeId = challengeCall.body?.result?.challengeId;
    if (challengeId) {
      await sleep(6000);
      const challengeDoc = (await db.collection("challenges").doc(challengeId).get()).data();
      report(
        "updateChallengeLeaderboard trigger populated leaderboard_top",
        Array.isArray(challengeDoc?.leaderboard_top) && challengeDoc.leaderboard_top.length === 1,
        JSON.stringify(challengeDoc?.leaderboard_top)
      );
      await db.collection("challenges").doc(challengeId).collection("participants").doc(uid).delete().catch(() => {});
      await db.collection("challenges").doc(challengeId).delete().catch(() => {});
    } else {
      report("updateChallengeLeaderboard trigger populated leaderboard_top", false, "no challengeId returned");
    }

    console.log("Testing provisionDevice + pairDevice -> onDeviceWrite trigger...");
    const serial = `SMOKETEST-${Date.now()}`;
    const provisionCall = await callFunction("provisionDevice", idToken, { serialNumber: serial });
    report("provisionDevice succeeds", provisionCall.status === 200, JSON.stringify(provisionCall.body));
    const deviceId = provisionCall.body?.result?.deviceId;
    if (deviceId) {
      const pairCall = await callFunction("pairDevice", idToken, { serialNumber: serial });
      report("pairDevice succeeds", pairCall.status === 200, JSON.stringify(pairCall.body));
      await sleep(6000);
      const pairingEvents = await db
        .collection("devicePairingEvents")
        .where("device_id", "==", deviceId)
        .where("event", "==", "paired")
        .get();
      report("onDeviceWrite trigger logged a paired event", !pairingEvents.empty);
      await db.collection("devices").doc(deviceId).delete().catch(() => {});
      for (const doc of pairingEvents.docs) await doc.ref.delete().catch(() => {});
    } else {
      report("pairDevice succeeds", false, "no deviceId returned from provisionDevice");
      report("onDeviceWrite trigger logged a paired event", false, "skipped, no deviceId");
    }
  } finally {
    console.log("Cleaning up test user...");
    await admin.auth().deleteUser(uid).catch(() => {});
    await db.collection("users").doc(uid).delete().catch(() => {});
    await db.collection("personalRecords").doc(uid).delete().catch(() => {});
    await db.collection("workoutSessions").where("user_id", "==", uid).get().then((snap) =>
      Promise.all(snap.docs.map((d) => d.ref.delete()))
    );
    await db.collection("dailyActivity").where("user_id", "==", uid).get().then((snap) =>
      Promise.all(snap.docs.map((d) => d.ref.delete()))
    );
  }

  console.log(`\n${pass} passed, ${fail} failed.`);
  process.exit(fail > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("Smoke test crashed:", err);
  process.exit(1);
});
