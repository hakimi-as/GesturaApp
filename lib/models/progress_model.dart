import 'package:cloud_firestore/cloud_firestore.dart';

class LearningProgressModel {
  final String id;
  final String oderId;
  final String lessonId;
  final String categoryId;
  final String lessonName;
  final String categoryName;
  final String type;            // NEW: 'lesson' or 'quiz'
  final String status;
  final double completionPercentage;
  final int timeSpentSeconds;
  final int practiceCount;
  final double bestAccuracy;
  final int xpEarned;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;

  LearningProgressModel({
    required this.id,
    required this.oderId,
    required this.lessonId,
    required this.categoryId,
    this.lessonName = '',
    this.categoryName = '',
    this.type = 'lesson',       // Default to lesson
    required this.status,
    this.completionPercentage = 0,
    this.timeSpentSeconds = 0,
    this.practiceCount = 0,
    this.bestAccuracy = 0,
    this.xpEarned = 0,
    this.startedAt,
    this.completedAt,
    required this.lastAccessedAt,
  });

  factory LearningProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both 'status' field and 'isCompleted' field for backward compatibility
    String status = data['status'] ?? 'not_started';
    if (data['isCompleted'] == true && status == 'not_started') {
      status = 'completed';
    }

    // Determine type (check field, fallback to ID check)
    String type = data['type'] ?? 'lesson';
    if (type == 'lesson' && 
       (data['lessonId'].toString().startsWith('quiz_') || data['categoryId'] == 'quiz')) {
      type = 'quiz';
    }
    
