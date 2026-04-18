"""
Gestura Sign Recognition API
─────────────────────────────
POST /match       — match landmark frames against the sign library
GET  /health      — liveness + library status

Auth: pass  X-API-Key: <your_key>  in the request header.
Set  API_KEY  env variable to enable key checking (leave blank to disable
during local dev).
"""

from __future__ import annotations
import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException, Request, Security
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel, Field

from dtw_engine import match_frames, normalize_sequence, match_normalized
from sign_library import get_library

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
)
logger = logging.getLogger("gestura.api")


# ── Startup / shutdown ────────────────────────────────────────────────────────

def _load_library_sync() -> None:
    """Runs in a thread — loads Firestore data without blocking the event loop."""
    cred_path = os.getenv("FIREBASE_CREDENTIALS", "serviceAccount.json")
    lib = get_library()
    if not lib.is_loaded:
        lib.load(credentials_path=cred_path)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Fire library loading in a background thread so the server starts
    # accepting requests (including Railway health checks) immediately.
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, _load_library_sync)
    yield


# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Gestura Sign Recognition API",
    description="DTW-based sign language matching for the Gestura app",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ── Auth ──────────────────────────────────────────────────────────────────────

API_KEY = os.getenv("API_KEY", "")          # empty = auth disabled (dev mode)
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_key(key: str | None = Security(api_key_header)) -> None:
    if not API_KEY:
        return  # auth disabled
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


# ── Request / response models ─────────────────────────────────────────────────

class LandmarkPoint(BaseModel):
    x: float
    y: float


class Frame(BaseModel):
    pose:        list[LandmarkPoint] | None = None
    left_hand:   list[LandmarkPoint] | None = None
    right_hand:  list[LandmarkPoint] | None = None


class MatchRequest(BaseModel):
    frames: list[Frame] = Field(..., min_length=1)
    top_k:  int = Field(default=5, ge=1, le=20)
    # Optional: client already normalised, skip server-side normalisation
    pre_normalized: bool = False


class SignResult(BaseModel):
    word:       str
    confidence: float
    distance:   float


class MatchResponse(BaseModel):
    matches:      list[SignResult]
    library_size: int
    latency_ms:   float


class HealthResponse(BaseModel):
    status:       str
    library_size: int
    library_ready: bool


# ── Helpers ───────────────────────────────────────────────────────────────────

def _frame_to_dict(frame: Frame) -> dict[str, Any]:
    """Convert Pydantic Frame → plain dict matching the dtw_engine format."""
    return {
        "pose":       [{"x": lm.x, "y": lm.y} for lm in frame.pose]       if frame.pose       else None,
        "left_hand":  [{"x": lm.x, "y": lm.y} for lm in frame.left_hand]  if frame.left_hand  else None,
        "right_hand": [{"x": lm.x, "y": lm.y} for lm in frame.right_hand] if frame.right_hand else None,
    }


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    lib = get_library()
    return HealthResponse(
        status="ok",
        library_size=lib.size,
        library_ready=lib.is_loaded,
    )


@app.post("/match", response_model=MatchResponse)
def match(body: MatchRequest, _: None = Security(verify_key)) -> MatchResponse:
    lib = get_library()

    if not lib.is_loaded:
        raise HTTPException(
            status_code=503,
            detail="Sign library is still loading. Try again in a moment.",
        )

    t0 = time.perf_counter()

    frames_as_dicts = [_frame_to_dict(f) for f in body.frames]

    if body.pre_normalized:
        # Client sent pre-normalised 96-dim float vectors — not landmark dicts.
        # In this mode frames should carry only pose with 48 x,y pairs (96 values)
        # packed into the pose field. We treat the raw coords as the feature vec.
        # This is an advanced path; the default path (below) is safer.
        from dtw_engine import normalize_sequence as _ns
        raw_vecs = [
            [c for lm in (f.pose or []) for c in (lm.x, lm.y)]
            for f in body.frames
        ]
        raw_results = match_normalized(raw_vecs, lib.library, top_k=body.top_k)
    else:
        raw_results = match_frames(frames_as_dicts, lib.library, top_k=body.top_k)

    latency_ms = (time.perf_counter() - t0) * 1000

    matches = [
        SignResult(
            word=r["word"],
            confidence=r["confidence"],
            distance=r["distance"],
        )
        for r in raw_results
    ]

    logger.info(
        "match: %d frames → top=%s (%.1f ms)",
        len(body.frames),
        matches[0].word if matches else "—",
        latency_ms,
    )

    return MatchResponse(
        matches=matches,
        library_size=lib.size,
        latency_ms=round(latency_ms, 2),
    )
