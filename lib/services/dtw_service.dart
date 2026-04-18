import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SignMatch {
  final String word;
  final double distance;
  final double confidence; // 0.0–1.0, higher = better

  const SignMatch({
    required this.word,
    required this.distance,
    required this.confidence,
  });
}

/// Singleton service: loads sign skeleton library from Firestore once,
/// then matches query frames using DTW (Dynamic Time Warping).
class DtwService {
  static DtwService? _instance;
  static DtwService get instance => _instance ??= DtwService._();
  DtwService._();

  // word_id → normalized feature sequences
  final Map<String, List<List<double>>> _library = {};
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  int get librarySize => _library.length;

  /// Load all signs that have skeleton data from Firestore.
  /// No-op if already loaded.
  Future<void> loadLibrary({
    void Function(int loaded, int total)? onProgress,
  }) async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('sign_animations').get();
      final total = snapshot.docs.length;
      int loaded = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data()['data'];
          if (data == null) continue;

          final frames = _extractFrames(data);
          if (frames.isEmpty) continue;

          final normalized = _normalizeSequence(frames);
          if (normalized.isEmpty) continue;

          _library[doc.id] = normalized;
          loaded++;
          onProgress?.call(loaded, total);
        } catch (e) {
          debugPrint('DTW: skipping ${doc.id}: $e');
        }
      }

      _isLoaded = true;
      debugPrint('DTW: library loaded — ${_library.length} signs');
    } catch (e) {
      debugPrint('DTW: loadLibrary error: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  void clearCache() {
    _library.clear();
    _isLoaded = false;
  }

  /// Returns a pose-only (12-dim) copy of the library for the compute() isolate.
  /// Truncating from 96 → 12 dims makes the payload ~8× smaller, which speeds up
  /// isolate serialisation and DTW comparison.
  Map<String, dynamic> exportLibraryForIsolate() => _library.map(
        (k, v) => MapEntry(
          k,
          v.map((f) => (f.length > 12 ? f.sublist(0, 12) : f)).toList(),
        ),
      );

  /// Match pre-normalized pose-only vectors (12 dims: shoulders/elbows/wrists × x,y)
  /// against only the first 12 dims of each library entry.
  /// Faster path for on-device ML Kit pose detection — no hand landmarks needed.
  List<SignMatch> matchPoseOnly(
    List<List<double>> normalizedPoseSeq, {
    int topK = 5,
  }) {
    if (_library.isEmpty || normalizedPoseSeq.isEmpty) return [];

    final distances = <String, double>{};
    for (final entry in _library.entries) {
      // Truncate library vectors to pose dims for a fair comparison
      final truncated = entry.value
          .map((v) => v.length > 12 ? v.sublist(0, 12) : List<double>.from(v))
          .toList();
      distances[entry.key] = _dtwDistance(normalizedPoseSeq, truncated);
    }

    final sorted = distances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final minDist = sorted.first.value;
    final maxDist = sorted.last.value;
    final range = (maxDist - minDist).clamp(1e-9, double.infinity);

    return sorted.take(topK).map((e) {
      final confidence = 1.0 - ((e.value - minDist) / range);
      return SignMatch(
        word: e.key.replaceAll('_', ' '),
        distance: e.value,
        confidence: confidence,
      );
    }).toList();
  }

  /// Normalize a sequence of 12-dim pose vectors (produced from ML Kit landmarks)
  /// using the same shoulder-midpoint + shoulder-width strategy as [_normalizeSequence].
  /// Pose vector order: [ls_x, ls_y, rs_x, rs_y, le_x, le_y, re_x, re_y, lw_x, lw_y, rw_x, rw_y]
  List<List<double>> normalizePoseSequence(List<List<double>> raw) {
    if (raw.isEmpty) return [];

    double? refX, refY, scale;
    for (final frame in raw) {
      if (frame.length < 4) continue;
      final lsx = frame[0], lsy = frame[1];
      final rsx = frame[2], rsy = frame[3];
      refX = (lsx + rsx) / 2;
      refY = (lsy + rsy) / 2;
      scale = sqrt(pow(rsx - lsx, 2) + pow(rsy - lsy, 2));
      if (scale < 0.01) scale = 0.1;
      break;
    }
    if (refX == null) return raw;

    final cx = refX, cy = refY!, sc = scale!;
    return raw.map((frame) {
      final result = List<double>.from(frame);
      for (int i = 0; i < result.length; i += 2) {
        result[i] = (result[i] - cx) / sc;
        if (i + 1 < result.length) result[i + 1] = (result[i + 1] - cy) / sc;
      }
      return result;
    }).toList();
  }

  /// Match query frames against the library.
  /// Returns up to [topK] matches, best first.
  List<SignMatch> match(
    List<Map<String, dynamic>> queryFrames, {
    int topK = 5,
  }) {
    if (_library.isEmpty) return [];

    final querySeq = _normalizeSequence(queryFrames);
    if (querySeq.isEmpty) return [];

    // Compute DTW distance to every stored sign
    final distances = <String, double>{};
    for (final entry in _library.entries) {
      distances[entry.key] = _dtwDistance(querySeq, entry.value);
    }

    final sorted = distances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final minDist = sorted.first.value;
    final maxDist = sorted.last.value;
    final range = (maxDist - minDist).clamp(1e-9, double.infinity);

    return sorted.take(topK).map((e) {
      final confidence = 1.0 - ((e.value - minDist) / range);
      return SignMatch(
        word: e.key.replaceAll('_', ' '),
        distance: e.value,
        confidence: confidence,
      );
    }).toList();
  }

  // ── Internal helpers ────────────────────────────────────────────────────

  List<Map<String, dynamic>> _extractFrames(dynamic data) {
    if (data is Map && data['frames'] is List) {
      return List<Map<String, dynamic>>.from(
        (data['frames'] as List).map((f) => Map<String, dynamic>.from(f as Map)),
      );
    }
    return [];
  }

  /// Build a feature vector for a single frame.
  /// Uses: pose upper-body (indices 11–16) + left hand (21 pts) + right hand (21 pts).
  /// Total: 6*2 + 21*2 + 21*2 = 96 dimensions.
  List<double> _frameToVector(Map<String, dynamic> frame) {
    final features = <double>[];

    // Pose: shoulders(11,12), elbows(13,14), wrists(15,16)
    final pose = frame['pose'] as List?;
    if (pose != null && pose.length > 16) {
      for (final idx in [11, 12, 13, 14, 15, 16]) {
        final lm = pose[idx];
        features.add((lm['x'] as num).toDouble());
        features.add((lm['y'] as num).toDouble());
      }
    } else {
      features.addAll(List.filled(12, 0.0));
    }

    // Left hand: 21 landmarks
    final leftHand = frame['left_hand'] as List?;
    if (leftHand != null && leftHand.isNotEmpty) {
      for (final lm in leftHand.take(21)) {
        features.add((lm['x'] as num).toDouble());
        features.add((lm['y'] as num).toDouble());
      }
      if (leftHand.length < 21) {
        features.addAll(List.filled((21 - leftHand.length) * 2, 0.0));
      }
    } else {
      features.addAll(List.filled(42, 0.0));
    }

    // Right hand: 21 landmarks
    final rightHand = frame['right_hand'] as List?;
    if (rightHand != null && rightHand.isNotEmpty) {
      for (final lm in rightHand.take(21)) {
        features.add((lm['x'] as num).toDouble());
        features.add((lm['y'] as num).toDouble());
      }
      if (rightHand.length < 21) {
        features.addAll(List.filled((21 - rightHand.length) * 2, 0.0));
      }
    } else {
      features.addAll(List.filled(42, 0.0));
    }

    return features;
  }

  /// Normalize a frame sequence to be position- and scale-invariant.
  /// Reference: midpoint of shoulders (pose 11, 12); scale = shoulder width.
  List<List<double>> _normalizeSequence(List<Map<String, dynamic>> frames) {
    if (frames.isEmpty) return [];

    // Find normalization params from first valid frame
    double? refX, refY, scale;
    for (final frame in frames) {
      final pose = frame['pose'] as List?;
      if (pose == null || pose.length < 13) continue;

      final ls = pose[11];
      final rs = pose[12];

      final lx = (ls['x'] as num).toDouble();
      final ly = (ls['y'] as num).toDouble();
      final rx = (rs['x'] as num).toDouble();
      final ry = (rs['y'] as num).toDouble();

      refX = (lx + rx) / 2;
      refY = (ly + ry) / 2;
      scale = sqrt(pow(rx - lx, 2) + pow(ry - ly, 2));
      if (scale < 0.01) scale = 0.1;
      break;
    }

    if (refX == null) return [];

    final cx = refX;
    final cy = refY!;
    final sc = scale!;

    final result = <List<double>>[];
    for (final frame in frames) {
      final vec = _frameToVector(frame);
      // Translate by reference center, scale by shoulder width
      for (int i = 0; i < vec.length; i += 2) {
        vec[i] = (vec[i] - cx) / sc;
        if (i + 1 < vec.length) {
          vec[i + 1] = (vec[i + 1] - cy) / sc;
        }
      }
      result.add(vec);
    }
    return result;
  }

  double _euclidean(List<double> a, List<double> b) {
    double sum = 0;
    final len = min(a.length, b.length);
    for (int i = 0; i < len; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return sqrt(sum);
  }

  /// DTW with Sakoe-Chiba band (window = 20% of longer sequence).
  /// Returns normalized distance (divided by path length).
  double _dtwDistance(List<List<double>> s1, List<List<double>> s2) {
    final n = s1.length;
    final m = s2.length;
    final window = max(1, (max(n, m) * 0.2).round());

    final dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      final jStart = max(1, i - window);
      final jEnd = min(m, i + window);
      for (int j = jStart; j <= jEnd; j++) {
        final cost = _euclidean(s1[i - 1], s2[j - 1]);
        final prev = min(dtw[i - 1][j], min(dtw[i][j - 1], dtw[i - 1][j - 1]));
        dtw[i][j] = cost + prev;
      }
    }

    // Guard against infinity (band too narrow)
    if (dtw[n][m] == double.infinity) return double.infinity;
    return dtw[n][m] / (n + m);
  }
}
