"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { CommunityView } from "@/components/community/community-view";
import { fetchComments, fetchPosts, fetchUsers } from "@/lib/data/api";
import { enrichComments, enrichPosts } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

async function loadCommunity() {
  const [users, rawPosts, rawComments] = await Promise.all([fetchUsers(), fetchPosts(true), fetchComments()]);
  return {
    posts: enrichPosts(rawPosts, users),
    comments: enrichComments(rawComments, users, rawPosts),
    users,
  };
}

export default function CommunityPage() {
  const { data, loading, error, reload } = useApiData(loadCommunity);

  return (
    <div>
      <PageHeader title="Community" description="Posts, comments, and photos shared across the app." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <CommunityView posts={data.posts} comments={data.comments} users={data.users} />}
    </div>
  );
}
