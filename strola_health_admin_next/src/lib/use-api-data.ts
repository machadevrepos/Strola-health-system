"use client";

import * as React from "react";
import { ApiError } from "@/lib/api-client";

interface ApiDataState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
}

/**
 * Fetches once on mount (and whenever `deps` change), via a real backend
 * call rather than a synchronous mock-data read — every dashboard page is a
 * client component for this reason, since the Firebase ID token used to
 * authenticate each request only resolves in the browser.
 */
export function useApiData<T>(fetcher: () => Promise<T>, deps: React.DependencyList = []): ApiDataState<T> {
  const [data, setData] = React.useState<T | null>(null);
  const [error, setError] = React.useState<string | null>(null);
  const [loading, setLoading] = React.useState(true);

  const load = React.useCallback(() => {
    setLoading(true);
    setError(null);
    fetcher()
      .then((result) => setData(result))
      .catch((err) => setError(err instanceof ApiError ? err.message : "Something went wrong loading this page."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  React.useEffect(() => {
    load();
  }, [load]);

  return { data, loading, error, reload: load };
}
