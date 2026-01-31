import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../services/haptic_service.dart';
import '../services/video_cache_service.dart';
import '../services/offline_service.dart';

/// Settings section for managing offline data and cache
class OfflineSettingsSection extends StatefulWidget {
  const OfflineSettingsSection({super.key});

  @override
  State<OfflineSettingsSection> createState() => _OfflineSettingsSectionState();
}

class _OfflineSettingsSectionState extends State<OfflineSettingsSection> {
  String _videoCacheSize = 'Calculating...';
  String _offlineDataSize = 'Calculating...';
  int _cachedVideos = 0;
  int _cachedLessons = 0;
  int _pendingSyncs = 0;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    
    // Listen for changes from other screens
    OfflineService.notifier.addListener(_loadStats);
  }

  @override
  void dispose() {
    OfflineService.notifier.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final videoCacheSize = await VideoCacheService.getFormattedCacheSize();
    final offlineDataSize = await OfflineService.getFormattedStorageSize();
    final cachedVideos = await VideoCacheService.getCachedVideoCount();
    final lessonIds = await OfflineService.getCachedLessonIds();
    final pendingSyncs = await OfflineService.getPendingSyncCount();

    if (mounted) {
      setState(() {
        _videoCacheSize = videoCacheSize;
        _offlineDataSize = offlineDataSize;
        _cachedVideos = cachedVideos;
        _cachedLessons = lessonIds.length;
        _pendingSyncs = pendingSyncs;
      });
    }
  }

  Future<void> _clearVideoCache() async {
    HapticService.buttonTap();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Video Cache?'),
        content: const Text(
          'This will remove all cached videos. You\'ll need an internet connection to watch them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isClearing = true);
      
      await VideoCacheService.clearCache();
      await _loadStats();
      
      setState(() => _isClearing = false);
      
      HapticService.success();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Video cache cleared'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _clearOfflineData() async {
    HapticService.buttonTap();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Offline Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will remove all downloaded lessons and offline data.',
            ),
            if (_pendingSyncs > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_pendingSyncs items haven\'t been synced yet. They will be lost!',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isClearing = true);
      
      await OfflineService.clearAllData();
      await _loadStats();
      
      setState(() => _isClearing = false);
      
      HapticService.success();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Offline data cleared'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'OFFLINE & STORAGE',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),

        // Storage overview card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: '📹',
                      value: '$_cachedVideos',
                      label: 'Videos',
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.borderColor,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: '📚',
                      value: '$_cachedLessons',
                      label: 'Lessons',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.borderColor,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: '🔄',
                      value: '$_pendingSyncs',
                      label: 'Pending',
                      color: _pendingSyncs > 0 
                          ? AppColors.warning 
                          : context.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Video cache
              _buildStorageRow(
                icon: Icons.video_library_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Video Cache',
                size: _videoCacheSize,
                onClear: _clearVideoCache,
              ),

              const SizedBox(height: 12),

              // Offline data
              _buildStorageRow(
                icon: Icons.folder_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'Offline Lessons',
                size: _offlineDataSize,
                onClear: _clearOfflineData,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),

        // Pending sync warning
        if (_pendingSyncs > 0) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sync_problem,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Sync',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_pendingSyncs items waiting to sync',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    HapticService.buttonTap();
                    final result = await OfflineService.syncPendingItems();
                    await _loadStats();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isComplete 
                                ? '✓ All items synced'
                                : 'Synced ${result.synced}, ${result.pending} remaining',
                          ),
                          backgroundColor: result.isComplete 
                              ? const Color(0xFF10B981)
                              : AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Sync Now'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).shake(delay: 500.ms, hz: 2),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStorageRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String size,
    required VoidCallback onClear,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                size,
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _isClearing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Clear'),
              ),
      ],
    );
  }
}


/// Quick offline stats card for dashboard or profile
class OfflineStatsCard extends StatefulWidget {
  final VoidCallback? onTap;
  
  const OfflineStatsCard({super.key, this.onTap});

  @override
  State<OfflineStatsCard> createState() => _OfflineStatsCardState();
}

class _OfflineStatsCardState extends State<OfflineStatsCard> {
  int _cachedLessons = 0;
  int _cachedVideos = 0;
  String _totalSize = '0 B';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final lessonIds = await OfflineService.getCachedLessonIds();
    final videoCount = await VideoCacheService.getCachedVideoCount();
    final videoSize = await VideoCacheService.getCacheSize();
    final offlineSize = await OfflineService.getStorageSize();
    final totalBytes = videoSize + offlineSize;

    if (mounted) {
      setState(() {
        _cachedLessons = lessonIds.length;
        _cachedVideos = videoCount;
        _totalSize = _formatBytes(totalBytes);
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedLessons == 0 && _cachedVideos == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        widget.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📥', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_cachedLessons lessons • $_cachedVideos videos • $_totalSize',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }
}