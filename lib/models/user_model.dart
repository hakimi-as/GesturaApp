import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  
  // Progress & Stats
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final int signsLearned;
  final int lessonsCompleted;
  final int quizzesCompleted;
  final int perfectQuizzes;
  
  // Daily Goals
  final int dailyGoalProgress;
  final int dailyGoalTarget;
  final String dailyGoalText;
  final int lessonsCompletedToday;
  final DateTime? lastLessonDate;
  
  // Time tracking
  final int totalTimeSpentSeconds;
  
  // Badges
  final List<String> unlockedBadges;
  final List<String> seenBadges;
  
  // Settings & Preferences
  final bool isAdmin;
  final String? preferredLanguage;
  final String? preferredSignLanguage; // ADDED: Missing field
  final String userType; // ADDED: Missing field (e.g., 'learner', 'teacher', 'interpreter')
  
  // Streak Freeze
  final int streakFreezes;
  final int totalFreezesEarned;
  final DateTime? lastFreezeUsed;
  final DateTime? lastFreezeEarned;
  final bool autoUseFreeze;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.createdAt,
    required this.lastActiveAt,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.signsLearned = 0,
    this.lessonsCompleted = 0,
    this.quizzesCompleted = 0,
    this.perfectQuizzes = 0,
    this.dailyGoalProgress = 0,
    this.dailyGoalTarget = 3,
    this.dailyGoalText = 'Complete 3 lessons',
    this.lessonsCompletedToday = 0,
    this.lastLessonDate,
    this.totalTimeSpentSeconds = 0,
    this.unlockedBadges = const [],
    this.seenBadges = const [],
    this.isAdmin = false,
    this.preferredLanguage,
    this.preferredSignLanguage = 'ASL', // ADDED: Default to ASL
    this.userType = 'learner', // ADDED: Default to learner
    // Streak Freeze
    this.streakFreezes = 0,
    this.totalFreezesEarned = 0,
    this.lastFreezeUsed,
    this.lastFreezeEarned,
    this.autoUseFreeze = true,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] as Timestamp).toDate() 
          : DateTime.now(),
      totalXP: data['totalXP'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      signsLearned: data['signsLearned'] ?? 0,
      lessonsCompleted: data['lessonsCompleted'] ?? 0,
      quizzesCompleted: data['quizzesCompleted'] ?? 0,
      perfectQuizzes: data['perfectQuizzes'] ?? 0,
      dailyGoalProgress: data['dailyGoalProgress'] ?? 0,
      dailyGoalTarget: data['dailyGoalTarget'] ?? 3,
      dailyGoalText: data['dailyGoalText'] ?? 'Complete 3 lessons',
      lessonsCompletedToday: data['lessonsCompletedToday'] ?? 0,
      lastLessonDate: data['lastLessonDate'] != null 
          ? (data['lastLessonDate'] as Timestamp).toDate() 
          : null,
      totalTimeSpentSeconds: data['totalTimeSpentSeconds'] ?? 0,
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      seenBadges: List<String>.from(data['seenBadges'] ?? []),
      isAdmin: data['isAdmin'] ?? false,
      preferredLanguage: data['preferredLanguage'],
      preferredSignLanguage: data['preferredSignLanguage'] ?? 'ASL', // ADDED
      userType: data['userType'] ?? 'learner', // ADDED
      // Streak Freeze
      streakFreezes: data['streakFreezes'] ?? 0,
      totalFreezesEarned: data['totalFreezesEarned'] ?? 0,
      lastFreezeUsed: data['lastFreezeUsed'] != null 
          ? (data['lastFreezeUsed'] as Timestamp).toDate() 
          : null,
      lastFreezeEarned: data['lastFreezeEarned'] != null 
          ? (data['lastFreezeEarned'] as Timestamp).toDate() 
          : null,
      autoUseFreeze: data['autoUseFreeze'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'signsLearned': signsLearned,
      'lessonsCompleted': lessonsCompleted,
      'quizzesCompleted': quizzesCompleted,
      'perfectQuizzes': perfectQuizzes,
      'dailyGoalProgress': dailyGoalProgress,
      'dailyGoalTarget': dailyGoalTarget,
      'dailyGoalText': dailyGoalText,
      'lessonsCompletedToday': lessonsCompletedToday,
      'lastLessonDate': lastLessonDate != null 
          ? Timestamp.fromDate(lastLessonDate!) 
          : null,
      'totalTimeSpentSeconds': totalTimeSpentSeconds,
      'unlockedBadges': unlockedBadges,
      'seenBadges': seenBadges,
      'isAdmin': isAdmin,
      'preferredLanguage': preferredLanguage,
      'preferredSignLanguage': preferredSignLanguage, // ADDED
      'userType': userType, // ADDED
      // Streak Freeze
      'streakFreezes': streakFreezes,
      'totalFreezesEarned': totalFreezesEarned,
      'lastFreezeUsed': lastFreezeUsed != null 
          ? Timestamp.fromDate(lastFreezeUsed!) 
          : null,
      'lastFreezeEarned': lastFreezeEarned != null 
          ? Timestamp.fromDate(lastFreezeEarned!) 
          : null,
      'autoUseFreeze': autoUseFreeze,
    };
  }

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    int? signsLearned,
    int? lessonsCompleted,
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? dailyGoalProgress,
    int? dailyGoalTarget,
    String? dailyGoalText,
    int? lessonsCompletedToday,
    DateTime? lastLessonDate,
    int? totalTimeSpentSeconds,
    List<String>? unlockedBadges,
    List<String>? seenBadges,
    bool? isAdmin,
    String? preferredLanguage,
    String? preferredSignLanguage, // ADDED
    String? userType, // ADDED
    // Streak Freeze
    int? streakFreezes,
    int? totalFreezesEarned,
    DateTime? lastFreezeUsed,
    DateTime? lastFreezeEarned,
    bool? autoUseFreeze,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      signsLearned: signsLearned ?? this.signsLearned,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
      dailyGoalProgress: dailyGoalProgress ?? this.dailyGoalProgress,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyGoalText: dailyGoalText ?? this.dailyGoalText,
      lessonsCompletedToday: lessonsCompletedToday ?? this.lessonsCompletedToday,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
      totalTimeSpentSeconds: totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      seenBadges: seenBadges ?? this.seenBadges,
      isAdmin: isAdmin ?? this.isAdmin,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredSignLanguage: preferredSignLanguage ?? this.preferredSignLanguage, // ADDED
      userType: userType ?? this.userType, // ADDED
      // Streak Freeze
      streakFreezes: streakFreezes ?? this.streakFreezes,
      totalFreezesEarned: totalFreezesEarned ?? this.totalFreezesEarned,
      lastFreezeUsed: lastFreezeUsed ?? this.lastFreezeUsed,
      lastFreezeEarned: lastFreezeEarned ?? this.lastFreezeEarned,
      autoUseFreeze: autoUseFreeze ?? this.autoUseFreeze,
    );
  }

  // ==================== STREAK FREEZE HELPERS ====================
  
  bool get hasFreeze => streakFreezes > 0;
  bool get canEarnFreeze => streakFreezes < 2;
  int get freezesRemaining => streakFreezes;
  static const int maxFreezes = 2;
  static const int daysToEarnFreeze = 7;
  static const int freezeXPCost = 500;
  
  int get daysUntilNextFreeze {
    if (!canEarnFreeze) return 0;
    return daysToEarnFreeze - (currentStreak % daysToEarnFreeze);
  }
  
  bool get canBuyFreeze => canEarnFreeze && totalXP >= freezeXPCost;

  // ==================== LEVEL & XP HELPERS ====================

  /// Get user initials for avatar
  String get initials {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty && names.first.isNotEmpty) {
      return names.first[0].toUpperCase();
    }
    return 'U';
  }

  /// Get formatted time spent
  String get formattedTimeSpent {
    final hours = totalTimeSpentSeconds ~/ 3600;
    final minutes = (totalTimeSpentSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  /// XP thresholds for each level
  static const List<int> _levelThresholds = [
    0,      // Level 1
    100,    // Level 2
    300,    // Level 3
    600,    // Level 4
    1000,   // Level 5
    1500,   // Level 6
    2100,   // Level 7
    2800,   // Level 8
    3600,   // Level 9
    4500,   // Level 10
  ];

  /// Get user level based on XP
  int get level {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= _levelThresholds[i]) {
        if (i == _levelThresholds.length - 1) {
          // Beyond level 10
          return 10 + ((totalXP - _levelThresholds.last) ~/ 1000);
        }
        return i + 1;
      }
    }
    return 1;
  }

  /// Get XP needed for next level (ADDED - was missing)
  int get xpForNextLevel {
    if (level < 10) {
      return _levelThresholds[level];
    }
    // For levels above 10
    return _levelThresholds.last + ((level - 9) * 1000);
  }

  /// Get XP remaining to reach next level (ADDED - this was causing errors)
  int get xpToNextLevel {
    return xpForNextLevel - totalXP;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    if (level < 10) {
      final currentLevelXP = _levelThresholds[level - 1];
      final nextLevelXP = _levelThresholds[level];
      final xpInLevel = totalXP - currentLevelXP;
      final xpNeeded = nextLevelXP - currentLevelXP;
      return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
    }
    // For levels above 10
    final baseXP = _levelThresholds.last + ((level - 10) * 1000);
    return ((totalXP - baseXP) / 1000).clamp(0.0, 1.0);
  }

  // ==================== BADGES HELPERS ====================

  /// Total badges earned (ADDED - this was causing errors)
  int get totalBadges => unlockedBadges.length;

  /// Check if user has a specific badge
  bool hasBadge(String badgeId) => unlockedBadges.contains(badgeId);

  /// Check if user has seen a specific badge notification
  bool hasSeenBadge(String badgeId) => seenBadges.contains(badgeId);

  /// Get unseen badges
  List<String> get unseenBadges {
    return unlockedBadges.where((b) => !seenBadges.contains(b)).toList();
  }

  // ==================== USER TYPE HELPERS ====================

  /// Check if user is a learner
  bool get isLearner => userType == 'learner';

  /// Check if user is a teacher
  bool get isTeacher => userType == 'teacher';

  /// Check if user is an interpreter
  bool get isInterpreter => userType == 'interpreter';

  /// Get display name for user type
  String get userTypeDisplay {
    switch (userType) {
      case 'learner':
        return 'Learner';
      case 'teacher':
        return 'Teacher';
      case 'interpreter':
        return 'Interpreter';
      default:
        return 'Learner';
    }
  }
}