import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeTier {
  bronze,
  silver,
  gold,
  platinum,
}

enum BadgeCategory {
  learning,
  streak,
  quiz,
  social,
  milestone,
  special,
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeTier tier;
  final BadgeCategory category;
  final int requirement;
  final String trackingField;
  final String? lessonCategoryId; // Optional: specific lesson category to track
  final String? lessonCategoryName; // Display name for the category
  final int xpReward;
  final bool isSecret;
  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.category,
    required this.requirement,
    this.trackingField = 'signsLearned',
    this.lessonCategoryId,
    this.lessonCategoryName,
    required this.xpReward,
    this.isSecret = false,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Color get tierColor {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  Color get tierGradientStart {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFE8E8E8);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFF00D9FF);
    }
  }

  Color get tierGradientEnd {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFF8B4513);
      case BadgeTier.silver:
        return const Color(0xFF808080);
      case BadgeTier.gold:
        return const Color(0xFFFF8C00);
      case BadgeTier.platinum:
        return const Color(0xFF9D00FF);
    }
  }

  String get tierName {
    switch (tier) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.platinum:
        return 'Platinum';
    }
  }

  String get categoryName {
    switch (category) {
      case BadgeCategory.learning:
        return 'Learning';
      case BadgeCategory.streak:
        return 'Streak';
      case BadgeCategory.quiz:
        return 'Quiz';
      case BadgeCategory.social:
        return 'Social';
      case BadgeCategory.milestone:
        return 'Milestone';
      case BadgeCategory.special:
        return 'Special';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'tier': tier.index,
      'category': category.index,
      'requirement': requirement,
      'trackingField': trackingField,
      'lessonCategoryId': lessonCategoryId,
      'lessonCategoryName': lessonCategoryName,
      'xpReward': xpReward,
      'isSecret': isSecret,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      tier: BadgeTier.values[map['tier'] ?? 0],
      category: BadgeCategory.values[map['category'] ?? 0],
      requirement: map['requirement'] ?? 0,
      trackingField: map['trackingField'] ?? 'signsLearned',
      lessonCategoryId: map['lessonCategoryId'],
      lessonCategoryName: map['lessonCategoryName'],
      xpReward: map['xpReward'] ?? 0,
      isSecret: map['isSecret'] ?? false,
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
    );
  }

  BadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    BadgeTier? tier,
    BadgeCategory? category,
    int? requirement,
    String? trackingField,
    String? lessonCategoryId,
    String? lessonCategoryName,
    int? xpReward,
    bool? isSecret,
    DateTime? unlockedAt,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      tier: tier ?? this.tier,
      category: category ?? this.category,
      requirement: requirement ?? this.requirement,
      trackingField: trackingField ?? this.trackingField,
      lessonCategoryId: lessonCategoryId ?? this.lessonCategoryId,
      lessonCategoryName: lessonCategoryName ?? this.lessonCategoryName,
      xpReward: xpReward ?? this.xpReward,
      isSecret: isSecret ?? this.isSecret,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  // Legacy support
  static List<BadgeModel> get allBadges {
    return BadgeTemplate.defaultBadges.map((t) => t.toBadge()).toList();
  }

  static BadgeModel? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<BadgeModel> getBadgesByCategory(BadgeCategory category) {
    return allBadges.where((badge) => badge.category == category).toList();
  }

  static List<BadgeModel> getBadgesByTier(BadgeTier tier) {
    return allBadges.where((badge) => badge.tier == tier).toList();
  }
}

