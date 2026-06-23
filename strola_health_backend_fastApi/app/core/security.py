from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from firebase_admin import auth as firebase_auth

from app.core.firebase import get_firebase_app


class DecodedToken:
    """Thin wrapper around the dict `firebase_admin.auth.verify_id_token`
    returns. `role` reads a custom claim set via `auth_service` — it is NOT
    present until a super_admin (or the provisioning bootstrap) sets it, so it
    defaults to the lowest-privilege role rather than failing.
    """

    def __init__(self, claims: dict):
        self.uid: str = claims["uid"]
        self.email: str | None = claims.get("email")
        self.role: str = claims.get("role", "user")
        self.claims = claims


def verify_firebase_token(credentials: HTTPAuthorizationCredentials | None) -> DecodedToken:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    get_firebase_app()
    try:
        decoded = firebase_auth.verify_id_token(credentials.credentials)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc
    return DecodedToken(decoded)


def set_role_claim(uid: str, role: str) -> None:
    get_firebase_app()
    firebase_auth.set_custom_user_claims(uid, {"role": role})


def disable_auth_account(uid: str) -> None:
    get_firebase_app()
    firebase_auth.update_user(uid, disabled=True)
