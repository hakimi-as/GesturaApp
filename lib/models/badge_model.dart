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

  // ==================== DEFAULT BADGES (10+ per category = 68 total) ====================
  
  static List<BadgeTemplate> get defaultBadges => [
    // ==================== LEARNING (12 badges) ====================
    BadgeTemplate(id: 'first_sign', name: 'First Sign', description: 'Learn your first sign', icon: '👋', tier: BadgeTier.bronze, category: BadgeCategory.learning, requirement: 1, trackingField: 'signsLearned', xpReward: 10, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_beginner', name: 'Sign Beginner', description: 'Learn 10 signs', icon: '🤟', tier: BadgeTier.bronze, category: BadgeCategory.learning, requirement: 10, trackingField: 'signsLearned', xpReward: 25, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_explorer', name: 'Sign Explorer', description: 'Learn 15 signs', icon: '🔍', tier: BadgeTier.bronze, category: BadgeCategory.learning, requirement: 15, trackingField: 'signsLearned', xpReward: 30, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_learner', name: 'Sign Learner', description: 'Learn 25 signs', icon: '✋', tier: BadgeTier.silver, category: BadgeCategory.learning, requirement: 25, trackingField: 'signsLearned', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_student', name: 'Sign Student', description: 'Learn 35 signs', icon: '📖', tier: BadgeTier.silver, category: BadgeCategory.learning, requirement: 35, trackingField: 'signsLearned', xpReward: 60, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_expert', name: 'Sign Expert', description: 'Learn 50 signs', icon: '🖐️', tier: BadgeTier.gold, category: BadgeCategory.learning, requirement: 50, trackingField: 'signsLearned', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_scholar', name: 'Sign Scholar', description: 'Learn 75 signs', icon: '🎓', tier: BadgeTier.gold, category: BadgeCategory.learning, requirement: 75, trackingField: 'signsLearned', xpReward: 150, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_master', name: 'Sign Master', description: 'Learn 100 signs', icon: '🙌', tier: BadgeTier.platinum, category: BadgeCategory.learning, requirement: 100, trackingField: 'signsLearned', xpReward: 250, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_professor', name: 'Sign Professor', description: 'Learn 150 signs', icon: '👨‍🏫', tier: BadgeTier.platinum, category: BadgeCategory.learning, requirement: 150, trackingField: 'signsLearned', xpReward: 350, createdAt: DateTime.now()),
    BadgeTemplate(id: 'sign_legend', name: 'Sign Legend', description: 'Learn 200 signs', icon: '🏅', tier: BadgeTier.platinum, category: BadgeCategory.learning, requirement: 200, trackingField: 'signsLearned', xpReward: 500, createdAt: DateTime.now()),
    BadgeTemplate(id: 'lesson_starter', name: 'Lesson Starter', description: 'Complete your first lesson', icon: '📝', tier: BadgeTier.bronze, category: BadgeCategory.learning, requirement: 1, trackingField: 'lessonsCompleted', xpReward: 10, createdAt: DateTime.now()),
    BadgeTemplate(id: 'lesson_lover', name: 'Lesson Lover', description: 'Complete 20 lessons', icon: '📚', tier: BadgeTier.silver, category: BadgeCategory.learning, requirement: 20, trackingField: 'lessonsCompleted', xpReward: 75, createdAt: DateTime.now()),
    
    // ==================== STREAK (12 badges) ====================
    BadgeTemplate(id: 'streak_starter', name: 'Streak Starter', description: 'Maintain a 3-day streak', icon: '🔥', tier: BadgeTier.bronze, category: BadgeCategory.streak, requirement: 3, trackingField: 'currentStreak', xpReward: 15, createdAt: DateTime.now()),
    BadgeTemplate(id: 'streak_keeper', name: 'Streak Keeper', description: 'Maintain a 5-day streak', icon: '🌟', tier: BadgeTier.bronze, category: BadgeCategory.streak, requirement: 5, trackingField: 'currentStreak', xpReward: 25, createdAt: DateTime.now()),
    BadgeTemplate(id: 'week_warrior', name: 'Week Warrior', description: 'Maintain a 7-day streak', icon: '⚡', tier: BadgeTier.silver, category: BadgeCategory.streak, requirement: 7, trackingField: 'currentStreak', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'ten_day_titan', name: 'Ten Day Titan', description: 'Maintain a 10-day streak', icon: '💪', tier: BadgeTier.silver, category: BadgeCategory.streak, requirement: 10, trackingField: 'currentStreak', xpReward: 75, createdAt: DateTime.now()),
    BadgeTemplate(id: 'fortnight_fighter', name: 'Fortnight Fighter', description: 'Maintain a 14-day streak', icon: '🛡️', tier: BadgeTier.gold, category: BadgeCategory.streak, requirement: 14, trackingField: 'currentStreak', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'three_week_wonder', name: 'Three Week Wonder', description: 'Maintain a 21-day streak', icon: '✨', tier: BadgeTier.gold, category: BadgeCategory.streak, requirement: 21, trackingField: 'currentStreak', xpReward: 150, createdAt: DateTime.now()),
    BadgeTemplate(id: 'monthly_master', name: 'Monthly Master', description: 'Maintain a 30-day streak', icon: '👑', tier: BadgeTier.platinum, category: BadgeCategory.streak, requirement: 30, trackingField: 'currentStreak', xpReward: 300, createdAt: DateTime.now()),
    BadgeTemplate(id: 'streak_champion', name: 'Streak Champion', description: 'Maintain a 45-day streak', icon: '🏆', tier: BadgeTier.platinum, category: BadgeCategory.streak, requirement: 45, trackingField: 'currentStreak', xpReward: 400, createdAt: DateTime.now()),
    BadgeTemplate(id: 'streak_legend', name: 'Streak Legend', description: 'Maintain a 60-day streak', icon: '🌈', tier: BadgeTier.platinum, category: BadgeCategory.streak, requirement: 60, trackingField: 'currentStreak', xpReward: 500, createdAt: DateTime.now()),
    BadgeTemplate(id: 'streak_immortal', name: 'Streak Immortal', description: 'Maintain a 90-day streak', icon: '💎', tier: BadgeTier.platinum, category: BadgeCategory.streak, requirement: 90, trackingField: 'currentStreak', xpReward: 750, createdAt: DateTime.now()),
    BadgeTemplate(id: 'longest_streak_10', name: 'Dedicated Learner', description: 'Achieve a longest streak of 10 days', icon: '📅', tier: BadgeTier.silver, category: BadgeCategory.streak, requirement: 10, trackingField: 'longestStreak', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'longest_streak_30', name: 'Consistency King', description: 'Achieve a longest streak of 30 days', icon: '🗓️', tier: BadgeTier.gold, category: BadgeCategory.streak, requirement: 30, trackingField: 'longestStreak', xpReward: 150, createdAt: DateTime.now()),
    
    // ==================== QUIZ (12 badges) ====================
    BadgeTemplate(id: 'first_quiz', name: 'Quiz Taker', description: 'Complete your first quiz', icon: '📝', tier: BadgeTier.bronze, category: BadgeCategory.quiz, requirement: 1, trackingField: 'quizzesCompleted', xpReward: 10, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_starter', name: 'Quiz Starter', description: 'Complete 5 quizzes', icon: '✅', tier: BadgeTier.bronze, category: BadgeCategory.quiz, requirement: 5, trackingField: 'quizzesCompleted', xpReward: 25, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_enthusiast', name: 'Quiz Enthusiast', description: 'Complete 10 quizzes', icon: '🎯', tier: BadgeTier.silver, category: BadgeCategory.quiz, requirement: 10, trackingField: 'quizzesCompleted', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_regular', name: 'Quiz Regular', description: 'Complete 20 quizzes', icon: '📋', tier: BadgeTier.silver, category: BadgeCategory.quiz, requirement: 20, trackingField: 'quizzesCompleted', xpReward: 75, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_expert', name: 'Quiz Expert', description: 'Complete 35 quizzes', icon: '🧠', tier: BadgeTier.gold, category: BadgeCategory.quiz, requirement: 35, trackingField: 'quizzesCompleted', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_master', name: 'Quiz Master', description: 'Complete 50 quizzes', icon: '🏅', tier: BadgeTier.platinum, category: BadgeCategory.quiz, requirement: 50, trackingField: 'quizzesCompleted', xpReward: 200, createdAt: DateTime.now()),
    BadgeTemplate(id: 'perfect_score', name: 'Perfect Score', description: 'Get 100% on a quiz', icon: '💯', tier: BadgeTier.silver, category: BadgeCategory.quiz, requirement: 1, trackingField: 'perfectQuizzes', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'perfect_three', name: 'Triple Perfect', description: 'Get 100% on 3 quizzes', icon: '🌟', tier: BadgeTier.gold, category: BadgeCategory.quiz, requirement: 3, trackingField: 'perfectQuizzes', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'perfect_five', name: 'Perfectionist', description: 'Get 100% on 5 quizzes', icon: '⭐', tier: BadgeTier.gold, category: BadgeCategory.quiz, requirement: 5, trackingField: 'perfectQuizzes', xpReward: 150, createdAt: DateTime.now()),
    BadgeTemplate(id: 'perfect_ten', name: 'Flawless Ten', description: 'Get 100% on 10 quizzes', icon: '💎', tier: BadgeTier.platinum, category: BadgeCategory.quiz, requirement: 10, trackingField: 'perfectQuizzes', xpReward: 300, createdAt: DateTime.now()),
    BadgeTemplate(id: 'quiz_legend', name: 'Quiz Legend', description: 'Complete 100 quizzes', icon: '🎖️', tier: BadgeTier.platinum, category: BadgeCategory.quiz, requirement: 100, trackingField: 'quizzesCompleted', xpReward: 500, createdAt: DateTime.now()),
    BadgeTemplate(id: 'accuracy_ace', name: 'Accuracy Ace', description: 'Get 100% on 20 quizzes', icon: '🎯', tier: BadgeTier.platinum, category: BadgeCategory.quiz, requirement: 20, trackingField: 'perfectQuizzes', xpReward: 500, createdAt: DateTime.now()),
    
    // ==================== SOCIAL (10 badges) ====================
    BadgeTemplate(id: 'first_friend', name: 'First Friend', description: 'Add your first friend', icon: '🤝', tier: BadgeTier.bronze, category: BadgeCategory.social, requirement: 1, trackingField: 'friendsCount', xpReward: 20, createdAt: DateTime.now()),
    BadgeTemplate(id: 'social_butterfly', name: 'Social Butterfly', description: 'Add 5 friends', icon: '🦋', tier: BadgeTier.bronze, category: BadgeCategory.social, requirement: 5, trackingField: 'friendsCount', xpReward: 40, createdAt: DateTime.now()),
    BadgeTemplate(id: 'friend_collector', name: 'Friend Collector', description: 'Add 8 friends', icon: '🎀', tier: BadgeTier.bronze, category: BadgeCategory.social, requirement: 8, trackingField: 'friendsCount', xpReward: 55, createdAt: DateTime.now()),
    BadgeTemplate(id: 'popular', name: 'Popular', description: 'Add 10 friends', icon: '🌟', tier: BadgeTier.silver, category: BadgeCategory.social, requirement: 10, trackingField: 'friendsCount', xpReward: 75, createdAt: DateTime.now()),
    BadgeTemplate(id: 'socialite', name: 'Socialite', description: 'Add 15 friends', icon: '🎭', tier: BadgeTier.silver, category: BadgeCategory.social, requirement: 15, trackingField: 'friendsCount', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'influencer', name: 'Influencer', description: 'Add 25 friends', icon: '👥', tier: BadgeTier.gold, category: BadgeCategory.social, requirement: 25, trackingField: 'friendsCount', xpReward: 150, createdAt: DateTime.now()),
    BadgeTemplate(id: 'community_builder', name: 'Community Builder', description: 'Add 35 friends', icon: '🏠', tier: BadgeTier.gold, category: BadgeCategory.social, requirement: 35, trackingField: 'friendsCount', xpReward: 200, createdAt: DateTime.now()),
    BadgeTemplate(id: 'social_star', name: 'Social Star', description: 'Add 50 friends', icon: '⭐', tier: BadgeTier.platinum, category: BadgeCategory.social, requirement: 50, trackingField: 'friendsCount', xpReward: 300, createdAt: DateTime.now()),
    BadgeTemplate(id: 'network_king', name: 'Network King', description: 'Add 75 friends', icon: '👑', tier: BadgeTier.platinum, category: BadgeCategory.social, requirement: 75, trackingField: 'friendsCount', xpReward: 400, createdAt: DateTime.now()),
    BadgeTemplate(id: 'social_legend', name: 'Social Legend', description: 'Add 100 friends', icon: '🌈', tier: BadgeTier.platinum, category: BadgeCategory.social, requirement: 100, trackingField: 'friendsCount', xpReward: 500, createdAt: DateTime.now()),
    
    // ==================== MILESTONE (12 badges) ====================
    BadgeTemplate(id: 'xp_starter', name: 'XP Starter', description: 'Earn 50 XP', icon: '✨', tier: BadgeTier.bronze, category: BadgeCategory.milestone, requirement: 50, trackingField: 'totalXP', xpReward: 10, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_collector', name: 'XP Collector', description: 'Earn 100 XP', icon: '⭐', tier: BadgeTier.bronze, category: BadgeCategory.milestone, requirement: 100, trackingField: 'totalXP', xpReward: 20, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_gatherer', name: 'XP Gatherer', description: 'Earn 250 XP', icon: '🌟', tier: BadgeTier.bronze, category: BadgeCategory.milestone, requirement: 250, trackingField: 'totalXP', xpReward: 35, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_hunter', name: 'XP Hunter', description: 'Earn 500 XP', icon: '💫', tier: BadgeTier.silver, category: BadgeCategory.milestone, requirement: 500, trackingField: 'totalXP', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_seeker', name: 'XP Seeker', description: 'Earn 750 XP', icon: '🔮', tier: BadgeTier.silver, category: BadgeCategory.milestone, requirement: 750, trackingField: 'totalXP', xpReward: 75, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_champion', name: 'XP Champion', description: 'Earn 1,000 XP', icon: '🏆', tier: BadgeTier.gold, category: BadgeCategory.milestone, requirement: 1000, trackingField: 'totalXP', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_master', name: 'XP Master', description: 'Earn 2,500 XP', icon: '👑', tier: BadgeTier.gold, category: BadgeCategory.milestone, requirement: 2500, trackingField: 'totalXP', xpReward: 200, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_legend', name: 'XP Legend', description: 'Earn 5,000 XP', icon: '💎', tier: BadgeTier.platinum, category: BadgeCategory.milestone, requirement: 5000, trackingField: 'totalXP', xpReward: 500, createdAt: DateTime.now()),
    BadgeTemplate(id: 'xp_mythic', name: 'XP Mythic', description: 'Earn 10,000 XP', icon: '🌈', tier: BadgeTier.platinum, category: BadgeCategory.milestone, requirement: 10000, trackingField: 'totalXP', xpReward: 1000, createdAt: DateTime.now()),
    BadgeTemplate(id: 'level_5', name: 'Level 5', description: 'Reach level 5', icon: '5️⃣', tier: BadgeTier.bronze, category: BadgeCategory.milestone, requirement: 5, trackingField: 'level', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'level_10', name: 'Level 10', description: 'Reach level 10', icon: '🔟', tier: BadgeTier.silver, category: BadgeCategory.milestone, requirement: 10, trackingField: 'level', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'level_25', name: 'Level 25', description: 'Reach level 25', icon: '🎯', tier: BadgeTier.gold, category: BadgeCategory.milestone, requirement: 25, trackingField: 'level', xpReward: 250, createdAt: DateTime.now()),
    
    // ==================== SPECIAL (10 badges) ====================
    BadgeTemplate(id: 'category_complete', name: 'Category Champion', description: 'Complete all lessons in a category', icon: '🏆', tier: BadgeTier.gold, category: BadgeCategory.special, requirement: 1, trackingField: 'categoriesCompleted', xpReward: 100, createdAt: DateTime.now()),
    BadgeTemplate(id: 'multi_category', name: 'Multi-Talented', description: 'Complete 3 categories', icon: '🎨', tier: BadgeTier.platinum, category: BadgeCategory.special, requirement: 3, trackingField: 'categoriesCompleted', xpReward: 300, createdAt: DateTime.now()),
    BadgeTemplate(id: 'speed_learner', name: 'Speed Learner', description: 'Complete 5 lessons in one day', icon: '🚀', tier: BadgeTier.gold, category: BadgeCategory.special, requirement: 5, trackingField: 'lessonsToday', xpReward: 150, isSecret: true, createdAt: DateTime.now()),
    BadgeTemplate(id: 'early_bird', name: 'Early Bird', description: 'Complete a lesson before 8 AM', icon: '🌅', tier: BadgeTier.silver, category: BadgeCategory.special, requirement: 1, trackingField: 'earlyBirdLessons', xpReward: 50, isSecret: true, createdAt: DateTime.now()),
    BadgeTemplate(id: 'night_owl', name: 'Night Owl', description: 'Complete a lesson after 10 PM', icon: '🦉', tier: BadgeTier.silver, category: BadgeCategory.special, requirement: 1, trackingField: 'nightOwlLessons', xpReward: 50, isSecret: true, createdAt: DateTime.now()),
    BadgeTemplate(id: 'weekend_warrior', name: 'Weekend Warrior', description: 'Complete lessons on both Saturday and Sunday', icon: '🎉', tier: BadgeTier.silver, category: BadgeCategory.special, requirement: 1, trackingField: 'weekendWarrior', xpReward: 75, createdAt: DateTime.now()),
    BadgeTemplate(id: 'comeback_kid', name: 'Comeback Kid', description: 'Return after 7+ days away', icon: '🔄', tier: BadgeTier.silver, category: BadgeCategory.special, requirement: 1, trackingField: 'comebacks', xpReward: 50, createdAt: DateTime.now()),
    BadgeTemplate(id: 'daily_devotee', name: 'Daily Devotee', description: 'Complete all daily challenges 5 times', icon: '📅', tier: BadgeTier.gold, category: BadgeCategory.special, requirement: 5, trackingField: 'perfectDailyDays', xpReward: 200, createdAt: DateTime.now()),
    BadgeTemplate(id: 'challenge_crusher', name: 'Challenge Crusher', description: 'Complete 50 challenges total', icon: '💪', tier: BadgeTier.platinum, category: BadgeCategory.special, requirement: 50, trackingField: 'challengesCompleted', xpReward: 400, createdAt: DateTime.now()),
    BadgeTemplate(id: 'signing_superstar', name: 'Signing Superstar', description: 'Master all available content', icon: '🌟', tier: BadgeTier.platinum, category: BadgeCategory.special, requirement: 1, trackingField: 'allContentCompleted', xpReward: 1000, isSecret: true, createdAt: DateTime.now()),
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
    {'value': 'level', 'label': 'User Level'},
    {'value': 'currentStreak', 'label': 'Current Streak'},
    {'value': 'longestStreak', 'label': 'Longest Streak'},
    {'value': 'categoriesCompleted', 'label': 'Categories Completed'},
    {'value': 'categoryCompleted', 'label': 'Specific Category Completed'},
    {'value': 'lessonsToday', 'label': 'Lessons Today'},
    {'value': 'friendsCount', 'label': 'Friends Count'},
    {'value': 'leaderboardAppearances', 'label': 'Leaderboard Appearances'},
    {'value': 'challengesCompleted', 'label': 'Challenges Completed'},
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