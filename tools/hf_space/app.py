"""
Gestura — HuggingFace Space: Sign Language Video → Skeleton JSON
================================================================
Uses mp.solutions.holistic (still present in mediapipe==0.10.9),
same model and settings as local extract_holistic.py.

Endpoints:
  POST /process       — upload a video file (+ optional start_sec / end_sec)
  POST /process-url   — provide a TikTok / Instagram / direct URL (+ optional trim)
  GET  /health        — liveness check
"""

import os
import tempfile
import subprocess
import cv2
import mediapipe as mp
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="Gestura Sign Processor")

mp_holistic = mp.solutions.holistic

print("Gestura Space is live.")


# ── Helpers ────────────────────────────────────────────────────────────────

def _get_landmarks(landmarks_obj):
    if not landmarks_obj:
        return []
    return [
        {"x": round(lm.x, 4), "y": round(lm.y, 4), "z": round(lm.z, 4)}
        for lm in landmarks_obj.landmark
    ]


def _extract_frames(video_path: str, start_sec: float = 0.0, end_sec: float = 0.0) -> list:
    """
    Process every frame through mp.solutions.holistic with smooth_landmarks=True,
    identical to local extract_holistic.py. Subsamples to ~150 frames after
    detection so Firestore stays under 1MB.
    """
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError("Could not open video file.")

    fps          = cap.get(cv2.CAP_PROP_FPS) or 30
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    start_frame = int(start_sec * fps) if start_sec > 0 else 0
    end_frame   = int(end_sec * fps)   if end_sec   > 0 else total_frames
    end_frame   = min(end_frame, total_frames)

    if start_frame >= end_frame:
        raise ValueError(f"Invalid trim: start ({start_sec}s) must be before end ({end_sec}s).")

    if start_frame > 0:
        cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)

    all_frames = []

    with mp_holistic.Holistic(
        static_image_mode=False,
        model_complexity=1,
        smooth_landmarks=True,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ) as holistic:
        while cap.isOpened():
            frame_pos = int(cap.get(cv2.CAP_PROP_POS_FRAMES))
            if frame_pos >= end_frame:
                break
            ret, frame = cap.read()
            if not ret:
                break

            rgb     = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = holistic.process(rgb)

            all_frames.append({
                "pose":       _get_landmarks(results.pose_landmarks),
                "left_hand":  _get_landmarks(results.left_hand_landmarks),
                "right_hand": _get_landmarks(results.right_hand_landmarks),
            })

    cap.release()

    # Subsample to ~150 frames after detection (not before — skipping frames
    # during detection breaks holistic's temporal smoother)
    if len(all_frames) > 150:
        step       = len(all_frames) / 150
        all_frames = [all_frames[int(i * step)] for i in range(150)]

    return all_frames


def _download_with_ytdlp(url: str, out_path: str, start_sec: float = 0.0, end_sec: float = 0.0):
    if any(x in url for x in ["youtube.com", "youtu.be"]):
        raise ValueError(
            "YouTube blocks automated downloads from server IPs.\n"
            "Please download the video manually and use 'Upload a File' instead.\n"
            "TikTok, Instagram Reels, and direct MP4 links work fine."
        )

    cmd = [
        "yt-dlp", "--no-playlist", "--max-filesize", "200M",
        "--impersonate", "chrome",
        "-f", "bestvideo[ext=mp4][height<=720]+bestaudio[ext=m4a]/best[ext=mp4]/best",
        "-o", out_path,
    ]

    if start_sec > 0 or end_sec > 0:
        start_str = _sec_to_hms(start_sec)
        end_str   = _sec_to_hms(end_sec) if end_sec > 0 else ""
        section   = f"*{start_str}-{end_str}" if end_str else f"*{start_str}-inf"
        cmd += ["--download-sections", section, "--force-keyframes-at-cuts"]

    cmd.append(url)
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        raise ValueError(f"yt-dlp error: {result.stderr.strip() or result.stdout.strip()}")


def _sec_to_hms(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:06.3f}"


# ── Routes ─────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/process")
async def process_file(
    video: UploadFile = File(...),
    start_sec: float = Form(0.0),
    end_sec: float   = Form(0.0),
):
    suffix = os.path.splitext(video.filename or "video.mp4")[1] or ".mp4"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(await video.read())
        tmp_path = tmp.name

    try:
        frames = _extract_frames(tmp_path, start_sec, end_sec)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        os.unlink(tmp_path)

    if not frames:
        raise HTTPException(status_code=422, detail="No skeleton frames extracted.")

    return JSONResponse(content={"data": frames})


class UrlRequest(BaseModel):
    url: str
    start_sec: Optional[float] = 0.0
    end_sec:   Optional[float] = 0.0


@app.post("/process-url")
async def process_url(body: UrlRequest):
    url = body.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL is required.")

    with tempfile.TemporaryDirectory() as tmpdir:
        out_path = os.path.join(tmpdir, "video.mp4")
        try:
            _download_with_ytdlp(url, out_path, body.start_sec or 0.0, body.end_sec or 0.0)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except subprocess.TimeoutExpired:
            raise HTTPException(status_code=408, detail="Video download timed out.")

        if not os.path.exists(out_path):
            files = os.listdir(tmpdir)
            if not files:
                raise HTTPException(status_code=400, detail="Download produced no file. Check the URL.")
            out_path = os.path.join(tmpdir, files[0])

        try:
            frames = _extract_frames(out_path)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    if not frames:
        raise HTTPException(status_code=422, detail="No skeleton frames extracted.")

    return JSONResponse(content={"data": frames})
