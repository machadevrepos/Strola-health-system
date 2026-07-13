"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { LegalView } from "@/components/legal/legal-view";
import { fetchLegalDocuments } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

export default function LegalPage() {
  const { data: documents, loading, error, reload } = useApiData(fetchLegalDocuments);

  return (
    <div>
      <PageHeader title="Legal" description="Privacy Policy, Terms, and Community Guidelines." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {documents && <LegalView documents={documents} />}
    </div>
  );
}
