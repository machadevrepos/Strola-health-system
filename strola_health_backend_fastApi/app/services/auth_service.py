from datetime import timedelta

from app.core.security import set_role_claim
from app.core.time import utcnow
from app.models.analytics import AnalyticsEventType
from app.models.user import Role, Subscription, SubscriptionStatus, UserProfile
from app.repositories.user_repository import UserRepository
from app.services.analytics_service import AnalyticsService


class AuthService:
    def __init__(self, user_repo: UserRepository, analytics: AnalyticsService, *, trial_period_days: int):
        self._users = user_repo
        self._analytics = analytics
        self._trial_period_days = trial_period_days

    def get_or_provision(self, uid: str, email: str | None) -> UserProfile:
        """Just-in-time provisioning: the first authenticated request from a
        new Firebase Auth user creates their Firestore profile, including the
        automatic free trial the client wants every signup to get without any
        purchase flow."""
        existing = self._users.get(uid)
        if existing:
            return existing

        now = utcnow()
        profile = UserProfile(
            id=uid,
            email=email,
            subscription=Subscription(
                status=SubscriptionStatus.trialing,
                comp_until=now + timedelta(days=self._trial_period_days),
                comp_reason="signup_trial",
            ),
            created_at=now,
            updated_at=now,
        )
        self._users.upsert(uid, profile)
        self._analytics.track(AnalyticsEventType.account_created, user_id=uid)
        return profile

    def promote(self, uid: str, role: Role) -> None:
        self._users.update(uid, {"role": role.value, "updated_at": utcnow()})
        set_role_claim(uid, role.value)

    def ensure_first_super_admin(self, uid: str) -> bool:
        """Safe one-time bootstrap: only promotes if no super_admin exists yet
        anywhere in the system. Meant to be invoked once, manually (e.g. from
        a Python shell during initial setup) — never expose this over HTTP as
        a self-service route, promoting to super_admin must never be
        reachable by an unprivileged caller."""
        if self._users.list_by_role(Role.super_admin, limit=1):
            return False
        self.promote(uid, Role.super_admin)
        return True
