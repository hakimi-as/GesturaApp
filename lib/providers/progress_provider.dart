import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/progress_model.dart';
import '../models/achievement_model.dart';

class ProgressProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<LearningProgressModel> _progressList = [];
  List<AchievementModel> _allAchievements = [];
  List<UserAchievementModel> _earnedAchievements = [];
  UserStatsModel? _userStats;
  List<DailyGoalModel> _dailyGoals = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LearningProgressModel> get progressList => _progressList;
  List<AchievementModel> get allAchievements => _allAchievements;
  List<UserAchievementModel> get earnedAchievements => _earnedAchievements;
  UserStatsModel get userStats => _userStats ?? UserStatsModel.empty;
  List<DailyGoalModel> get dailyGoals => _dailyGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  List<AchievementModel> get earnedAchievementsList {
    final earnedIds = _earnedAchievements.map((e) => e.achievementId).toSet();
    return _allAchievements.where((a) => earnedIds.contains(a.id)).toList();
  }

  List<AchievementModel> get lockedAchievementsList {
    final earnedIds = _earnedAchievements.map((e) => e.achievementId).toSet();
    return _allAchievements.where((a) => !earnedIds.contains(a.id)).toList();
  }

  int get totalEarnedAchievements => _earnedAchievements.length;
  int get totalAchievements => _allAchievements.length;

  int get completedGoals => _dailyGoals.where((g) => g.isCompleted).length;
  int get totalGoals => _dailyGoals.length;

  /// Get all active days (days when user completed at least one lesson)
  Set<DateTime> get activeDays {
    final Set<DateTime> days = {};
    for (var progress in _progressList) {
      if (progress.isCompleted && progress.completedAt != null) {
        final date = progress.completedAt!;
        days.add(DateTime(date.year, date.month, date.day));
      }
    }
    return days;
  }

  /// Get active days for a specific month
  Set<int> getActiveDaysForMonth(int year, int month) {
    final Set<int> days = {};
    for (var progress in _progressList) {
      if (progress.isCompleted && progress.completedAt != null) {
        final date = progress.completedAt!;
        if (date.year == year && date.month == month) {
          days.add(date.day);
        }
      }
    }
    return days;
  }

  /// Get lessons completed count for each day of the current week (Mon-Sun)
  List<int> getWeeklyLessonsCount() {
    final now = DateTime.now();
    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    
    List<int> weekData = List.filled(7, 0); // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    
    for (var progress in _progressList) {
      if (progress.isCompleted && progress.completedAt != null) {
        final date = progress.completedAt!;
        final progressDate = DateTime(date.year, date.month, date.day);
        
        // Check if this progress is within current week
        final diff = progressDate.difference(mondayDate).inDays;
        if (diff >= 0 && diff < 7) {
          weekData[diff]++;
        }
      }
    }
    
    return weekData;
  }

  /// Get total lessons completed this week
  int get weeklyTotal {
    return getWeeklyLessonsCount().reduce((a, b) => a + b);
  }

  /// Get average lessons per day this week
  double get weeklyAverage {
    final data = getWeeklyLessonsCount();
    return data.reduce((a, b) => a + b) / 7;
  }

  /// Get best day this week
  int get weeklyBest {
    final data = getWeeklyLessonsCount();
    return data.reduce((a, b) => a > b ? a : b);
  }

  // Initialize stats for a user
  Future<void> initializeUserStats(String oderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load user's actual progress from Firebase
      _progressList = await _firestoreService.getUserProgress(oderId);
      
      // Load achievements
      _allAchievements = await _firestoreService.getAchievements();
      if (_allAchievements.isEmpty) {
        _allAchievements = AchievementModel.defaultAchievements;
      }
      
      _earnedAchievements = await _firestoreService.getUserAchievements(oderId);

      // Calculate actual stats based on progress
      _userStats = UserStatsModel(
        totalSignsLearned: _progressList.where((p) => p.isCompleted).length,
        totalTimeHours: _calculateTotalTime(),
        averageAccuracy: _calculateAverageAccuracy(),
        currentStreak: 0, // Will be calculated from user data
        longestStreak: 0,
        totalXP: 0, // Will come from user model
        quizzesCompleted: 0,
        perfectQuizzes: 0,
        activeDays: [],
      );

      // Initialize empty daily goals for new users
      _dailyGoals = DailyGoalModel.emptyGoals;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  double _calculateTotalTime() {
    int totalSeconds = 0;
    for (var progress in _progressList) {
      totalSeconds += progress.timeSpentSeconds;
    }
    return totalSeconds / 3600; // Convert to hours
  }

  double _calculateAverageAccuracy() {
    if (_progressList.isEmpty) return 0;
    double totalAccuracy = 0;
    int count = 0;
    for (var progress in _progressList) {
      if (progress.bestAccuracy > 0) {
        totalAccuracy += progress.bestAccuracy;
        count++;
      }
    }
    return count > 0 ? totalAccuracy / count : 0;
  }

  // Load user progress
  Future<void> loadUserProgress(String oderId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _progressList = await _firestoreService.getUserProgress(oderId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load achievements
  Future<void> loadAchievements(String oderId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allAchievements = await _firestoreService.getAchievements();
      _earnedAchievements = await _firestoreService.getUserAchievements(oderId);

      if (_allAchievements.isEmpty) {
        _allAchievements = AchievementModel.defaultAchievements;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check if lesson is completed
  bool isLessonCompleted(String lessonId) {
    return _progressList.any((p) => p.lessonId == lessonId && p.isCompleted);
  }

  // Reset provider (for logout)
  void reset() {
    _progressList = [];
    _allAchievements = [];
    _earnedAchievements = [];
    _userStats = null;
    _dailyGoals = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}