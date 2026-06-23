from datetime import date

from google.cloud import firestore

from app.models.activity import DailyActivitySummary, WorkoutSession
from app.repositories.base import FirestoreRepository


class WorkoutSessionRepository(FirestoreRepository[WorkoutSession]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "workout_sessions", WorkoutSession)

    def list_for_user(self, user_id: str, *, limit: int = 50) -> list[WorkoutSession]:
        return self.query([("user_id", "==", user_id)], order_by="start_time", descending=True, limit=limit)

    def get_by_external_id(self, user_id: str, external_id: str) -> WorkoutSession | None:
        results = self.query(
            [("user_id", "==", user_id), ("external_id", "==", external_id)],
            limit=1,
        )
        return results[0] if results else None


class DailyActivitySummaryRepository(FirestoreRepository[DailyActivitySummary]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "daily_activity_summaries", DailyActivitySummary)

    @staticmethod
    def doc_id(user_id: str, day: date) -> str:
        return f"{user_id}_{day.isoformat()}"

    def get_for_day(self, user_id: str, day: date) -> DailyActivitySummary | None:
        return self.get(self.doc_id(user_id, day))

    def list_recent(self, user_id: str, *, days: int = 30) -> list[DailyActivitySummary]:
        return self.query([("user_id", "==", user_id)], order_by="date", descending=True, limit=days)
