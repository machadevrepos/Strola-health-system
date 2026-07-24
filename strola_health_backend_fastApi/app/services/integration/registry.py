from app.core.config import Settings
from app.models.enums import DataSource
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.repositories.user_repository import UserRepository
from app.services.activity_service import ActivityService
from app.services.integration.base import OAuthHealthProvider
from app.services.integration.garmin import GarminProvider
from app.services.integration.oura import OuraProvider
from app.services.integration.strava import StravaProvider


def build_oauth_providers(
    settings: Settings,
    connection_repo: IntegrationConnectionRepository,
    activity_service: ActivityService,
    user_repo: UserRepository,
) -> dict[DataSource, OAuthHealthProvider]:
    """The dispatch table the integrations router uses to route
    `/integrations/{provider}/...` requests. Apple Health and Health Connect
    are deliberately absent — they're not OAuth providers, see
    `apple_health.py` / `health_connect.py`."""
    deps = (connection_repo, activity_service, user_repo)
    return {
        DataSource.oura: OuraProvider(settings, *deps),
        DataSource.garmin: GarminProvider(settings, *deps),
        DataSource.strava: StravaProvider(settings, *deps),
    }
