import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../config/theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final VoidCallback? onCompleted;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.onCompleted,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      _videoPlayerController.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: widget.aspectRatio ?? _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
        placeholder: _buildPlaceholder(),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (_videoPlayerController.value.position >= _videoPlayerController.value.duration &&
        _videoPlayerController.value.duration > Duration.zero) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget(_errorMessage ?? 'Unknown error');
    }

    if (!_isInitialized || _chewieController == null) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Chewie(controller: _chewieController!),
    );
  }
}

/// Simple video thumbnail widget
class VideoThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final String? videoUrl;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    this.videoUrl,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          image: thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(thumbnailUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Play button overlay
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            // Video icon badge
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}