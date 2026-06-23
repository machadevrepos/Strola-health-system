import uuid

from app.core.exceptions import ConflictError, NotFoundError
from app.core.time import utcnow
from app.models.badge import Badge, BadgeCreate, BadgeUpdate, UserBadge
from app.repositories.badge_repository import BadgeRepository, UserBadgeRepository


class BadgeService:
    def __init__(self, badge_repo: BadgeRepository, user_badge_repo: UserBadgeRepository):
        self._badges = badge_repo
        self._user_badges = user_badge_repo

    def create(self, payload: BadgeCreate) -> Badge:
        badge = Badge(
            id=str(uuid.uuid4()),
            name=payload.name,
            description=payload.description,
            emoji=payload.emoji,
            created_at=utcnow(),
        )
        return self._badges.upsert(badge.id, badge)

    def list_all(self) -> list[Badge]:
        return self._badges.query(limit=200)

    def update(self, badge_id: str, payload: BadgeUpdate) -> Badge:
        if not self._badges.get(badge_id):
            raise NotFoundError("Badge not found")
        updates = payload.model_dump(exclude_unset=True)
        if updates:
            self._badges.update(badge_id, updates)
        return self._badges.get(badge_id)

    def delete(self, badge_id: str) -> None:
        """Cascades to awards — a deleted badge shouldn't leave user_badges
        rows pointing at a badge that no longer exists."""
        if not self._badges.get(badge_id):
            raise NotFoundError("Badge not found")
        for award in self._user_badges.query([("badge_id", "==", badge_id)], limit=10_000):
            self._user_badges.delete(award.id)
        self._badges.delete(badge_id)

    def award(self, user_id: str, badge_id: str, *, awarded_by: str | None = None) -> UserBadge:
        if not self._badges.get(badge_id):
            raise NotFoundError("Badge not found")
        doc_id = self._user_badges.doc_id(user_id, badge_id)
        if self._user_badges.get(doc_id):
            raise ConflictError("Badge already awarded to this user")
        award = UserBadge(
            id=doc_id, user_id=user_id, badge_id=badge_id, awarded_at=utcnow(), awarded_by=awarded_by
        )
        return self._user_badges.upsert(award.id, award)

    def list_for_user(self, user_id: str) -> list[UserBadge]:
        return self._user_badges.list_for_user(user_id)

    def list_all_awards(self) -> list[UserBadge]:
        return self._user_badges.list_all()

    def revoke(self, user_id: str, badge_id: str) -> None:
        doc_id = self._user_badges.doc_id(user_id, badge_id)
        if not self._user_badges.get(doc_id):
            raise NotFoundError("This user doesn't have that badge")
        self._user_badges.delete(doc_id)
