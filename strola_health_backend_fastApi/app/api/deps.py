from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.cloud import firestore

from app.core.config import Settings, get_settings
from app.core.firebase import get_firestore
from app.core.security import verify_firebase_token
from app.models.user import Role, UserProfile
from app.repositories.activity_repository import DailyActivitySummaryRepository, WorkoutSessionRepository
from app.repositories.analytics_repository import AnalyticsEventRepository
from app.repositories.badge_repository import BadgeRepository, UserBadgeRepository
from app.repositories.challenge_repository import ChallengeParticipantRepository, ChallengeRepository
from app.repositories.community_repository import CommunityPostRepository, PostLikeRepository
from app.repositories.device_repository import DeviceRepository, DevicePairingEventRepository
from app.repositories.feature_flag_repository import FeatureFlagRepository
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.user_repository import UserRepository
from app.services.activity_service import ActivityService
from app.services.admin_service import AdminService
from app.services.analytics_service import AnalyticsService
from app.services.auth_service import AuthService
from app.services.badge_service import BadgeService
from app.services.challenge_service import ChallengeService
from app.services.community_service import CommunityService
from app.services.deletion_service import DeletionService
from app.services.device_service import DeviceService
from app.services.integration.registry import build_oauth_providers
from app.services.report_service import ReportService
from app.services.subscription_service import SubscriptionService
from app.services.user_service import UserService

bearer_scheme = HTTPBearer(auto_error=False)


def get_db() -> firestore.Client:
    return get_firestore()


# --- Repositories -----------------------------------------------------------

def get_user_repository(db: firestore.Client = Depends(get_db)) -> UserRepository:
    return UserRepository(db)


def get_device_repository(db: firestore.Client = Depends(get_db)) -> DeviceRepository:
    return DeviceRepository(db)


def get_device_pairing_event_repository(db: firestore.Client = Depends(get_db)) -> DevicePairingEventRepository:
    return DevicePairingEventRepository(db)


def get_session_repository(db: firestore.Client = Depends(get_db)) -> WorkoutSessionRepository:
    return WorkoutSessionRepository(db)


def get_daily_repository(db: firestore.Client = Depends(get_db)) -> DailyActivitySummaryRepository:
    return DailyActivitySummaryRepository(db)


def get_integration_repository(db: firestore.Client = Depends(get_db)) -> IntegrationConnectionRepository:
    return IntegrationConnectionRepository(db)


def get_post_repository(db: firestore.Client = Depends(get_db)) -> CommunityPostRepository:
    return CommunityPostRepository(db)


def get_like_repository(db: firestore.Client = Depends(get_db)) -> PostLikeRepository:
    return PostLikeRepository(db)


def get_challenge_repository(db: firestore.Client = Depends(get_db)) -> ChallengeRepository:
    return ChallengeRepository(db)


def get_participant_repository(db: firestore.Client = Depends(get_db)) -> ChallengeParticipantRepository:
    return ChallengeParticipantRepository(db)


def get_badge_repository(db: firestore.Client = Depends(get_db)) -> BadgeRepository:
    return BadgeRepository(db)


def get_user_badge_repository(db: firestore.Client = Depends(get_db)) -> UserBadgeRepository:
    return UserBadgeRepository(db)


def get_report_repository(db: firestore.Client = Depends(get_db)) -> ReportRepository:
    return ReportRepository(db)


def get_analytics_repository(db: firestore.Client = Depends(get_db)) -> AnalyticsEventRepository:
    return AnalyticsEventRepository(db)


def get_feature_flag_repository(db: firestore.Client = Depends(get_db)) -> FeatureFlagRepository:
    return FeatureFlagRepository(db)


# --- Services ----------------------------------------------------------------

def get_analytics_service(repo: AnalyticsEventRepository = Depends(get_analytics_repository)) -> AnalyticsService:
    return AnalyticsService(repo)