/// Badge template for the pool (stored in Firestore)
class BadgeTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeTier tier;
  final BadgeCategory category;
  final int requirement;
  final String trackingField;
  final String? lessonCategoryId; // Optional: specific lesson category
  final String? lessonCategoryName; // Display name
  final int xpReward;
  final bool isSecret;
  final bool isActive;
  final DateTime createdAt;

  const BadgeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.category,
    required this.requirement,
    required this.trackingField,
    this.lessonCategoryId,
    this.lessonCategoryName,
    required this.xpReward,
    this.isSecret = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory BadgeTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      tier: BadgeTier.values[data['tier'] ?? 0],
      category: BadgeCategory.values[data['category'] ?? 0],
      requirement: data['requirement'] ?? 1,
      trackingField: data['trackingField'] ?? 'signsLearned',
      lessonCategoryId: data['lessonCategoryId'],
      lessonCategoryName: data['lessonCategoryName'],
      xpReward: data['xpReward'] ?? 10,
      isSecret: data['isSecret'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'tier': tier.index,
      'category': category.index,
      'requirement': requirement,
      'trackingField': trackingField,
      'lessonCategoryId': lessonCategoryId,
      'lessonCategoryName': lessonCategoryName,
      'xpReward': xpReward,
      'isSecret': isSecret,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BadgeTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    BadgeTier? tier,
    BadgeCategory? category,
    int? requirement,
    String? trackingField,
    String? lessonCategoryId,
    String? lessonCategoryName,
    int? xpReward,
    bool? isSecret,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BadgeTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      tier: tier ?? this.tier,
      category: category ?? this.category,
      requirement: requirement ?? this.requirement,
      trackingField: trackingField ?? this.trackingField,
      lessonCategoryId: lessonCategoryId ?? this.lessonCategoryId,
      lessonCategoryName: lessonCategoryName ?? this.lessonCategoryName,
      xpReward: xpReward ?? this.xpReward,
      isSecret: isSecret ?? this.isSecret,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  BadgeModel toBadge({DateTime? unlockedAt}) {
    return BadgeModel(
      id: id,
      name: name,
      description: description,
      icon: icon,
      tier: tier,
      category: category,
      requirement: requirement,
      trackingField: trackingField,
      lessonCategoryId: lessonCategoryId,
      lessonCategoryName: lessonCategoryName,
      xpReward: xpReward,
      isSecret: isSecret,
      unlockedAt: unlockedAt,
    );
  }

  static List<BadgeTemplate> get defaultBadges => [
    // LEARNING (general)
    BadgeTemplate(id: 'first_sign', name: 'First Sign', description: 'Learn your first sign', icon: '👋', tier: BadgeTier.bronze, category: BadgeCategory.learning, requirement: 1, trackingField: 'signsLearned', xpReward: 10, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_beginner', name: 'Sign Beginner', description: 'Learn 10 signs', icon: '🤟', tier: BadgeTier.bronze, category: BadgeCategory.learning, requirement: 10, trackingField: 'signsLearned', xpReward: 25, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_learner', name: 'Sign Learner', description: 'Learn 25 signs', icon: '✋', tier: BadgeTier.silver, category: BadgeCategory.learning, requirement: 25, trackingField: 'signsLearned', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_expert', name: 'Sign Expert', description: 'Learn 50 signs', icon: '🖐️', tier: BadgeTier.gold, category: BadgeCategory.learning, requirement: 50, trackingField: 'signsLearned', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_master', name: 'Sign Master', description: 'Learn 100 signs', icon: '🙌', tier: BadgeTier.platinum, category: BadgeCategory.learning, requirement: 100, trackingField: 'signsLearned', xpReward: 250, createdAt: DateTime.now()),
    // STREAK
    BadgeTemplate(id: 'streak_starter', name: 'Streak Starter', description: 'Maintain a 3-day streak', icon: '🔥', tier: BadgeTier.bronze, category: BadgeCategory.streak, requirement: 3, trackingField: 'currentStreak', xpReward: 15, createdAt: DateTime.now()),
    BadgeTemplate(id: 'week_warrior', name: 'Week Warrior', description: 'Maintain a 7-day streak', icon: '⚡', tier: BadgeTier.silver, category: BadgeCategory.streak, requirement: 7, trackingField: 'currentStreak', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'fortnight_fighter', name: 'Fortnight Fighter', description: 'Maintain a 14-day streak', icon: '💪', tier: BadgeTier.gold, category: BadgeCategory.streak, requirement: 14, trackingField: 'currentStreak', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'monthly_master', name: 'Monthly Master', description: 'Maintain a 30-day streak', icon: '👑', tier: BadgeTier.platinum, category: BadgeCategory.streak, requirement: 30, trackingField: 'currentStreak', xpReward: 300, createdAt: DateTime.now()),
    // QUIZ
    BadgeTemplate(id: 'first_quiz', name: 'Quiz Taker', description: 'Complete your first quiz', icon: '📝', tier: BadgeTier.bronze, category: BadgeCategory.quiz, requirement: 1, trackingField: 'quizzesCompleted', xpReward: 10, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_enthusiast', name: 'Quiz Enthusiast', description: 'Complete 10 quizzes', icon: '🎯', tier: BadgeTier.silver, category: BadgeCategory.quiz, requirement: 10, trackingField: 'quizzesCompleted', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'perfect_score', name: 'Perfect Score', description: 'Get 100% on a quiz', icon: '💯', tier: BadgeTier.gold, category: BadgeCategory.quiz, requirement: 1, trackingField: 'perfectQuizzes', xpReward: 75, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_master', name: 'Quiz Master', description: 'Complete 50 quizzes', icon: '🏅', tier: BadgeTier.platinum, category: BadgeCategory.quiz, requirement: 50, trackingField: 'quizzesCompleted', xpReward: 200, createdAt: DateTime.now()),
    // MILESTONE
    BadgeTemplate(id: 'xp_collector', name: 'XP Collector', description: 'Earn 100 XP', icon: '⭐', tier: BadgeTier.bronze, category: BadgeCategory.milestone, requirement: 100, trackingField: 'totalXP', xpReward: 20, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_hunter', name: 'XP Hunter', description: 'Earn 500 XP', icon: '🌟', tier: BadgeTier.silver, category: BadgeCategory.milestone, requirement: 500, trackingField: 'totalXP', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_champion', name: 'XP Champion', description: 'Earn 1,000 XP', icon: '✨', tier: BadgeTier.gold, category: BadgeCategory.milestone, requirement: 1000, trackingField: 'totalXP', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_legend', name: 'XP Legend', description: 'Earn 5,000 XP', icon: '💫', tier: BadgeTier.platinum, category: BadgeCategory.milestone, requirement: 5000, trackingField: 'totalXP', xpReward: 500, createdAt: DateTime.now()),
    // SPECIAL
    BadgeTemplate(id: 'category_complete', name: 'Category Champion', description: 'Complete all lessons in a category', icon: '🏆', tier: BadgeTier.gold, category: BadgeCategory.special, requirement: 1, trackingField: 'categoriesCompleted', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'speed_learner', name: 'Speed Learner', description: 'Complete 5 lessons in one day', icon: '🚀', tier: BadgeTier.platinum, category: BadgeCategory.special, requirement: 5, trackingField: 'lessonsToday', xpReward: 150, isSecret: true, createdAt: DateTime.now()),
  ];

  // Tracking field options for admin dropdown
  static List<Map<String, String>> get trackingFieldOptions => [
    // General tracking
    {'value': 'signsLearned', 'label': 'Signs Learned (Total)'},
    {'value': 'signsInCategory', 'label': 'Signs in Specific Category'},
    {'value': 'lessonsCompleted', 'label': 'Lessons Completed (Total)'},
    {'value': 'lessonsInCategory', 'label': 'Lessons in Specific Category'},
    {'value': 'quizzesCompleted', 'label': 'Quizzes Completed (Total)'},
    {'value': 'perfectQuizzes', 'label': 'Perfect Quizzes (Total)'},
    {'value': 'totalXP', 'label': 'Total XP'},
    {'value': 'currentStreak', 'label': 'Current Streak'},
    {'value': 'longestStreak', 'label': 'Longest Streak'},
    {'value': 'categoriesCompleted', 'label': 'Categories Completed'},
    {'value': 'categoryCompleted', 'label': 'Specific Category Completed'},
    {'value': 'lessonsToday', 'label': 'Lessons Today'},
  ];

  // Check if tracking field requires a category selection
  static bool requiresCategory(String trackingField) {
    return trackingField.contains('InCategory') || trackingField == 'categoryCompleted';
  }
}

class UserBadge {
  final String badgeId;
  final DateTime unlockedAt;
  final bool hasBeenSeen;

  const UserBadge({
    required this.badgeId,
    required this.unlockedAt,
    this.hasBeenSeen = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'hasBeenSeen': hasBeenSeen,
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      badgeId: map['badgeId'] ?? '',
      unlockedAt: DateTime.parse(map['unlockedAt']),
      hasBeenSeen: map['hasBeenSeen'] ?? false,
    );
  }
}