from datetime import datetime

from google.cloud import firestore

from app.models.community import CommunityPost, PostLike
from app.repositories.base import FirestoreRepository


class CommunityPostRepository(FirestoreRepository[CommunityPost]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "community_posts", CommunityPost)

    def list_feed(self, *, limit: int = 20, include_hidden: bool = False) -> list[CommunityPost]:
        filters = [] if include_hidden else [("moderation.hidden", "==", False)]
        return self.query(filters, order_by="timestamp", descending=True, limit=limit)

    def list_by_author(self, author_id: str, *, limit: int = 50) -> list[CommunityPost]:
        return self.query([("author_id", "==", author_id)], order_by="timestamp", descending=True, limit=limit)

    def list_with_photos_older_than(self, cutoff: datetime, *, limit: int = 500) -> list[CommunityPost]:
        """Candidates for the photo-retention cleanup. Firestore can't filter
        on "image_url is not null" directly, so this over-fetches by date and
        filters client-side — acceptable at today's post volume."""
        candidates = self.query([("timestamp", "<", cutoff)], limit=limit)
        return [p for p in candidates if p.image_url]


class PostLikeRepository(FirestoreRepository[PostLike]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "post_likes", PostLike)

    @staticmethod
    def doc_id(post_id: str, user_id: str) -> str:
        return f"{post_id}_{user_id}"

    def has_liked(self, post_id: str, user_id: str) -> bool:
        return self.get(self.doc_id(post_id, user_id)) is not None
