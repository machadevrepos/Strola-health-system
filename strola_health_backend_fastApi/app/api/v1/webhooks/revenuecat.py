from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.api.deps import get_subscription_service
from app.core.config import Settings, get_settings
from app.services.subscription_service import SubscriptionService

router = APIRouter(tags=["webhooks"])


@router.post("/revenuecat")
def receive_revenuecat_event(
    body: dict,
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
    service: SubscriptionService = Depends(get_subscription_service),
) -> dict:
    """RevenueCat authenticates webhooks with a static bearer token you set
    in their dashboard (Project Settings > Webhooks), not a request
    signature — verified here against `REVENUECAT_WEBHOOK_AUTH_TOKEN`.
    """
    expected = settings.revenuecat_webhook_auth_token
    if expected and authorization != f"Bearer {expected}":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid webhook token")

    event = body.get("event", {})
    service.handle_webhook_event(event)
    return {"status": "ok"}
