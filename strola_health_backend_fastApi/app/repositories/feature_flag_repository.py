from google.cloud import firestore

from app.models.feature_flag import FeatureFlag
from app.repositories.base import FirestoreRepository


class FeatureFlagRepository(FirestoreRepository[FeatureFlag]):
    def __init__(self, db: firestore.Client):
        super().__init__(db, "feature_flags", FeatureFlag)

    def list_all(self) -> list[FeatureFlag]:
        return self.query(limit=200)
