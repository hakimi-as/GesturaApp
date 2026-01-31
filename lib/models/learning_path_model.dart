import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a guided learning path
class LearningPath {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? iconEmoji;
  final String difficulty; // beginner, intermediate, advanced
  final int estimatedDays;
  final int totalLessons;
  final int totalXP;
  final List<LearningPathStep> steps;
  final bool isActive;
  final int order;
  final DateTime createdAt;

  LearningPath({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.iconEmoji,
    required this.difficulty,
    required this.estimatedDays,
    required this.totalLessons,
    required this.totalXP,
    required this.steps,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
  });

  factory LearningPath.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final stepsData = data['steps'] as List<dynamic>? ?? [];
    final steps = stepsData.map((s) => LearningPathStep.fromMap(s)).toList();
    
    return LearningPath(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      iconEmoji: data['iconEmoji'],
      difficulty: data['difficulty'] ?? 'beginner',
      estimatedDays: data['estimatedDays'] ?? 7,
      totalLessons: data['totalLessons'] ?? steps.length,
      totalXP: data['totalXP'] ?? 0,
      steps: steps,
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconEmoji': iconEmoji,
      'difficulty': difficulty,
      'estimatedDays': estimatedDays,
      'totalLessons': totalLessons,
      'totalXP': totalXP,
      'steps': steps.map((s) => s.toMap()).toList(),
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get difficulty color
  int get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 0xFF10B981; // Green
      case 'intermediate':
        return 0xFFF59E0B; // Orange
      case 'advanced':
        return 0xFFEF4444; // Red
      default:
        return 0xFF6366F1; // Primary
    }
  }

  /// Get difficulty label
  String get difficultyLabel {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'All Levels';
    }
  }
}

/// Represents a step/stage in a learning path
class LearningPathStep {
  final String id;
  final String title;
  final String? description;
  final String type; // lesson, quiz, challenge, category
  final String? targetId; // lessonId, quizId, challengeId, categoryId
  final String? categoryId;
  final int xpReward;
  final int order;
  final bool isRequired;
  final List<String>? prerequisiteStepIds;

  LearningPathStep({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.targetId,
    this.categoryId,
    required this.xpReward,
    required this.order,
    this.isRequired = true,
    this.prerequisiteStepIds,
  });

  factory LearningPathStep.fromMap(Map<String, dynamic> data) {
    return LearningPathStep(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      type: data['type'] ?? 'lesson',
      targetId: data['targetId'],
      categoryId: data['categoryId'],
      xpReward: data['xpReward'] ?? 10,
      order: data['order'] ?? 0,
      isRequired: data['isRequired'] ?? true,
      prerequisiteStepIds: (data['prerequisiteStepIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'targetId': targetId,
      'categoryId': categoryId,
      'xpReward': xpReward,
      'order': order,
      'isRequired': isRequired,
      'prerequisiteStepIds': prerequisiteStepIds,
    };
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case 'lesson':
        return '📚';
      case 'quiz':
        return '📝';
      case 'challenge':
        return '🎯';
      case 'category':
        return '📂';
      default:
        return '✨';
    }
  }
}

/// Tracks user progress in a learning path
class UserLearningPathProgress {
  final String id;
  final String userId;
  final String pathId;
  final List<String> completedStepIds;
  final String? currentStepId;
  final int xpEarned;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime lastActivityAt;

  UserLearningPathProgress({
    required this.id,
    required this.userId,
    required this.pathId,
    required this.completedStepIds,
    this.currentStepId,
    required this.xpEarned,
    required this.startedAt,
    this.completedAt,
    required this.lastActivityAt,
  });

  factory UserLearningPathProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserLearningPathProgress(
      id: doc.id,
      userId: data['userId'] ?? '',
      pathId: data['pathId'] ?? '',
      completedStepIds: (data['completedStepIds'] as List<dynamic>?)?.cast<String>() ?? [],
      currentStepId: data['currentStepId'],
      xpEarned: data['xpEarned'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pathId': pathId,
      'completedStepIds': completedStepIds,
      'currentStepId': currentStepId,
      'xpEarned': xpEarned,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
    };
  }

  bool get isCompleted => completedAt != null;

  double progressPercent(int totalSteps) {
    if (totalSteps == 0) return 0;
    return completedStepIds.length / totalSteps;
  }
}