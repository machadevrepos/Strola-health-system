/**
 * One-off bootstrap: grants the FIRST super_admin, since setUserRole itself
 * requires an existing super_admin caller (see README's "bootstrapping gap").
 * Every promotion after this one should go through setUserRole instead, so
 * it stays audit-logged.
 *
 * Usage (run from strola_health_firebase/functions/):
 *   node scripts/bootstrap-super-admin.js someone@example.com
 *
 * Needs credentials for the target Firebase project. Either:
 *   - `gcloud auth application-default login` (uses your own Google login), or
 *   - a service account key: Firebase console -> Project settings ->
 *     Service accounts -> Generate new private key, then
 *     `GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node scripts/bootstrap-super-admin.js ...`
 *
 * The target user must already exist in Firebase Auth (i.e. they've signed
 * up through the app or panel at least once) before running this.
 *
 * Race-condition note (found the hard way): if the account was created only
 * seconds ago, the `onUserCreate` Auth trigger may still be in flight and
 * can overwrite this script's claims/role write right back to "user" a
 * moment later (it does its own setCustomUserClaims + Firestore write on
 * every new user). This script verifies its write stuck a few seconds later
 * and retries once if a trigger race clobbered it — safe to run any time,
 * but if the account is brand new, waiting ~10s before running it avoids
 * the retry path entirely.
 */

const admin = require("firebase-admin");

const email = process.argv[2];
if (!email) {
  console.error("Usage: node scripts/bootstrap-super-admin.js <email>");
  process.exit(1);
}

admin.initializeApp();

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function promote(uid) {
  await admin.auth().setCustomUserClaims(uid, { role: "super_admin" });
  await admin.firestore().collection("users").doc(uid).set(
    { role: "super_admin", updated_at: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );
}

async function main() {
  const user = await admin.auth().getUserByEmail(email);
  await promote(user.uid);

  await sleep(6000);
  const recheck = await admin.auth().getUser(user.uid);
  if (recheck.customClaims?.role !== "super_admin") {
    console.log("onUserCreate trigger raced this write — re-applying once more.");
    await promote(user.uid);
  }

  console.log(`${email} (${user.uid}) is now super_admin.`);
  console.log("They'll need to sign out and back in (or wait for their next token refresh) to see it take effect.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
