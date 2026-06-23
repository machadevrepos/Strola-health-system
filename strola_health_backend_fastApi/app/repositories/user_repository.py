from google.cloud import firestore

from app.models.user import Role, UserProfile
from app.repositories.base import FirestoreRepository


class UserRepository(FirestoreRepository[UserProfile]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "users", UserProfile)

    def get_by_username(self, username: str) -> UserProfile | None:
        results = self.query([("username", "==", username)], limit=1)
        return results[0] if results else None

    def list_by_role(self, role: Role, *, limit: int = 100) -> list[UserProfile]:
        return self.query([("role", "==", role)], limit=limit)

    def search(self, *, banned: bool | None = None, limit: int = 50) -> list[UserProfile]:
        filters = []
        if banned is not None:
            filters.append(("banned", "==", banned))
        return self.query(filters, order_by="created_at", descending=True, limit=limit)
