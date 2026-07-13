"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { AnnouncementsView } from "@/components/announcements/announcements-view";
import { fetchAnnouncements, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadAnnouncements() {
  const [announcements, users] = await Promise.all([fetchAnnouncements(), fetchUsers()]);
  return { announcements, users };
}

export default function AnnouncementsPage() {
  const { data, loading, error, reload } = useApiData(loadAnnouncements);

  return (
    <div>
      <PageHeader
        title="Announcements"
        description="A message shown once per user when they open the app — a direct line to every user, no email or push needed."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <AnnouncementsView announcements={data.announcements} users={data.users} />}
    </div>
  );
}
