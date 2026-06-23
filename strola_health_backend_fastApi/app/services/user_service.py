from app.core.exceptions import ConflictError, NotFoundError
from app.core.time import utcnow
from app.models.user import PrivacySettingsUpdate, PublicUserProfile, UserProfile, UserProfileUpdate
from app.repositories.user_repository import UserRepository


class UserService:
    def __init__(self, user_repo: UserRepository):
        self._users = user_repo

    def get(self, uid: str) -> UserProfile | None:
        return self._users.get(uid)

    def get_public(self, uid: str) -> PublicUserProfile | None:
        profile = self._users.get(uid)
        return PublicUserProfile.from_profile(profile) if profile else None

    def update_profile(self, uid: str, payload: UserProfileUpdate) -> UserProfile:
        profile = self._users.get(uid)
        if not profile:
            raise NotFoundError(f"User {uid} not found")

        updates = payload.model_dump(exclude_unset=True)
        if "username" in updates and updates["username"] != profile.username:
            existing = self._users.get_by_username(updates["username"])
            if existing and existing.id != uid:
                raise ConflictError("Username already taken")

        updates["updated_at"] = utcnow()
        self._users.update(uid, updates)
        return self._users.get(uid)

    def update_privacy(self, uid: str, payload: PrivacySettingsUpdate) -> UserProfile:
        if not self._users.get(uid):
            raise NotFoundError(f"User {uid} not found")
        updates = {f"privacy.{k}": v for k, v in payload.model_dump(exclude_unset=True).items()}
        updates["updated_at"] = utcnow()
        self._users.update(uid, updates)
        return self._users.get(uid)
