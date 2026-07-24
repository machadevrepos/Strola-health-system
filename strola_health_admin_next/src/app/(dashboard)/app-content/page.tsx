"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { AppContentView } from "@/components/app-content/app-content-view";
import { fetchAppContent } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

export default function AppContentPage() {
  const { data: entries, loading, error, reload } = useApiData(fetchAppContent);

  return (
    <div>
      <PageHeader
        title="App Content"
        description="Every user-facing string in the app, organized by where it appears — with {Variable} support and an in-context preview. The app doesn't fetch this content yet (every string is still hardcoded in the Flutter build), so this is a staging library and spec for that wiring, not a live editor."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {entries && <AppContentView entries={entries} />}
    </div>
  );
}
