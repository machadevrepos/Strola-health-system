"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { LegalView } from "@/components/legal/legal-view";
import { fetchLegalAcceptances, fetchLegalVersions } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadLegal() {
  const [versions, acceptances] = await Promise.all([fetchLegalVersions(), fetchLegalAcceptances()]);
  return { versions, acceptances };
}

export default function LegalPage() {
  const { data, loading, error, reload } = useApiData(loadLegal);

  return (
    <div>
      <PageHeader
        title="Legal"
        description="Privacy Policy, Terms, and Community Guidelines — drafts and publishing are separate, with full version history."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <LegalView {...data} />}
    </div>
  );
}
