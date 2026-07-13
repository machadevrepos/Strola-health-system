"use client";

import * as React from "react";
import Image from "next/image";
import Link from "next/link";
import { ImageBroken, ImageSquare } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { userDisplayName } from "@/lib/data/queries";
import { formatRelative } from "@/lib/format";
import type { EnrichedPost } from "@/lib/data/queries";

export function PhotosPanel({
  posts,
  onRemovePhoto,
}: {
  posts: EnrichedPost[];
  onRemovePhoto: (postId: string) => void | Promise<void>;
}) {
  const withPhotos = posts.filter((p) => p.image_url);

  if (withPhotos.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 py-16 text-center text-muted-foreground">
        <ImageSquare size={24} />
        <p className="text-sm">No posts have a photo attached right now.</p>
      </div>
    );
  }

  return (
    <div>
      <p className="mb-3 text-xs text-muted-foreground">{withPhotos.length} photo{withPhotos.length === 1 ? "" : "s"} across all posts.</p>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        {withPhotos.map((post) => (
          <div key={post.id} className="group relative overflow-hidden rounded-lg border border-border">
            <div className="relative aspect-square w-full">
              <Image src={post.image_url!} alt="" fill className="object-cover" sizes="(min-width: 1024px) 25vw, 33vw" />
            </div>
            {post.moderation.hidden && (
              <Badge variant="destructive" className="absolute left-1.5 top-1.5">
                Hidden
              </Badge>
            )}
            <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 to-transparent p-2 pt-6">
              <Link href={`/users/${post.author_id}`} className="truncate text-xs font-medium text-white hover:underline">
                {userDisplayName(post.author)}
              </Link>
              <p className="truncate text-[11px] text-white/75">{formatRelative(post.timestamp)}</p>
            </div>
            <Button
              variant="secondary"
              size="icon-sm"
              className="absolute right-1.5 top-1.5 opacity-0 shadow-sm transition-opacity group-hover:opacity-100"
              aria-label="Remove photo"
              onClick={() => onRemovePhoto(post.id)}
            >
              <ImageBroken size={14} />
            </Button>
          </div>
        ))}
      </div>
    </div>
  );
}
