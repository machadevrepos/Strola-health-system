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
        description="Edit welcome messages, challenge descriptions, quotes, notification text, and empty states — no app update needed."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {entries && <AppContentView entries={entries} />}
    </div>
  );
}
