"""
DTW Engine — direct Python port of lib/services/dtw_service.dart

Feature vector per frame (96 dims):
  pose upper-body  : shoulders(11,12), elbows(13,14), wrists(15,16) → 6 × 2 = 12
  left hand        : 21 landmarks × 2 = 42
  right hand       : 21 landmarks × 2 = 42
  total            : 96

Normalisation: translate by shoulder-midpoint, scale by shoulder-width.
DTW: Sakoe-Chiba band (20% of longer sequence), path-length normalised.
"""

from __future__ import annotations
import math
from typing import Any


# ── Feature extraction ────────────────────────────────────────────────────────

def _lm_xy(lm: dict[str, Any]) -> tuple[float, float]:
    return float(lm["x"]), float(lm["y"])


def frame_to_vector(frame: dict[str, Any]) -> list[float]:
    features: list[float] = []

    # Pose: shoulders(11,12), elbows(13,14), wrists(15,16)
    pose = frame.get("pose") or []
    if len(pose) > 16:
        for idx in [11, 12, 13, 14, 15, 16]:
            x, y = _lm_xy(pose[idx])
            features += [x, y]
    else:
        features += [0.0] * 12

    # Left hand: 21 landmarks
    left_hand = frame.get("left_hand") or []
    if left_hand:
        for lm in left_hand[:21]:
            x, y = _lm_xy(lm)
            features += [x, y]
        if len(left_hand) < 21:
            features += [0.0] * ((21 - len(left_hand)) * 2)
    else:
        features += [0.0] * 42

    # Right hand: 21 landmarks
    right_hand = frame.get("right_hand") or []
    if right_hand:
        for lm in right_hand[:21]:
            x, y = _lm_xy(lm)
            features += [x, y]
        if len(right_hand) < 21:
            features += [0.0] * ((21 - len(right_hand)) * 2)
    else:
        features += [0.0] * 42

    return features


# ── Normalisation ─────────────────────────────────────────────────────────────

def normalize_sequence(frames: list[dict[str, Any]]) -> list[list[float]]:
    """
    Position- and scale-invariant normalisation.
    Reference: midpoint of shoulders (pose[11], pose[12]).
    Scale     : shoulder width (Euclidean distance between the two).
    """
    ref_x = ref_y = scale = None

    for frame in frames:
        pose = frame.get("pose") or []
        if len(pose) < 13:
            continue
        ls, rs = pose[11], pose[12]
        lx, ly = float(ls["x"]), float(ls["y"])
        rx, ry = float(rs["x"]), float(rs["y"])
        ref_x = (lx + rx) / 2
        ref_y = (ly + ry) / 2
        scale = math.sqrt((rx - lx) ** 2 + (ry - ly) ** 2)
        if scale < 0.01:
            scale = 0.1
        break

    if ref_x is None:
        return []

    result: list[list[float]] = []
    for frame in frames:
        vec = frame_to_vector(frame)
        for i in range(0, len(vec), 2):
            vec[i] = (vec[i] - ref_x) / scale
            if i + 1 < len(vec):
                vec[i + 1] = (vec[i + 1] - ref_y) / scale
        result.append(vec)

    return result


def normalize_pose_sequence(raw: list[list[float]]) -> list[list[float]]:
    """
    Normalise a pre-extracted 12-dim pose-only sequence.
    Vector order: [ls_x, ls_y, rs_x, rs_y, le_x, le_y, re_x, re_y, lw_x, lw_y, rw_x, rw_y]
    """
    if not raw:
        return []

    ref_x = ref_y = scale = None
    for frame in raw:
        if len(frame) < 4:
            continue
        lsx, lsy, rsx, rsy = frame[0], frame[1], frame[2], frame[3]
        ref_x = (lsx + rsx) / 2
        ref_y = (lsy + rsy) / 2
        scale = math.sqrt((rsx - lsx) ** 2 + (rsy - lsy) ** 2)
        if scale < 0.01:
            scale = 0.1
        break

    if ref_x is None:
        return raw

    result: list[list[float]] = []
    for frame in raw:
        vec = list(frame)
        for i in range(0, len(vec), 2):
            vec[i] = (vec[i] - ref_x) / scale
            if i + 1 < len(vec):
                vec[i + 1] = (vec[i + 1] - ref_y) / scale
        result.append(vec)

    return result


# ── DTW distance ──────────────────────────────────────────────────────────────

def _euclidean(a: list[float], b: list[float]) -> float:
    length = min(len(a), len(b))
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(length)))


def dtw_distance(
    s1: list[list[float]],
    s2: list[list[float]],
) -> float:
    """
    DTW with Sakoe-Chiba band (window = 20% of longer sequence).
    Returns path-length normalised distance.
    """
    n, m = len(s1), len(s2)
    window = max(1, round(max(n, m) * 0.2))

    INF = float("inf")
    # Use two-row rolling array for memory efficiency
    prev = [INF] * (m + 1)
    curr = [INF] * (m + 1)
    prev[0] = 0.0

    for i in range(1, n + 1):
        curr = [INF] * (m + 1)
        j_start = max(1, i - window)
        j_end = min(m, i + window)
        for j in range(j_start, j_end + 1):
            cost = _euclidean(s1[i - 1], s2[j - 1])
            best_prev = min(prev[j], curr[j - 1], prev[j - 1])
            curr[j] = cost + best_prev
        prev = curr

    result = curr[m]
    if result == INF:
        return INF
    return result / (n + m)


# ── Matching ──────────────────────────────────────────────────────────────────

def match_frames(
    query_frames: list[dict[str, Any]],
    library: dict[str, list[list[float]]],
    top_k: int = 5,
) -> list[dict[str, Any]]:
    """
    Match a list of raw landmark frames against the pre-normalised library.
    Returns up to top_k results sorted by confidence (best first).
    """
    if not library or not query_frames:
        return []

    query_seq = normalize_sequence(query_frames)
    if not query_seq:
        return []

    return _rank(query_seq, library, top_k)


def match_normalized(
    normalized_seq: list[list[float]],
    library: dict[str, list[list[float]]],
    top_k: int = 5,
) -> list[dict[str, Any]]:
    """
    Match a caller-normalized sequence directly (skips normalization step).
    Useful when the client already normalised on-device.
    """
    if not library or not normalized_seq:
        return []
    return _rank(normalized_seq, library, top_k)


def _rank(
    query_seq: list[list[float]],
    library: dict[str, list[list[float]]],
    top_k: int,
) -> list[dict[str, Any]]:
    distances: dict[str, float] = {}
    for sign_id, ref_seq in library.items():
        distances[sign_id] = dtw_distance(query_seq, ref_seq)

    sorted_entries = sorted(distances.items(), key=lambda x: x[1])

    if not sorted_entries:
        return []

    min_dist = sorted_entries[0][1]
    max_dist = sorted_entries[-1][1]
    dist_range = max(max_dist - min_dist, 1e-9)

    results = []
    for sign_id, dist in sorted_entries[:top_k]:
        confidence = 1.0 - ((dist - min_dist) / dist_range)
        results.append({
            "word": sign_id.replace("_", " "),
            "distance": round(dist, 6),
            "confidence": round(confidence, 4),
        })

    return results
