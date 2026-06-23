import os
from functools import lru_cache

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials
from google.cloud.firestore_v1.client import Client as FirestoreClient

from app.core.config import get_settings


@lru_cache
def get_firebase_app() -> firebase_admin.App:
    """Initializes the Firebase Admin app exactly once per process.

    Emulator hosts are picked up from env vars by the underlying Firestore /
    Auth client libraries automatically when set — no special-casing needed
    here beyond making sure they're exported before init.
    """
    settings = get_settings()
    if settings.firestore_emulator_host:
        os.environ["FIRESTORE_EMULATOR_HOST"] = settings.firestore_emulator_host
    if settings.firebase_auth_emulator_host:
        os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = settings.firebase_auth_emulator_host

    if settings.firebase_credentials_path:
        cred = credentials.Certificate(settings.firebase_credentials_path)
    else:
        cred = credentials.ApplicationDefault()

    options = {}
    if settings.firebase_project_id:
        options["projectId"] = settings.firebase_project_id

    return firebase_admin.initialize_app(cred, options)


@lru_cache
def get_firestore() -> FirestoreClient:
    from firebase_admin import firestore

    return firestore.client(get_firebase_app())


def get_auth_client():
    get_firebase_app()
    return firebase_auth
