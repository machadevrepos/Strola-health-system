from fastapi import APIRouter, Depends, status

from app.api.deps import get_challenge_service, get_current_user
from app.models.challenge import Challenge, ChallengeParticipant
from app.models.user import UserProfile
from app.services.challenge_service import ChallengeService

router = APIRouter(prefix="/challenges", tags=["challenges"])


@router.get("", response_model=list[Challenge])
def list_public_challenges(
    limit: int = 50,
    _: UserProfile = Depends(get_current_user),
    service: ChallengeService = Depends(get_challenge_service),
) -> list[Challenge]:
    return service.list_public(limit=limit)


@router.get("/mine", response_model=list[ChallengeParticipant])
def list_my_challenges(
    current: UserProfile = Depends(get_current_user),
    service: ChallengeService = Depends(get_challenge_service),
) -> list[ChallengeParticipant]:
    return service.list_for_user(current.id)


@router.post("/{challenge_id}/join", response_model=ChallengeParticipant)
def join_challenge(
    challenge_id: str,
    current: UserProfile = Depends(get_current_user),
    service: ChallengeService = Depends(get_challenge_service),
) -> ChallengeParticipant:
    return service.join(current.id, challenge_id, current)


@router.post("/{challenge_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
def leave_challenge(
    challenge_id: str,
    current: UserProfile = Depends(get_current_user),
    service: ChallengeService = Depends(get_challenge_service),
) -> None:
    service.leave(current.id, challenge_id)


@router.get("/{challenge_id}/leaderboard", response_model=list[ChallengeParticipant])
def get_leaderboard(
    challenge_id: str,
    limit: int = 200,
    _: UserProfile = Depends(get_current_user),
    service: ChallengeService = Depends(get_challenge_service),
) -> list[ChallengeParticipant]:
    return service.leaderboard(challenge_id, limit=limit)
