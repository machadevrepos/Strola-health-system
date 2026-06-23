from datetime import date, datetime
from enum import Enum
from typing import Generic, TypeVar

from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from pydantic import BaseModel

ModelT = TypeVar("ModelT", bound=BaseModel)


def _to_firestore_value(value):
    """Recursively prepares a dumped Pydantic value for Firestore: enums
    become their plain value (Firestore has no enum type), and bare `date`
    (not `datetime`) becomes an ISO string (Firestore only has a Timestamp
    type, and Pydantic parses ISO strings back into `date` automatically on
    read — so no special handling is needed on the read path).
    """
    if isinstance(value, dict):
        return {k: _to_firestore_value(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_to_firestore_value(v) for v in value]
    if isinstance(value, Enum):
        return value.value
    if isinstance(value, date) and not isinstance(value, datetime):
        return value.isoformat()
    return value


class FirestoreRepository(Generic[ModelT]):
    """Firestore access layer for one collection, mapped to one Pydantic
    model. This is the only layer that touches the Firestore client directly
    — services and routers never import `google.cloud.firestore`, which keeps
    every business rule and validation in the service layer instead of
    scattered across repositories.
    """

    def __init__(self, db: firestore.Client, collection_name: str, model: type[ModelT]):
        self._db = db
        self._collection_name = collection_name
        self._model = model

    @property
    def client(self) -> firestore.Client:
        return self._db

    @property
    def collection(self):
        return self._db.collection(self._collection_name)

    def get(self, doc_id: str) -> ModelT | None:
        snap = self.collection.document(doc_id).get()
        if not snap.exists:
            return None
        return self._model.model_validate(snap.to_dict())

    def upsert(self, doc_id: str, model: ModelT) -> ModelT:
        data = _to_firestore_value(model.model_dump(mode="python"))
        self.collection.document(doc_id).set(data)
        return model

    def update(self, doc_id: str, fields: dict) -> None:
        self.collection.document(doc_id).update(_to_firestore_value(fields))

    def delete(self, doc_id: str) -> None:
        self.collection.document(doc_id).delete()

    def query(
        self,
        filters: list[tuple[str, str, object]] | None = None,
        *,
        order_by: str | None = None,
        descending: bool = False,
        limit: int = 50,
    ) -> list[ModelT]:
        q = self.collection
        for field, op, value in filters or []:
            q = q.where(filter=FieldFilter(field, op, _to_firestore_value(value)))
        if order_by:
            direction = firestore.Query.DESCENDING if descending else firestore.Query.ASCENDING
            q = q.order_by(order_by, direction=direction)
        q = q.limit(limit)
        return [self._model.model_validate(doc.to_dict()) for doc in q.stream()]
