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
    "face": (
        "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task",
        os.path.join(MODEL_DIR, "face.task"),
    ),
}

for name, (url, path) in MODELS.items():
    if not os.path.exists(path):
        print(f"Downloading {name} model...")
        urllib.request.urlretrieve(url, path)
        print(f"  {name} ready.")

print("All models ready. Space is live.")


# ── Landmarker factory (VIDEO mode = temporal tracking enabled) ────────────
# Fresh instances per request — VIDEO mode timestamps must increase
# monotonically within one session and can't be shared across requests.

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
    face = mp_vision.FaceLandmarker.create_from_options(
        mp_vision.FaceLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=MODELS["face"][1]),
            running_mode=mp_vision.RunningMode.VIDEO,
            num_faces=1,
            min_face_detection_confidence=0.5,
            min_face_presence_confidence=0.5,
            min_tracking_confidence=0.5,
        )
    )
    return pose, hands, face


# ── Helpers ────────────────────────────────────────────────────────────────

def _to_list(landmarks):
    if not landmarks:
        return []
    return [{"x": lm.x, "y": lm.y, "z": lm.z} for lm in landmarks]


def _build_frame(pose_res, hand_res, face_res):
    pose_lm = pose_res.pose_landmarks[0] if pose_res.pose_landmarks else []

    left_hand, right_hand = [], []
    if hand_res.hand_landmarks and hand_res.handedness:
        for lm, hd in zip(hand_res.hand_landmarks, hand_res.handedness):
            if hd[0].category_name == "Left":
                left_hand = lm
            else:
                right_hand = lm

    face_lm = face_res.face_landmarks[0] if face_res.face_landmarks else []

    return {
        "pose":       _to_list(pose_lm),
        "left_hand":  _to_list(left_hand),
        "right_hand": _to_list(right_hand),
        "face":       _to_list(face_lm),
    }


def _smooth_frames(frames: list, alpha: float = 0.5) -> list:
    """
    Exponential moving average across frames — replicates smooth_landmarks=True.
    alpha=0.5: equal weight between current detection and previous smoothed position.
    Lower alpha → smoother but more lag. Higher alpha → less smoothing.
    """
    if len(frames) <= 1:
        return frames

    def _ema_landmarks(prev_lms, curr_lms):
        # If either list is empty or lengths differ (hand appeared/disappeared),
        # use current as-is — don't blend with stale positions.
        if not prev_lms or not curr_lms or len(prev_lms) != len(curr_lms):
            return curr_lms
        return [
            {
                "x": alpha * c["x"] + (1 - alpha) * p["x"],
                "y": alpha * c["y"] + (1 - alpha) * p["y"],
                "z": alpha * c["z"] + (1 - alpha) * p["z"],
            }
            for p, c in zip(prev_lms, curr_lms)
        ]

    smoothed = [frames[0]]
    for curr in frames[1:]:
        prev = smoothed[-1]
        smoothed.append({
            key: _ema_landmarks(prev[key], curr[key])
            for key in ("pose", "left_hand", "right_hand", "face")
        })

    # Round after smoothing (not before — rounding before would amplify jitter)
    def _round_lms(lms):
        return [{"x": round(lm["x"], 3), "y": round(lm["y"], 3), "z": round(lm["z"], 3)}
                for lm in lms]

    return [
        {key: _round_lms(f[key]) for key in ("pose", "left_hand", "right_hand", "face")}
        for f in smoothed
    ]


def _extract_frames(video_path: str, start_sec: float = 0.0, end_sec: float = 0.0) -> list:
    """
    Sample ~150 frames from a video, optionally trimmed to [start_sec, end_sec].
    VIDEO mode provides mediapipe-level temporal tracking; EMA smoothing is
    applied on top to remove residual jitter.
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

    clip_length = end_frame - start_frame
    step        = max(1, clip_length // 150)

    if start_frame > 0:
        cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)

    pose, hands, face = _make_landmarkers()
    raw_frames = []
    idx = 0

    try:
        while cap.isOpened():
            frame_pos = int(cap.get(cv2.CAP_PROP_POS_FRAMES))
            if frame_pos >= end_frame:
                break
            ret, frame = cap.read()
            if not ret:
                break

            if idx % step == 0:
                timestamp_ms = int(frame_pos * 1000 / fps)
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

                pose_res = pose.detect_for_video(img, timestamp_ms)
                hand_res = hands.detect_for_video(img, timestamp_ms)
                face_res = face.detect_for_video(img, timestamp_ms)

                raw_frames.append(_build_frame(pose_res, hand_res, face_res))

            idx += 1
    finally:
        cap.release()
        pose.close()
        hands.close()
        face.close()

    return _smooth_frames(raw_frames)


def _download_with_ytdlp(url: str, out_path: str, start_sec: float = 0.0, end_sec: float = 0.0):
    """Download from TikTok / Instagram / direct URL. YouTube is blocked on server IPs."""
    if any(x in url for x in ["youtube.com", "youtu.be"]):
        raise ValueError(
            "YouTube blocks automated downloads from server IPs.\n"
            "Please download the video manually and use 'Upload a File' instead.\n"
            "TikTok, Instagram Reels, and direct MP4 links work fine."
        )

    cmd = [
        "yt-dlp",
        "--no-playlist",
        "--max-filesize", "200M",
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
