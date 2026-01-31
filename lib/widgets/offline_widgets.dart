import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/connectivity_provider.dart';
import '../config/theme.dart';
import '../services/offline_service.dart';

/// Banner that appears at the top of the screen when offline
class OfflineBanner extends StatelessWidget {
  final bool showSyncCount;
  
  const OfflineBanner({
    super.key,
    this.showSyncCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF97316)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'You\'re offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Some features may be limited',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showSyncCount)
                  FutureBuilder<int>(
                    future: OfflineService.getPendingSyncCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sync,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$count pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ).animate().slideY(begin: -1, duration: 300.ms, curve: Curves.easeOut);
      },
    );
  }
}


/// Compact offline indicator (dot or icon)
class OfflineIndicator extends StatelessWidget {
  final double size;
  final bool showText;
  
  const OfflineIndicator({
    super.key,
    this.size = 10,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        if (showText) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withAlpha(100),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 1.seconds,
        );
      },
    );
  }
}


/// Connection status chip
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        final isOnline = connectivity.isOnline;
        final connectionType = connectivity.connectionTypeString;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline 
                ? const Color(0xFF10B981).withAlpha(30) 
                : AppColors.error.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnline 
                  ? const Color(0xFF10B981).withAlpha(100) 
                  : AppColors.error.withAlpha(100),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: isOnline ? const Color(0xFF10B981) : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? connectionType : 'Offline',
                style: TextStyle(
                  color: isOnline ? const Color(0xFF10B981) : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/// Syncing indicator that shows when back online and syncing
class SyncingIndicator extends StatefulWidget {
  const SyncingIndicator({super.key});

  @override
  State<SyncingIndicator> createState() => _SyncingIndicatorState();
}

class _SyncingIndicatorState extends State<SyncingIndicator> {
  bool _isSyncing = false;
  bool _wasOffline = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        // Detect when coming back online
        if (connectivity.isOnline && _wasOffline && !_isSyncing) {
          _syncPendingItems();
        }
        _wasOffline = connectivity.isOffline;

        if (!_isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Syncing...',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }

  Future<void> _syncPendingItems() async {
    setState(() => _isSyncing = true);
    
    try {
      final result = await OfflineService.syncPendingItems();
      
      if (mounted) {
        if (result.synced > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Synced ${result.synced} items'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error syncing: $e');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }
}


/// Widget wrapper that handles offline state
class OfflineAware extends StatelessWidget {
  final Widget child;
  final Widget? offlineChild;
  final bool showBanner;
  
  const OfflineAware({
    super.key,
    required this.child,
    this.offlineChild,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Column(
          children: [
            if (showBanner) const OfflineBanner(),
            Expanded(
              child: connectivity.isOffline && offlineChild != null
                  ? offlineChild!
                  : child,
            ),
          ],
        );
      },
    );
  }
}


/// Empty state shown when offline and no cached data
class OfflineEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  
  const OfflineEmptyState({
    super.key,
    this.title = 'You\'re offline',
    this.subtitle = 'Connect to the internet to access this content',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📡', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}