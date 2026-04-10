"""
Gestura — HuggingFace Space: Sign Language Video → Skeleton JSON
================================================================
Endpoints:
  POST /process       — upload a video file
  POST /process-url   — provide a YouTube / direct URL
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
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

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

# ── Initialise landmarkers ─────────────────────────────────────────────────
_pose = mp_vision.PoseLandmarker.create_from_options(
    mp_vision.PoseLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=MODELS["pose"][1]),
        running_mode=mp_vision.RunningMode.IMAGE,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_pose_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
)
_hands = mp_vision.HandLandmarker.create_from_options(
    mp_vision.HandLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=MODELS["hand"][1]),
        running_mode=mp_vision.RunningMode.IMAGE,
        num_hands=2,
        min_hand_detection_confidence=0.5,
        min_hand_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
)
_face = mp_vision.FaceLandmarker.create_from_options(
    mp_vision.FaceLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=MODELS["face"][1]),
        running_mode=mp_vision.RunningMode.IMAGE,
        num_faces=1,
        min_face_detection_confidence=0.5,
        min_face_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
)

print("All models ready. Space is live.")


# ── Helpers ────────────────────────────────────────────────────────────────

def _to_list(landmarks):
    if not landmarks:
        return []
    return [{"x": round(lm.x, 3), "y": round(lm.y, 3), "z": round(lm.z, 3)}
            for lm in landmarks]


def _process_frame(rgb):
    img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

    pose_res  = _pose.detect(img)
    hand_res  = _hands.detect(img)
    face_res  = _face.detect(img)

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


def _extract_frames(video_path: str) -> list:
    """Sample ~150 frames from a video file and run skeleton detection."""
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError("Could not open video file.")

    total     = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    max_frames = min(total, 600)
    step       = max(1, max_frames // 150)

    frames = []
    idx = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if idx % step == 0:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frames.append(_process_frame(rgb))
        idx += 1

    cap.release()
    return frames


def _download_with_ytdlp(url: str, out_path: str):
    """Download a video from TikTok / Instagram / direct URL.
    Note: YouTube blocks server-side downloads — users should upload the file directly.
    """
    is_youtube = any(x in url for x in ["youtube.com", "youtu.be"])

    if is_youtube:
        raise ValueError(
            "YouTube blocks automated downloads from server IPs.\n"
            "Please download the video manually and use the 'Upload a File' option instead.\n"
            "TikTok, Instagram Reels, and direct MP4 links work fine."
        )

    cmd = [
        "yt-dlp",
        "--no-playlist",
        "--max-filesize", "200M",
        "--js-runtime", "nodejs",
        "-f", "bestvideo[ext=mp4][height<=720]+bestaudio[ext=m4a]/best[ext=mp4]/best",
        "-o", out_path,
        url,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        raise ValueError(f"yt-dlp error: {result.stderr.strip() or result.stdout.strip()}")


# ── Routes ─────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/process")
async def process_file(video: UploadFile = File(...)):
    """Accept a video file upload and return skeleton JSON."""
    suffix = os.path.splitext(video.filename or "video.mp4")[1] or ".mp4"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(await video.read())
        tmp_path = tmp.name

    try:
        frames = _extract_frames(tmp_path)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        os.unlink(tmp_path)

    if not frames:
        raise HTTPException(status_code=422, detail="No skeleton frames extracted.")

    return JSONResponse(content={"data": frames})


class UrlRequest(BaseModel):
    url: str


@app.post("/process-url")
async def process_url(body: UrlRequest):
    """Accept a YouTube / TikTok / Instagram / direct MP4 URL and return skeleton JSON."""
    url = body.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL is required.")

    with tempfile.TemporaryDirectory() as tmpdir:
        out_path = os.path.join(tmpdir, "video.mp4")
        try:
            _download_with_ytdlp(url, out_path)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except subprocess.TimeoutExpired:
            raise HTTPException(status_code=408, detail="Video download timed out.")

        if not os.path.exists(out_path):
            # yt-dlp may choose a different extension
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