    return LearningProgressModel(
      id: doc.id,
      oderId: data['userId'] ?? '',
      lessonId: data['lessonId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      lessonName: data['lessonName'] ?? '',
      categoryName: data['categoryName'] ?? '',
      type: type,
      status: status,
      completionPercentage: (data['completionPercentage'] ?? 0).toDouble(),
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      practiceCount: data['practiceCount'] ?? 0,
      bestAccuracy: (data['bestAccuracy'] ?? 0).toDouble(),
      xpEarned: data['xpEarned'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      lastAccessedAt: (data['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'lessonId': lessonId,
      'categoryId': categoryId,
      'lessonName': lessonName,
      'categoryName': categoryName,
      'type': type,           // Save type
      'status': status,
      'completionPercentage': completionPercentage,
      'timeSpentSeconds': timeSpentSeconds,
      'practiceCount': practiceCount,
      'bestAccuracy': bestAccuracy,
      'xpEarned': xpEarned,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
    };
  }

  // Check completion - handle both formats
  bool get isCompleted => status == 'completed' || completionPercentage >= 100;
  bool get isInProgress => status == 'in_progress';
  bool get isNotStarted => status == 'not_started';
  bool get isQuiz => type == 'quiz';

  /// Get display title for recent activity
  String get displayTitle {
    if (lessonName.isNotEmpty && categoryName.isNotEmpty) {
      return '$categoryName - $lessonName';
    } else if (lessonName.isNotEmpty) {
      return lessonName;
    } else if (categoryName.isNotEmpty) {
      return categoryName;
    }
    return 'Lesson';
  }

  String get formattedTime {
    final hours = timeSpentSeconds ~/ 3600;
    final minutes = (timeSpentSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class UserStatsModel {
  final int totalSignsLearned;
  final double totalTimeHours;
  final double averageAccuracy;
  final int currentStreak;
  final int longestStreak;
  final int totalXP;
  final int quizzesCompleted;
  final int perfectQuizzes;
  final List<DateTime> activeDays;

  UserStatsModel({
    this.totalSignsLearned = 0,
    this.totalTimeHours = 0,
    this.averageAccuracy = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXP = 0,
    this.quizzesCompleted = 0,
    this.perfectQuizzes = 0,
    this.activeDays = const [],
  });

  static UserStatsModel get sampleStats {
    return UserStatsModel(
      totalSignsLearned: 89,
      totalTimeHours: 12.5,
      averageAccuracy: 92,
      currentStreak: 7,
      longestStreak: 14,
      totalXP: 1250,
      quizzesCompleted: 15,
      perfectQuizzes: 5,
      activeDays: [
        DateTime.now().subtract(const Duration(days: 6)),
        DateTime.now().subtract(const Duration(days: 5)),
        DateTime.now().subtract(const Duration(days: 4)),
        DateTime.now().subtract(const Duration(days: 3)),
        DateTime.now().subtract(const Duration(days: 2)),
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now(),
      ],
    );
  }

  static UserStatsModel get empty {
    return UserStatsModel(
      totalSignsLearned: 0,
      totalTimeHours: 0,
      averageAccuracy: 0,
      currentStreak: 0,
      longestStreak: 0,
      totalXP: 0,
      quizzesCompleted: 0,
      perfectQuizzes: 0,
      activeDays: [],
    );
  }
}

class DailyGoalModel {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final String goalType;
  final bool isCompleted;

  DailyGoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.xpReward,
    required this.goalType,
    required this.isCompleted,
  });

  double get progress => targetValue > 0 ? currentValue / targetValue : 0;

  // ==================== 50 DAILY GOALS ====================
  
  static const List<Map<String, dynamic>> _allGoals = [
    {'title': 'Learn 3 new signs today', 'description': 'Complete 3 sign language lessons', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Practice greetings vocabulary', 'description': 'Learn greeting signs', 'target': 2, 'xp': 25, 'type': 'lessons'},
    {'title': 'Master alphabet letters A-E', 'description': 'Practice fingerspelling A-E', 'target': 5, 'xp': 40, 'type': 'lessons'},
    {'title': 'Complete a quiz with 80%+', 'description': 'Score at least 80% on any quiz', 'target': 80, 'xp': 50, 'type': 'quiz_score'},
    {'title': 'Learn family-related signs', 'description': 'Study family vocabulary', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Practice numbers 1-10', 'description': 'Master number signs', 'target': 10, 'xp': 35, 'type': 'lessons'},
    {'title': 'Review yesterday\'s lessons', 'description': 'Refresh your memory', 'target': 2, 'xp': 20, 'type': 'lessons'},
    {'title': 'Learn 5 common phrases', 'description': 'Study everyday expressions', 'target': 5, 'xp': 45, 'type': 'lessons'},
    {'title': 'Practice food vocabulary', 'description': 'Learn food-related signs', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Master emergency signs', 'description': 'Learn important emergency signs', 'target': 3, 'xp': 40, 'type': 'lessons'},
    {'title': 'Learn animal signs', 'description': 'Study animal vocabulary', 'target': 4, 'xp': 30, 'type': 'lessons'},
    {'title': 'Complete 3 lessons without hints', 'description': 'Challenge yourself', 'target': 3, 'xp': 50, 'type': 'lessons'},
    {'title': 'Practice color vocabulary', 'description': 'Learn color signs', 'target': 5, 'xp': 35, 'type': 'lessons'},
    {'title': 'Learn time-related signs', 'description': 'Study time expressions', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Master weather signs', 'description': 'Learn weather vocabulary', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Practice emotional expressions', 'description': 'Study emotion signs', 'target': 4, 'xp': 40, 'type': 'lessons'},
    {'title': 'Learn workplace vocabulary', 'description': 'Study work-related signs', 'target': 3, 'xp': 35, 'type': 'lessons'},
    {'title': 'Complete a perfect quiz', 'description': 'Score 100% on any quiz', 'target': 100, 'xp': 75, 'type': 'quiz_score'},
    {'title': 'Practice direction signs', 'description': 'Learn directional vocabulary', 'target': 4, 'xp': 30, 'type': 'lessons'},
    {'title': 'Learn medical signs', 'description': 'Study health vocabulary', 'target': 3, 'xp': 40, 'type': 'lessons'},
    {'title': 'Master shopping vocabulary', 'description': 'Learn shopping signs', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Practice transportation signs', 'description': 'Study travel vocabulary', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Learn sports-related signs', 'description': 'Study sports vocabulary', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Complete lessons in 2 categories', 'description': 'Diversify your learning', 'target': 2, 'xp': 40, 'type': 'categories'},
    {'title': 'Practice money-related signs', 'description': 'Learn financial vocabulary', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Learn clothing vocabulary', 'description': 'Study clothing signs', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Master body part signs', 'description': 'Learn body vocabulary', 'target': 5, 'xp': 40, 'type': 'lessons'},
    {'title': 'Practice question words', 'description': 'Study interrogative signs', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Learn home-related signs', 'description': 'Study household vocabulary', 'target': 4, 'xp': 30, 'type': 'lessons'},
    {'title': 'Complete your daily streak', 'description': 'Keep your streak alive', 'target': 1, 'xp': 25, 'type': 'streak'},
    {'title': 'Practice school vocabulary', 'description': 'Learn education signs', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Learn music-related signs', 'description': 'Study music vocabulary', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Master technology signs', 'description': 'Learn tech vocabulary', 'target': 4, 'xp': 40, 'type': 'lessons'},
    {'title': 'Practice nature vocabulary', 'description': 'Study nature signs', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Learn holiday signs', 'description': 'Study celebration vocabulary', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Complete 5 lessons today', 'description': 'Intensive learning day', 'target': 5, 'xp': 60, 'type': 'lessons'},
    {'title': 'Practice action verbs', 'description': 'Study verb signs', 'target': 5, 'xp': 40, 'type': 'lessons'},
    {'title': 'Learn descriptive signs', 'description': 'Study adjective vocabulary', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Master polite expressions', 'description': 'Learn courtesy signs', 'target': 3, 'xp': 30, 'type': 'lessons'},
    {'title': 'Practice conversation starters', 'description': 'Study social phrases', 'target': 4, 'xp': 40, 'type': 'lessons'},
    {'title': 'Explore sign language history', 'description': 'Learn about ASL culture', 'target': 1, 'xp': 25, 'type': 'lessons'},
    {'title': 'Complete a timed quiz', 'description': 'Test under pressure', 'target': 1, 'xp': 45, 'type': 'quiz'},
    {'title': 'Practice fingerspelling', 'description': 'Master the alphabet', 'target': 26, 'xp': 50, 'type': 'lessons'},
    {'title': 'Learn regional variations', 'description': 'Explore sign dialects', 'target': 2, 'xp': 35, 'type': 'lessons'},
    {'title': 'Master facial expressions', 'description': 'Non-manual markers practice', 'target': 3, 'xp': 40, 'type': 'lessons'},
    {'title': 'Practice two-handed signs', 'description': 'Bilateral coordination', 'target': 4, 'xp': 35, 'type': 'lessons'},
    {'title': 'Learn compound signs', 'description': 'Study complex vocabulary', 'target': 3, 'xp': 45, 'type': 'lessons'},
    {'title': 'Complete all beginner lessons', 'description': 'Finish basics category', 'target': 1, 'xp': 100, 'type': 'category_complete'},
    {'title': 'Practice storytelling signs', 'description': 'Narrative vocabulary', 'target': 3, 'xp': 40, 'type': 'lessons'},
    {'title': 'Learn cultural deaf signs', 'description': 'Deaf community vocabulary', 'target': 3, 'xp': 45, 'type': 'lessons'},
  ];

  /// Get today's goals (3-4 random goals based on date)
  static List<DailyGoalModel> getTodaysGoals({int currentProgress = 0}) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    
    // Determine number of goals (3 or 4, alternates by day)
    final numberOfGoals = (dayOfYear % 2 == 0) ? 3 : 4;
    
    // Use day of year as seed for consistent daily selection
    final selectedIndices = <int>[];
    int seed = dayOfYear;
    
    while (selectedIndices.length < numberOfGoals) {
      seed = (seed * 1103515245 + 12345) % (1 << 31);
      final index = seed % _allGoals.length;
      
      if (!selectedIndices.contains(index)) {
        selectedIndices.add(index);
      }
    }
    
    int lessonsCompleted = currentProgress;
    
    return selectedIndices.asMap().entries.map((entry) {
      final goal = _allGoals[entry.value];
      final goalType = goal['type'] as String;
      final targetValue = goal['target'] as int;
      
      bool isCompleted = false;
      int currentValue = 0;
      
      if (goalType == 'lessons') {
        currentValue = lessonsCompleted;
        isCompleted = lessonsCompleted >= targetValue;
        if (isCompleted) {
          lessonsCompleted = (lessonsCompleted - targetValue).clamp(0, lessonsCompleted);
        }
      } else if (goalType == 'streak') {
        currentValue = currentProgress > 0 ? 1 : 0;
        isCompleted = currentProgress > 0;
      }
      
      return DailyGoalModel(
        id: 'daily_${entry.key}',
        title: goal['title'] as String,
        description: goal['description'] as String,
        targetValue: targetValue,
        currentValue: currentValue,
        xpReward: goal['xp'] as int,
        goalType: goalType,
        isCompleted: isCompleted,
      );
    }).toList();
  }

  static String getDailyGoalText() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _allGoals.length;
    return _allGoals[index]['title'] as String;
  }

  static int getDailyGoalTarget() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _allGoals.length;
    final target = _allGoals[index]['target'] as int;
    return target > 5 ? 5 : target;
  }

  static List<DailyGoalModel> get defaultGoals => getTodaysGoals();
  static List<DailyGoalModel> get emptyGoals => getTodaysGoals(currentProgress: 0);
}