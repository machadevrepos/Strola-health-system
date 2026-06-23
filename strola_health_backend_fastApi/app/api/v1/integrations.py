from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import (
    get_activity_service,
    get_analytics_service,
    get_current_user,
    get_integration_repository,
    get_oauth_providers,
)
from app.core.time import utcnow
from app.models.analytics import AnalyticsEventType
from app.models.enums import DataSource
from app.models.integration import (
    ConnectionStatus,
    HealthSampleIngest,
    IntegrationConnection,
    OAuthConnectResponse,
)
from app.models.user import UserProfile
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.services.activity_service import ActivityService
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/integrations", tags=["integrations"])

_ON_DEVICE_SOURCES = {DataSource.healthkit, DataSource.health_connect}


@router.get("", response_model=list[IntegrationConnection])
def list_my_integrations(
    current: UserProfile = Depends(get_current_user),
    repo: IntegrationConnectionRepository = Depends(get_integration_repository),
) -> list[IntegrationConnection]:
    return repo.list_for_user(current.id)


@router.get("/{provider}/connect", response_model=OAuthConnectResponse)
def connect(
    provider: DataSource,
    current: UserProfile = Depends(get_current_user),
    providers: dict = Depends(get_oauth_providers),
) -> OAuthConnectResponse:
    adapter = providers.get(provider)
    if not adapter:
        raise HTTPException(status_code=400, detail=f"{provider.value} is not a connectable OAuth provider")
    return OAuthConnectResponse(authorization_url=adapter.get_authorization_url(current.id))


@router.get("/{provider}/callback", response_model=IntegrationConnection)
def callback(
    provider: DataSource,
    code: str,
    state: str,
    providers: dict = Depends(get_oauth_providers),
) -> IntegrationConnection:
    """No `get_current_user` dependency here on purpose: this request comes
    from the provider's own redirect (typically inside a webview), not from
    our authenticated app, so there's no Bearer token to rely on. `state`
    carries the Strolla user id, set when `connect` built the authorization
    URL. For production hardening, swap the raw user id for a signed/random
    state token mapped server-side, to rule out state-forgery — left as the
    raw id for now since these adapters are still stubbed pending API
    credentials anyway."""
    adapter = providers.get(provider)
    if not adapter:
        raise HTTPException(status_code=400, detail=f"{provider.value} is not a connectable OAuth provider")
    return adapter.handle_callback(state, code)


@router.post("/{provider}/webhook")
def webhook(
    provider: DataSource,
    payload: dict,
    providers: dict = Depends(get_oauth_providers),
) -> dict:
    """Unauthenticated by design — webhook calls come from the provider, not
    our app, and each provider has its own signature-verification scheme
    (not yet implemented; see the adapter's `handle_webhook` docstring)."""
    adapter = providers.get(provider)
    if not adapter:
        raise HTTPException(status_code=400, detail=f"{provider.value} has no webhook handler")
    adapter.handle_webhook(payload)
    return {"status": "received"}


@router.post("/{provider}/connected", status_code=204)
def mark_on_device_connected(
    provider: DataSource,
    current: UserProfile = Depends(get_current_user),
    repo: IntegrationConnectionRepository = Depends(get_integration_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
) -> None:
    """HealthKit/Health Connect have no OAuth callback to hang a "connected"
    event off — the app calls this directly once the user grants on-device
    permission, so it shows up the same way an OAuth connection would."""
    if provider not in _ON_DEVICE_SOURCES:
        raise HTTPException(status_code=400, detail=f"{provider.value} connects via OAuth, not this endpoint")
    connection = IntegrationConnection(
        id=repo.doc_id(current.id, provider),
        user_id=current.id,
        provider=provider,
        status=ConnectionStatus.connected,
        connected_at=utcnow(),
    )
    repo.upsert(connection.id, connection)
    analytics.track(AnalyticsEventType.health_app_connected, user_id=current.id, metadata={"provider": provider.value})


@router.post("/ingest")
def ingest_health_sample(
    payload: HealthSampleIngest,
    current: UserProfile = Depends(get_current_user),
    activity_service: ActivityService = Depends(get_activity_service),
) -> dict:
    """The entire backend integration point for Apple Health / Health
    Connect — see `app/services/integration/apple_health.py` for why there's
    no OAuth adapter for these two, and why this is also the fallback
    step-count source for users without a Strolla device."""
    summary = activity_service.ingest_health_sample(current.id, payload)
    return {"date": summary.date.isoformat(), "steps": summary.steps}
