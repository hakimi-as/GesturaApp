import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/video_cache_service.dart';
import '../../services/haptic_service.dart';

/// Video player that automatically caches videos for offline playback
class CachedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final BoxFit fit;
  final Widget? placeholder;
  final Function(VideoPlayerController)? onControllerReady;
  final VoidCallback? onVideoEnd;
  
  const CachedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = true,
    this.showControls = true,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.onControllerReady,
    this.onVideoEnd,
  });

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  bool _isFromCache = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CachedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Check if video is cached
      final cachedFile = await VideoCacheService.getCachedVideo(widget.videoUrl);
      
      if (cachedFile != null && await cachedFile.exists()) {
        // Play from cache
        debugPrint('📦 Playing video from cache');
        _controller = VideoPlayerController.file(cachedFile);
        _isFromCache = true;
      } else {
        // Play from network and cache in background
        debugPrint('🌐 Playing video from network');
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        _isFromCache = false;
        
        // Start caching in background
        VideoCacheService.cacheVideo(widget.videoUrl);
      }

      await _controller!.initialize();
      
      _controller!.addListener(_videoListener);
      _controller!.setLooping(widget.looping);
      
      if (widget.autoPlay) {
        await _controller!.play();
      }

      widget.onControllerReady?.call(_controller!);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    final isBuffering = _controller?.value.isBuffering ?? false;
    if (_isBuffering != isBuffering) {
      setState(() => _isBuffering = isBuffering);
    }

    // Check if video ended
    if (_controller != null && 
        _controller!.value.position >= _controller!.value.duration &&
        !widget.looping) {
      widget.onVideoEnd?.call();
    }
  }

  void _disposeController() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticService.buttonTap();
    if (_controller?.value.isPlaying ?? false) {
      _controller?.pause();
    } else {
      _controller?.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: widget.showControls ? _togglePlayPause : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          AspectRatio(
            aspectRatio: widget.aspectRatio ?? _controller!.value.aspectRatio,
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

          // Buffering indicator
          if (_isBuffering)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),

          // Play/Pause overlay
          if (widget.showControls && !(_controller?.value.isPlaying ?? false) && !_isBuffering)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ).animate().fadeIn(duration: 200.ms),

          // Cache indicator
          if (_isFromCache)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_pin,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Cached',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Controls overlay
          if (widget.showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return widget.placeholder ?? Container(
      color: context.bgElevated,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: context.bgElevated,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load video',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                HapticService.buttonTap();
                setState(() {
                  _hasError = false;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(180),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white.withAlpha(80),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(50),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).toInt(),
                );
                _controller?.seekTo(newPosition);
              },
            ),
          ),
          
          // Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}


/// Simple cached video thumbnail
class CachedVideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  
  const CachedVideoThumbnail({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  State<CachedVideoThumbnail> createState() => _CachedVideoThumbnailState();
}

class _CachedVideoThumbnailState extends State<CachedVideoThumbnail> {
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    final cached = await VideoCacheService.isVideoCached(widget.videoUrl);
    if (mounted) {
      setState(() => _isCached = cached);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Placeholder
        Container(
          width: widget.width,
          height: widget.height,
          color: context.bgElevated,
          child: widget.placeholder ?? const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ),
        
        // Cached indicator
        if (_isCached)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.offline_pin,
                size: 14,
                color: Color(0xFF10B981),
              ),
            ),
          ),
      ],
    );
  }
}