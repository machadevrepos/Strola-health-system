from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central app configuration, loaded from environment variables / .env.

    Anything that looks like a secret (API keys, client secrets) is read here
    and nowhere else — services receive values, never read os.environ
    themselves, so there is exactly one place to audit for credentials.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Strolla Health API"
    api_v1_prefix: str = "/api/v1"

    firebase_credentials_path: str | None = None
    firebase_project_id: str | None = None
    firestore_emulator_host: str | None = None
    firebase_auth_emulator_host: str | None = None

    allowed_origins: str = "http://localhost:3000"

    revenuecat_webhook_auth_token: str | None = None

    oura_client_id: str | None = None
    oura_client_secret: str | None = None
    oura_redirect_uri: str | None = None

    garmin_client_id: str | None = None
    garmin_client_secret: str | None = None
    garmin_redirect_uri: str | None = None

    strava_client_id: str | None = None
    strava_client_secret: str | None = None
    strava_redirect_uri: str | None = None

    # Default daily step goal used for new users before they set their own,
    # and as the locked goal fallback for challenge participants who never set one.
    default_daily_goal_steps: int = 10_000

    # Automatic free trial granted to every new account on signup.
    trial_period_days: int = 30

    # Post images older than this are eligible for deletion by the (currently
    # manually-invoked, not yet scheduled) photo retention cleanup.
    photo_retention_days: int = 180

    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
