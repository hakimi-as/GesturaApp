import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'offline_service.dart';

/// Service for caching sign language videos locally
/// Videos are cached after first view for instant playback
class VideoCacheService {
  static const String _cacheKey = 'gestura_video_cache';
  static const Duration _stalePeriod = Duration(days: 30);
  static const int _maxCacheSize = 500; // Max 500 videos cached
  static const int _maxCacheSizeBytes = 500 * 1024 * 1024; // 500 MB max

  static CacheManager? _instance;

  /// Get the cache manager instance
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _stalePeriod,
        maxNrOfCacheObjects: _maxCacheSize,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Check if a video is already cached
  static Future<bool> isVideoCached(String videoUrl) async {
    try {
      final fileInfo = await instance.getFileFromCache(videoUrl);
      return fileInfo != null && await fileInfo.file.exists();
    } catch (e) {
      debugPrint('Error checking video cache: $e');
      return false;
    }
  }

  /// Get cached video file (returns null if not cached)
  static Future<File?> getCachedVideo(String videoUrl) async {
    try {
      final fileInfo = await instance.getFileFromCache(videoUrl);
      if (fileInfo != null && await fileInfo.file.exists()) {
        return fileInfo.file;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached video: $e');
      return null;
    }
  }

  /// Download and cache a video
  /// Returns the cached file, or null if download fails
  static Future<File?> cacheVideo(
    String videoUrl, {
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('📥 Caching video: $videoUrl');
      
      final file = await instance.getSingleFile(
        videoUrl,
        key: videoUrl,
      );
      
      debugPrint('✅ Video cached: ${file.path}');
      
      // Notify listeners that data changed
      OfflineDataNotifier.instance.notifyDataChanged();
      
      return file;
    } catch (e) {
      debugPrint('❌ Error caching video: $e');
      return null;
    }
  }

  /// Download video with progress tracking
  static Stream<FileResponse> downloadVideoWithProgress(String videoUrl) {
    return instance.getFileStream(
      videoUrl,
      key: videoUrl,
      withProgress: true,
    );
  }

  /// Pre-cache multiple videos (e.g., for a lesson)
  static Future<Map<String, bool>> preCacheVideos(
    List<String> videoUrls, {
    Function(int completed, int total)? onProgress,
  }) async {
    final results = <String, bool>{};
    int completed = 0;

    for (final url in videoUrls) {
      try {
        // Skip if already cached
        if (await isVideoCached(url)) {
          results[url] = true;
          completed++;
          onProgress?.call(completed, videoUrls.length);
          continue;
        }

        // Download and cache
        final file = await cacheVideo(url);
        results[url] = file != null;
        completed++;
        onProgress?.call(completed, videoUrls.length);
      } catch (e) {
        results[url] = false;
        completed++;
        onProgress?.call(completed, videoUrls.length);
      }
    }

    return results;
  }

  /// Remove a specific video from cache
  static Future<void> removeFromCache(String videoUrl) async {
    try {
      await instance.removeFile(videoUrl);
      debugPrint('🗑️ Removed from cache: $videoUrl');
      
      // Notify listeners that data changed
      OfflineDataNotifier.instance.notifyDataChanged();
    } catch (e) {
      debugPrint('Error removing from cache: $e');
    }
  }

  /// Clear all cached videos
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      debugPrint('🗑️ Video cache cleared');
      
      // Notify listeners that data changed
      OfflineDataNotifier.instance.notifyDataChanged();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get total cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final gesturaCacheDir = Directory('${cacheDir.path}/$_cacheKey');
      
      if (!await gesturaCacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final file in gesturaCacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  /// Get formatted cache size string
  static Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSize();
    return _formatBytes(bytes);
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get number of cached videos
  static Future<int> getCachedVideoCount() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final gesturaCacheDir = Directory('${cacheDir.path}/$_cacheKey');
      
      if (!await gesturaCacheDir.exists()) {
        return 0;
      }

      int count = 0;
      await for (final file in gesturaCacheDir.list(recursive: true)) {
        if (file is File && _isVideoFile(file.path)) {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Error getting cached video count: $e');
      return 0;
    }
  }

  /// Check if file is a video
  static bool _isVideoFile(String path) {
    final extensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  /// Clean up old cache if size exceeds limit
  static Future<void> cleanupIfNeeded() async {
    try {
      final currentSize = await getCacheSize();
      if (currentSize > _maxCacheSizeBytes) {
        debugPrint('⚠️ Cache size exceeded limit, cleaning up...');
        // The cache manager handles this automatically based on stalePeriod
        // But we can force a cleanup if needed
        await instance.emptyCache();
      }
    } catch (e) {
      debugPrint('Error during cache cleanup: $e');
    }
  }
}


/// Extension for easier video caching in widgets
extension VideoCacheExtension on String {
  /// Check if this URL is cached
  Future<bool> get isCached => VideoCacheService.isVideoCached(this);
  
  /// Get cached file for this URL
  Future<File?> get cachedFile => VideoCacheService.getCachedVideo(this);
  
  /// Cache this URL
  Future<File?> cache() => VideoCacheService.cacheVideo(this);
}