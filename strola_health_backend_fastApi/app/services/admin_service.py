from app.core.exceptions import NotFoundError
from app.core.time import utcnow
from app.models.feature_flag import FeatureFlag, FeatureFlagUpdate
from app.models.user import Role, UserProfile
from app.repositories.feature_flag_repository import FeatureFlagRepository
from app.repositories.user_repository import UserRepository
from app.services.auth_service import AuthService


class AdminService:
    def __init__(self, user_repo: UserRepository, auth_service: AuthService, flag_repo: FeatureFlagRepository):
        self._users = user_repo
        self._auth = auth_service
        self._flags = flag_repo

    def set_role(self, uid: str, role: Role) -> None:
        if not self._users.get(uid):
            raise NotFoundError(f"User {uid} not found")
        self._auth.promote(uid, role)

    def ban(self, uid: str, *, reason: str) -> None:
        if not self._users.get(uid):
            raise NotFoundError(f"User {uid} not found")
        self._users.update(uid, {"banned": True, "ban_reason": reason, "updated_at": utcnow()})

    def unban(self, uid: str) -> None:
        if not self._users.get(uid):
            raise NotFoundError(f"User {uid} not found")
        self._users.update(uid, {"banned": False, "ban_reason": None, "updated_at": utcnow()})

    def search_users(self, *, banned: bool | None = None, limit: int = 50) -> list[UserProfile]:
        return self._users.search(banned=banned, limit=limit)

    def set_feature_flag(self, key: str, payload: FeatureFlagUpdate) -> FeatureFlag:
        flag = FeatureFlag(
            key=key,
            required_tier=payload.required_tier,
            description=payload.description,
            updated_at=utcnow(),
        )
        return self._flags.upsert(key, flag)

    def list_feature_flags(self) -> list[FeatureFlag]:
        return self._flags.list_all()
