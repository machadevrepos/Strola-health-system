from google.cloud import firestore

from app.models.badge import Badge, UserBadge
from app.repositories.base import FirestoreRepository


class BadgeRepository(FirestoreRepository[Badge]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "badges", Badge)


class UserBadgeRepository(FirestoreRepository[UserBadge]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "user_badges", UserBadge)

    @staticmethod
    def doc_id(user_id: str, badge_id: str) -> str:
        return f"{user_id}_{badge_id}"

    def list_for_user(self, user_id: str) -> list[UserBadge]:
        return self.query([("user_id", "==", user_id)])

    def list_all(self, *, limit: int = 5000) -> list[UserBadge]:
        """Every award across every user — the admin badges UI filters this
        client-side for both "who has badge X" and "this user's badges"
        rather than needing a bespoke endpoint per view, at the award volume
        this app generates."""
        return self.query(limit=limit)
