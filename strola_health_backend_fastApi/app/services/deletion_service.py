from app.core.exceptions import NotFoundError
from app.core.security import disable_auth_account
from app.core.time import utcnow
from app.repositories.integration_repository import IntegrationConnectionRepository
from app.repositories.user_repository import UserRepository
from app.services.device_service import DeviceService


class DeletionService:
    """Account deletion policy, confirmed with the client: anonymize, don't
    delete activity. Profile PII is scrubbed and the account is tombstoned;
    workout sessions, GPS routes, daily activity summaries, community posts,
    and challenge results are RETAINED (attributed to "Deleted User" via
    `PublicUserProfile.from_profile`) because the business wants this data
    for future analytics — this is a deliberate choice, not an oversight, and
    is explicitly not a full right-to-erasure implementation.
    """

    def __init__(
        self,
        user_repo: UserRepository,
        device_service: DeviceService,
        integration_repo: IntegrationConnectionRepository,
    ):
        self._users = user_repo
        self._devices = device_service
        self._integrations = integration_repo

    def delete_account(self, user_id: str) -> None:
        if not self._users.get(user_id):
            raise NotFoundError(f"User {user_id} not found")

        self._devices.unpair_all_for_user(user_id, reason="account_deleted")

        # Delete our copy of any OAuth tokens. Once Oura/Garmin/Strava are
        # live, this is also where a call to each provider's own revoke
        # endpoint belongs — not added yet since there are no real tokens to
        # revoke against.
        for connection in self._integrations.list_for_user(user_id):
            self._integrations.delete(connection.id)

        self._users.update(
            user_id,
            {
                "deleted": True,
                "deleted_at": utcnow(),
                "name": "Deleted User",
                "username": f"deleted_{user_id[:8]}",
                "email": None,
                "bio": None,
                "photo_url": None,
                "location": None,
                "date_of_birth": None,
                "updated_at": utcnow(),
            },
        )

        disable_auth_account(user_id)
