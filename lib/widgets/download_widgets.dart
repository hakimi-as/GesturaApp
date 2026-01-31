import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../config/theme.dart';
import '../services/haptic_service.dart';
import '../services/video_cache_service.dart';
import '../services/offline_service.dart';

/// Status of a downloadable lesson
enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

/// Download button that shows download progress
class DownloadButton extends StatefulWidget {
  final String lessonId;
  final String? videoUrl;
  final Map<String, dynamic>? lessonData;
  final VoidCallback? onDownloadComplete;
  final double size;
  
  const DownloadButton({
    super.key,
    required this.lessonId,
    this.videoUrl,
    this.lessonData,
    this.onDownloadComplete,
    this.size = 36,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  DownloadStatus _status = DownloadStatus.notDownloaded;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final isLessonCached = await OfflineService.isLessonAvailable(widget.lessonId);
    bool isVideoCached = true;
    
    if (widget.videoUrl != null) {
      isVideoCached = await VideoCacheService.isVideoCached(widget.videoUrl!);
    }

    if (mounted) {
      setState(() {
        _status = (isLessonCached && isVideoCached)
            ? DownloadStatus.downloaded
            : DownloadStatus.notDownloaded;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_status == DownloadStatus.downloading) return;

    setState(() {
      _status = DownloadStatus.downloading;
      _progress = 0;
    });

    HapticService.buttonTap();

    try {
      // Save lesson data
      if (widget.lessonData != null) {
        await OfflineService.saveLesson(widget.lessonId, widget.lessonData!);
        setState(() => _progress = 0.3);
      }

      // Download video if available
      if (widget.videoUrl != null) {
        await for (final response in VideoCacheService.downloadVideoWithProgress(widget.videoUrl!)) {
          if (response is DownloadProgress) {
            setState(() {
              final progress = response.progress ?? 0.0;
              _progress = 0.3 + (progress * 0.7);
            });
          }
        }
      }

      setState(() {
        _status = DownloadStatus.downloaded;
        _progress = 1.0;
      });

      HapticService.success();
      widget.onDownloadComplete?.call();
    } catch (e) {
      debugPrint('Download error: $e');
      setState(() {
        _status = DownloadStatus.error;
      });
      HapticService.error();
    }
  }

  Future<void> _removeDownload() async {
    HapticService.buttonTap();
    
    await OfflineService.removeLesson(widget.lessonId);
    if (widget.videoUrl != null) {
      await VideoCacheService.removeFromCache(widget.videoUrl!);
    }

    setState(() {
      _status = DownloadStatus.notDownloaded;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (_status) {
          case DownloadStatus.notDownloaded:
          case DownloadStatus.error:
            _startDownload();
            break;
          case DownloadStatus.downloaded:
            _showRemoveDialog();
            break;
          case DownloadStatus.downloading:
            // Do nothing while downloading
            break;
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          shape: BoxShape.circle,
        ),
        child: _buildContent(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_status) {
      case DownloadStatus.notDownloaded:
        return context.bgElevated;
      case DownloadStatus.downloading:
        return AppColors.primary.withAlpha(30);
      case DownloadStatus.downloaded:
        return const Color(0xFF10B981).withAlpha(30);
      case DownloadStatus.error:
        return AppColors.error.withAlpha(30);
    }
  }

  Widget _buildContent() {
    switch (_status) {
      case DownloadStatus.notDownloaded:
        return Icon(
          Icons.download_outlined,
          size: widget.size * 0.5,
          color: context.textMuted,
        );
      case DownloadStatus.downloading:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widget.size * 0.7,
              height: widget.size * 0.7,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: AppColors.primary.withAlpha(50),
              ),
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: widget.size * 0.22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      case DownloadStatus.downloaded:
        return Icon(
          Icons.check_circle,
          size: widget.size * 0.6,
          color: const Color(0xFF10B981),
        );
      case DownloadStatus.error:
        return Icon(
          Icons.error_outline,
          size: widget.size * 0.5,
          color: AppColors.error,
        );
    }
  }

  void _showRemoveDialog() {
    HapticService.buttonTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Download?'),
        content: const Text(
          'This will remove the lesson from your device. You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeDownload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}


/// Card showing a downloadable lesson with progress
class DownloadableLessonCard extends StatefulWidget {
  final String lessonId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? videoUrl;
  final Map<String, dynamic> lessonData;
  final VoidCallback? onTap;
  
  const DownloadableLessonCard({
    super.key,
    required this.lessonId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.videoUrl,
    required this.lessonData,
    this.onTap,
  });

  @override
  State<DownloadableLessonCard> createState() => _DownloadableLessonCardState();
}

class _DownloadableLessonCardState extends State<DownloadableLessonCard> {
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isAvailable = await OfflineService.isLessonAvailable(widget.lessonId);
    if (mounted) {
      setState(() => _isDownloaded = isAvailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        widget.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDownloaded 
                ? const Color(0xFF10B981).withAlpha(100) 
                : context.borderColor,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('🤟', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text('🤟', style: TextStyle(fontSize: 28)),
                    ),
            ),
            const SizedBox(width: 14),
            
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isDownloaded)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download_done,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Saved',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            
            // Download button
            DownloadButton(
              lessonId: widget.lessonId,
              videoUrl: widget.videoUrl,
              lessonData: widget.lessonData,
              onDownloadComplete: () {
                setState(() => _isDownloaded = true);
              },
            ),
          ],
        ),
      ),
    );
  }
}


/// Download all button for bulk downloads
class DownloadAllButton extends StatefulWidget {
  final List<Map<String, dynamic>> lessons;
  final VoidCallback? onComplete;
  
  const DownloadAllButton({
    super.key,
    required this.lessons,
    this.onComplete,
  });

  @override
  State<DownloadAllButton> createState() => _DownloadAllButtonState();
}

class _DownloadAllButtonState extends State<DownloadAllButton> {
  bool _isDownloading = false;
  int _completed = 0;
  int _total = 0;

  Future<void> _downloadAll() async {
    if (_isDownloading) return;

    HapticService.buttonTap();
    
    setState(() {
      _isDownloading = true;
      _completed = 0;
      _total = widget.lessons.length;
    });

    for (final lesson in widget.lessons) {
      try {
        final lessonId = lesson['id'] as String;
        final videoUrl = lesson['videoUrl'] as String?;
        
        // Save lesson data
        await OfflineService.saveLesson(lessonId, lesson);
        
        // Cache video if available
        if (videoUrl != null) {
          await VideoCacheService.cacheVideo(videoUrl);
        }
        
        setState(() => _completed++);
      } catch (e) {
        debugPrint('Error downloading lesson: $e');
        setState(() => _completed++);
      }
    }

    HapticService.success();
    
    setState(() => _isDownloading = false);
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: _total > 0 ? _completed / _total : null,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Downloading $_completed/$_total',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _downloadAll,
      icon: const Icon(Icons.download, size: 18),
      label: Text('Download All (${widget.lessons.length})'),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.bgCard,
        foregroundColor: context.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.borderColor),
        ),
      ),
    );
  }
}


/// Offline availability indicator badge
class OfflineAvailableBadge extends StatelessWidget {
  final String lessonId;
  
  const OfflineAvailableBadge({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OfflineService.isLessonAvailable(lessonId),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.offline_pin,
                size: 12,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 3),
              Text(
                'Offline',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }
}