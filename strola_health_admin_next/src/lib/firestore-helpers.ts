import {
  collection,
  collectionGroup,
  doc,
  getDoc as fsGetDoc,
  getDocs as fsGetDocs,
  query,
  Timestamp,
  type QueryConstraint,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { getFirestoreDb, getFunctionsClient } from "@/lib/firebase-client";
import { ApiError } from "@/lib/api-client";

/**
 * Every doc in Firestore stores dates as native Timestamps; every type in
 * types.ts expects an ISO string (the whole type system mirrors what a JSON
 * REST API returns — see that file's header comment). This walks a doc's
 * data recursively and converts every Timestamp found, at any depth
 * (top-level fields like created_at, and nested ones like
 * subscription.comp_until or moderation.hidden_at).
 */
function convertTimestamps<T>(value: unknown): T {
  if (value instanceof Timestamp) {
    return value.toDate().toISOString() as unknown as T;
  }
  if (Array.isArray(value)) {
    return value.map((v) => convertTimestamps(v)) as unknown as T;
  }
  if (value && typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = convertTimestamps(v);
    }
    return out as T;
  }
  return value as T;
}

/** Fetch one document by path (e.g. "users/abc123"). Returns null if it
 * doesn't exist — callers decide whether that's a 404. */
export async function getDocData<T>(path: string): Promise<T | null> {
  const snap = await fsGetDoc(doc(getFirestoreDb(), path));
  if (!snap.exists()) return null;
  return convertTimestamps<T>(snap.data());
}

/** Same as getDocData, but throws a 404 ApiError instead of returning null
 * — for single-required-entity fetches (fetchUser, fetchChallenge) where
 * every caller's return type assumes the entity exists, matching how the
 * REST-backed mock/real split originally behaved (a missing id was always
 * a thrown 404, never a null). */
export async function getDocDataOrThrow<T>(path: string, notFoundMessage = "Not found"): Promise<T> {
  const data = await getDocData<T>(path);
  if (data === null) throw new ApiError(404, notFoundMessage);
  return data;
}

/** Fetch a document immediately after a mutation callable, for handlers
 * that only return `{success: true, ...}` — keeps every api.ts export
 * returning the full fresh entity, matching what mock-api.ts already
 * returns, so page/component code never needs to know which transport a
 * given function uses. */
export async function refetchDoc<T>(path: string): Promise<T> {
  return getDocDataOrThrow<T>(path, "Not found after mutation");
}

/** Fetch every document in a collection (optionally filtered/ordered),
 * converted and with each doc's own `id` field trusted over doc.id (every
 * Cloud Function writes `id: ref.id` into the document itself, so they
 * always match — this just avoids a second merge step). */
export async function getCollectionData<T>(
  path: string,
  ...constraints: QueryConstraint[]
): Promise<T[]> {
  const q = constraints.length > 0 ? query(collection(getFirestoreDb(), path), ...constraints) : collection(getFirestoreDb(), path);
  const snap = await fsGetDocs(q);
  return snap.docs.map((d) => convertTimestamps<T>(d.data()));
}

/** Fetch every document in a subcollection under a specific parent, e.g.
 * `getSubcollectionData("challenges/abc/participants")`. Same shape as
 * getCollectionData — Firestore doesn't distinguish top-level vs nested
 * collections at the API level, this just documents intent at call sites. */
export const getSubcollectionData = getCollectionData;

/** Fetch across every subcollection with a given name regardless of parent
 * — e.g. every post's `comments` subcollection at once. Requires
 * firestore.rules to allow the read for each matched doc (they do, scoped
 * per-doc same as any other query). */
export async function getCollectionGroupData<T>(
  collectionId: string,
  ...constraints: QueryConstraint[]
): Promise<T[]> {
  const q = query(collectionGroup(getFirestoreDb(), collectionId), ...constraints);
  const snap = await fsGetDocs(q);
  return snap.docs.map((d) => convertTimestamps<T>(d.data()));
}

/**
 * Invokes a deployed Cloud Functions callable and unwraps its `.data`.
 * Every mutation in this app goes through here — see
 * strola_health_firebase/functions/src for what each callable does.
 * Errors are normalized to the same `ApiError` shape api-client.ts's REST
 * path throws, so callers (and error-handling UI) don't need to care which
 * transport a given api.ts function uses under the hood.
 */
export async function callFn<TResult = unknown, TData = Record<string, unknown>>(
  name: string,
  data?: TData
): Promise<TResult> {
  try {
    const callable = httpsCallable<TData, TResult>(getFunctionsClient(), name);
    const result = await callable(data as TData);
    return result.data;
  } catch (err) {
    const code = (err as { code?: string })?.code ?? "unknown";
    const message = (err as { message?: string })?.message ?? "Something went wrong.";
    const status = HTTPS_ERROR_STATUS[code] ?? 500;
    throw new ApiError(status, message);
  }
}

const HTTPS_ERROR_STATUS: Record<string, number> = {
  "functions/unauthenticated": 401,
  "functions/permission-denied": 403,
  "functions/not-found": 404,
  "functions/invalid-argument": 400,
  "functions/failed-precondition": 409,
  "functions/already-exists": 409,
  "functions/internal": 500,
  "functions/unavailable": 503,
};
