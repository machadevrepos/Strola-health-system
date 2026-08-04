/**
 * Shared helpers for the full-coverage test suite (test-all.js). Uses curl
 * (via execFileSync) for every HTTP call instead of Node's fetch — fetch
 * intermittently hangs indefinitely in this environment (confirmed during
 * the post-deploy smoke test), curl doesn't.
 */
const admin = require("firebase-admin");
const { execFileSync } = require("child_process");

const PROJECT_ID = "strolla-health-4c93b";
const REGION = "us-central1";
const WEB_API_KEY = "AIzaSyBB3lV4opSVuTzo7OKsDRIa9SLIHmDzyFY";

if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

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

function curlRaw(url, { method = "GET", headers = {} } = {}) {
  const args = ["-sS", "--max-time", "25", "-i", "-X", method];
  for (const [key, value] of Object.entries(headers)) args.push("-H", `${key}: ${value}`);
  args.push(url);
  return execFileSync("curl", args, { encoding: "utf8" });
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

async function callFn(name, idToken, data) {
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

/** Creates a real Auth user, waits for onUserCreate, then re-applies a role
 * promotion (handles the trigger race documented in bootstrap-super-admin.js)
 * and returns { uid, idToken }. */
async function makeUser(role) {
  const email = `test-${role}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}@strolla.internal`;
  const user = await admin.auth().createUser({ email });
  const uid = user.uid;
  await sleep(4000); // let onUserCreate finish before we touch role/claims

  if (role !== "user") {
    await admin.auth().setCustomUserClaims(uid, { role });
    await db.collection("users").doc(uid).set({ role }, { merge: true });
  }
  const idToken = await idTokenFor(uid);
  return { uid, email, idToken };
}

const createdUids = new Set();
function trackUser(uid) {
  createdUids.add(uid);
  return uid;
}

async function cleanupUsers() {
  for (const uid of createdUids) {
    await admin.auth().deleteUser(uid).catch(() => {});
    await db.collection("users").doc(uid).delete().catch(() => {});
  }
}

/** Deletes every doc in a collection matching a query, best-effort. */
async function purgeQuery(query) {
  const snap = await query.get();
  await Promise.all(snap.docs.map((d) => d.ref.delete().catch(() => {})));
  return snap.size;
}

class Results {
  constructor(domain) {
    this.domain = domain;
    this.rows = [];
  }
  ok(name, condition, detail) {
    this.rows.push({ name, pass: !!condition, detail });
    console.log(`  ${condition ? "PASS" : "FAIL"} - ${name}${detail && !condition ? ` (${detail})` : ""}`);
  }
  summary() {
    const pass = this.rows.filter((r) => r.pass).length;
    const fail = this.rows.length - pass;
    return { domain: this.domain, pass, fail, rows: this.rows };
  }
}

module.exports = {
  admin,
  db,
  PROJECT_ID,
  REGION,
  curlJson,
  curlRaw,
  idTokenFor,
  callFn,
  sleep,
  makeUser,
  trackUser,
  cleanupUsers,
  purgeQuery,
  Results,
};
