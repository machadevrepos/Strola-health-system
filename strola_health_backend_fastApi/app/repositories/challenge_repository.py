from google.cloud import firestore

from app.models.challenge import Challenge, ChallengeParticipant
from app.repositories.base import FirestoreRepository


class ChallengeRepository(FirestoreRepository[Challenge]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "challenges", Challenge)

    def list_public(self, *, limit: int = 50) -> list[Challenge]:
        return self.query([("visibility", "==", "public")], order_by="start_date", descending=True, limit=limit)

    def list_all(self, *, limit: int = 200) -> list[Challenge]:
        """Admin-facing: every challenge regardless of visibility, unlike
        `list_public` which the mobile app's discovery feed uses."""
        return self.query(order_by="start_date", descending=True, limit=limit)

    def get_official(self) -> Challenge | None:
        results = self.query([("is_official", "==", True)], order_by="start_date", descending=True, limit=1)
        return results[0] if results else None


class ChallengeParticipantRepository(FirestoreRepository[ChallengeParticipant]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "challenge_participants", ChallengeParticipant)

    @staticmethod
    def doc_id(challenge_id: str, user_id: str) -> str:
        return f"{challenge_id}_{user_id}"

    def get_participant(self, challenge_id: str, user_id: str) -> ChallengeParticipant | None:
        return self.get(self.doc_id(challenge_id, user_id))

    def list_for_challenge(self, challenge_id: str, *, limit: int = 200) -> list[ChallengeParticipant]:
        return self.query([("challenge_id", "==", challenge_id)], order_by="steps", descending=True, limit=limit)

    def list_for_user(self, user_id: str) -> list[ChallengeParticipant]:
        return self.query([("user_id", "==", user_id)])
