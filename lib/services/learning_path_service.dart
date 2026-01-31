import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/learning_path_model.dart';

/// Service for managing learning paths
class LearningPathService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static CollectionReference get _pathsCollection => _db.collection('learningPaths');
  static CollectionReference get _progressCollection => _db.collection('userLearningProgress');

  // ==================== FETCH LEARNING PATHS ====================

  /// Get all active learning paths (no composite index needed)
  static Future<List<LearningPath>> getAllPaths() async {
    try {
      // Simple query - fetch all, filter locally
      final snapshot = await _pathsCollection.get();
      
      debugPrint('📚 Fetched ${snapshot.docs.length} path documents from Firestore');
      
      final paths = snapshot.docs
          .map((doc) {
            try {
              return LearningPath.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing path ${doc.id}: $e');
              return null;
            }
          })
          .where((path) => path != null && path.isActive)
          .cast<LearningPath>()
          .toList();
      
      // Sort locally by order
      paths.sort((a, b) => a.order.compareTo(b.order));
      
      debugPrint('📚 Returning ${paths.length} active paths');
      return paths;
    } catch (e) {
      debugPrint('❌ Error getting learning paths: $e');
      return [];
    }
  }

  /// Get paths filtered by difficulty (no composite index needed)
  static Future<List<LearningPath>> getPathsByDifficulty(String difficulty) async {
    try {
      final snapshot = await _pathsCollection.get();
      
      final paths = snapshot.docs
          .map((doc) {
            try {
              return LearningPath.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing path ${doc.id}: $e');
              return null;
            }
          })
          .where((path) => path != null && path.isActive && path.difficulty == difficulty)
          .cast<LearningPath>()
          .toList();
      
      paths.sort((a, b) => a.order.compareTo(b.order));
      
      return paths;
    } catch (e) {
      debugPrint('Error getting paths by difficulty: $e');
      return [];
    }
  }

  /// Get a single learning path by ID
  static Future<LearningPath?> getPath(String pathId) async {
    try {
      final doc = await _pathsCollection.doc(pathId).get();
      if (doc.exists) {
        return LearningPath.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting learning path: $e');
      return null;
    }
  }

  /// Get recommended paths based on user level
  static Future<List<LearningPath>> getRecommendedPaths(int userLevel) async {
    try {
      String difficulty;
      if (userLevel < 5) {
        difficulty = 'beginner';
      } else if (userLevel < 15) {
        difficulty = 'intermediate';
      } else {
        difficulty = 'advanced';
      }

      final paths = await getPathsByDifficulty(difficulty);
      if (paths.isEmpty) {
        return await getPathsByDifficulty('beginner');
      }
      return paths;
    } catch (e) {
      debugPrint('Error getting recommended paths: $e');
      return [];
    }
  }

  // ==================== USER PROGRESS ====================

  /// Get all progress for a user
  static Future<List<UserLearningPathProgress>> getUserProgress(String userId) async {
    try {
      final snapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) => UserLearningPathProgress.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return [];
    }
  }

  /// Get user's progress for a specific path
  static Future<UserLearningPathProgress?> getUserPathProgress(String userId, String pathId) async {
    try {
      final snapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('pathId', isEqualTo: pathId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return UserLearningPathProgress.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user path progress: $e');
      return null;
    }
  }

  /// Get the user's current active (incomplete) path
  static Future<LearningPath?> getCurrentActivePath(String userId) async {
    try {
      // Get all user progress and filter locally (avoids composite index)
      final snapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      // Find incomplete paths (completedAt is null), sort by lastActivityAt
      final progressList = snapshot.docs
          .map((doc) => UserLearningPathProgress.fromFirestore(doc))
          .where((p) => p.completedAt == null)
          .toList();
      
      if (progressList.isEmpty) return null;
      
      // Sort by most recent activity
      progressList.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
      
      final mostRecent = progressList.first;
      return await getPath(mostRecent.pathId);
    } catch (e) {
      debugPrint('Error getting current active path: $e');
      return null;
    }
  }

  /// Start a new learning path for user
  static Future<UserLearningPathProgress?> startPath(String userId, String pathId) async {
    try {
      // Check if already started
      final existing = await getUserPathProgress(userId, pathId);
      if (existing != null) {
        return existing;
      }

      final path = await getPath(pathId);
      if (path == null || path.steps.isEmpty) {
        return null;
      }

      final progress = UserLearningPathProgress(
        id: '',
        userId: userId,
        pathId: pathId,
        completedStepIds: [],
        currentStepId: path.steps.first.id,
        xpEarned: 0,
        startedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
      );

      final docRef = await _progressCollection.add(progress.toMap());
      
      return UserLearningPathProgress(
        id: docRef.id,
        userId: progress.userId,
        pathId: progress.pathId,
        completedStepIds: progress.completedStepIds,
        currentStepId: progress.currentStepId,
        xpEarned: progress.xpEarned,
        startedAt: progress.startedAt,
        lastActivityAt: progress.lastActivityAt,
      );
    } catch (e) {
      debugPrint('Error starting path: $e');
      return null;
    }
  }

  /// Complete a step in a learning path
  static Future<bool> completeStep(String userId, String pathId, String stepId) async {
    try {
      final snapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('pathId', isEqualTo: pathId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return false;

      final progressDoc = snapshot.docs.first;
      final progress = UserLearningPathProgress.fromFirestore(progressDoc);
      
      // Already completed this step
      if (progress.completedStepIds.contains(stepId)) return true;

      final path = await getPath(pathId);
      if (path == null) return false;

      // Find the step and its XP reward
      final step = path.steps.firstWhere((s) => s.id == stepId, orElse: () => path.steps.first);
      final stepIndex = path.steps.indexWhere((s) => s.id == stepId);
      
      // Determine next step
      String? nextStepId;
      if (stepIndex < path.steps.length - 1) {
        nextStepId = path.steps[stepIndex + 1].id;
      }

      final updatedCompletedSteps = [...progress.completedStepIds, stepId];
      final isPathComplete = updatedCompletedSteps.length >= path.steps.length;

      await progressDoc.reference.update({
        'completedStepIds': updatedCompletedSteps,
        'currentStepId': nextStepId,
        'xpEarned': FieldValue.increment(step.xpReward),
        'lastActivityAt': Timestamp.now(),
        if (isPathComplete) 'completedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      debugPrint('Error completing step: $e');
      return false;
    }
  }

  /// Reset progress for a learning path
  static Future<bool> resetPathProgress(String userId, String pathId) async {
    try {
      final snapshot = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('pathId', isEqualTo: pathId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return false;

      final path = await getPath(pathId);
      
      await snapshot.docs.first.reference.update({
        'completedStepIds': [],
        'currentStepId': path?.steps.first.id,
        'xpEarned': 0,
        'completedAt': null,
        'lastActivityAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      debugPrint('Error resetting path progress: $e');
      return false;
    }
  }

  /// Get the next incomplete step for user in a path
  static Future<LearningPathStep?> getNextStep(String userId, String pathId) async {
    try {
      final progress = await getUserPathProgress(userId, pathId);
      if (progress == null) return null;

      final path = await getPath(pathId);
      if (path == null) return null;

      // Return current step if set
      if (progress.currentStepId != null) {
        return path.steps.firstWhere(
          (s) => s.id == progress.currentStepId,
          orElse: () => path.steps.first,
        );
      }

      // Find first incomplete step
      for (final step in path.steps) {
        if (!progress.completedStepIds.contains(step.id)) {
          return step;
        }
      }

      return null; // All steps completed
    } catch (e) {
      debugPrint('Error getting next step: $e');
      return null;
    }
  }

  // ==================== ADMIN: CREATE PATHS ====================

  /// Create a new learning path
  static Future<String?> createPath(LearningPath path) async {
    try {
      final docRef = await _pathsCollection.add(path.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating path: $e');
      return null;
    }
  }

  /// Update a learning path
  static Future<bool> updatePath(String pathId, Map<String, dynamic> updates) async {
    try {
      await _pathsCollection.doc(pathId).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating path: $e');
      return false;
    }
  }

  /// Delete a learning path
  static Future<bool> deletePath(String pathId) async {
    try {
      await _pathsCollection.doc(pathId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting path: $e');
      return false;
    }
  }
}