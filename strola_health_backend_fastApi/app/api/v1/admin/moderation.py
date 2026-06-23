from fastapi import APIRouter, Depends

from app.api.deps import get_community_service, get_report_service, require_admin
from app.models.community import CommunityPost, CommunityPostUpdate
from app.models.report import Report, ReportResolve
from app.models.user import UserProfile
from app.services.community_service import CommunityService
from app.services.report_service import ReportService

router = APIRouter(tags=["admin:moderation"])


@router.get("/posts", response_model=list[CommunityPost])
def list_all_posts(
    limit: int = 50,
    include_hidden: bool = True,
    _: UserProfile = Depends(require_admin),
    service: CommunityService = Depends(get_community_service),
) -> list[CommunityPost]:
    """The admin moderation view — unlike the public feed, defaults to
    including hidden posts so moderators can review/restore them."""
    return service.list_feed(limit=limit, include_hidden=include_hidden)


@router.patch("/posts/{post_id}", response_model=CommunityPost)
def update_post(
    post_id: str,
    payload: CommunityPostUpdate,
    _: UserProfile = Depends(require_admin),
    service: CommunityService = Depends(get_community_service),
) -> CommunityPost:
    """Content correction — distinct from moderation actions below, which
    change visibility rather than content."""
    return service.update_post(post_id, payload)


@router.post("/posts/{post_id}/hide", status_code=204)
def hide_post(
    post_id: str,
    reason: str | None = None,
    current: UserProfile = Depends(require_admin),
    service: CommunityService = Depends(get_community_service),
) -> None:
    service.hide_post(post_id, admin_id=current.id, reason=reason)


@router.post("/posts/{post_id}/unhide", status_code=204)
def unhide_post(
    post_id: str,
    _: UserProfile = Depends(require_admin),
    service: CommunityService = Depends(get_community_service),
) -> None:
    service.unhide_post(post_id)


@router.delete("/posts/{post_id}", status_code=204)
def delete_post(
    post_id: str,
    _: UserProfile = Depends(require_admin),
    service: CommunityService = Depends(get_community_service),
) -> None:
    service.delete_post(post_id)


@router.delete("/posts/{post_id}/photo", status_code=204)
def remove_photo(
    post_id: str,
    _: UserProfile = Depends(require_admin),
    service: CommunityService = Depends(get_community_service),
) -> None:
    service.remove_photo(post_id)


@router.get("/reports", response_model=list[Report])
def list_open_reports(
    limit: int = 50,
    _: UserProfile = Depends(require_admin),
    service: ReportService = Depends(get_report_service),
) -> list[Report]:
    return service.list_open(limit=limit)


@router.post("/reports/{report_id}/resolve", response_model=Report)
def resolve_report(
    report_id: str,
    payload: ReportResolve,
    current: UserProfile = Depends(require_admin),
    service: ReportService = Depends(get_report_service),
) -> Report:
    return service.resolve(report_id, current.id, payload)
