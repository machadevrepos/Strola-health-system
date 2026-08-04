type CacheEntry<T> = { value: T; expiresAt: number };

const store = new Map<string, CacheEntry<unknown>>();
const inflight = new Map<string, Promise<unknown>>();

const DEFAULT_TTL_MS = 30_000;

/**
 * In-memory read cache for api.ts's Firestore/Cloud Function reads. Without
 * this, every page navigation (or tab switch back to a page already
 * visited) re-runs a full Firestore read via useApiData's fetch-on-mount
 * behaviour. A short TTL turns that into a cache hit, while every mutation
 * below explicitly invalidates the keys it can affect, so an edit is always
 * reflected on the very next read rather than waiting out the TTL.
 *
 * In-flight de-duplication means two components requesting the same key at
 * once (e.g. two charts both reading `analyticsEvents`) share one network
 * call instead of firing it twice.
 */
export function getOrFetch<T>(key: string, fetcher: () => Promise<T>, ttlMs = DEFAULT_TTL_MS): Promise<T> {
  const hit = store.get(key);
  if (hit && hit.expiresAt > Date.now()) return Promise.resolve(hit.value as T);

  const pending = inflight.get(key);
  if (pending) return pending as Promise<T>;

  const promise = fetcher()
    .then((value) => {
      store.set(key, { value, expiresAt: Date.now() + ttlMs });
      inflight.delete(key);
      return value;
    })
    .catch((err) => {
      inflight.delete(key);
      throw err;
    });
  inflight.set(key, promise);
  return promise;
}

/** Drops every cached entry at `prefix` or nested under `${prefix}:...` —
 * call after any mutation that could change what a cached read returns. */
export function invalidate(prefix: string): void {
  for (const key of store.keys()) {
    if (key === prefix || key.startsWith(`${prefix}:`)) store.delete(key);
  }
}

/** Runs `promise`, invalidates the given prefixes on success, and passes
 * the result through unchanged — lets a mutation stay a one-liner. */
export function invalidateAfter<T>(promise: Promise<T>, ...prefixes: string[]): Promise<T> {
  return promise.then((result) => {
    for (const p of prefixes) invalidate(p);
    return result;
  });
}
