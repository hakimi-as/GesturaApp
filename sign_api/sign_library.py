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

Memory-efficient mode (default):
  Stores pose-only 12-dim vectors (shoulders/elbows/wrists x,y) instead of
  the full 96-dim holistic vectors. This reduces RAM usage by ~8x, making
  it suitable for free-tier hosting (~512 MB). Accuracy is slightly lower
  than full holistic but perfectly adequate for real-time feedback.

  Full 96-dim mode can be enabled by setting USE_POSE_ONLY=false env var.
"""

from __future__ import annotations
import json
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

        # Use pose-only (12-dim) by default to keep RAM under 512 MB.
        # Set USE_POSE_ONLY=false to load full 96-dim holistic vectors.
        pose_only = os.getenv("USE_POSE_ONLY", "true").lower() != "false"
        mode = "pose-only (12-dim)" if pose_only else "full holistic (96-dim)"
        logger.info("Loading sign library from Firestore — mode: %s…", mode)

        snapshot = db.collection("sign_animations").get()
        total = len(snapshot)
        loaded = 0

        for doc in snapshot:
            try:
                data = doc.to_dict()
                frames_raw: list[dict[str, Any]] = data.get("data") or []
                if not frames_raw:
                    continue

                if pose_only:
                    normalized = _normalize_pose_only(frames_raw)
                else:
                    normalized = normalize_sequence(frames_raw)

                if not normalized:
                    continue

                self._library[doc.id] = normalized
                loaded += 1
            except Exception as exc:
                logger.warning("Skipping %s: %s", doc.id, exc)

        self._loaded = True
        logger.info(
            "Sign library ready — %d / %d signs loaded (%s)",
            loaded,
            total,
            mode,
        )


# ── Pose-only extraction ──────────────────────────────────────────────────────

def _normalize_pose_only(frames: list[dict[str, Any]]) -> list[list[float]]:
    """
    Extract and normalise only upper-body pose landmarks (12 dims):
    [ls_x, ls_y, rs_x, rs_y, le_x, le_y, re_x, re_y, lw_x, lw_y, rw_x, rw_y]
    Indices: shoulders(11,12), elbows(13,14), wrists(15,16)
    """
    import math

    raw: list[list[float]] = []
    for frame in frames:
        pose = frame.get("pose") or []
        if len(pose) <= 16:
            raw.append([0.0] * 12)
            continue
        vec: list[float] = []
        for idx in [11, 12, 13, 14, 15, 16]:
            lm = pose[idx]
            vec.append(float(lm["x"]))
            vec.append(float(lm["y"]))
        raw.append(vec)

    if not raw:
        return []

    # Normalise: translate by shoulder midpoint, scale by shoulder width
    ref_x = ref_y = scale = None
    for vec in raw:
        if len(vec) < 4:
            continue
        lsx, lsy, rsx, rsy = vec[0], vec[1], vec[2], vec[3]
        ref_x = (lsx + rsx) / 2
        ref_y = (lsy + rsy) / 2
        scale = math.sqrt((rsx - lsx) ** 2 + (rsy - lsy) ** 2)
        if scale < 0.01:
            scale = 0.1
        break

    if ref_x is None:
        return []

    result: list[list[float]] = []
    for vec in raw:
        v = list(vec)
        for i in range(0, len(v), 2):
            v[i] = (v[i] - ref_x) / scale
            if i + 1 < len(v):
                v[i + 1] = (v[i + 1] - ref_y) / scale
        result.append(v)

    return result


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
