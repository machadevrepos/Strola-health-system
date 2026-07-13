"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { ModerationView } from "@/components/moderation/moderation-view";
import { fetchComments, fetchPosts, fetchReports, fetchUsers } from "@/lib/data/api";
import { enrichComments, enrichPosts, enrichReports } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

async function loadModeration() {
  const [users, rawPosts, rawReports, rawComments] = await Promise.all([
    fetchUsers(),
    fetchPosts(true),
    fetchReports(),
    fetchComments(),
  ]);
  return {
    posts: enrichPosts(rawPosts, users),
    reports: enrichReports(rawReports, users, rawPosts),
    comments: enrichComments(rawComments, users, rawPosts),
    users,
  };
}

export default function ModerationPage() {
  const { data, loading, error, reload } = useApiData(loadModeration);

  return (
    <div>
      <PageHeader title="Moderation" description="Review community posts and resolve user reports." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <ModerationView posts={data.posts} reports={data.reports} comments={data.comments} users={data.users} />}
    </div>
  );
}
