from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import activity, analytics, auth, challenges, community, devices, integrations, users
from app.api.v1.admin.router import router as admin_router
from app.api.v1.webhooks import revenuecat
from app.core.config import get_settings
from app.core.exceptions import AppError


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title=settings.app_name)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.exception_handler(AppError)
    async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})

    prefix = settings.api_v1_prefix
    app.include_router(auth.router, prefix=prefix)
    app.include_router(users.router, prefix=prefix)
    app.include_router(devices.router, prefix=prefix)
    app.include_router(activity.router, prefix=prefix)
    app.include_router(integrations.router, prefix=prefix)
    app.include_router(community.router, prefix=prefix)
    app.include_router(challenges.router, prefix=prefix)
    app.include_router(analytics.router, prefix=prefix)
    app.include_router(revenuecat.router, prefix=f"{prefix}/webhooks")
    app.include_router(admin_router, prefix=f"{prefix}/admin")

    @app.get("/health", tags=["health"])
    def health_check() -> dict:
        return {"status": "ok"}

    return app


app = create_app()
