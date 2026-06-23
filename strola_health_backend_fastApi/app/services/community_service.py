import uuid
from datetime import timedelta

from google.cloud import firestore

from app.core.exceptions import NotFoundError
from app.core.time import utcnow
from app.models.analytics import AnalyticsEventType
from app.models.community import CommunityPost, CommunityPostCreate, CommunityPostUpdate
from app.repositories.community_repository import CommunityPostRepository, PostLikeRepository
from app.services.analytics_service import AnalyticsService


class CommunityService:
    def __init__(
        self,
        post_repo: CommunityPostRepository,
        like_repo: PostLikeRepository,
        analytics: AnalyticsService,
    ):
        self._posts = post_repo
        self._likes = like_repo
        self._analytics = analytics

    def create_post(self, user_id: str, payload: CommunityPostCreate) -> CommunityPost:
        post = CommunityPost(
            id=str(uuid.uuid4()),
            author_id=user_id,
            content=payload.content,
            timestamp=utcnow(),
            step_count=payload.step_count,
            badge_emoji=payload.badge_emoji,
            image_url=payload.image_url,
        )
        self._posts.upsert(post.id, post)
        self._analytics.track(AnalyticsEventType.community_post_created, user_id=user_id)
        return post

    def list_feed(self, *, limit: int = 20, include_hidden: bool = False) -> list[CommunityPost]:
        return self._posts.list_feed(limit=limit, include_hidden=include_hidden)

    def list_by_author(self, author_id: str, *, limit: int = 50) -> list[CommunityPost]:
        return self._posts.list_by_author(author_id, limit=limit)

    def toggle_like(self, user_id: str, post_id: str) -> CommunityPost:
        """Atomic like/unlike: a `post_likes` doc is the idempotency/dedup
        record, and `likes_count` is incremented/decremented in the same
        Firestore transaction so concurrent likes can't desync the counter —
        the original mock repo's plain `likes +/- 1` doesn't hold up once more
        than one user can like a post at the same time.
        """
        post_ref = self._posts.collection.document(post_id)
        like_ref = self._likes.collection.document(self._likes.doc_id(post_id, user_id))

        @firestore.transactional
        def _run(transaction: firestore.Transaction) -> None:
            post_snap = post_ref.get(transaction=transaction)
            if not post_snap.exists:
                raise NotFoundError("Post not found")
            like_snap = like_ref.get(transaction=transaction)
            likes_count = post_snap.to_dict().get("likes_count", 0)

            if like_snap.exists:
                transaction.delete(like_ref)
                transaction.update(post_ref, {"likes_count": max(0, likes_count - 1)})
            else:
                transaction.set(
                    like_ref,
                    {"id": like_ref.id, "post_id": post_id, "user_id": user_id, "created_at": utcnow()},
                )
                transaction.update(post_ref, {"likes_count": likes_count + 1})

        _run(self._posts.client.transaction())
        return self._posts.get(post_id)

    def has_liked(self, post_id: str, user_id: str) -> bool:
        return self._likes.has_liked(post_id, user_id)

    def hide_post(self, post_id: str, *, admin_id: str, reason: str | None) -> None:
        if not self._posts.get(post_id):
            raise NotFoundError("Post not found")
        self._posts.update(
            post_id,
            {
                "moderation.hidden": True,
                "moderation.hidden_by": admin_id,
                "moderation.hidden_reason": reason,
                "moderation.hidden_at": utcnow(),
            },
        )

    def unhide_post(self, post_id: str) -> None:
        if not self._posts.get(post_id):
            raise NotFoundError("Post not found")
        self._posts.update(
            post_id,
            {
                "moderation.hidden": False,
                "moderation.hidden_by": None,
                "moderation.hidden_reason": None,
                "moderation.hidden_at": None,
            },
        )

    def update_post(self, post_id: str, payload: CommunityPostUpdate) -> CommunityPost:
        if not self._posts.get(post_id):
            raise NotFoundError("Post not found")
        updates = payload.model_dump(exclude_unset=True)
        if updates:
            self._posts.update(post_id, updates)
        return self._posts.get(post_id)

    def remove_photo(self, post_id: str) -> None:
        if not self._posts.get(post_id):
            raise NotFoundError("Post not found")
        self._posts.update(post_id, {"image_url": None})

    def delete_post(self, post_id: str) -> None:
        self._posts.delete(post_id)

    def delete_photos_older_than(self, retention_days: int) -> int:
        """Documented 6-month photo retention policy. This is a callable
        method, not a live scheduled job — there's no Cloud Scheduler wired
        up yet, so invoke it manually (or behind a future cron endpoint)
        until that's set up. Returns the number of posts whose photo was
        cleared."""
        cutoff = utcnow() - timedelta(days=retention_days)
        candidates = self._posts.list_with_photos_older_than(cutoff)
        for post in candidates:
            self._posts.update(post.id, {"image_url": None})
        return len(candidates)
