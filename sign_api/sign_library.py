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
import os
import logging
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

        credentials_path: path to serviceAccount.json.
        Falls back to FIREBASE_CREDENTIALS env var, then to Application
        Default Credentials (works on Cloud Run / Railway with GCP auth).
        """
        # ── Firebase init ──────────────────────────────────────────────
        if not firebase_admin._apps:
            cred_path = credentials_path or os.getenv("FIREBASE_CREDENTIALS")
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase initialised with service account: %s", cred_path)
            else:
                # Application Default Credentials (Railway / Cloud Run)
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


# Module-level singleton
_library = SignLibrary()


def get_library() -> SignLibrary:
    return _library
