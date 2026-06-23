from fastapi import APIRouter

from app.api.v1.admin import analytics, badges, challenges, devices, moderation, system, users

router = APIRouter()
router.include_router(users.router)
router.include_router(moderation.router)
router.include_router(devices.router)
router.include_router(challenges.router)
router.include_router(badges.router)
router.include_router(analytics.router)
router.include_router(system.router)
