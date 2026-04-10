"""
Gestura — HuggingFace Space: Sign Language Video → Skeleton JSON
================================================================
Endpoints:
  POST /process       — upload a video file (+ optional start_sec / end_sec)
  POST /process-url   — provide a TikTok / Instagram / direct URL (+ optional trim)
  GET  /health        — liveness check
"""

import os
import tempfile
import urllib.request
import subprocess
import cv2
import numpy as np
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="Gestura Sign Processor")

# ── Download mediapipe models at startup ───────────────────────────────────
MODEL_DIR = "/tmp/mediapipe_models"
os.makedirs(MODEL_DIR, exist_ok=True)

MODELS = {
    "pose": (
        "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task",
        os.path.join(MODEL_DIR, "pose.task"),
    ),
    "hand": (
        "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task",
        os.path.join(MODEL_DIR, "hand.task"),
    ),
}

for name, (url, path) in MODELS.items():
    if not os.path.exists(path):
        print(f"Downloading {name} model...")
        urllib.request.urlretrieve(url, path)
        print(f"  {name} ready.")

print("All models ready. Space is live.")


# ── Landmarker factory (VIDEO mode = built-in temporal tracking) ───────────

def _make_landmarkers():
    pose = mp_vision.PoseLandmarker.create_from_options(
        mp_vision.PoseLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=MODELS["pose"][1]),
            running_mode=mp_vision.RunningMode.VIDEO,
            num_poses=1,
            min_pose_detection_confidence=0.5,
            min_pose_presence_confidence=0.5,
            min_tracking_confidence=0.5,
        )
    )
    hands = mp_vision.HandLandmarker.create_from_options(
        mp_vision.HandLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=MODELS["hand"][1]),
            running_mode=mp_vision.RunningMode.VIDEO,
            num_hands=2,
            min_hand_detection_confidence=0.5,
            min_hand_presence_confidence=0.5,
            min_tracking_confidence=0.5,
        )
    )
    return pose, hands


# ── Gaussian smoothing ─────────────────────────────────────────────────────

def _gaussian_kernel(sigma: float):
    """Build a 1D Gaussian kernel (pure numpy, no scipy needed)."""
    size = int(6 * sigma + 1) | 1          # ensure odd
    x    = np.arange(size) - size // 2
    k    = np.exp(-x ** 2 / (2 * sigma ** 2))
    return k / k.sum()


def _smooth_series(values: np.ndarray, sigma: float) -> np.ndarray:
    """Convolve a 1-D array with a Gaussian kernel (edge-padded)."""
    kernel  = _gaussian_kernel(sigma)
    half    = len(kernel) // 2
    padded  = np.pad(values, half, mode="edge")
    return np.convolve(padded, kernel, mode="valid")[: len(values)]


def _smooth_frames(frames: list, sigma: float = 2.5) -> list:
    """
    Apply Gaussian smoothing over the time axis for every landmark coordinate.
    sigma=2.5 gives strong smoothing comparable to smooth_landmarks=True in
    the holistic model. Only smooths landmark groups that are consistently
    present (skips frames where a hand was not detected).
    """
    if len(frames) <= 2:
        return frames

    keys = ("pose", "left_hand", "right_hand")

    for key in keys:
        # How many landmarks does this group have when it IS detected?
        n_lm = max((len(f.get(key, [])) for f in frames), default=0)
        if n_lm == 0:
            continue

        for coord in ("x", "y", "z"):
            # Build (n_frames, n_landmarks) array; NaN where not detected
            series = np.full((len(frames), n_lm), np.nan)
            for i, f in enumerate(frames):
                lms = f.get(key, [])
                for j in range(min(len(lms), n_lm)):
                    series[i, j] = lms[j][coord]

            # Smooth each landmark's time series independently
            for j in range(n_lm):
                col      = series[:, j]
                detected = ~np.isnan(col)
                if detected.sum() < 3:
                    continue
                # Smooth only the detected segment(s)
                col[detected] = _smooth_series(col[detected], sigma)
                series[:, j]  = col

            # Write smoothed values back into frames
            for i, f in enumerate(frames):
                lms = f.get(key, [])
                for j in range(min(len(lms), n_lm)):
                    if not np.isnan(series[i, j]):
                        lms[j][coord] = float(series[i, j])

    # Round after smoothing (rounding before would re-introduce quantisation noise)
    for f in frames:
        for key in keys:
            for lm in f.get(key, []):
                lm["x"] = round(lm["x"], 3)
                lm["y"] = round(lm["y"], 3)
                lm["z"] = round(lm["z"], 3)

    return frames


# ── Helpers ────────────────────────────────────────────────────────────────

def _to_list(landmarks):
    if not landmarks:
        return []
    # Keep floats unrounded here — smoothing rounds afterwards
    return [{"x": lm.x, "y": lm.y, "z": lm.z} for lm in landmarks]


def _build_frame(pose_res, hand_res):
    pose_lm = pose_res.pose_landmarks[0] if pose_res.pose_landmarks else []

    left_hand, right_hand = [], []
    if hand_res.hand_landmarks and hand_res.handedness:
        for lm, hd in zip(hand_res.hand_landmarks, hand_res.handedness):
            if hd[0].category_name == "Left":
                left_hand = lm
            else:
                right_hand = lm

    return {
        "pose":       _to_list(pose_lm),
        "left_hand":  _to_list(left_hand),
        "right_hand": _to_list(right_hand),
    }


def _extract_frames(video_path: str, start_sec: float = 0.0, end_sec: float = 0.0) -> list:
    """
    1. Decode every frame in the clip (temporal continuity for VIDEO mode).
    2. Run pose + hand detection on every frame.
    3. Apply Gaussian smoothing over the time axis (sigma=2.5).
    4. Subsample to ~150 frames for Firestore.
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

    pose, hands = _make_landmarkers()
    all_frames  = []

    try:
        while cap.isOpened():
            frame_pos = int(cap.get(cv2.CAP_PROP_POS_FRAMES))
            if frame_pos >= end_frame:
                break
            ret, frame = cap.read()
            if not ret:
                break

            timestamp_ms = int(frame_pos * 1000 / fps)
            rgb          = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img          = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

            pose_res = pose.detect_for_video(img, timestamp_ms)
            hand_res = hands.detect_for_video(img, timestamp_ms)

            all_frames.append(_build_frame(pose_res, hand_res))

    finally:
        cap.release()
        pose.close()
        hands.close()

    # Gaussian smooth BEFORE subsampling (full temporal resolution = best smoothing)
    all_frames = _smooth_frames(all_frames, sigma=2.5)

    # Subsample to ~150 frames after smoothing
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
        "--js-runtime", "nodejs",
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
