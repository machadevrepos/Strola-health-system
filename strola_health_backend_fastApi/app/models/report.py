from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel


class ReportTargetType(StrEnum):
    post = "post"
    user = "user"


class ReportStatus(StrEnum):
    open = "open"
    resolved = "resolved"
    dismissed = "dismissed"


class Report(BaseModel):
    id: str
    reporter_id: str
    target_type: ReportTargetType
    target_id: str
    reason: str
    status: ReportStatus = ReportStatus.open
    resolved_by: str | None = None
    resolved_at: datetime | None = None
    resolution_note: str | None = None
    created_at: datetime


class ReportCreate(BaseModel):
    target_type: ReportTargetType
    target_id: str
    reason: str


class ReportResolve(BaseModel):
    status: ReportStatus
    resolution_note: str | None = None
