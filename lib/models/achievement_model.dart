import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String tier;
  final String achievementType;
  final int requirementValue;
  final int xpReward;
  final bool isActive;
  final DateTime createdAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.achievementType,
    required this.requirementValue,
    required this.xpReward,
    this.isActive = true,
    required this.createdAt,
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      tier: data['tier'] ?? 'bronze',
      achievementType: data['achievementType'] ?? 'first_steps',
      requirementValue: data['requirementValue'] ?? 1,
      xpReward: data['xpReward'] ?? 10,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'tier': tier,
      'achievementType': achievementType,
      'requirementValue': requirementValue,
      'xpReward': xpReward,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get tierColor {
    switch (tier) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'platinum':
        return '#E5E4E2';
      default:
        return '#CD7F32';
    }
  }

  String get tierDisplayName {
    return '${tier[0].toUpperCase()}${tier.substring(1)}';
  }

  // Default achievements
  static List<AchievementModel> get defaultAchievements {
    final now = DateTime.now();
    return [
      AchievementModel(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Complete your first lesson',
        icon: '👶',
        tier: 'bronze',
        achievementType: 'first_steps',
        requirementValue: 1,
        xpReward: 10,
        createdAt: now,
      ),
      AchievementModel(
        id: 'alphabet_master',
        name: 'Alphabet Master',
        description: 'Complete all alphabet signs',
        icon: '🔤',
        tier: 'silver',
        achievementType: 'sign_master',
        requirementValue: 26,
        xpReward: 50,
        createdAt: now,
      ),
      AchievementModel(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: '7-day learning streak',
        icon: '🔥',
        tier: 'gold',
        achievementType: 'learning_streak',
        requirementValue: 7,
        xpReward: 100,
        createdAt: now,
      ),
      AchievementModel(
        id: 'quiz_champion',
        name: 'Quiz Champion',
        description: 'Score 100% on 5 quizzes',
        icon: '🏆',
        tier: 'gold',
        achievementType: 'quiz_master',
        requirementValue: 5,
        xpReward: 100,
        createdAt: now,
      ),
      AchievementModel(
        id: 'sign_language_pro',
        name: 'Sign Language Pro',
        description: 'Learn 100 signs',
        icon: '🤟',
        tier: 'platinum',
        achievementType: 'sign_master',
        requirementValue: 100,
        xpReward: 500,
        createdAt: now,
      ),
      AchievementModel(
        id: 'month_master',
        name: 'Month Master',
        description: '30-day learning streak',
        icon: '📅',
        tier: 'platinum',
        achievementType: 'learning_streak',
        requirementValue: 30,
        xpReward: 500,
        createdAt: now,
      ),
    ];
  }
}

class UserAchievementModel {
  final String id;
  final String oderId;
  final String achievementId;
  final DateTime earnedAt;
  final bool isDisplayed;

  UserAchievementModel({
    required this.id,
    required this.oderId,
    required this.achievementId,
    required this.earnedAt,
    this.isDisplayed = true,
  });

  factory UserAchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAchievementModel(
      id: doc.id,
      oderId: data['userId'] ?? '',
      achievementId: data['achievementId'] ?? '',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDisplayed: data['isDisplayed'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'achievementId': achievementId,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'isDisplayed': isDisplayed,
    };
  }
}