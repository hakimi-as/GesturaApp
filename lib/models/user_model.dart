import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String userType;
  final String preferredSignLanguage;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final int signsLearned;
  final int quizzesCompleted;
  final int perfectQuizzes;
  final int lessonsCompletedToday;
  final int dailyGoalTarget;
  final int dailyGoalProgress;
  final String dailyGoalText;
  final int totalTimeSpentSeconds;  // Total time spent in app (seconds)
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final DateTime? lastLessonDate;
  final bool isAdmin;
  final List<String> unlockedBadges;
  final List<String> seenBadges;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.userType = 'learner',
    this.preferredSignLanguage = 'ASL',
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.signsLearned = 0,
    this.quizzesCompleted = 0,
    this.perfectQuizzes = 0,
    this.lessonsCompletedToday = 0,
    this.dailyGoalTarget = 3,
    this.dailyGoalProgress = 0,
    this.dailyGoalText = 'Complete 3 lessons today',
    this.totalTimeSpentSeconds = 0,
    required this.createdAt,
    required this.lastActiveAt,
    this.lastLessonDate,
    this.isAdmin = false,
    this.unlockedBadges = const [],
    this.seenBadges = const [],
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Get user initials from full name
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  /// Calculate user level based on XP (100 XP per level)
  int get level {
    return (totalXP / 100).floor() + 1;
  }

  /// XP required for next level
  int get xpToNextLevel {
    return (level * 100) - totalXP;
  }

  /// Progress percentage to next level (0.0 to 1.0)
  double get levelProgress {
    final xpInCurrentLevel = totalXP % 100;
    return xpInCurrentLevel / 100;
  }

  /// Get formatted time spent string
  String get formattedTimeSpent {
    final hours = totalTimeSpentSeconds ~/ 3600;
    final minutes = (totalTimeSpentSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}.${(minutes / 6).floor()}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Display name (first name)
  String get displayName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : 'Learner';
  }

  /// Check if daily goal is completed
  bool get isDailyGoalCompleted {
    return dailyGoalProgress >= dailyGoalTarget;
  }

  /// Total badges unlocked count
  int get totalBadges {
    return unlockedBadges.length;
  }

  /// Check if user has a specific badge
  bool hasBadge(String badgeId) {
    return unlockedBadges.contains(badgeId);
  }

  /// Get unseen badges count
  int get unseenBadgesCount {
    return unlockedBadges.where((id) => !seenBadges.contains(id)).length;
  }

  // ==================== FACTORY & METHODS ====================

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      userType: data['userType'] ?? 'learner',
      preferredSignLanguage: data['preferredSignLanguage'] ?? 'ASL',
      totalXP: data['totalXP'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      signsLearned: data['signsLearned'] ?? 0,
      quizzesCompleted: data['quizzesCompleted'] ?? 0,
      perfectQuizzes: data['perfectQuizzes'] ?? 0,
      lessonsCompletedToday: data['lessonsCompletedToday'] ?? 0,
      dailyGoalTarget: data['dailyGoalTarget'] ?? 3,
      dailyGoalProgress: data['dailyGoalProgress'] ?? 0,
      dailyGoalText: data['dailyGoalText'] ?? 'Complete lessons today',
      totalTimeSpentSeconds: data['totalTimeSpentSeconds'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLessonDate: (data['lastLessonDate'] as Timestamp?)?.toDate(),
      isAdmin: data['isAdmin'] ?? false,
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      seenBadges: List<String>.from(data['seenBadges'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'userType': userType,
      'preferredSignLanguage': preferredSignLanguage,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'signsLearned': signsLearned,
      'quizzesCompleted': quizzesCompleted,
      'perfectQuizzes': perfectQuizzes,
      'lessonsCompletedToday': lessonsCompletedToday,
      'dailyGoalTarget': dailyGoalTarget,
      'dailyGoalProgress': dailyGoalProgress,
      'dailyGoalText': dailyGoalText,
      'totalTimeSpentSeconds': totalTimeSpentSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'lastLessonDate': lastLessonDate != null ? Timestamp.fromDate(lastLessonDate!) : null,
      'isAdmin': isAdmin,
      'unlockedBadges': unlockedBadges,
      'seenBadges': seenBadges,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    String? userType,
    String? preferredSignLanguage,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    int? signsLearned,
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? lessonsCompletedToday,
    int? dailyGoalTarget,
    int? dailyGoalProgress,
    String? dailyGoalText,
    int? totalTimeSpentSeconds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? lastLessonDate,
    bool? isAdmin,
    List<String>? unlockedBadges,
    List<String>? seenBadges,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      preferredSignLanguage: preferredSignLanguage ?? this.preferredSignLanguage,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      signsLearned: signsLearned ?? this.signsLearned,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
      lessonsCompletedToday: lessonsCompletedToday ?? this.lessonsCompletedToday,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyGoalProgress: dailyGoalProgress ?? this.dailyGoalProgress,
      dailyGoalText: dailyGoalText ?? this.dailyGoalText,
      totalTimeSpentSeconds: totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
      isAdmin: isAdmin ?? this.isAdmin,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      seenBadges: seenBadges ?? this.seenBadges,
    );
  }
}