def get_auth_service(
    user_repo: UserRepository = Depends(get_user_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
    settings: Settings = Depends(get_settings),
) -> AuthService:
    return AuthService(user_repo, analytics, trial_period_days=settings.trial_period_days)


def get_user_service(user_repo: UserRepository = Depends(get_user_repository)) -> UserService:
    return UserService(user_repo)


def get_device_service(
    device_repo: DeviceRepository = Depends(get_device_repository),
    event_repo: DevicePairingEventRepository = Depends(get_device_pairing_event_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
) -> DeviceService:
    return DeviceService(device_repo, event_repo, analytics)


def get_challenge_service(
    challenge_repo: ChallengeRepository = Depends(get_challenge_repository),
    participant_repo: ChallengeParticipantRepository = Depends(get_participant_repository),
    daily_repo: DailyActivitySummaryRepository = Depends(get_daily_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
) -> ChallengeService:
    return ChallengeService(challenge_repo, participant_repo, daily_repo, analytics)


def get_activity_service(
    session_repo: WorkoutSessionRepository = Depends(get_session_repository),
    daily_repo: DailyActivitySummaryRepository = Depends(get_daily_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
    challenge_service: ChallengeService = Depends(get_challenge_service),
) -> ActivityService:
    return ActivityService(session_repo, daily_repo, analytics, challenge_service=challenge_service)


def get_community_service(
    post_repo: CommunityPostRepository = Depends(get_post_repository),
    like_repo: PostLikeRepository = Depends(get_like_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
) -> CommunityService:
    return CommunityService(post_repo, like_repo, analytics)


def get_report_service(repo: ReportRepository = Depends(get_report_repository)) -> ReportService:
    return ReportService(repo)


def get_badge_service(
    badge_repo: BadgeRepository = Depends(get_badge_repository),
    user_badge_repo: UserBadgeRepository = Depends(get_user_badge_repository),
) -> BadgeService:
    return BadgeService(badge_repo, user_badge_repo)


def get_subscription_service(
    user_repo: UserRepository = Depends(get_user_repository),
    analytics: AnalyticsService = Depends(get_analytics_service),
) -> SubscriptionService:
    return SubscriptionService(user_repo, analytics)


def get_admin_service(
    user_repo: UserRepository = Depends(get_user_repository),
    auth_service: AuthService = Depends(get_auth_service),
    flag_repo: FeatureFlagRepository = Depends(get_feature_flag_repository),
) -> AdminService:
    return AdminService(user_repo, auth_service, flag_repo)


def get_deletion_service(
    user_repo: UserRepository = Depends(get_user_repository),
    device_service: DeviceService = Depends(get_device_service),
    integration_repo: IntegrationConnectionRepository = Depends(get_integration_repository),
) -> DeletionService:
    return DeletionService(user_repo, device_service, integration_repo)


def get_oauth_providers(
    settings: Settings = Depends(get_settings),
    connection_repo: IntegrationConnectionRepository = Depends(get_integration_repository),
    activity_service: ActivityService = Depends(get_activity_service),
    user_repo: UserRepository = Depends(get_user_repository),
) -> dict:
    return build_oauth_providers(settings, connection_repo, activity_service, user_repo)


# --- Auth / current user ------------------------------------------------------

def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    auth_service: AuthService = Depends(get_auth_service),
) -> UserProfile:
    token = verify_firebase_token(credentials)
    profile = auth_service.get_or_provision(token.uid, token.email)
    if profile.banned:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Account banned: {profile.ban_reason or 'no reason given'}",
        )
    if profile.deleted:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account has been deleted")
    return profile


_ROLE_RANK = {Role.user: 0, Role.admin: 1, Role.super_admin: 2}


def require_role(minimum: Role):
    def _check(current: UserProfile = Depends(get_current_user)) -> UserProfile:
        if _ROLE_RANK[current.role] < _ROLE_RANK[minimum]:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return current

    return _check


require_admin = require_role(Role.admin)
require_super_admin = require_role(Role.super_admin)
