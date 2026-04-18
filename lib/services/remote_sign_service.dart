import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dtw_service.dart';

/// Result from the remote sign recognition API.
/// Identical shape to [SignMatch] so callers can use either interchangeably.
class RemoteSignMatch {
  final String word;
  final double confidence;
  final double distance;

  const RemoteSignMatch({
    required this.word,
    required this.confidence,
    required this.distance,
  });
}

/// Calls the Gestura Sign Recognition API for server-side DTW matching.
///
/// Falls back to on-device [DtwService] automatically when:
///   - the server is unreachable
///   - the server returns an error
///   - [serverUrl] is not configured
///
/// Usage:
///   final matches = await RemoteSignService.instance.match(frames, topK: 5);
class RemoteSignService {
  RemoteSignService._();
  static final RemoteSignService instance = RemoteSignService._();

  // ── Configuration ───────────────────────────────────────────────────────
  // Set these before using the service, e.g. in main() after Firebase init.

  /// Base URL of the sign recognition server, no trailing slash.
  /// Example: 'https://your-app.up.railway.app'
  static String serverUrl = '';

  /// API key sent in the X-API-Key header.
  static String apiKey = '';

  /// Timeout for remote requests.
  static const Duration _timeout = Duration(seconds: 6);

  // ── Public API ──────────────────────────────────────────────────────────

  /// Match [queryFrames] against the sign library.
  ///
  /// Tries the remote server first. If the server is unavailable or not
  /// configured, falls back to on-device [DtwService].
  ///
  /// [queryFrames] — list of landmark frame maps with keys:
  ///   'pose', 'left_hand', 'right_hand' (same format as DtwService).
  Future<List<RemoteSignMatch>> match(
    List<Map<String, dynamic>> queryFrames, {
    int topK = 5,
  }) async {
    if (serverUrl.isNotEmpty) {
      try {
        return await _remoteMatch(queryFrames, topK: topK);
      } catch (e) {
        debugPrint('RemoteSignService: server error, falling back on-device: $e');
      }
    }
    return _localMatch(queryFrames, topK: topK);
  }

  /// Check server health. Returns null if unreachable.
  Future<Map<String, dynamic>?> checkHealth() async {
    if (serverUrl.isEmpty) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$serverUrl/health'),
            headers: _headers(),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Remote path ─────────────────────────────────────────────────────────

  Future<List<RemoteSignMatch>> _remoteMatch(
    List<Map<String, dynamic>> frames, {
    required int topK,
  }) async {
    final body = jsonEncode({
      'frames': frames.map(_sanitizeFrame).toList(),
      'top_k': topK,
    });

    final response = await http
        .post(
          Uri.parse('$serverUrl/match'),
          headers: {
            ..._headers(),
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final matches = (data['matches'] as List).cast<Map<String, dynamic>>();

    debugPrint(
      'RemoteSignService: ${matches.isNotEmpty ? matches.first['word'] : '—'} '
      '(${data['latency_ms']} ms, library=${data['library_size']})',
    );

    return matches
        .map((m) => RemoteSignMatch(
              word: m['word'] as String,
              confidence: (m['confidence'] as num).toDouble(),
              distance: (m['distance'] as num).toDouble(),
            ))
        .toList();
  }

  // ── Local fallback ───────────────────────────────────────────────────────

  Future<List<RemoteSignMatch>> _localMatch(
    List<Map<String, dynamic>> frames, {
    required int topK,
  }) async {
    final dtw = DtwService.instance;

    if (!dtw.isLoaded) {
      debugPrint('RemoteSignService: loading on-device DTW library…');
      await dtw.loadLibrary();
    }

    final matches = dtw.match(frames, topK: topK);

    debugPrint('RemoteSignService: on-device fallback → ${matches.isNotEmpty ? matches.first.word : '—'}');

    return matches
        .map((m) => RemoteSignMatch(
              word: m.word,
              confidence: m.confidence,
              distance: m.distance,
            ))
        .toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, String> _headers() => {
        if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
      };

  /// Ensure each frame only contains serialisable data.
  Map<String, dynamic> _sanitizeFrame(Map<String, dynamic> frame) {
    return {
      'pose': _sanitizeLandmarks(frame['pose']),
      'left_hand': _sanitizeLandmarks(frame['left_hand']),
      'right_hand': _sanitizeLandmarks(frame['right_hand']),
    };
  }

  dynamic _sanitizeLandmarks(dynamic lms) {
    if (lms == null) return null;
    if (lms is List) {
      return lms
          .map((lm) => {
                'x': (lm['x'] as num).toDouble(),
                'y': (lm['y'] as num).toDouble(),
              })
          .toList();
    }
    return null;
  }
}
