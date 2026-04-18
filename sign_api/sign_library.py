"""
Sign Library — loads sign_animations from Firestore and caches in RAM.

Each Firestore document structure:
  {
    "word": "hello",
    "fps":  30,
    "type": "holistic",
    "data": [
      { "pose": [...], "left_hand": [...], "right_hand": [...] },
      ...
    ]
  }

The library stored in memory is:
  { sign_id: normalized_feature_sequence }
where each sequence is a list of 96-dim float vectors.
"""

from __future__ import annotations
import json
import os
import logging
import tempfile
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore

from dtw_engine import normalize_sequence

logger = logging.getLogger(__name__)


class SignLibrary:
    def __init__(self) -> None:
        self._library: dict[str, list[list[float]]] = {}
        self._loaded = False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    @property
    def size(self) -> int:
        return len(self._library)

    @property
    def library(self) -> dict[str, list[list[float]]]:
        return self._library

    def load(self, credentials_path: str | None = None) -> None:
        """
        Initialise Firebase (if not already done) and pull all
        sign_animations documents into memory.

        Credential resolution order:
          1. FIREBASE_SERVICE_ACCOUNT_JSON env var (full JSON string) — Railway
          2. credentials_path argument or FIREBASE_CREDENTIALS env var (file path)
          3. Application Default Credentials (GCP-hosted environments)
        """
        # ── Firebase init ──────────────────────────────────────────────
        if not firebase_admin._apps:
            cred = _resolve_credentials(credentials_path)
            if cred:
                firebase_admin.initialize_app(cred)
            else:
                firebase_admin.initialize_app()
                logger.info("Firebase initialised with Application Default Credentials")

        db = firestore.client()

        # ── Pull all sign_animations docs ──────────────────────────────
        logger.info("Loading sign library from Firestore…")
        snapshot = db.collection("sign_animations").get()
        total = len(snapshot)
        loaded = 0

        for doc in snapshot:
            try:
                data = doc.to_dict()
                frames_raw: list[dict[str, Any]] = data.get("data") or []
                if not frames_raw:
                    continue

                # Wrap raw frame list in the same dict format the engine expects
                # (Firestore stores frames directly as the list, not nested under "frames")
                normalized = normalize_sequence(frames_raw)
                if not normalized:
                    continue

                self._library[doc.id] = normalized
                loaded += 1
            except Exception as exc:
                logger.warning("Skipping %s: %s", doc.id, exc)

        self._loaded = True
        logger.info(
            "Sign library ready — %d / %d signs loaded successfully",
            loaded,
            total,
        )


# ── Credential resolution ─────────────────────────────────────────────────────

def _resolve_credentials(credentials_path: str | None) -> credentials.Certificate | None:
    # Option 1: full JSON string in env var (Railway / Render / Heroku)
    json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if json_str:
        try:
            service_account_info = json.loads(json_str)
            cred = credentials.Certificate(service_account_info)
            logger.info("Firebase initialised from FIREBASE_SERVICE_ACCOUNT_JSON env var")
            return cred
        except Exception as exc:
            logger.error("Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: %s", exc)

    # Option 2: path to a JSON file
    cred_path = credentials_path or os.getenv("FIREBASE_CREDENTIALS")
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        logger.info("Firebase initialised with service account file: %s", cred_path)
        return cred

    return None


# Module-level singleton
_library = SignLibrary()


def get_library() -> SignLibrary:
    return _library
