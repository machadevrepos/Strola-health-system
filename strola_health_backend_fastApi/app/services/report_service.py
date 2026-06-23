import uuid

from app.core.exceptions import NotFoundError
from app.core.time import utcnow
from app.models.report import Report, ReportCreate, ReportResolve
from app.repositories.report_repository import ReportRepository


class ReportService:
    def __init__(self, report_repo: ReportRepository):
        self._reports = report_repo

    def submit(self, reporter_id: str, payload: ReportCreate) -> Report:
        report = Report(
            id=str(uuid.uuid4()),
            reporter_id=reporter_id,
            target_type=payload.target_type,
            target_id=payload.target_id,
            reason=payload.reason,
            created_at=utcnow(),
        )
        return self._reports.upsert(report.id, report)

    def list_open(self, *, limit: int = 50) -> list[Report]:
        return self._reports.list_open(limit=limit)

    def resolve(self, report_id: str, admin_id: str, payload: ReportResolve) -> Report:
        report = self._reports.get(report_id)
        if not report:
            raise NotFoundError("Report not found")
        self._reports.update(
            report_id,
            {
                "status": payload.status.value,
                "resolved_by": admin_id,
                "resolved_at": utcnow(),
                "resolution_note": payload.resolution_note,
            },
        )
        return self._reports.get(report_id)
