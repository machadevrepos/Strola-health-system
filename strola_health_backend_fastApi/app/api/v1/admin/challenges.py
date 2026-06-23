from fastapi import APIRouter, Depends, status

from app.api.deps import get_challenge_service, require_admin, require_super_admin
from app.core.exceptions import NotFoundError
from app.models.challenge import Challenge, ChallengeCreate, ChallengeUpdate
from app.models.user import UserProfile
from app.services.challenge_service import ChallengeService

router = APIRouter(prefix="/challenges", tags=["admin:challenges"])


@router.get("", response_model=list[Challenge])
def list_challenges(
    limit: int = 200,
    _: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> list[Challenge]:
    """Every challenge regardless of visibility — unlike the public
    `GET /challenges` the mobile app uses, staff need to see private/invite
    challenges too."""
    return service.list_all(limit=limit)


@router.get("/{challenge_id}", response_model=Challenge)
def get_challenge(
    challenge_id: str,
    _: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> Challenge:
    challenge = service.get(challenge_id)
    if not challenge:
        raise NotFoundError("Challenge not found")
    return challenge


@router.post("", response_model=Challenge)
def create_challenge(
    payload: ChallengeCreate,
    current: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> Challenge:
    return service.create(payload, created_by=current.id)


@router.patch("/{challenge_id}", response_model=Challenge)
def update_challenge(
    challenge_id: str,
    payload: ChallengeUpdate,
    _: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> Challenge:
    return service.update(challenge_id, payload)


@router.delete("/{challenge_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_challenge(
    challenge_id: str,
    _: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> None:
    service.delete(challenge_id)


@router.delete("/{challenge_id}/participants/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_participant(
    challenge_id: str,
    user_id: str,
    _: UserProfile = Depends(require_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> None:
    """Admin-forced removal (e.g. a cheater) — distinct from the
    participant's own self-service `leave`."""
    service.remove_participant(challenge_id, user_id)


@router.post("/{challenge_id}/set-official-monthly", status_code=status.HTTP_204_NO_CONTENT)
def set_official_monthly(
    challenge_id: str,
    _: UserProfile = Depends(require_super_admin),
    service: ChallengeService = Depends(get_challenge_service),
) -> None:
    """Only one challenge is the official public monthly challenge at a
    time — kept super_admin-only since it's a brand/platform-level decision,
    not routine moderation."""
    service.set_official_monthly(challenge_id)
