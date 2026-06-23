from app.core.config import Settings
from app.models.enums import DataSource
from app.services.integration.base import OAuthHealthProvider
from app.services.integration.garmin import GarminProvider
from app.services.integration.oura import OuraProvider
from app.services.integration.strava import StravaProvider


def build_oauth_providers(settings: Settings) -> dict[DataSource, OAuthHealthProvider]:
    """The dispatch table the integrations router uses to route
    `/integrations/{provider}/...` requests. Apple Health and Health Connect
    are deliberately absent — they're not OAuth providers, see
    `apple_health.py` / `health_connect.py`."""
    return {
        DataSource.oura: OuraProvider(settings),
        DataSource.garmin: GarminProvider(settings),
        DataSource.strava: StravaProvider(settings),
    }
