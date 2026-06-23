import { type FirebaseApp, getApps, initializeApp } from "firebase/app";
import { connectAuthEmulator, getAuth, type Auth } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
};

function getFirebaseApp(): FirebaseApp {
  const existing = getApps();
  return existing.length > 0 ? existing[0] : initializeApp(firebaseConfig);
}

let auth: Auth | null = null;
let connectedToEmulator = false;

export function getFirebaseAuth(): Auth {
  if (!auth) {
    auth = getAuth(getFirebaseApp());
  }
  const emulatorHost = process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST;
  if (emulatorHost && !connectedToEmulator) {
    connectAuthEmulator(auth, `http://${emulatorHost}`);
    connectedToEmulator = true;
  }
  return auth;
}
