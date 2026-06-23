from datetime import datetime, timezone

from app.core.exceptions import NotFoundError
from app.core.time import utcnow
from app.models.analytics import AnalyticsEventType
from app.models.user import SubscriptionStatus, SubscriptionTier
from app.repositories.user_repository import UserRepository
from app.services.analytics_service import AnalyticsService

# RevenueCat webhook event "type" values that grant/extend premium access.
_ACTIVE_EVENT_TYPES = {
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "NON_RENEWING_PURCHASE",
    "PRODUCT_CHANGE",
}
_CANCEL_EVENT_TYPES = {"CANCELLATION"}
_EXPIRE_EVENT_TYPES = {"EXPIRATION"}


class SubscriptionService:
    """Consumes RevenueCat webhook events to keep `users/{uid}.subscription`
    in sync. RevenueCat — not Strolla — is the system of record for the
    actual purchase/receipt (and therefore for PCI/App Store/Play Store
    compliance); this only mirrors enough state to gate features.
    """

    def __init__(self, user_repo: UserRepository, analytics: AnalyticsService):
        self._users = user_repo
        self._analytics = analytics

    def handle_webhook_event(self, event: dict) -> None:
        event_type = event.get("type")
        app_user_id = event.get("app_user_id")
        if not app_user_id:
            return
        user = self._users.get(app_user_id)
        if not user:
            return  # event for a user we don't have a profile for — ignore rather than error

        expiration_ms = event.get("expiration_at_ms")
        renews_at = datetime.fromtimestamp(expiration_ms / 1000, tz=timezone.utc) if expiration_ms else None

        subscription = user.subscription
        subscription.revenuecat_app_user_id = app_user_id

        if event_type in _ACTIVE_EVENT_TYPES:
            subscription.tier = SubscriptionTier.premium
            subscription.status = SubscriptionStatus.active
            subscription.renews_at = renews_at
            subscription.cancelled_at = None
            self._analytics.track(
                AnalyticsEventType.premium_started, user_id=user.id, metadata={"revenuecat_event": event_type}
            )
        elif event_type in _CANCEL_EVENT_TYPES:
            # Cancelled but still entitled until the current period ends —
            # RevenueCat sends EXPIRATION separately once that actually elapses.
            subscription.cancelled_at = utcnow()
            self._analytics.track(
                AnalyticsEventType.premium_cancelled, user_id=user.id, metadata={"revenuecat_event": event_type}
            )
        elif event_type in _EXPIRE_EVENT_TYPES:
            subscription.tier = SubscriptionTier.free
            subscription.status = SubscriptionStatus.expired

        self._users.update(
            user.id, {"subscription": subscription.model_dump(mode="python"), "updated_at": utcnow()}
        )

    def grant_comp_period(self, user_id: str, *, until: datetime, reason: str) -> None:
        """Single primitive behind the automatic signup trial, a Kickstarter
        backer's 6-month reward, and an admin's manual 'grant premium' action
        from the dashboard — all three are just this call with a different
        `reason` and `until` date."""
        user = self._users.get(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found")
        user.subscription.comp_until = until
        user.subscription.comp_reason = reason
        self._users.update(
            user_id, {"subscription": user.subscription.model_dump(mode="python"), "updated_at": utcnow()}
        )

    def revoke_comp(self, user_id: str) -> None:
        """Clears a comp grant (trial, Kickstarter reward, admin grant)
        early. Deliberately does NOT touch `tier`/`status` — those reflect a
        real RevenueCat-driven purchase if one exists, and revoking a comp
        period must never silently cancel an actual paid subscription. A
        genuine subscription is cancelled through the App Store/Play Store,
        which flows back here via the RevenueCat webhook."""
        user = self._users.get(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found")
        user.subscription.comp_until = None
        user.subscription.comp_reason = None
        self._users.update(
            user_id, {"subscription": user.subscription.model_dump(mode="python"), "updated_at": utcnow()}
        )
