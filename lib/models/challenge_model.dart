import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  daily,
  weekly,
  special,
}

enum ChallengeStatus {
  active,
  completed,
  expired,
}

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;
  final String trackingField;
  final String? categoryId; // Optional: specific category to track

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.xpReward,
    required this.startDate,
    required this.endDate,
    this.status = ChallengeStatus.active,
    this.trackingField = 'lessonsToday',
    this.categoryId,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  bool get isCompleted => currentValue >= targetValue;
  
  int get remainingTime {
    final now = DateTime.now();
    return endDate.difference(now).inHours;
  }

  String get remainingTimeText {
    final hours = remainingTime;
    if (hours <= 0) return 'Expired';
    if (hours < 24) return '${hours}h left';
    return '${(hours / 24).floor()}d left';
  }

  Color get typeColor {
    switch (type) {
      case ChallengeType.daily:
        return const Color(0xFF10B981);
      case ChallengeType.weekly:
        return const Color(0xFF6366F1);
      case ChallengeType.special:
        return const Color(0xFFF59E0B);
    }
  }

  String get typeLabel {
    switch (type) {
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.weekly:
        return 'Weekly';
      case ChallengeType.special:
        return 'Special';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.index,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'xpReward': xpReward,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.index,
      'trackingField': trackingField,
      'categoryId': categoryId,
    };
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '🎯',
      type: ChallengeType.values[map['type'] ?? 0],
      targetValue: map['targetValue'] ?? 1,
      currentValue: map['currentValue'] ?? 0,
      xpReward: map['xpReward'] ?? 10,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now(),
      status: ChallengeStatus.values[map['status'] ?? 0],
      trackingField: map['trackingField'] ?? 'lessonsToday',
      categoryId: map['categoryId'],
    );
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    ChallengeType? type,
    int? targetValue,
    int? currentValue,
    int? xpReward,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    String? trackingField,
    String? categoryId,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      xpReward: xpReward ?? this.xpReward,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      trackingField: trackingField ?? this.trackingField,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

/// Challenge template for the pool (stored in Firestore)
class ChallengeTemplate {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;
  final int targetValue;
  final int xpReward;
  final String trackingField;
  final String? categoryId; // Optional: specific category to track
  final String? categoryName; // Display name for the category
  final bool isActive;
  final DateTime createdAt;

