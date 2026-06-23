from fastapi import APIRouter, Depends

from app.api.deps import get_community_service, get_current_user, get_report_service
from app.models.community import CommunityPost, CommunityPostCreate
from app.models.report import Report, ReportCreate
from app.models.user import UserProfile
from app.services.community_service import CommunityService
from app.services.report_service import ReportService

router = APIRouter(prefix="/community", tags=["community"])


@router.get("/posts", response_model=list[CommunityPost])
def list_feed(
    limit: int = 20,
    _: UserProfile = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> list[CommunityPost]:
    return service.list_feed(limit=limit)


@router.post("/posts", response_model=CommunityPost)
def create_post(
    payload: CommunityPostCreate,
    current: UserProfile = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> CommunityPost:
    return service.create_post(current.id, payload)


@router.post("/posts/{post_id}/like", response_model=CommunityPost)
def toggle_like(
    post_id: str,
    current: UserProfile = Depends(get_current_user),
    service: CommunityService = Depends(get_community_service),
) -> CommunityPost:
    return service.toggle_like(current.id, post_id)


@router.post("/reports", response_model=Report)
def submit_report(
    payload: ReportCreate,
    current: UserProfile = Depends(get_current_user),
    service: ReportService = Depends(get_report_service),
) -> Report:
    return service.submit(current.id, payload)
