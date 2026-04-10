import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Status updates during video processing.
enum ProcessingStatus { uploading, processing, done, failed }

class VideoProcessingResult {
  final bool success;
  final String? errorMessage;
  final List<Map<String, dynamic>> frames;

  const VideoProcessingResult({
    required this.success,
    this.errorMessage,
    this.frames = const [],
  });
}

class VideoProcessingService {
  static const String baseUrl = 'https://hakimi-as-gestura-converter.hf.space';

  /// Process a video through the HuggingFace Space.
  /// Accepts raw bytes — works on web and native alike.
  static Future<VideoProcessingResult> processVideo({
    required Uint8List videoBytes,
    required String filename,
    void Function(ProcessingStatus status, String message)? onStatus,
    int timeoutSec = 300,
  }) async {
    try {
      onStatus?.call(ProcessingStatus.uploading, 'Uploading video...');

      final uri = Uri.parse('$baseUrl/process');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'video',
        videoBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send().timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException(
          'Processing timed out after ${timeoutSec}s. Try a shorter video (< 5s).',
        ),
      );

      onStatus?.call(ProcessingStatus.processing, 'Processing skeleton...');

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        String detail = responseBody;
        try { detail = json.decode(responseBody)['detail'] ?? responseBody; } catch (_) {}
        throw Exception('Server error ${streamedResponse.statusCode}: $detail');
      }

      final decoded = json.decode(responseBody) as Map<String, dynamic>;
      final rawFrames = decoded['data'] as List?;

      if (rawFrames == null || rawFrames.isEmpty) {
        throw Exception('No skeleton frames returned. Ensure the video shows a person signing.');
      }

      final frames = rawFrames.cast<Map<String, dynamic>>();
      onStatus?.call(ProcessingStatus.done, 'Done — ${frames.length} frames extracted');
      return VideoProcessingResult(success: true, frames: frames);
    } on TimeoutException catch (e) {
      debugPrint('VideoProcessingService timeout: $e');
      onStatus?.call(ProcessingStatus.failed, e.message ?? 'Timed out');
      return VideoProcessingResult(success: false, errorMessage: e.message);
    } catch (e) {
      debugPrint('VideoProcessingService error: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');
      onStatus?.call(ProcessingStatus.failed, msg);
      return VideoProcessingResult(success: false, errorMessage: msg);
    }
  }

  /// Process a video from a YouTube / TikTok / direct URL.
  static Future<VideoProcessingResult> processVideoUrl({
    required String url,
    void Function(ProcessingStatus status, String message)? onStatus,
    int timeoutSec = 300,
  }) async {
    try {
      onStatus?.call(ProcessingStatus.uploading, 'Downloading video from URL...');

      final uri = Uri.parse('$baseUrl/process-url');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      ).timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException('Timed out after ${timeoutSec}s.'),
      );

      onStatus?.call(ProcessingStatus.processing, 'Processing skeleton...');

      if (response.statusCode != 200) {
        String detail = response.body;
        try { detail = json.decode(response.body)['detail'] ?? response.body; } catch (_) {}
        throw Exception('Server error ${response.statusCode}: $detail');
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final rawFrames = decoded['data'] as List?;

      if (rawFrames == null || rawFrames.isEmpty) {
        throw Exception('No skeleton frames returned.');
      }

      final frames = rawFrames.cast<Map<String, dynamic>>();
      onStatus?.call(ProcessingStatus.done, 'Done — ${frames.length} frames extracted');
      return VideoProcessingResult(success: true, frames: frames);
    } on TimeoutException catch (e) {
      debugPrint('processVideoUrl timeout: $e');
      onStatus?.call(ProcessingStatus.failed, e.message ?? 'Timed out');
      return VideoProcessingResult(success: false, errorMessage: e.message);
    } catch (e) {
      debugPrint('processVideoUrl error: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');
      onStatus?.call(ProcessingStatus.failed, msg);
      return VideoProcessingResult(success: false, errorMessage: msg);
    }
  }

  static Future<bool> isSpaceReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
