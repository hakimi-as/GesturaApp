import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global notifier that fires when offline data changes
class OfflineDataNotifier extends ChangeNotifier {
  static final OfflineDataNotifier instance = OfflineDataNotifier._();
  OfflineDataNotifier._();
  
  void notifyDataChanged() {
    notifyListeners();
  }
}

/// Service for managing offline data storage and synchronization
class OfflineService {
  static const String _lessonsBoxName = 'offline_lessons';
  static const String _progressBoxName = 'offline_progress';
  static const String _pendingSyncBoxName = 'pending_sync';
  static const String _userDataBoxName = 'offline_user_data';

  static Box? _lessonsBox;
  static Box? _progressBox;
  static Box? _pendingSyncBox;
  static Box? _userDataBox;

  static bool _isInitialized = false;
  
  /// Get the notifier to listen for changes
  static OfflineDataNotifier get notifier => OfflineDataNotifier.instance;

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      _lessonsBox = await Hive.openBox(_lessonsBoxName);
      _progressBox = await Hive.openBox(_progressBoxName);
      _pendingSyncBox = await Hive.openBox(_pendingSyncBoxName);
      _userDataBox = await Hive.openBox(_userDataBoxName);
      
      _isInitialized = true;
      debugPrint('📦 OfflineService initialized');
    } catch (e) {
      debugPrint('Error initializing OfflineService: $e');
    }
  }

  /// Ensure service is initialized
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ==================== LESSON CACHING ====================

  /// Save a lesson for offline access
  static Future<void> saveLesson(String lessonId, Map<String, dynamic> lessonData) async {
    await _ensureInitialized();
    try {
      await _lessonsBox?.put(lessonId, {
        ...lessonData,
        'cachedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('💾 Lesson saved offline: $lessonId');
      
      // Notify listeners that data changed
      OfflineDataNotifier.instance.notifyDataChanged();
    } catch (e) {
      debugPrint('Error saving lesson offline: $e');
    }
  }

  /// Get a cached lesson
  static Future<Map<String, dynamic>?> getLesson(String lessonId) async {
    await _ensureInitialized();
    try {
      final data = _lessonsBox?.get(lessonId);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting offline lesson: $e');
      return null;
    }
  }

  /// Check if a lesson is available offline
  static Future<bool> isLessonAvailable(String lessonId) async {
    await _ensureInitialized();
    return _lessonsBox?.containsKey(lessonId) ?? false;
  }

  /// Get all cached lesson IDs
  static Future<List<String>> getCachedLessonIds() async {
    await _ensureInitialized();
    return _lessonsBox?.keys.cast<String>().toList() ?? [];
  }

  /// Remove a cached lesson
  static Future<void> removeLesson(String lessonId) async {
    await _ensureInitialized();
    await _lessonsBox?.delete(lessonId);
    
    // Notify listeners that data changed
    OfflineDataNotifier.instance.notifyDataChanged();
  }

  /// Save multiple lessons (e.g., entire category)
  static Future<void> saveLessons(Map<String, Map<String, dynamic>> lessons) async {
    await _ensureInitialized();
    for (final entry in lessons.entries) {
      await saveLesson(entry.key, entry.value);
    }
  }

  // ==================== PROGRESS TRACKING ====================

  /// Save progress update locally (for later sync)
  static Future<void> saveProgressLocally(
    String odlerndId,
    String lessonId,
    Map<String, dynamic> progressData,
  ) async {
    await _ensureInitialized();
    try {
      final key = '${odlerndId}_$lessonId';
      await _progressBox?.put(key, {
        ...progressData,
        'userId': odlerndId,
        'lessonId': lessonId,
        'savedAt': DateTime.now().toIso8601String(),
      });
      
      // Add to pending sync queue
      await _addToPendingSync('progress', key, progressData);
      
      debugPrint('💾 Progress saved locally: $lessonId');
    } catch (e) {
      debugPrint('Error saving progress locally: $e');
    }
  }

  /// Get locally saved progress
  static Future<Map<String, dynamic>?> getLocalProgress(
    String userId,
    String lessonId,
  ) async {
    await _ensureInitialized();
    try {
      final key = '${userId}_$lessonId';
      final data = _progressBox?.get(key);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting local progress: $e');
      return null;
    }
  }

  // ==================== PENDING SYNC QUEUE ====================

  /// Add item to pending sync queue
  static Future<void> _addToPendingSync(
    String type,
    String key,
    Map<String, dynamic> data,
  ) async {
    await _ensureInitialized();
    try {
      final syncKey = '${type}_$key';
      await _pendingSyncBox?.put(syncKey, {
        'type': type,
        'key': key,
        'data': data,
        'createdAt': DateTime.now().toIso8601String(),
        'attempts': 0,
      });
    } catch (e) {
      debugPrint('Error adding to pending sync: $e');
    }
  }

  /// Get all pending sync items
  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    await _ensureInitialized();
    try {
      final items = <Map<String, dynamic>>[];
      for (final key in _pendingSyncBox?.keys ?? []) {
        final data = _pendingSyncBox?.get(key);
        if (data != null) {
          items.add({
            'syncKey': key,
            ...Map<String, dynamic>.from(data),
          });
        }
      }
      return items;
    } catch (e) {
      debugPrint('Error getting pending sync items: $e');
      return [];
    }
  }

  /// Get pending sync count
  static Future<int> getPendingSyncCount() async {
    await _ensureInitialized();
    return _pendingSyncBox?.length ?? 0;
  }

  /// Remove item from pending sync after successful sync
  static Future<void> removePendingSync(String syncKey) async {
    await _ensureInitialized();
    await _pendingSyncBox?.delete(syncKey);
  }

  /// Sync all pending items to Firestore
  static Future<SyncResult> syncPendingItems() async {
    await _ensureInitialized();
    
    final items = await getPendingSyncItems();
    if (items.isEmpty) {
      return SyncResult(synced: 0, failed: 0, pending: 0);
    }

    debugPrint('🔄 Syncing ${items.length} pending items...');
    
    int synced = 0;
    int failed = 0;

    for (final item in items) {
      try {
        final type = item['type'] as String;
        final data = Map<String, dynamic>.from(item['data']);
        
        switch (type) {
          case 'progress':
            await _syncProgress(data);
            break;
          case 'lessonComplete':
            await _syncLessonComplete(data);
            break;
          case 'quizComplete':
            await _syncQuizComplete(data);
            break;
          default:
            debugPrint('Unknown sync type: $type');
        }
        
        await removePendingSync(item['syncKey']);
        synced++;
      } catch (e) {
        debugPrint('Error syncing item: $e');
        failed++;
        
        // Update attempt count
        final attempts = (item['attempts'] ?? 0) + 1;
        if (attempts >= 5) {
          // Remove after 5 failed attempts
          await removePendingSync(item['syncKey']);
        } else {
          await _pendingSyncBox?.put(item['syncKey'], {
            ...item,
            'attempts': attempts,
            'lastAttempt': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    final remaining = await getPendingSyncCount();
    debugPrint('✅ Sync complete: $synced synced, $failed failed, $remaining pending');
    
    return SyncResult(synced: synced, failed: failed, pending: remaining);
  }

  /// Sync progress to Firestore
  static Future<void> _syncProgress(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    final lessonId = data['lessonId'] as String;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(lessonId)
        .set(data, SetOptions(merge: true));
  }

  /// Sync lesson completion to Firestore
  static Future<void> _syncLessonComplete(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    
    // Update user stats
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          'lessonsCompleted': FieldValue.increment(1),
          'totalXP': FieldValue.increment(data['xpEarned'] ?? 10),
          'lastLessonDate': FieldValue.serverTimestamp(),
        });
  }

  /// Sync quiz completion to Firestore
  static Future<void> _syncQuizComplete(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          'quizzesCompleted': FieldValue.increment(1),
          'totalXP': FieldValue.increment(data['xpEarned'] ?? 10),
        });
  }

  // ==================== USER DATA ====================

  /// Save user data for offline access
  static Future<void> saveUserData(String odlerndId, Map<String, dynamic> userData) async {
    await _ensureInitialized();
    try {
      await _userDataBox?.put(odlerndId, {
        ...userData,
        'cachedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('💾 User data saved offline');
    } catch (e) {
      debugPrint('Error saving user data offline: $e');
    }
  }

  /// Get cached user data
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    await _ensureInitialized();
    try {
      final data = _userDataBox?.get(userId);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting offline user data: $e');
      return null;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all offline data
  static Future<void> clearAllData() async {
    await _ensureInitialized();
    await _lessonsBox?.clear();
    await _progressBox?.clear();
    await _pendingSyncBox?.clear();
    await _userDataBox?.clear();
    debugPrint('🗑️ All offline data cleared');
    
    // Notify listeners that data changed
    OfflineDataNotifier.instance.notifyDataChanged();
  }

  /// Get total offline storage size
  static Future<int> getStorageSize() async {
    await _ensureInitialized();
    int totalSize = 0;
    
    // This is approximate - Hive doesn't provide exact file sizes
    totalSize += (_lessonsBox?.length ?? 0) * 1024; // ~1KB per lesson estimate
    totalSize += (_progressBox?.length ?? 0) * 256;
    totalSize += (_pendingSyncBox?.length ?? 0) * 512;
    totalSize += (_userDataBox?.length ?? 0) * 1024;
    
    return totalSize;
  }

  /// Get formatted storage size
  static Future<String> getFormattedStorageSize() async {
    final bytes = await getStorageSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get offline stats
  static Future<OfflineStats> getStats() async {
    await _ensureInitialized();
    return OfflineStats(
      cachedLessons: _lessonsBox?.length ?? 0,
      pendingSyncs: _pendingSyncBox?.length ?? 0,
      savedProgress: _progressBox?.length ?? 0,
    );
  }
}


/// Result of a sync operation
class SyncResult {
  final int synced;
  final int failed;
  final int pending;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.pending,
  });

  bool get hasErrors => failed > 0;
  bool get isComplete => pending == 0;
}


/// Offline storage statistics
class OfflineStats {
  final int cachedLessons;
  final int pendingSyncs;
  final int savedProgress;

  OfflineStats({
    required this.cachedLessons,
    required this.pendingSyncs,
    required this.savedProgress,
  });
}