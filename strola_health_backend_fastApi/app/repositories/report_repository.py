from google.cloud import firestore

from app.models.report import Report
from app.repositories.base import FirestoreRepository


class ReportRepository(FirestoreRepository[Report]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "reports", Report)

    def list_open(self, *, limit: int = 50) -> list[Report]:
        return self.query([("status", "==", "open")], order_by="created_at", descending=True, limit=limit)
