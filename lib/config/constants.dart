class AppConstants {
  // App Info
  static const String appName = 'Gestura';
  static const String appTagline = 'Breaking Silence, Building Bridges';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String categoriesCollection = 'categories';
  static const String lessonsCollection = 'lessons';
  static const String quizzesCollection = 'quizzes';
  static const String questionsCollection = 'questions';
  static const String achievementsCollection = 'achievements';
  static const String userAchievementsCollection = 'user_achievements';
  static const String progressCollection = 'progress';

  // Shared Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefUserId = 'user_id';
  static const String prefSignLanguage = 'sign_language';
  static const String prefOnboardingComplete = 'onboarding_complete';

  // XP Values
  static const int xpLessonComplete = 10;
  static const int xpQuizCorrect = 5;
  static const int xpQuizPerfect = 50;
  static const int xpDailyGoal = 20;
  static const int xpStreak = 10;

  // Quiz Settings
  static const int quizQuestionsCount = 10;
  static const int quizTimeLimitSeconds = 60;
  static const double quizPassingScore = 0.7;

  // UI Settings
  static const double maxMobileWidth = 430.0;
  static const double defaultPadding = 24.0;
  static const double cardBorderRadius = 18.0;
  static const double buttonBorderRadius = 14.0;

  // Animation Durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  // Sign Languages
  static const List<Map<String, String>> supportedSignLanguages = [
    {'code': 'ASL', 'name': 'American Sign Language'},
    {'code': 'BSL', 'name': 'British Sign Language'},
    {'code': 'MSL', 'name': 'Malaysian Sign Language'},
  ];

  // User Types
  static const String userTypeLearner = 'learner';
  static const String userTypeEducator = 'educator';
  static const String userTypeDeaf = 'deaf';

  // Difficulty Levels
  static const String difficultyBeginner = 'beginner';
  static const String difficultyIntermediate = 'intermediate';
  static const String difficultyAdvanced = 'advanced';
}