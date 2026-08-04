import { type FirebaseApp, getApps, initializeApp } from "firebase/app";
import { connectAuthEmulator, getAuth, type Auth } from "firebase/auth";
import { connectFirestoreEmulator, getFirestore, type Firestore } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, type Functions } from "firebase/functions";
import { connectStorageEmulator, getStorage, type FirebaseStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const FUNCTIONS_REGION = process.env.NEXT_PUBLIC_FIREBASE_FUNCTIONS_REGION || "us-central1";

function getFirebaseApp(): FirebaseApp {
  const existing = getApps();
  return existing.length > 0 ? existing[0] : initializeApp(firebaseConfig);
}

let auth: Auth | null = null;
let authEmulatorConnected = false;

export function getFirebaseAuth(): Auth {
  if (!auth) {
    auth = getAuth(getFirebaseApp());
  }
  const emulatorHost = process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST;
  if (emulatorHost && !authEmulatorConnected) {
    connectAuthEmulator(auth, `http://${emulatorHost}`);
    authEmulatorConnected = true;
  }
  return auth;
}

let firestoreDb: Firestore | null = null;
let firestoreEmulatorConnected = false;

/** Direct Firestore reads — used for every collection the signed-in
 * caller's role is allowed to read per firestore.rules (see
 * strola_health_firebase/firestore.rules). Mutations never go through
 * here — those are Cloud Functions callables via getFunctionsClient(). */
export function getFirestoreDb(): Firestore {
  if (!firestoreDb) {
    firestoreDb = getFirestore(getFirebaseApp());
  }
  const emulatorHost = process.env.NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST;
  if (emulatorHost && !firestoreEmulatorConnected) {
    const [host, port] = emulatorHost.split(":");
    connectFirestoreEmulator(firestoreDb, host, Number(port));
    firestoreEmulatorConnected = true;
  }
  return firestoreDb;
}

let functionsClient: Functions | null = null;
let functionsEmulatorConnected = false;

/** Every mutation, and every read of an admin-locked-down collection (e.g.
 * integrationConnections, which strips OAuth tokens server-side before
 * returning), goes through a callable here. */
export function getFunctionsClient(): Functions {
  if (!functionsClient) {
    functionsClient = getFunctions(getFirebaseApp(), FUNCTIONS_REGION);
  }
  const emulatorHost = process.env.NEXT_PUBLIC_FUNCTIONS_EMULATOR_HOST;
  if (emulatorHost && !functionsEmulatorConnected) {
    const [host, port] = emulatorHost.split(":");
    connectFunctionsEmulator(functionsClient, host, Number(port));
    functionsEmulatorConnected = true;
  }
  return functionsClient;
}

let storage: FirebaseStorage | null = null;
let storageEmulatorConnected = false;

/** Direct browser-to-Storage uploads (challenge cover photos) — allowed by
 * storage.rules' `challenge_images/{adminUid}/{fileName}` rule for a
 * signed-in admin/super_admin, same direct-write shape as the mobile app's
 * community post images. */
export function getFirebaseStorage(): FirebaseStorage {
  if (!storage) {
    storage = getStorage(getFirebaseApp());
  }
  const emulatorHost = process.env.NEXT_PUBLIC_STORAGE_EMULATOR_HOST;
  if (emulatorHost && !storageEmulatorConnected) {
    const [host, port] = emulatorHost.split(":");
    connectStorageEmulator(storage, host, Number(port));
    storageEmulatorConnected = true;
  }
  return storage;
}