  const ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.targetValue,
    required this.xpReward,
    required this.trackingField,
    this.categoryId,
    this.categoryName,
    this.isActive = true,
    required this.createdAt,
  });

  factory ChallengeTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeTemplate(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '🎯',
      type: ChallengeType.values[data['type'] ?? 0],
      targetValue: data['targetValue'] ?? 1,
      xpReward: data['xpReward'] ?? 10,
      trackingField: data['trackingField'] ?? 'lessonsToday',
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.index,
      'targetValue': targetValue,
      'xpReward': xpReward,
      'trackingField': trackingField,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ChallengeTemplate copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    ChallengeType? type,
    int? targetValue,
    int? xpReward,
    String? trackingField,
    String? categoryId,
    String? categoryName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ChallengeTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      xpReward: xpReward ?? this.xpReward,
      trackingField: trackingField ?? this.trackingField,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  ChallengeModel toChallenge() {
    final now = DateTime.now();
    DateTime endDate;
    
    switch (type) {
      case ChallengeType.daily:
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ChallengeType.weekly:
        final daysUntilSunday = 7 - now.weekday;
        endDate = DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);
        break;
      case ChallengeType.special:
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      type: type,
      targetValue: targetValue,
      xpReward: xpReward,
      startDate: now,
      endDate: endDate,
      trackingField: trackingField,
      categoryId: categoryId,
    );
  }

  // Default challenges (generic, no specific category)
  static List<ChallengeTemplate> get defaultDailyChallenges => [
    ChallengeTemplate(id: 'daily_lessons_3', title: 'Lesson Streak', description: 'Complete 3 lessons today', emoji: '📚', type: ChallengeType.daily, targetValue: 3, xpReward: 50, trackingField: 'lessonsToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_lessons_5', title: 'Learning Spree', description: 'Complete 5 lessons today', emoji: '📖', type: ChallengeType.daily, targetValue: 5, xpReward: 80, trackingField: 'lessonsToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_lessons_1', title: 'First Step', description: 'Complete at least 1 lesson', emoji: '👣', type: ChallengeType.daily, targetValue: 1, xpReward: 20, trackingField: 'lessonsToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_quiz_1', title: 'Quiz Champion', description: 'Complete 1 quiz today', emoji: '🎯', type: ChallengeType.daily, targetValue: 1, xpReward: 30, trackingField: 'quizzesToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_quiz_2', title: 'Double Quiz', description: 'Complete 2 quizzes today', emoji: '✌️', type: ChallengeType.daily, targetValue: 2, xpReward: 50, trackingField: 'quizzesToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_xp_50', title: 'XP Starter', description: 'Earn 50 XP today', emoji: '⭐', type: ChallengeType.daily, targetValue: 50, xpReward: 25, trackingField: 'xpToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_xp_100', title: 'XP Hunter', description: 'Earn 100 XP today', emoji: '🌟', type: ChallengeType.daily, targetValue: 100, xpReward: 40, trackingField: 'xpToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_signs_5', title: 'Sign Explorer', description: 'Learn 5 new signs today', emoji: '🤟', type: ChallengeType.daily, targetValue: 5, xpReward: 40, trackingField: 'signsToday', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'daily_perfect_1', title: 'Perfect Score', description: 'Get 100% on any quiz', emoji: '💯', type: ChallengeType.daily, targetValue: 1, xpReward: 60, trackingField: 'perfectQuizzesToday', createdAt: DateTime.now()),
  ];

  static List<ChallengeTemplate> get defaultWeeklyChallenges => [
    ChallengeTemplate(id: 'weekly_lessons_10', title: 'Weekly Learner', description: 'Complete 10 lessons this week', emoji: '📚', type: ChallengeType.weekly, targetValue: 10, xpReward: 150, trackingField: 'lessonsThisWeek', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_lessons_15', title: 'Learning Machine', description: 'Complete 15 lessons this week', emoji: '🚀', type: ChallengeType.weekly, targetValue: 15, xpReward: 200, trackingField: 'lessonsThisWeek', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_streak_3', title: 'Getting Started', description: 'Maintain a 3-day streak', emoji: '🔥', type: ChallengeType.weekly, targetValue: 3, xpReward: 100, trackingField: 'currentStreak', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_streak_5', title: 'On Fire', description: 'Maintain a 5-day streak', emoji: '🔥', type: ChallengeType.weekly, targetValue: 5, xpReward: 200, trackingField: 'currentStreak', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_streak_7', title: 'Perfect Week', description: 'Maintain a 7-day streak', emoji: '🔥', type: ChallengeType.weekly, targetValue: 7, xpReward: 300, trackingField: 'currentStreak', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_quiz_5', title: 'Quiz Master', description: 'Complete 5 quizzes this week', emoji: '🏆', type: ChallengeType.weekly, targetValue: 5, xpReward: 150, trackingField: 'quizzesThisWeek', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_signs_15', title: 'Sign Apprentice', description: 'Learn 15 signs this week', emoji: '🤟', type: ChallengeType.weekly, targetValue: 15, xpReward: 150, trackingField: 'signsThisWeek', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'weekly_xp_300', title: 'XP Gatherer', description: 'Earn 300 XP this week', emoji: '⭐', type: ChallengeType.weekly, targetValue: 300, xpReward: 100, trackingField: 'xpThisWeek', createdAt: DateTime.now()),
  ];

  static List<ChallengeTemplate> get defaultSpecialChallenges => [
    ChallengeTemplate(id: 'special_master_category', title: 'Category Master', description: 'Complete all lessons in any category', emoji: '👑', type: ChallengeType.special, targetValue: 1, xpReward: 500, trackingField: 'categoriesCompleted', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'special_perfect_3', title: 'Perfectionist', description: 'Get 100% on 3 quizzes', emoji: '💯', type: ChallengeType.special, targetValue: 3, xpReward: 400, trackingField: 'perfectQuizzes', createdAt: DateTime.now()),
    ChallengeTemplate(id: 'special_streak_14', title: 'Two Week Warrior', description: 'Maintain a 14-day streak', emoji: '🏅', type: ChallengeType.special, targetValue: 14, xpReward: 600, trackingField: 'currentStreak', createdAt: DateTime.now()),
  ];

  // Tracking field options for admin dropdown
  static List<Map<String, String>> get trackingFieldOptions => [
    // Daily fields
    {'value': 'lessonsToday', 'label': 'Lessons Today (Any Category)'},
    {'value': 'lessonsInCategoryToday', 'label': 'Lessons Today (Specific Category)'},
    {'value': 'quizzesToday', 'label': 'Quizzes Today'},
    {'value': 'xpToday', 'label': 'XP Today'},
    {'value': 'signsToday', 'label': 'Signs Today (Any Category)'},
    {'value': 'signsInCategoryToday', 'label': 'Signs Today (Specific Category)'},
    {'value': 'perfectQuizzesToday', 'label': 'Perfect Quizzes Today'},
    // Weekly fields
    {'value': 'lessonsThisWeek', 'label': 'Lessons This Week (Any Category)'},
    {'value': 'lessonsInCategoryThisWeek', 'label': 'Lessons This Week (Specific Category)'},
    {'value': 'quizzesThisWeek', 'label': 'Quizzes This Week'},
    {'value': 'xpThisWeek', 'label': 'XP This Week'},
    {'value': 'signsThisWeek', 'label': 'Signs This Week (Any Category)'},
    {'value': 'signsInCategoryThisWeek', 'label': 'Signs This Week (Specific Category)'},
    // Cumulative fields
    {'value': 'currentStreak', 'label': 'Current Streak'},
    {'value': 'totalSigns', 'label': 'Total Signs Learned'},
    {'value': 'signsInCategory', 'label': 'Signs in Specific Category (Total)'},
    {'value': 'totalXP', 'label': 'Total XP'},
    {'value': 'totalQuizzes', 'label': 'Total Quizzes'},
    {'value': 'perfectQuizzes', 'label': 'Perfect Quizzes (Total)'},
    {'value': 'categoriesCompleted', 'label': 'Categories Completed'},
    {'value': 'categoryCompleted', 'label': 'Specific Category Completed'},
  ];

  // Check if tracking field requires a category selection
  static bool requiresCategory(String trackingField) {
    return trackingField.contains('InCategory') || trackingField == 'categoryCompleted';
  }
}