import 'package:flutter/material.dart';

/// Manual implementation — no code-gen required.
/// To add a new language: add its code to [supportedLocales] and a new
/// entry in [_strings]. Every key must exist in all languages (fall back to 'en').
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'), // English
    Locale('ms'), // Bahasa Malaysia
  ];

  // ── Translations ───────────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // App
      'appTitle': 'Gestura',
      'appTagline': 'Breaking Silence, Building Bridges',

      // Navigation
      'navHome': 'Home',
      'navTranslate': 'Translate',
      'navLearn': 'Learn',
      'navSettings': 'Settings',

      // Common actions
      'cancel': 'Cancel',
      'save': 'Save',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'submit': 'Submit',
      'retry': 'Try Again',
      'close': 'Close',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'search': 'Search',
      'all': 'All',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
      'refresh': 'Refresh',

      // Auth
      'login': 'Log In',
      'register': 'Register',
      'logout': 'Log Out',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'welcomeBack': 'Welcome Back!',
      'createAccount': 'Create Account',
      'forgotPassword': 'Forgot Password?',
      'loginSubtitle': 'Sign in to continue learning',
      'registerSubtitle': 'Join the Gestura community',
      'alreadyHaveAccount': 'Already have an account? Log in',
      'dontHaveAccount': "Don't have an account? Register",
      'orContinueWith': 'Or continue with',

      // Learn tab
      'learnTitle': 'Learn',
      'lessonCategories': 'Lesson Categories',
      'signs': 'signs',
      'completed': 'completed',
      'continueLabel': 'Continue',
      'startLearning': 'Start Learning',

      // Quiz tab
      'quizTitle': 'Quiz',
      'chooseQuizType': 'Choose Quiz Type',
      'recentScores': 'Recent Scores',
      'signToText': 'Sign to Text',
      'signToTextDesc': 'Watch and identify',
      'textToSign': 'Text to Sign',
      'textToSignDesc': 'Find the correct sign',
      'timedChallenge': 'Timed Challenge',
      'timedChallengeDesc': 'Beat the clock',
      'spellingQuiz': 'Spelling Quiz',
      'spellingQuizDesc': 'Finger-spell words',
      'fillInBlank': 'Fill in the Blank',
      'fillInBlankDesc': 'Type the answer',
      'typeYourAnswer': 'Type your answer...',
      'questions': 'questions',
      'notPlayedYet': 'Not played yet',
      'bestScore': 'Best',
      'noQuizzesYet': 'No quizzes taken yet',
      'completeQuizPrompt': 'Complete a quiz to see your scores here',

      // Quiz screen
      'whatSignIsThis': 'What sign is this?',
      'whichSignMeans': 'Which sign means',
      'pickCorrectSign': 'Pick the correct sign below',
      'whatWordSpelled': 'What word is being spelled?',
      'timeUp': "Time's Up!",
      'correctAnswer': 'Correct Answer',
      'hintLabel': 'Hint',
      'submitAnswer': 'Submit Answer',
      'nextQuestion': 'Next Question',
      'finishQuiz': 'Finish Quiz',
      'quitQuiz': 'Quit Quiz?',
      'quitQuizMessage': 'Your progress will be lost. Are you sure you want to quit?',

      // Quiz result
      'quizComplete': 'Quiz Complete!',
      'greatJob': 'Great Job!',
      'keepPracticing': 'Keep Practicing!',
      'score': 'Score',
      'correct': 'Correct',
      'wrong': 'Wrong',
      'xpEarned': 'XP Earned',
      'perfectScore': 'Perfect Score!',
      'reviewMistakes': 'Review Mistakes',
      'tryAgain': 'Try Again',
      'backToHome': 'Back to Home',

      // Progress tab
      'progressTitle': 'Progress',
      'overallProgress': 'Overall Progress',
      'weeklyActivity': 'Weekly Activity',
      'dailyStreak': 'Daily Streak',
      'days': 'days',
      'lessonsCompleted': 'Lessons Completed',
      'quizzesCompleted': 'Quizzes Completed',
      'totalXP': 'Total XP',
      'averageAccuracy': 'Quiz Accuracy',

      // Badges tab
      'badgesTitle': 'Badges',
      'noBadgesYet': 'No badges yet',
      'keepLearning': 'Keep learning to earn badges!',
      'badgeUnlocked': 'Badge Unlocked!',

      // Settings
      'settingsTitle': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'theme': 'Theme',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'systemDefault': 'System Default',
      'notifications': 'Notifications',
      'signLanguage': 'Sign Language',
      'account': 'Account',
      'appearance': 'Appearance',
      'appVersion': 'App Version',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'about': 'About',

      // Profile
      'profileTitle': 'Profile',
      'editProfile': 'Edit Profile',
      'level': 'Level',
      'streak': 'Streak',
      'joinedLabel': 'Joined',

      // Home
      'homeWelcome': 'Welcome back',
      'todayChallenge': "Today's Challenge",
      'continueLesson': 'Continue Lesson',
      'leaderboard': 'Leaderboard',
      'seeAll': 'See All',

      // Difficulty
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',

      // Quiz screen extras
      'noQuestionsAvailable': 'No questions available',
      'selectAnAnswer': 'Select an answer',
      'seeResults': 'See Results',
      'correctAnswerIs': 'Correct answer',
      'yourAnswer': 'Your answer',
      'timeSpent': 'Time Spent',
      'quit': 'Quit',
      'reviewWrongAnswers': 'Review Mistakes',
      'lightningFastFeedback': '⚡ Lightning fast!',
      'fastFeedback': '✓ Fast!',
      'correctFeedback': '✓ Correct!',
      'wrongFeedback': '✗ Wrong! Answer:',
      'quickStart': 'Quick Start',

      // Result screen performance labels
      'perfectScoreLabel': 'Perfect Score!',
      'excellent': 'Excellent!',
      'goodEffort': 'Good Effort!',
      'perfectScoreMsg': 'You got every sign right! Amazing!',
      'excellentMsg': 'Almost perfect! Outstanding performance!',
      'greatJobMsg': 'You passed! Review the ones you missed.',
      'goodEffortMsg': "You're improving! Check your mistakes below.",
      'keepPracticingMsg': 'Review the signs below and try again!',

      // Auth extras
      'fullName': 'Full Name',
      'enterFullName': 'Enter your full name',
      'enterEmail': 'Enter your email',
      'enterPassword': 'Enter your password',
      'createPassword': 'Create a password',
      'confirmPassword': 'Confirm Password',
      'confirmPasswordHint': 'Re-enter your password',
      'iAmA': 'I am a...',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'joinCommunity': 'Join our sign language community',

      // Validation
      'pleaseEnterName': 'Please enter your name',
      'pleaseEnterEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'pleaseEnterPassword': 'Please enter your password',
      'passwordMinLength': 'Password must be at least 6 characters',
      'pleaseConfirmPassword': 'Please confirm your password',
      'passwordsDoNotMatch': 'Passwords do not match',

      // Quiz list
      'noQuizzesAvailable': 'No quizzes available',
      'checkBackLater': 'Check back later for new quizzes',

      // Learn tab section headers
      'lessonProgress': 'Lesson Progress',
      'quizAccuracy': 'Quiz Accuracy',
      'practiceMore': 'Keep practicing!',

      // Settings sections
      'general': 'GENERAL',
      'preferences': 'PREFERENCES',
      'adminSection': 'ADMIN',
      'accountSection': 'ACCOUNT',
      'notificationSettings': 'Notification Settings',
      'soundEffects': 'Sound Effects',
      'vibration': 'Vibration',
      'autoUseFreeze': 'Auto-use Freeze',
      'dark': 'Dark',
      'light': 'Light',
      'system': 'System',
      'adminPanel': 'Admin Panel',
      'shareProgress': 'Share Progress',
      'logOut': 'Log Out',
      'logOutQuestion': 'Log Out?',
      'logOutMessage': 'Are you sure you want to log out?',
      'changeProfilePicture': 'Change Profile Picture',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'removePhoto': 'Remove Photo',
      'buyStreakFreeze': 'Buy Streak Freeze?',
      'streakFreezeDesc': 'Protect your streak for one day if you miss a lesson.',
      'cost': 'Cost:',
      'youHave': 'You have:',
      'buyFreeze': 'Buy Freeze',
      'selectSignLanguage': 'Select Sign Language',
      'aboutVersion': 'Version 1.0.0',
      'aboutDescription': 'Gestura is a sign language learning app designed to help you communicate better through sign language.',
      'aboutCopyright': '© 2025 Gestura Team',
      'uploading': 'Uploading...',
      'profileSavedCloud': '✓ Profile picture saved to cloud',
      'profileSavedLocally': '✓ Profile picture saved locally',
      'profilePhotoRemoved': '✓ Profile photo removed',
      'streakFreezePurchased': '✓ Streak freeze purchased!',
      'purchaseFailed': 'Purchase failed',
      'dayStreakLabel': 'Day Streak',
      'badgesLabel': 'Badges',

      // Badges screen
      'yourCollection': 'Your Collection',
      'allBadgesTab': 'All Badges',
      'unlockedTab': 'Unlocked',
      'noBadgesEmpty': 'No badges yet',
      'earnBadgesPrompt': 'Complete lessons and quizzes to earn badges!',
      'badgeLearning': 'Learning',
      'badgeStreaks': 'Streaks',
      'badgeQuizzes': 'Quizzes',
      'badgeSocial': 'Social',
      'badgeMilestones': 'Milestones',
      'badgeSpecial': 'Special',
      'tierBronze': 'Bronze',
      'tierSilver': 'Silver',
      'tierGold': 'Gold',
      'tierPlatinum': 'Platinum',

      // Profile extras
      'myProfile': 'My Profile',
      'myStats': 'My Stats',
      'profileUpdated': 'Profile updated successfully!',
      'preferredSignLanguage': 'Preferred Sign Language',
      'noUserData': 'No user data',

      // Dashboard
      'goodMorning': 'Good Morning,',
      'goodAfternoon': 'Good Afternoon,',
      'goodEvening': 'Good Evening,',
      'welcomeBackExclaim': 'Welcome back! ',
      'quickActions': 'Quick Actions',
      'realTimeTranslation': 'Real-time sign translation',
      'interactiveLessons': 'Interactive lessons',
      'testKnowledge': 'Test your knowledge',
      'trackStats': 'Track your stats',
      'competeConnect': 'Compete & Connect',
      'competeGlobally': 'Compete globally',
      'friends': 'Friends',
      'connectCompare': 'Connect & compare',
      'dailyChallenges': 'Daily Challenges',
      'challengesBonusXP': 'Complete challenges for bonus XP',
      'activeLabel': 'Active',
      'recentActivity': 'Recent Activity',
      'viewAll': 'View All',
      'noActivityYet': 'No activity yet',
      'startLearningProgress': 'Start learning to see your progress!',
      'todaysProgress': "Today's Progress",
      'noDailyChallenges': 'No daily challenges available',
      'justNow': 'Just now',
      'minAgo': 'min ago',
      'hoursAgo': 'hours ago',
      'yesterday': 'Yesterday',
      'daysAgoLabel': 'days ago',
      'signsLabel': 'Signs',
      'completedActivity': 'Completed',
      'startedActivity': 'Started',
      'lessonActivity': 'Lesson',

      // Quiz home screen
      'quizHeaderSubtitle': 'Take a quiz and earn XP!',
      'today': 'Today',
      'signToTextFullDesc': 'See a sign and pick what it means',
      'textToSignFullDesc': 'Read a word and pick the correct sign',
      'timedChallengeFullDesc': 'Race against the clock, 10s per sign',
      'spellingQuizFullDesc': 'Decode fingerspelled words letter by letter',
      'fillInBlankFullDesc': 'See a sign image and type the word it represents',
      'bonusXP': '+50 Bonus XP',

      // Admin panel
      'overview': 'Overview',
      'manage': 'Manage',
      'welcomeAdmin': 'Welcome, Admin!',
      'administrator': 'Administrator',
      'adminContentDesc': 'Manage your app content here',
      'totalUsers': 'Total Users',
      'categories': 'Categories',
      'lessons': 'Lessons',
      'quizzes': 'Quizzes',
      'users': 'Users',
      'viewManageUsers': 'View and manage users',
      'addEditDeleteCategories': 'Add, edit, delete categories',
      'manageLessonContent': 'Manage lesson content',
      'createManageQuizzes': 'Create and manage quizzes',
      'manageChallengesDesc': 'Manage daily/weekly challenges',
      'manageAchievementBadges': 'Manage achievement badges',
      'signLibrary': 'Sign Library',
      'viewDeleteUploadSigns': 'View, Delete & Upload Signs',
      'learningPaths': 'Learning Paths',
      'seedPathsFromLessons': 'Seed paths from existing lessons',
      'seedQuizzes': 'Seed Quizzes',
      'generate3QuizzesPerType': 'Generate 3 quizzes for each quiz type',
      'addCategory': 'Add Category',
      'addLesson': 'Add Lesson',

      // Forgot password
      'forgotPasswordSubtitle': 'No worries! Enter your email address and we\'ll send you a link to reset your password.',
      'sendResetLink': 'Send Reset Link',
      'backToSignIn': 'Back to Sign In',
      'emailSent': 'Email Sent!',
      'emailSentDesc': 'We\'ve sent a password reset link to',
      'didntReceive': 'Didn\'t receive? Try again',

      // Onboarding
      'skip': 'Skip',
      'getStarted': 'Get Started',
      'onboardingTitle1': 'Welcome to Gestura',
      'onboardingSubtitle1': 'Learn sign language through interactive lessons, quizzes, and real-time translation.',
      'onboardingTitle2': 'Interactive Lessons',
      'onboardingSubtitle2': 'Master signs step-by-step with video tutorials, practice exercises, and instant feedback.',
      'onboardingTitle3': 'Track Your Progress',
      'onboardingSubtitle3': 'Earn XP, unlock badges, maintain streaks, and watch your skills grow every day.',
      'onboardingTitle4': 'Real-Time Translation',
      'onboardingSubtitle4': 'Use your camera to translate signs to text or type text to see sign demonstrations.',

      // Preference screen
      'preferencesTitle': 'Preferences',
      'chooseSignLanguage': 'Choose Your Sign Language',
      'dailyLearningGoal': 'Daily Learning Goal',
      'experienceLevel': 'Your Experience Level',
      'selectAllOptions': 'Select All Options',
      'casualLearning': 'Casual Learning',
      'regularPractice': 'Regular Practice',
      'intensiveStudy': 'Intensive Study',
      'completeBeginner': 'Complete Beginner',
      'knowSomeSigns': 'Know Some Signs',

      // Translate screen
      'signToTextTab': 'Sign → Text',
      'textToSignTab': 'Text → Sign',
      'translationOutput': 'TRANSLATION OUTPUT',
      'aslToEnglish': 'ASL → English',
      'waitingForGestures': 'Waiting for gestures...',
      'speak': 'Speak',
      'copy': 'Copy',
      'clear': 'Clear',
      'enterText': 'ENTER TEXT',
      'typeWordSentence': 'Type a word or sentence...',
      'listening': 'Listening...',
      'voice': 'Voice',
      'translateBtn': 'Translate',
      'currentSign': 'CURRENT SIGN',
      'englishToMsl': 'English → MSL',
      'typeSomethingToSee': 'Type something to see ML animation',
      'startCamera': 'Start Camera',
      'stopCamera': 'Stop Camera',
      'pointCameraAtSigns': 'Point your camera at sign language gestures to translate them in real-time',
      'cameraActive': 'Camera Active',
      'showSignToTranslate': 'Show a sign to translate',
      'readyToTranslate': 'Ready to translate',
      'translating': 'Translating...',
      'copiedToClipboard': '✓ Copied to clipboard',
      'micAccessDenied': 'Microphone access denied or unavailable',
      'speakSign': 'Speak Sign',

      // Notifications screen
      'readAll': 'Read All',
      'clearAll': 'Clear All',
      'clearAllNotifications': 'Clear All Notifications',
      'clearAllConfirm': 'Are you sure you want to delete all notifications?',
      'allMarkedRead': 'All notifications marked as read',
      'allNotificationsCleared': 'All notifications cleared',
      'noNotifications': 'No Notifications',
      'allCaughtUp': 'You\'re all caught up! Check back later.',

      // Notification settings
      'pushNotifications': 'Push Notifications',
      'receiveImportantUpdates': 'You\'ll receive important updates',
      'notificationsDisabled': 'Notifications are disabled',
      'notificationTypes': 'Notification Types',
      'streakReminders': 'Streak Reminders',
      'dontLoseStreak': 'Don\'t lose your learning streak',
      'dailyGoalsNotif': 'Daily Goals',
      'remindersToComplete': 'Reminders to complete your goals',
      'achievementsNotif': 'Achievements',
      'whenUnlockBadges': 'When you unlock new badges',
      'challengesNotif': 'Challenges',
      'newChallengesCompletions': 'New challenges and completions',
      'dailyReminderTime': 'Daily Reminder Time',
      'reminderTime': 'Reminder Time',
      'whenToSendReminders': 'When to send daily reminders',
      'testNotifications': 'Test Notifications',
      'sendTestNotification': 'Send Test Notification',
      'testNotificationSent': 'Test notification sent!',

      // Theme settings
      'currentTheme': 'Current Theme',
      'chooseTheme': 'Choose Theme',
      'brightAndClear': 'Bright and clear',
      'easyOnEyes': 'Easy on the eyes',
      'matchDeviceSettings': 'Match device settings',
      'proTip': 'Pro Tip',
      'darkModeReduceStrain': 'Dark mode can help reduce eye strain in low-light environments.',

      // Leaderboard
      'globalRanking': 'Global Ranking',
      'friendsRanking': 'Friends Ranking',
      'global': 'Global',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'allTime': 'All Time',
      'noRankingsYet': 'No rankings yet',
      'startLearningLeaderboard': 'Start learning to appear on the leaderboard!',
      'addFriendsCompete': 'Add friends to compete with them!',
      'findFriends': 'Find Friends',
      'youLabel': 'YOU',
      'streakStat': 'streak',
      'signsStat': 'signs',

      // Friends screen
      'friendsTab': 'Friends',
      'requestsTab': 'Requests',
      'findTab': 'Find',
      'noFriendsYet': 'No friends yet',
      'searchFriendsQr': 'Search for friends or share your QR code',
      'addFriendsBtn': 'Add Friends',
      'noPendingRequests': 'No pending requests',
      'requestsWillAppear': 'Friend requests you receive will appear here',
      'decline': 'Decline',
      'accept': 'Accept',

      // Add Friend screen
      'addFriendTitle': 'Add Friend',
      'scanQrTab': 'Scan QR',
      'myQrTab': 'My QR',
      'enterCodeTab': 'Enter Code',
      'scanFriendQr': 'Scan Friend\'s QR Code',
      'pointCameraQr': 'Point your camera at their QR code to add them',
      'alignQrFrame': 'Align QR code within frame',
      'findingUser': 'Finding user...',
      'letFriendsScan': 'Let friends scan this code to add you',
      'myFriendCode': 'My Friend Code',
      'enterFriendCode': 'Enter Friend Code',
      'askFriendCode': 'Ask your friend for their code or scan their QR',
      'pasteFriendCode': 'Paste friend code here',
      'findFriend': 'Find Friend',
      'tipsLabel': 'Tips',
      'friendCodeCopied': '✅ Friend code copied!',
      'invalidQrFormat': '❌ Invalid QR code format',
      'cameraAccessRequired': 'Camera Access Required',
      'pleaseEnterFriendCode': 'Please enter a friend code',
      'userNotFound': 'User not found. Check the code and try again.',
      'cannotAddSelf': 'You cannot add yourself as a friend!',
      'anErrorOccurred': 'An error occurred. Please try again.',
      'searchByNameEmail': 'Search by name or email...',
      'noUsersFound': 'No users found',
      'tryDifferentSearch': 'Try a different search term',
      'findNewFriends': 'Find New Friends',
      'addByQrCode': 'Add by QR Code',

      // Friend challenges
      'challengesTab': 'Challenges',
      'challengeFriend': 'Challenge',
      'sendChallenge': 'Send Challenge',
      'challengeSent': '🏆 Challenge sent!',
      'challengeDeclined': 'Challenge declined',
      'noChallenges': 'No challenges',
      'noIncomingChallenges': 'No incoming challenges',
      'challengesWillAppear': 'Friend challenges will appear here',
      'incomingChallenge': 'Incoming Challenge',
      'outgoingChallenge': 'Outgoing Challenge',
      'challengeFrom': 'Challenge from',
      'theyScored': 'They scored',
      'yourScore': 'Your score',
      'beatThisScore': 'Can you beat',
      'acceptChallenge': 'Accept & Play',
      'declineChallenge': 'Decline',
      'challengeWon': 'You won! 🎉',
      'challengeLost': 'They won this round',
      'challengeTied': 'It\'s a tie! 🤝',
      'challengeExpired': 'Challenge expired',
      'pendingChallenge': 'Pending',
      'completedChallenge': 'Completed',
      'selectQuizType': 'Select Quiz Type',
      'challengeMessage': 'Challenge message (optional)',
      'challengeMessageHint': 'Think you can beat me?',
      'sendChallengeDesc': 'Your friend will have 3 days to complete this quiz and beat your score.',
      'yourCurrentScore': 'Your current best',

      // Progress screen
      'myProgressTitle': 'My Progress',
      'progressOverviewTab': 'Overview',
      'progressAchievementsTab': 'Achievements',
      'progressHistoryTab': 'History',
      'detailedStats': 'Detailed Stats',
      'dailyGoalsSection': 'Daily Goals',
      'monDay': 'Mon',
      'tueDay': 'Tue',
      'wedDay': 'Wed',
      'thuDay': 'Thu',
      'friDay': 'Fri',
      'satDay': 'Sat',
      'sunDay': 'Sun',

      // Enhanced progress analytics tab
      'xpThisWeek': 'XP This Week',
      'quizPerformanceLabel': 'Quiz Performance',
      'learningInsights': 'Learning Insights',
      'sessionsThisMonth': 'Sessions this month',
      'avgPerActiveDay': 'Avg per active day',
      'mostActiveDayLabel': 'Most active day',
      'overallAccuracyLabel': 'Overall accuracy',
      'longestStreakLabel': 'Longest streak',
      'totalQuizzesLabel': 'Total quizzes',
      'noQuizzesYetAnalytics': 'No quizzes yet',
      'analyticsTab': 'Analytics',
      'activityTab': 'Activity',
      'achievementsTab': 'Achievements',
      'categoryProgressLabel': 'Category Progress',
      'streakCalendarLabel': 'Streak Calendar',
      'dayStreakLabel2': 'day streak',
      'thisWeek': 'This Week',
      'xpLabel': 'XP',
      'lessonsLabel': 'lessons',
      'perDayLabel': 'per day',
      'overviewTabLabel': 'Overview',
      'totalLabel': 'Total',
      'averageLabel': 'Average',
      'bestLabel': 'Best',
      'noCategoriesYet': 'No categories yet',
      'yourBadges': 'Your Badges',
      'badgeCollection': 'Badge Collection',
      'bronzeTier': 'Bronze',
      'silverTier': 'Silver',
      'goldTier': 'Gold',
      'platinumTier': 'Platinum',
      'dailyAvgLabel': 'Daily avg',
      'bestDayLabel': 'Best day',
      'notPlayed': 'Not played',
      'spellingQuizType': 'Spelling',
      'timedQuizType': 'Timed',
      'monthJanuary': 'January',
      'monthFebruary': 'February',
      'monthMarch': 'March',
      'monthApril': 'April',
      'monthMay': 'May',
      'monthJune': 'June',
      'monthJuly': 'July',
      'monthAugust': 'August',
      'monthSeptember': 'September',
      'monthOctober': 'October',
      'monthNovember': 'November',
      'monthDecember': 'December',
      'signsLearned': 'Signs Learned',
      'totalLearningTime': 'Total Learning Time',
      'perfectQuizzes': 'Perfect Quizzes',
      'hoursLabel': 'hours',
      'daysLabel': 'days',
      'xpToLevel': 'XP to Level',
      'noGoalsToday': 'No goals set for today',
      'noAchievementsEarned': 'No achievements earned yet',
      'noLearningHistory': 'No learning history yet',
      'completeLessonsHistory': 'Complete lessons to see your history here',
      'inProgressLabel': 'In Progress',
      'lessonLabel': 'Lesson',
      'earnedLabel': 'Earned',
      'lockedLabel': 'Locked',

      'noLessonsYet': 'No lessons yet',
      'masterSignLanguage': 'Master sign language step by step',
      'noPathsAvailable': 'No paths available',
      'reviewPath': 'Review Path',
      'continueLearning': 'Continue Learning',
      'startJourney': 'Start Journey',
      'yourProgress': 'Your Progress',
      'learningJourney': 'Learning Journey',
      'retryLabel': 'Retry',
      'progressLabel': 'Progress',
      'defaultLearningPath': 'Learning Path',
      'completedExclamation': 'Completed! 🎉',
      'signToTextQuiz': 'Sign to Text',
      'textToSignQuiz': 'Text to Sign',
      'quizLabel': 'Quiz',

      // Category lessons certificate
      'generatingCertificate': 'Generating Certificate...',
      'completeLessonsForCert': 'Complete lessons to get certificate',
      'getCompletionCertificate': 'Get Completion Certificate 🎓',
      'allLessonsCompleted': '🎉 All lessons completed!',
      'errorGeneratingCertificate': 'Error generating certificate',
      'shareProgressCertificate': 'Share Progress Certificate',

      // Learning paths
      'failedLoadPaths': 'Failed to load learning paths',
    },

    'ms': {
      // App
      'appTitle': 'Gestura',
      'appTagline': 'Memecah Kesunyian, Membina Jambatan',

      // Navigation
      'navHome': 'Utama',
      'navTranslate': 'Terjemah',
      'navLearn': 'Belajar',
      'navSettings': 'Tetapan',

      // Common actions
      'cancel': 'Batal',
      'save': 'Simpan',
      'back': 'Kembali',
      'next': 'Seterusnya',
      'done': 'Selesai',
      'submit': 'Hantar',
      'retry': 'Cuba Lagi',
      'close': 'Tutup',
      'yes': 'Ya',
      'no': 'Tidak',
      'loading': 'Memuatkan...',
      'error': 'Ada yang tidak kena',
      'search': 'Cari',
      'all': 'Semua',
      'delete': 'Padam',
      'edit': 'Edit',
      'confirm': 'Sahkan',
      'refresh': 'Muat Semula',

      // Auth
      'login': 'Log Masuk',
      'register': 'Daftar',
      'logout': 'Log Keluar',
      'email': 'E-mel',
      'password': 'Kata Laluan',
      'username': 'Nama Pengguna',
      'welcomeBack': 'Selamat Kembali!',
      'createAccount': 'Cipta Akaun',
      'forgotPassword': 'Lupa Kata Laluan?',
      'loginSubtitle': 'Log masuk untuk terus belajar',
      'registerSubtitle': 'Sertai komuniti Gestura',
      'alreadyHaveAccount': 'Sudah ada akaun? Log masuk',
      'dontHaveAccount': 'Tiada akaun? Daftar',
      'orContinueWith': 'Atau teruskan dengan',

      // Learn tab
      'learnTitle': 'Belajar',
      'lessonCategories': 'Kategori Pelajaran',
      'signs': 'isyarat',
      'completed': 'selesai',
      'continueLabel': 'Teruskan',
      'startLearning': 'Mula Belajar',

      // Quiz tab
      'quizTitle': 'Kuiz',
      'chooseQuizType': 'Pilih Jenis Kuiz',
      'recentScores': 'Skor Terkini',
      'signToText': 'Isyarat ke Teks',
      'signToTextDesc': 'Tonton dan kenal pasti',
      'textToSign': 'Teks ke Isyarat',
      'textToSignDesc': 'Cari isyarat yang betul',
      'timedChallenge': 'Cabaran Masa',
      'timedChallengeDesc': 'Kalahkan jam',
      'spellingQuiz': 'Kuiz Ejaan',
      'spellingQuizDesc': 'Ejakan perkataan',
      'fillInBlank': 'Isi Tempat Kosong',
      'fillInBlankDesc': 'Taip jawapan',
      'typeYourAnswer': 'Taip jawapan anda...',
      'questions': 'soalan',
      'notPlayedYet': 'Belum dimainkan',
      'bestScore': 'Terbaik',
      'noQuizzesYet': 'Belum ada kuiz dimainkan',
      'completeQuizPrompt': 'Selesaikan kuiz untuk melihat skor anda di sini',

      // Quiz screen
      'whatSignIsThis': 'Apakah isyarat ini?',
      'whichSignMeans': 'Isyarat mana yang bermaksud',
      'pickCorrectSign': 'Pilih isyarat yang betul di bawah',
      'whatWordSpelled': 'Apakah perkataan yang dieja?',
      'timeUp': 'Masa Tamat!',
      'correctAnswer': 'Jawapan Betul',
      'hintLabel': 'Petunjuk',
      'submitAnswer': 'Hantar Jawapan',
      'nextQuestion': 'Soalan Seterusnya',
      'finishQuiz': 'Tamatkan Kuiz',
      'quitQuiz': 'Keluar Kuiz?',
      'quitQuizMessage': 'Kemajuan anda akan hilang. Adakah anda pasti mahu keluar?',

      // Quiz result
      'quizComplete': 'Kuiz Selesai!',
      'greatJob': 'Bagus Sekali!',
      'keepPracticing': 'Teruskan Berlatih!',
      'score': 'Skor',
      'correct': 'Betul',
      'wrong': 'Salah',
      'xpEarned': 'XP Diperoleh',
      'perfectScore': 'Skor Sempurna!',
      'reviewMistakes': 'Semak Kesilapan',
      'tryAgain': 'Cuba Lagi',
      'backToHome': 'Kembali ke Utama',

      // Progress tab
      'progressTitle': 'Kemajuan',
      'overallProgress': 'Kemajuan Keseluruhan',
      'weeklyActivity': 'Aktiviti Mingguan',
      'dailyStreak': 'Rentetan Harian',
      'days': 'hari',
      'lessonsCompleted': 'Pelajaran Selesai',
      'quizzesCompleted': 'Kuiz Selesai',
      'totalXP': 'Jumlah XP',
      'averageAccuracy': 'Ketepatan Kuiz',

      // Badges tab
      'badgesTitle': 'Lencana',
      'noBadgesYet': 'Belum ada lencana',
      'keepLearning': 'Teruskan belajar untuk mendapat lencana!',
      'badgeUnlocked': 'Lencana Dibuka!',

      // Settings
      'settingsTitle': 'Tetapan',
      'language': 'Bahasa',
      'selectLanguage': 'Pilih Bahasa',
      'theme': 'Tema',
      'darkMode': 'Mod Gelap',
      'lightMode': 'Mod Cerah',
      'systemDefault': 'Lalai Sistem',
      'notifications': 'Pemberitahuan',
      'signLanguage': 'Bahasa Isyarat',
      'account': 'Akaun',
      'appearance': 'Penampilan',
      'appVersion': 'Versi Aplikasi',
      'privacyPolicy': 'Dasar Privasi',
      'termsOfService': 'Terma Perkhidmatan',
      'about': 'Tentang',

      // Profile
      'profileTitle': 'Profil',
      'editProfile': 'Edit Profil',
      'level': 'Tahap',
      'streak': 'Rentetan',
      'joinedLabel': 'Menyertai',

      // Home
      'homeWelcome': 'Selamat kembali',
      'todayChallenge': 'Cabaran Hari Ini',
      'continueLesson': 'Teruskan Pelajaran',
      'leaderboard': 'Papan Pendahulu',
      'seeAll': 'Lihat Semua',

      // Difficulty
      'easy': 'Mudah',
      'medium': 'Sederhana',
      'hard': 'Susah',
      'beginner': 'Pemula',
      'intermediate': 'Pertengahan',
      'advanced': 'Lanjutan',

      // Quiz screen extras
      'noQuestionsAvailable': 'Tiada soalan tersedia',
      'selectAnAnswer': 'Pilih jawapan',
      'seeResults': 'Lihat Keputusan',
      'correctAnswerIs': 'Jawapan betul',
      'yourAnswer': 'Jawapan anda',
      'timeSpent': 'Masa Digunakan',
      'quit': 'Keluar',
      'reviewWrongAnswers': 'Semak Kesilapan',
      'lightningFastFeedback': '⚡ Pantas sekali!',
      'fastFeedback': '✓ Pantas!',
      'correctFeedback': '✓ Betul!',
      'wrongFeedback': '✗ Salah! Jawapan:',
      'quickStart': 'Mula Pantas',

      // Result screen performance labels
      'perfectScoreLabel': 'Skor Sempurna!',
      'excellent': 'Cemerlang!',
      'goodEffort': 'Usaha Bagus!',
      'perfectScoreMsg': 'Anda betulkan semua isyarat! Luar biasa!',
      'excellentMsg': 'Hampir sempurna! Prestasi cemerlang!',
      'greatJobMsg': 'Anda lulus! Semak yang terlepas.',
      'goodEffortMsg': 'Anda semakin baik! Semak kesilapan di bawah.',
      'keepPracticingMsg': 'Semak isyarat di bawah dan cuba lagi!',

      // Auth extras
      'fullName': 'Nama Penuh',
      'enterFullName': 'Masukkan nama penuh anda',
      'enterEmail': 'Masukkan e-mel anda',
      'enterPassword': 'Masukkan kata laluan anda',
      'createPassword': 'Cipta kata laluan',
      'confirmPassword': 'Sahkan Kata Laluan',
      'confirmPasswordHint': 'Masukkan semula kata laluan',
      'iAmA': 'Saya adalah...',
      'signIn': 'Log Masuk',
      'signUp': 'Daftar',
      'joinCommunity': 'Sertai komuniti bahasa isyarat kami',

      // Validation
      'pleaseEnterName': 'Sila masukkan nama anda',
      'pleaseEnterEmail': 'Sila masukkan e-mel anda',
      'pleaseEnterValidEmail': 'Sila masukkan e-mel yang sah',
      'pleaseEnterPassword': 'Sila masukkan kata laluan anda',
      'passwordMinLength': 'Kata laluan mestilah sekurang-kurangnya 6 aksara',
      'pleaseConfirmPassword': 'Sila sahkan kata laluan anda',
      'passwordsDoNotMatch': 'Kata laluan tidak sepadan',

      // Quiz list
      'noQuizzesAvailable': 'Tiada kuiz tersedia',
      'checkBackLater': 'Kembali semula untuk kuiz baru',

      // Learn tab section headers
      'lessonProgress': 'Kemajuan Pelajaran',
      'quizAccuracy': 'Ketepatan Kuiz',
      'practiceMore': 'Teruskan berlatih!',

      // Settings sections
      'general': 'UMUM',
      'preferences': 'KEUTAMAAN',
      'adminSection': 'ADMIN',
      'accountSection': 'AKAUN',
      'notificationSettings': 'Tetapan Pemberitahuan',
      'soundEffects': 'Kesan Bunyi',
      'vibration': 'Getaran',
      'autoUseFreeze': 'Guna Beku Secara Auto',
      'dark': 'Gelap',
      'light': 'Cerah',
      'system': 'Sistem',
      'adminPanel': 'Panel Admin',
      'shareProgress': 'Kongsi Kemajuan',
      'logOut': 'Log Keluar',
      'logOutQuestion': 'Log Keluar?',
      'logOutMessage': 'Adakah anda pasti mahu log keluar?',
      'changeProfilePicture': 'Tukar Gambar Profil',
      'takePhoto': 'Ambil Foto',
      'chooseFromGallery': 'Pilih dari Galeri',
      'removePhoto': 'Buang Foto',
      'buyStreakFreeze': 'Beli Beku Rentetan?',
      'streakFreezeDesc': 'Lindungi rentetan anda selama sehari jika anda terlepas pelajaran.',
      'cost': 'Kos:',
      'youHave': 'Anda ada:',
      'buyFreeze': 'Beli Beku',
      'selectSignLanguage': 'Pilih Bahasa Isyarat',
      'aboutVersion': 'Versi 1.0.0',
      'aboutDescription': 'Gestura adalah aplikasi pembelajaran bahasa isyarat yang direka untuk membantu anda berkomunikasi lebih baik melalui bahasa isyarat.',
      'aboutCopyright': '© 2025 Pasukan Gestura',
      'uploading': 'Memuat naik...',
      'profileSavedCloud': '✓ Gambar profil disimpan ke awan',
      'profileSavedLocally': '✓ Gambar profil disimpan secara tempatan',
      'profilePhotoRemoved': '✓ Foto profil dibuang',
      'streakFreezePurchased': '✓ Beku rentetan dibeli!',
      'purchaseFailed': 'Pembelian gagal',
      'dayStreakLabel': 'Hari Berturut',
      'badgesLabel': 'Lencana',

      // Badges screen
      'yourCollection': 'Koleksi Anda',
      'allBadgesTab': 'Semua Lencana',
      'unlockedTab': 'Terbuka',
      'noBadgesEmpty': 'Belum ada lencana',
      'earnBadgesPrompt': 'Selesaikan pelajaran dan kuiz untuk mendapat lencana!',
      'badgeLearning': 'Pembelajaran',
      'badgeStreaks': 'Rentetan',
      'badgeQuizzes': 'Kuiz',
      'badgeSocial': 'Sosial',
      'badgeMilestones': 'Pencapaian',
      'badgeSpecial': 'Khas',
      'tierBronze': 'Gangsa',
      'tierSilver': 'Perak',
      'tierGold': 'Emas',
      'tierPlatinum': 'Platinum',

      // Profile extras
      'myProfile': 'Profil Saya',
      'myStats': 'Statistik Saya',
      'profileUpdated': 'Profil berjaya dikemas kini!',
      'preferredSignLanguage': 'Bahasa Isyarat Pilihan',
      'noUserData': 'Tiada data pengguna',

      // Dashboard
      'goodMorning': 'Selamat Pagi,',
      'goodAfternoon': 'Selamat Tengah Hari,',
      'goodEvening': 'Selamat Petang,',
      'welcomeBackExclaim': 'Selamat kembali! ',
      'quickActions': 'Tindakan Pantas',
      'realTimeTranslation': 'Terjemahan isyarat masa nyata',
      'interactiveLessons': 'Pelajaran interaktif',
      'testKnowledge': 'Uji pengetahuan anda',
      'trackStats': 'Jejaki statistik anda',
      'competeConnect': 'Bersaing & Berhubung',
      'competeGlobally': 'Bersaing secara global',
      'friends': 'Kawan',
      'connectCompare': 'Hubungi & bandingkan',
      'dailyChallenges': 'Cabaran Harian',
      'challengesBonusXP': 'Selesaikan cabaran untuk XP bonus',
      'activeLabel': 'Aktif',
      'recentActivity': 'Aktiviti Terkini',
      'viewAll': 'Lihat Semua',
      'noActivityYet': 'Belum ada aktiviti',
      'startLearningProgress': 'Mula belajar untuk lihat kemajuan anda!',
      'todaysProgress': 'Kemajuan Hari Ini',
      'noDailyChallenges': 'Tiada cabaran harian tersedia',
      'justNow': 'Baru sahaja',
      'minAgo': 'minit lalu',
      'hoursAgo': 'jam lalu',
      'yesterday': 'Semalam',
      'daysAgoLabel': 'hari lalu',
      'signsLabel': 'Isyarat',
      'completedActivity': 'Selesai',
      'startedActivity': 'Dimulakan',
      'lessonActivity': 'Pelajaran',

      // Quiz home screen
      'quizHeaderSubtitle': 'Ambil kuiz dan dapatkan XP!',
      'today': 'Hari ini',
      'signToTextFullDesc': 'Lihat isyarat dan pilih maknanya',
      'textToSignFullDesc': 'Baca perkataan dan pilih isyarat yang betul',
      'timedChallengeFullDesc': 'Lumba menentang jam, 10s setiap isyarat',
      'spellingQuizFullDesc': 'Nyahkod perkataan ejaan jari huruf demi huruf',
      'fillInBlankFullDesc': 'Lihat gambar isyarat dan taip perkataan yang diwakilinya',
      'bonusXP': '+50 XP Bonus',

      // Admin panel
      'overview': 'Gambaran Keseluruhan',
      'manage': 'Urus',
      'welcomeAdmin': 'Selamat Datang, Admin!',
      'administrator': 'Pentadbir',
      'adminContentDesc': 'Urus kandungan aplikasi anda di sini',
      'totalUsers': 'Jumlah Pengguna',
      'categories': 'Kategori',
      'lessons': 'Pelajaran',
      'quizzes': 'Kuiz',
      'users': 'Pengguna',
      'viewManageUsers': 'Lihat dan urus pengguna',
      'addEditDeleteCategories': 'Tambah, edit, padam kategori',
      'manageLessonContent': 'Urus kandungan pelajaran',
      'createManageQuizzes': 'Cipta dan urus kuiz',
      'manageChallengesDesc': 'Urus cabaran harian/mingguan',
      'manageAchievementBadges': 'Urus lencana pencapaian',
      'signLibrary': 'Perpustakaan Isyarat',
      'viewDeleteUploadSigns': 'Lihat, Padam & Muat Naik Isyarat',
      'learningPaths': 'Laluan Pembelajaran',
      'seedPathsFromLessons': 'Jana laluan dari pelajaran sedia ada',
      'seedQuizzes': 'Jana Kuiz',
      'generate3QuizzesPerType': 'Jana 3 kuiz untuk setiap jenis kuiz',
      'addCategory': 'Tambah Kategori',
      'addLesson': 'Tambah Pelajaran',

      // Forgot password
      'forgotPasswordSubtitle': 'Tiada masalah! Masukkan alamat e-mel anda dan kami akan menghantar pautan untuk menetapkan semula kata laluan anda.',
      'sendResetLink': 'Hantar Pautan Tetapan Semula',
      'backToSignIn': 'Kembali ke Log Masuk',
      'emailSent': 'E-mel Dihantar!',
      'emailSentDesc': 'Kami telah menghantar pautan tetapkan semula kata laluan ke',
      'didntReceive': 'Tidak terima? Cuba lagi',

      // Onboarding
      'skip': 'Langkau',
      'getStarted': 'Mulakan',
      'onboardingTitle1': 'Selamat Datang ke Gestura',
      'onboardingSubtitle1': 'Belajar bahasa isyarat melalui pelajaran interaktif, kuiz, dan terjemahan masa nyata.',
      'onboardingTitle2': 'Pelajaran Interaktif',
      'onboardingSubtitle2': 'Kuasai isyarat langkah demi langkah dengan tutorial video, latihan amali, dan maklum balas segera.',
      'onboardingTitle3': 'Jejaki Kemajuan Anda',
      'onboardingSubtitle3': 'Kumpul XP, buka lencana, kekalkan rentetan, dan saksikan kemahiran anda berkembang setiap hari.',
      'onboardingTitle4': 'Terjemahan Masa Nyata',
      'onboardingSubtitle4': 'Gunakan kamera anda untuk menterjemah isyarat kepada teks atau taip teks untuk melihat demonstrasi isyarat.',

      // Preference screen
      'preferencesTitle': 'Keutamaan',
      'chooseSignLanguage': 'Pilih Bahasa Isyarat Anda',
      'dailyLearningGoal': 'Sasaran Pembelajaran Harian',
      'experienceLevel': 'Tahap Pengalaman Anda',
      'selectAllOptions': 'Pilih Semua Pilihan',
      'casualLearning': 'Pembelajaran Santai',
      'regularPractice': 'Latihan Tetap',
      'intensiveStudy': 'Pengajian Intensif',
      'completeBeginner': 'Pemula Sepenuhnya',
      'knowSomeSigns': 'Tahu Beberapa Isyarat',

      // Translate screen
      'signToTextTab': 'Isyarat → Teks',
      'textToSignTab': 'Teks → Isyarat',
      'translationOutput': 'OUTPUT TERJEMAHAN',
      'aslToEnglish': 'BIM → Bahasa',
      'waitingForGestures': 'Menunggu isyarat...',
      'speak': 'Sebut',
      'copy': 'Salin',
      'clear': 'Kosongkan',
      'enterText': 'MASUKKAN TEKS',
      'typeWordSentence': 'Taip perkataan atau ayat...',
      'listening': 'Mendengar...',
      'voice': 'Suara',
      'translateBtn': 'Terjemah',
      'currentSign': 'ISYARAT SEMASA',
      'englishToMsl': 'Inggeris → BIM',
      'typeSomethingToSee': 'Taip sesuatu untuk melihat animasi ML',
      'startCamera': 'Mulakan Kamera',
      'stopCamera': 'Hentikan Kamera',
      'pointCameraAtSigns': 'Arahkan kamera anda ke isyarat bahasa isyarat untuk menterjemahnya secara masa nyata',
      'cameraActive': 'Kamera Aktif',
      'showSignToTranslate': 'Tunjukkan isyarat untuk diterjemah',
      'readyToTranslate': 'Sedia untuk menterjemah',
      'translating': 'Menterjemah...',
      'copiedToClipboard': '✓ Disalin ke papan klip',
      'micAccessDenied': 'Akses mikrofon dinafikan atau tidak tersedia',
      'speakSign': 'Sebut Isyarat',

      // Notifications screen
      'readAll': 'Baca Semua',
      'clearAll': 'Kosongkan Semua',
      'clearAllNotifications': 'Kosongkan Semua Pemberitahuan',
      'clearAllConfirm': 'Adakah anda pasti mahu memadamkan semua pemberitahuan?',
      'allMarkedRead': 'Semua pemberitahuan ditanda sebagai dibaca',
      'allNotificationsCleared': 'Semua pemberitahuan dikosongkan',
      'noNotifications': 'Tiada Pemberitahuan',
      'allCaughtUp': 'Anda sudah selesai! Kembali semula nanti.',

      // Notification settings
      'pushNotifications': 'Pemberitahuan Tolak',
      'receiveImportantUpdates': 'Anda akan menerima kemas kini penting',
      'notificationsDisabled': 'Pemberitahuan dilumpuhkan',
      'notificationTypes': 'Jenis Pemberitahuan',
      'streakReminders': 'Peringatan Rentetan',
      'dontLoseStreak': 'Jangan kehilangan rentetan pembelajaran anda',
      'dailyGoalsNotif': 'Sasaran Harian',
      'remindersToComplete': 'Peringatan untuk mencapai sasaran anda',
      'achievementsNotif': 'Pencapaian',
      'whenUnlockBadges': 'Apabila anda membuka lencana baru',
      'challengesNotif': 'Cabaran',
      'newChallengesCompletions': 'Cabaran baru dan penyelesaian',
      'dailyReminderTime': 'Masa Peringatan Harian',
      'reminderTime': 'Masa Peringatan',
      'whenToSendReminders': 'Bila untuk menghantar peringatan harian',
      'testNotifications': 'Uji Pemberitahuan',
      'sendTestNotification': 'Hantar Pemberitahuan Ujian',
      'testNotificationSent': 'Pemberitahuan ujian dihantar!',

      // Theme settings
      'currentTheme': 'Tema Semasa',
      'chooseTheme': 'Pilih Tema',
      'brightAndClear': 'Cerah dan jelas',
      'easyOnEyes': 'Selesa di mata',
      'matchDeviceSettings': 'Sepadan dengan tetapan peranti',
      'proTip': 'Tip Pro',
      'darkModeReduceStrain': 'Mod gelap boleh membantu mengurangkan ketegangan mata dalam persekitaran cahaya rendah.',

      // Leaderboard
      'globalRanking': 'Kedudukan Global',
      'friendsRanking': 'Kedudukan Kawan',
      'global': 'Global',
      'weekly': 'Mingguan',
      'monthly': 'Bulanan',
      'allTime': 'Sepanjang Masa',
      'noRankingsYet': 'Belum ada kedudukan',
      'startLearningLeaderboard': 'Mula belajar untuk muncul di papan pendahulu!',
      'addFriendsCompete': 'Tambah kawan untuk bersaing dengan mereka!',
      'findFriends': 'Cari Kawan',
      'youLabel': 'ANDA',
      'streakStat': 'hari berturut',
      'signsStat': 'isyarat',

      // Friends screen
      'friendsTab': 'Kawan',
      'requestsTab': 'Permintaan',
      'findTab': 'Cari',
      'noFriendsYet': 'Belum ada kawan',
      'searchFriendsQr': 'Cari kawan atau kongsi kod QR anda',
      'addFriendsBtn': 'Tambah Kawan',
      'noPendingRequests': 'Tiada permintaan tertunda',
      'requestsWillAppear': 'Permintaan kawan yang anda terima akan muncul di sini',
      'decline': 'Tolak',
      'accept': 'Terima',

      // Add Friend screen
      'addFriendTitle': 'Tambah Kawan',
      'scanQrTab': 'Imbas QR',
      'myQrTab': 'QR Saya',
      'enterCodeTab': 'Masukkan Kod',
      'scanFriendQr': 'Imbas Kod QR Kawan',
      'pointCameraQr': 'Arahkan kamera anda ke kod QR mereka untuk menambah mereka',
      'alignQrFrame': 'Sejajarkan kod QR dalam bingkai',
      'findingUser': 'Mencari pengguna...',
      'letFriendsScan': 'Biarkan kawan mengimbas kod ini untuk menambah anda',
      'myFriendCode': 'Kod Kawan Saya',
      'enterFriendCode': 'Masukkan Kod Kawan',
      'askFriendCode': 'Minta kod kawan anda atau imbas QR mereka',
      'pasteFriendCode': 'Tampal kod kawan di sini',
      'findFriend': 'Cari Kawan',
      'tipsLabel': 'Petua',
      'friendCodeCopied': '✅ Kod kawan disalin!',
      'invalidQrFormat': '❌ Format kod QR tidak sah',
      'cameraAccessRequired': 'Akses Kamera Diperlukan',
      'pleaseEnterFriendCode': 'Sila masukkan kod kawan',
      'userNotFound': 'Pengguna tidak ditemui. Semak kod dan cuba lagi.',
      'cannotAddSelf': 'Anda tidak boleh menambah diri sendiri sebagai kawan!',
      'anErrorOccurred': 'Ralat berlaku. Sila cuba lagi.',
      'searchByNameEmail': 'Cari mengikut nama atau emel...',
      'noUsersFound': 'Tiada pengguna dijumpai',
      'tryDifferentSearch': 'Cuba istilah carian yang berbeza',
      'findNewFriends': 'Cari Rakan Baharu',
      'addByQrCode': 'Tambah melalui Kod QR',

      // Friend challenges
      'challengesTab': 'Cabaran',
      'challengeFriend': 'Cabar',
      'sendChallenge': 'Hantar Cabaran',
      'challengeSent': '🏆 Cabaran dihantar!',
      'challengeDeclined': 'Cabaran ditolak',
      'noChallenges': 'Tiada cabaran',
      'noIncomingChallenges': 'Tiada cabaran masuk',
      'challengesWillAppear': 'Cabaran rakan akan muncul di sini',
      'incomingChallenge': 'Cabaran Masuk',
      'outgoingChallenge': 'Cabaran Keluar',
      'challengeFrom': 'Cabaran dari',
      'theyScored': 'Mereka dapat',
      'yourScore': 'Markah anda',
      'beatThisScore': 'Boleh kalahkan',
      'acceptChallenge': 'Terima & Main',
      'declineChallenge': 'Tolak',
      'challengeWon': 'Anda menang! 🎉',
      'challengeLost': 'Mereka menang kali ini',
      'challengeTied': 'Seri! 🤝',
      'challengeExpired': 'Cabaran tamat tempoh',
      'pendingChallenge': 'Menunggu',
      'completedChallenge': 'Selesai',
      'selectQuizType': 'Pilih Jenis Kuiz',
      'challengeMessage': 'Mesej cabaran (pilihan)',
      'challengeMessageHint': 'Boleh kalahkan saya?',
      'sendChallengeDesc': 'Rakan anda ada 3 hari untuk selesaikan kuiz ini dan kalahkan markah anda.',
      'yourCurrentScore': 'Terbaik anda sekarang',

      // Progress screen
      'myProgressTitle': 'Kemajuan Saya',
      'progressOverviewTab': 'Gambaran',
      'progressAchievementsTab': 'Pencapaian',
      'progressHistoryTab': 'Sejarah',
      'detailedStats': 'Statistik Terperinci',
      'dailyGoalsSection': 'Sasaran Harian',
      'monDay': 'Isn',
      'tueDay': 'Sel',
      'wedDay': 'Rab',
      'thuDay': 'Kha',
      'friDay': 'Jum',
      'satDay': 'Sab',
      'sunDay': 'Ahd',

      // Enhanced progress analytics tab
      'xpThisWeek': 'XP Minggu Ini',
      'quizPerformanceLabel': 'Prestasi Kuiz',
      'learningInsights': 'Wawasan Pembelajaran',
      'sessionsThisMonth': 'Sesi bulan ini',
      'avgPerActiveDay': 'Purata setiap hari aktif',
      'mostActiveDayLabel': 'Hari paling aktif',
      'overallAccuracyLabel': 'Ketepatan keseluruhan',
      'longestStreakLabel': 'Rentetan terpanjang',
      'totalQuizzesLabel': 'Jumlah kuiz',
      'noQuizzesYetAnalytics': 'Belum ada kuiz',
      'analyticsTab': 'Analitik',
      'activityTab': 'Aktiviti',
      'achievementsTab': 'Pencapaian',
      'categoryProgressLabel': 'Kemajuan Kategori',
      'streakCalendarLabel': 'Kalendar Rentetan',
      'dayStreakLabel2': 'hari berturut',
      'thisWeek': 'Minggu Ini',
      'xpLabel': 'XP',
      'lessonsLabel': 'pelajaran',
      'perDayLabel': 'setiap hari',
      'overviewTabLabel': 'Gambaran Keseluruhan',
      'totalLabel': 'Jumlah',
      'averageLabel': 'Purata',
      'bestLabel': 'Terbaik',
      'noCategoriesYet': 'Belum ada kategori',
      'yourBadges': 'Lencana Anda',
      'badgeCollection': 'Koleksi Lencana',
      'bronzeTier': 'Gangsa',
      'silverTier': 'Perak',
      'goldTier': 'Emas',
      'platinumTier': 'Platinum',
      'dailyAvgLabel': 'Purata harian',
      'bestDayLabel': 'Hari terbaik',
      'notPlayed': 'Tidak dimainkan',
      'spellingQuizType': 'Ejaan',
      'timedQuizType': 'Berwaktu',
      'monthJanuary': 'Januari',
      'monthFebruary': 'Februari',
      'monthMarch': 'Mac',
      'monthApril': 'April',
      'monthMay': 'Mei',
      'monthJune': 'Jun',
      'monthJuly': 'Julai',
      'monthAugust': 'Ogos',
      'monthSeptember': 'September',
      'monthOctober': 'Oktober',
      'monthNovember': 'November',
      'monthDecember': 'Disember',
      'signsLearned': 'Tanda Dipelajari',
      'totalLearningTime': 'Jumlah Masa Belajar',
      'perfectQuizzes': 'Kuiz Sempurna',
      'hoursLabel': 'jam',
      'daysLabel': 'hari',
      'xpToLevel': 'XP ke Tahap',
      'noGoalsToday': 'Tiada sasaran ditetapkan untuk hari ini',
      'noAchievementsEarned': 'Belum ada pencapaian yang diperoleh',
      'noLearningHistory': 'Tiada sejarah pembelajaran lagi',
      'completeLessonsHistory': 'Selesaikan pelajaran untuk melihat sejarah anda di sini',
      'inProgressLabel': 'Sedang Berlangsung',
      'lessonLabel': 'Pelajaran',
      'earnedLabel': 'Diperoleh',
      'lockedLabel': 'Terkunci',

      'noLessonsYet': 'Belum ada pelajaran',
      'masterSignLanguage': 'Kuasai bahasa isyarat langkah demi langkah',
      'noPathsAvailable': 'Tiada laluan tersedia',
      'reviewPath': 'Semak Laluan',
      'continueLearning': 'Teruskan Pembelajaran',
      'startJourney': 'Mulakan Perjalanan',
      'yourProgress': 'Kemajuan Anda',
      'learningJourney': 'Perjalanan Pembelajaran',
      'retryLabel': 'Cuba Semula',
      'progressLabel': 'Kemajuan',
      'defaultLearningPath': 'Laluan Pembelajaran',
      'completedExclamation': 'Selesai! 🎉',
      'signToTextQuiz': 'Isyarat ke Teks',
      'textToSignQuiz': 'Teks ke Isyarat',
      'quizLabel': 'Kuiz',

      // Category lessons certificate
      'generatingCertificate': 'Jana Sijil...',
      'completeLessonsForCert': 'Selesaikan pelajaran untuk mendapat sijil',
      'getCompletionCertificate': 'Dapatkan Sijil Penyelesaian 🎓',
      'allLessonsCompleted': '🎉 Semua pelajaran selesai!',
      'errorGeneratingCertificate': 'Ralat menjana sijil',
      'shareProgressCertificate': 'Kongsi Sijil Kemajuan',

      // Learning paths
      'failedLoadPaths': 'Gagal memuatkan laluan pembelajaran',
    },
  };

  // ── Accessor ───────────────────────────────────────────────────────────────

  String _t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['en']![key] ?? key;

  // App
  String get appTitle => _t('appTitle');
  String get appTagline => _t('appTagline');

  // Navigation
  String get navHome => _t('navHome');
  String get navTranslate => _t('navTranslate');
  String get navLearn => _t('navLearn');
  String get navSettings => _t('navSettings');

  // Common actions
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get back => _t('back');
  String get next => _t('next');
  String get done => _t('done');
  String get submit => _t('submit');
  String get retry => _t('retry');
  String get close => _t('close');
  String get yes => _t('yes');
  String get no => _t('no');
  String get loading => _t('loading');
  String get error => _t('error');
  String get search => _t('search');
  String get all => _t('all');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get confirm => _t('confirm');
  String get refresh => _t('refresh');

  // Auth
  String get login => _t('login');
  String get register => _t('register');
  String get logout => _t('logout');
  String get email => _t('email');
  String get password => _t('password');
  String get username => _t('username');
  String get welcomeBack => _t('welcomeBack');
  String get createAccount => _t('createAccount');
  String get forgotPassword => _t('forgotPassword');
  String get loginSubtitle => _t('loginSubtitle');
  String get registerSubtitle => _t('registerSubtitle');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get dontHaveAccount => _t('dontHaveAccount');
  String get orContinueWith => _t('orContinueWith');

  // Learn
  String get learnTitle => _t('learnTitle');
  String get lessonCategories => _t('lessonCategories');
  String get signs => _t('signs');
  String get completed => _t('completed');
  String get continueLabel => _t('continueLabel');
  String get startLearning => _t('startLearning');

  // Quiz
  String get quizTitle => _t('quizTitle');
  String get chooseQuizType => _t('chooseQuizType');
  String get recentScores => _t('recentScores');
  String get signToText => _t('signToText');
  String get signToTextDesc => _t('signToTextDesc');
  String get textToSign => _t('textToSign');
  String get textToSignDesc => _t('textToSignDesc');
  String get timedChallenge => _t('timedChallenge');
  String get timedChallengeDesc => _t('timedChallengeDesc');
  String get spellingQuiz => _t('spellingQuiz');
  String get spellingQuizDesc => _t('spellingQuizDesc');
  String get fillInBlank => _t('fillInBlank');
  String get fillInBlankDesc => _t('fillInBlankDesc');
  String get typeYourAnswer => _t('typeYourAnswer');
  String get questions => _t('questions');
  String get notPlayedYet => _t('notPlayedYet');
  String get bestScore => _t('bestScore');
  String get noQuizzesYet => _t('noQuizzesYet');
  String get completeQuizPrompt => _t('completeQuizPrompt');

  // Quiz screen
  String get whatSignIsThis => _t('whatSignIsThis');
  String get timeUp => _t('timeUp');
  String get correctAnswer => _t('correctAnswer');
  String get hintLabel => _t('hintLabel');
  String get submitAnswer => _t('submitAnswer');
  String get nextQuestion => _t('nextQuestion');
  String get finishQuiz => _t('finishQuiz');
  String get quitQuiz => _t('quitQuiz');
  String get quitQuizMessage => _t('quitQuizMessage');

  // Quiz result
  String get quizComplete => _t('quizComplete');
  String get greatJob => _t('greatJob');
  String get keepPracticing => _t('keepPracticing');
  String get score => _t('score');
  String get correct => _t('correct');
  String get wrong => _t('wrong');
  String get xpEarned => _t('xpEarned');
  String get perfectScore => _t('perfectScore');
  String get reviewMistakes => _t('reviewMistakes');
  String get tryAgain => _t('tryAgain');
  String get backToHome => _t('backToHome');

  // Progress
  String get progressTitle => _t('progressTitle');
  String get overallProgress => _t('overallProgress');
  String get weeklyActivity => _t('weeklyActivity');
  String get dailyStreak => _t('dailyStreak');
  String get days => _t('days');
  String get lessonsCompleted => _t('lessonsCompleted');
  String get quizzesCompleted => _t('quizzesCompleted');
  String get totalXP => _t('totalXP');
  String get averageAccuracy => _t('averageAccuracy');

  // Badges
  String get badgesTitle => _t('badgesTitle');
  String get noBadgesYet => _t('noBadgesYet');
  String get keepLearning => _t('keepLearning');
  String get badgeUnlocked => _t('badgeUnlocked');

  // Settings
  String get settingsTitle => _t('settingsTitle');
  String get language => _t('language');
  String get selectLanguage => _t('selectLanguage');
  String get theme => _t('theme');
  String get darkMode => _t('darkMode');
  String get lightMode => _t('lightMode');
  String get systemDefault => _t('systemDefault');
  String get notifications => _t('notifications');
  String get signLanguage => _t('signLanguage');
  String get account => _t('account');
  String get appearance => _t('appearance');
  String get appVersion => _t('appVersion');
  String get privacyPolicy => _t('privacyPolicy');
  String get termsOfService => _t('termsOfService');
  String get about => _t('about');

  // Profile
  String get profileTitle => _t('profileTitle');
  String get editProfile => _t('editProfile');
  String get level => _t('level');
  String get streak => _t('streak');
  String get joinedLabel => _t('joinedLabel');

  // Home
  String get homeWelcome => _t('homeWelcome');
  String get todayChallenge => _t('todayChallenge');
  String get continueLesson => _t('continueLesson');
  String get leaderboard => _t('leaderboard');
  String get seeAll => _t('seeAll');

  // Difficulty
  String get easy => _t('easy');
  String get medium => _t('medium');
  String get hard => _t('hard');
  String get beginner => _t('beginner');
  String get intermediate => _t('intermediate');
  String get advanced => _t('advanced');

  // Quiz screen extras
  String get noQuestionsAvailable => _t('noQuestionsAvailable');
  String get selectAnAnswer => _t('selectAnAnswer');
  String get seeResults => _t('seeResults');
  String get whichSignMeans => _t('whichSignMeans');
  String get pickCorrectSign => _t('pickCorrectSign');
  String get correctAnswerIs => _t('correctAnswerIs');
  String get yourAnswer => _t('yourAnswer');
  String get timeSpent => _t('timeSpent');
  String get quit => _t('quit');
  String get reviewWrongAnswers => _t('reviewWrongAnswers');
  String get whatWordSpelled => _t('whatWordSpelled');
  String get lightningFastFeedback => _t('lightningFastFeedback');
  String get fastFeedback => _t('fastFeedback');
  String get correctFeedback => _t('correctFeedback');
  String get wrongFeedback => _t('wrongFeedback');
  String get quickStart => _t('quickStart');

  // Result performance labels
  String get perfectScoreLabel => _t('perfectScoreLabel');
  String get excellent => _t('excellent');
  String get goodEffort => _t('goodEffort');
  String get perfectScoreMsg => _t('perfectScoreMsg');
  String get excellentMsg => _t('excellentMsg');
  String get greatJobMsg => _t('greatJobMsg');
  String get goodEffortMsg => _t('goodEffortMsg');
  String get keepPracticingMsg => _t('keepPracticingMsg');

  // Auth extras
  String get fullName => _t('fullName');
  String get enterFullName => _t('enterFullName');
  String get enterEmail => _t('enterEmail');
  String get enterPassword => _t('enterPassword');
  String get createPassword => _t('createPassword');
  String get confirmPassword => _t('confirmPassword');
  String get confirmPasswordHint => _t('confirmPasswordHint');
  String get iAmA => _t('iAmA');
  String get signIn => _t('signIn');
  String get signUp => _t('signUp');
  String get joinCommunity => _t('joinCommunity');

  // Validation
  String get pleaseEnterName => _t('pleaseEnterName');
  String get pleaseEnterEmail => _t('pleaseEnterEmail');
  String get pleaseEnterValidEmail => _t('pleaseEnterValidEmail');
  String get pleaseEnterPassword => _t('pleaseEnterPassword');
  String get passwordMinLength => _t('passwordMinLength');
  String get pleaseConfirmPassword => _t('pleaseConfirmPassword');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');

  // Quiz list
  String get noQuizzesAvailable => _t('noQuizzesAvailable');
  String get checkBackLater => _t('checkBackLater');

  // Learn section headers
  String get lessonProgress => _t('lessonProgress');
  String get quizAccuracy => _t('quizAccuracy');
  String get practiceMore => _t('practiceMore');

  // Badges screen
  String get yourCollection => _t('yourCollection');
  String get allBadgesTab => _t('allBadgesTab');
  String get unlockedTab => _t('unlockedTab');
  String get noBadgesEmpty => _t('noBadgesEmpty');
  String get earnBadgesPrompt => _t('earnBadgesPrompt');
  String get badgeLearning => _t('badgeLearning');
  String get badgeStreaks => _t('badgeStreaks');
  String get badgeQuizzes => _t('badgeQuizzes');
  String get badgeSocial => _t('badgeSocial');
  String get badgeMilestones => _t('badgeMilestones');
  String get badgeSpecial => _t('badgeSpecial');
  String get tierBronze => _t('tierBronze');
  String get tierSilver => _t('tierSilver');
  String get tierGold => _t('tierGold');
  String get tierPlatinum => _t('tierPlatinum');

  // Profile extras
  String get myProfile => _t('myProfile');
  String get myStats => _t('myStats');
  String get profileUpdated => _t('profileUpdated');
  String get preferredSignLanguage => _t('preferredSignLanguage');
  String get noUserData => _t('noUserData');

  // Settings sections
  String get general => _t('general');
  String get preferences => _t('preferences');
  String get adminSection => _t('adminSection');
  String get accountSection => _t('accountSection');
  String get notificationSettings => _t('notificationSettings');
  String get soundEffects => _t('soundEffects');
  String get vibration => _t('vibration');
  String get autoUseFreeze => _t('autoUseFreeze');
  String get dark => _t('dark');
  String get light => _t('light');
  String get system => _t('system');
  String get adminPanel => _t('adminPanel');
  String get shareProgress => _t('shareProgress');
  String get logOut => _t('logOut');
  String get logOutQuestion => _t('logOutQuestion');
  String get logOutMessage => _t('logOutMessage');
  String get changeProfilePicture => _t('changeProfilePicture');
  String get takePhoto => _t('takePhoto');
  String get chooseFromGallery => _t('chooseFromGallery');
  String get removePhoto => _t('removePhoto');
  String get buyStreakFreeze => _t('buyStreakFreeze');
  String get streakFreezeDesc => _t('streakFreezeDesc');
  String get cost => _t('cost');
  String get youHave => _t('youHave');
  String get buyFreeze => _t('buyFreeze');
  String get selectSignLanguage => _t('selectSignLanguage');
  String get aboutVersion => _t('aboutVersion');
  String get aboutDescription => _t('aboutDescription');
  String get aboutCopyright => _t('aboutCopyright');
  String get uploading => _t('uploading');
  String get profileSavedCloud => _t('profileSavedCloud');
  String get profileSavedLocally => _t('profileSavedLocally');
  String get profilePhotoRemoved => _t('profilePhotoRemoved');
  String get streakFreezePurchased => _t('streakFreezePurchased');
  String get purchaseFailed => _t('purchaseFailed');
  String get dayStreakLabel => _t('dayStreakLabel');
  String get badgesLabel => _t('badgesLabel');

  // Dashboard
  String get goodMorning => _t('goodMorning');
  String get goodAfternoon => _t('goodAfternoon');
  String get goodEvening => _t('goodEvening');
  String get welcomeBackExclaim => _t('welcomeBackExclaim');
  String get quickActions => _t('quickActions');
  String get realTimeTranslation => _t('realTimeTranslation');
  String get interactiveLessons => _t('interactiveLessons');
  String get testKnowledge => _t('testKnowledge');
  String get trackStats => _t('trackStats');
  String get competeConnect => _t('competeConnect');
  String get competeGlobally => _t('competeGlobally');
  String get friends => _t('friends');
  String get connectCompare => _t('connectCompare');
  String get dailyChallenges => _t('dailyChallenges');
  String get challengesBonusXP => _t('challengesBonusXP');
  String get activeLabel => _t('activeLabel');
  String get recentActivity => _t('recentActivity');
  String get viewAll => _t('viewAll');
  String get noActivityYet => _t('noActivityYet');
  String get startLearningProgress => _t('startLearningProgress');
  String get todaysProgress => _t('todaysProgress');
  String get noDailyChallenges => _t('noDailyChallenges');
  String get justNow => _t('justNow');
  String get minAgo => _t('minAgo');
  String get hoursAgo => _t('hoursAgo');
  String get yesterday => _t('yesterday');
  String get daysAgoLabel => _t('daysAgoLabel');
  String get signsLabel => _t('signsLabel');
  String get completedActivity => _t('completedActivity');
  String get startedActivity => _t('startedActivity');
  String get lessonActivity => _t('lessonActivity');

  // Quiz home screen
  String get quizHeaderSubtitle => _t('quizHeaderSubtitle');
  String get today => _t('today');
  String get signToTextFullDesc => _t('signToTextFullDesc');
  String get textToSignFullDesc => _t('textToSignFullDesc');
  String get timedChallengeFullDesc => _t('timedChallengeFullDesc');
  String get spellingQuizFullDesc => _t('spellingQuizFullDesc');
  String get fillInBlankFullDesc => _t('fillInBlankFullDesc');
  String get bonusXP => _t('bonusXP');

  // Admin panel
  String get overview => _t('overview');
  String get manage => _t('manage');
  String get welcomeAdmin => _t('welcomeAdmin');
  String get administrator => _t('administrator');
  String get adminContentDesc => _t('adminContentDesc');
  String get totalUsers => _t('totalUsers');
  String get categories => _t('categories');
  String get lessonsAdmin => _t('lessons');
  String get quizzesLabel => _t('quizzes');
  String get users => _t('users');
  String get viewManageUsers => _t('viewManageUsers');
  String get addEditDeleteCategories => _t('addEditDeleteCategories');
  String get manageLessonContent => _t('manageLessonContent');
  String get createManageQuizzes => _t('createManageQuizzes');
  String get manageChallengesDesc => _t('manageChallengesDesc');
  String get manageAchievementBadges => _t('manageAchievementBadges');
  String get signLibrary => _t('signLibrary');
  String get viewDeleteUploadSigns => _t('viewDeleteUploadSigns');
  String get learningPaths => _t('learningPaths');
  String get seedPathsFromLessons => _t('seedPathsFromLessons');
  String get seedQuizzes => _t('seedQuizzes');
  String get generate3QuizzesPerType => _t('generate3QuizzesPerType');
  String get addCategory => _t('addCategory');
  String get addLesson => _t('addLesson');

  // Forgot password
  String get forgotPasswordSubtitle => _t('forgotPasswordSubtitle');
  String get sendResetLink => _t('sendResetLink');
  String get backToSignIn => _t('backToSignIn');
  String get emailSent => _t('emailSent');
  String get emailSentDesc => _t('emailSentDesc');
  String get didntReceive => _t('didntReceive');

  // Onboarding
  String get skip => _t('skip');
  String get getStarted => _t('getStarted');
  String get onboardingTitle1 => _t('onboardingTitle1');
  String get onboardingSubtitle1 => _t('onboardingSubtitle1');
  String get onboardingTitle2 => _t('onboardingTitle2');
  String get onboardingSubtitle2 => _t('onboardingSubtitle2');
  String get onboardingTitle3 => _t('onboardingTitle3');
  String get onboardingSubtitle3 => _t('onboardingSubtitle3');
  String get onboardingTitle4 => _t('onboardingTitle4');
  String get onboardingSubtitle4 => _t('onboardingSubtitle4');

  // Preference screen
  String get preferencesTitle => _t('preferencesTitle');
  String get chooseSignLanguage => _t('chooseSignLanguage');
  String get dailyLearningGoal => _t('dailyLearningGoal');
  String get experienceLevel => _t('experienceLevel');
  String get selectAllOptions => _t('selectAllOptions');
  String get casualLearning => _t('casualLearning');
  String get regularPractice => _t('regularPractice');
  String get intensiveStudy => _t('intensiveStudy');
  String get completeBeginner => _t('completeBeginner');
  String get knowSomeSigns => _t('knowSomeSigns');

  // Translate screen
  String get signToTextTab => _t('signToTextTab');
  String get textToSignTab => _t('textToSignTab');
  String get translationOutput => _t('translationOutput');
  String get aslToEnglish => _t('aslToEnglish');
  String get waitingForGestures => _t('waitingForGestures');
  String get speak => _t('speak');
  String get copy => _t('copy');
  String get clear => _t('clear');
  String get enterText => _t('enterText');
  String get typeWordSentence => _t('typeWordSentence');
  String get listening => _t('listening');
  String get voice => _t('voice');
  String get translateBtn => _t('translateBtn');
  String get currentSign => _t('currentSign');
  String get englishToMsl => _t('englishToMsl');
  String get typeSomethingToSee => _t('typeSomethingToSee');
  String get startCamera => _t('startCamera');
  String get stopCamera => _t('stopCamera');
  String get pointCameraAtSigns => _t('pointCameraAtSigns');
  String get cameraActive => _t('cameraActive');
  String get showSignToTranslate => _t('showSignToTranslate');
  String get readyToTranslate => _t('readyToTranslate');
  String get translating => _t('translating');
  String get copiedToClipboard => _t('copiedToClipboard');
  String get micAccessDenied => _t('micAccessDenied');
  String get speakSign => _t('speakSign');

  // Notifications screen
  String get readAll => _t('readAll');
  String get clearAll => _t('clearAll');
  String get clearAllNotifications => _t('clearAllNotifications');
  String get clearAllConfirm => _t('clearAllConfirm');
  String get allMarkedRead => _t('allMarkedRead');
  String get allNotificationsCleared => _t('allNotificationsCleared');
  String get noNotifications => _t('noNotifications');
  String get allCaughtUp => _t('allCaughtUp');

  // Notification settings
  String get pushNotifications => _t('pushNotifications');
  String get receiveImportantUpdates => _t('receiveImportantUpdates');
  String get notificationsDisabled => _t('notificationsDisabled');
  String get notificationTypes => _t('notificationTypes');
  String get streakReminders => _t('streakReminders');
  String get dontLoseStreak => _t('dontLoseStreak');
  String get dailyGoalsNotif => _t('dailyGoalsNotif');
  String get remindersToComplete => _t('remindersToComplete');
  String get achievementsNotif => _t('achievementsNotif');
  String get whenUnlockBadges => _t('whenUnlockBadges');
  String get challengesNotif => _t('challengesNotif');
  String get newChallengesCompletions => _t('newChallengesCompletions');
  String get dailyReminderTime => _t('dailyReminderTime');
  String get reminderTime => _t('reminderTime');
  String get whenToSendReminders => _t('whenToSendReminders');
  String get testNotifications => _t('testNotifications');
  String get sendTestNotification => _t('sendTestNotification');
  String get testNotificationSent => _t('testNotificationSent');

  // Theme settings
  String get currentTheme => _t('currentTheme');
  String get chooseTheme => _t('chooseTheme');
  String get brightAndClear => _t('brightAndClear');
  String get easyOnEyes => _t('easyOnEyes');
  String get matchDeviceSettings => _t('matchDeviceSettings');
  String get proTip => _t('proTip');
  String get darkModeReduceStrain => _t('darkModeReduceStrain');

  // Leaderboard
  String get globalRanking => _t('globalRanking');
  String get friendsRanking => _t('friendsRanking');
  String get global => _t('global');
  String get weekly => _t('weekly');
  String get monthly => _t('monthly');
  String get allTime => _t('allTime');
  String get noRankingsYet => _t('noRankingsYet');
  String get startLearningLeaderboard => _t('startLearningLeaderboard');
  String get addFriendsCompete => _t('addFriendsCompete');
  String get findFriends => _t('findFriends');
  String get youLabel => _t('youLabel');
  String get streakStat => _t('streakStat');
  String get signsStat => _t('signsStat');

  // Friends screen
  String get friendsTab => _t('friendsTab');
  String get requestsTab => _t('requestsTab');
  String get findTab => _t('findTab');
  String get noFriendsYet => _t('noFriendsYet');
  String get searchFriendsQr => _t('searchFriendsQr');
  String get addFriendsBtn => _t('addFriendsBtn');
  String get noPendingRequests => _t('noPendingRequests');
  String get requestsWillAppear => _t('requestsWillAppear');
  String get decline => _t('decline');
  String get accept => _t('accept');

  // Add Friend screen
  String get addFriendTitle => _t('addFriendTitle');
  String get scanQrTab => _t('scanQrTab');
  String get myQrTab => _t('myQrTab');
  String get enterCodeTab => _t('enterCodeTab');
  String get scanFriendQr => _t('scanFriendQr');
  String get pointCameraQr => _t('pointCameraQr');
  String get alignQrFrame => _t('alignQrFrame');
  String get findingUser => _t('findingUser');
  String get letFriendsScan => _t('letFriendsScan');
  String get myFriendCode => _t('myFriendCode');
  String get enterFriendCode => _t('enterFriendCode');
  String get askFriendCode => _t('askFriendCode');
  String get pasteFriendCode => _t('pasteFriendCode');
  String get findFriend => _t('findFriend');
  String get tipsLabel => _t('tipsLabel');
  String get friendCodeCopied => _t('friendCodeCopied');
  String get invalidQrFormat => _t('invalidQrFormat');
  String get cameraAccessRequired => _t('cameraAccessRequired');
  String get pleaseEnterFriendCode => _t('pleaseEnterFriendCode');
  String get userNotFound => _t('userNotFound');
  String get cannotAddSelf => _t('cannotAddSelf');
  String get anErrorOccurred => _t('anErrorOccurred');
  String get searchByNameEmail => _t('searchByNameEmail');
  String get noUsersFound => _t('noUsersFound');
  String get tryDifferentSearch => _t('tryDifferentSearch');
  String get findNewFriends => _t('findNewFriends');
  String get addByQrCode => _t('addByQrCode');

  // Friend challenges
  String get challengesTab => _t('challengesTab');
  String get challengeFriend => _t('challengeFriend');
  String get sendChallenge => _t('sendChallenge');
  String get challengeSent => _t('challengeSent');
  String get challengeDeclined => _t('challengeDeclined');
  String get noChallenges => _t('noChallenges');
  String get noIncomingChallenges => _t('noIncomingChallenges');
  String get challengesWillAppear => _t('challengesWillAppear');
  String get incomingChallenge => _t('incomingChallenge');
  String get outgoingChallenge => _t('outgoingChallenge');
  String get challengeFrom => _t('challengeFrom');
  String get theyScored => _t('theyScored');
  String get yourScore => _t('yourScore');
  String get beatThisScore => _t('beatThisScore');
  String get acceptChallenge => _t('acceptChallenge');
  String get declineChallenge => _t('declineChallenge');
  String get challengeWon => _t('challengeWon');
  String get challengeLost => _t('challengeLost');
  String get challengeTied => _t('challengeTied');
  String get challengeExpired => _t('challengeExpired');
  String get pendingChallenge => _t('pendingChallenge');
  String get completedChallenge => _t('completedChallenge');
  String get selectQuizType => _t('selectQuizType');
  String get challengeMessage => _t('challengeMessage');
  String get challengeMessageHint => _t('challengeMessageHint');
  String get sendChallengeDesc => _t('sendChallengeDesc');
  String get yourCurrentScore => _t('yourCurrentScore');

  // Progress screen
  String get myProgressTitle => _t('myProgressTitle');
  String get progressOverviewTab => _t('progressOverviewTab');
  String get progressAchievementsTab => _t('progressAchievementsTab');
  String get progressHistoryTab => _t('progressHistoryTab');
  String get detailedStats => _t('detailedStats');
  String get dailyGoalsSection => _t('dailyGoalsSection');
  String get monDay => _t('monDay');
  String get tueDay => _t('tueDay');
  String get wedDay => _t('wedDay');
  String get thuDay => _t('thuDay');
  String get friDay => _t('friDay');
  String get satDay => _t('satDay');
  String get sunDay => _t('sunDay');

  // Enhanced progress analytics tab
  String get xpThisWeek => _t('xpThisWeek');
  String get quizPerformanceLabel => _t('quizPerformanceLabel');
  String get learningInsights => _t('learningInsights');
  String get overviewTabLabel => _t('overviewTabLabel');
  String get totalLabel => _t('totalLabel');
  String get averageLabel => _t('averageLabel');
  String get bestLabel => _t('bestLabel');
  String get noCategoriesYet => _t('noCategoriesYet');
  String get yourBadges => _t('yourBadges');
  String get badgeCollection => _t('badgeCollection');
  String get bronzeTier => _t('bronzeTier');
  String get silverTier => _t('silverTier');
  String get goldTier => _t('goldTier');
  String get platinumTier => _t('platinumTier');
  String get dailyAvgLabel => _t('dailyAvgLabel');
  String get bestDayLabel => _t('bestDayLabel');
  String get notPlayed => _t('notPlayed');
  String get spellingQuizType => _t('spellingQuizType');
  String get timedQuizType => _t('timedQuizType');
  String get monthJanuary => _t('monthJanuary');
  String get monthFebruary => _t('monthFebruary');
  String get monthMarch => _t('monthMarch');
  String get monthApril => _t('monthApril');
  String get monthMay => _t('monthMay');
  String get monthJune => _t('monthJune');
  String get monthJuly => _t('monthJuly');
  String get monthAugust => _t('monthAugust');
  String get monthSeptember => _t('monthSeptember');
  String get monthOctober => _t('monthOctober');
  String get monthNovember => _t('monthNovember');
  String get monthDecember => _t('monthDecember');
  String get sessionsThisMonth => _t('sessionsThisMonth');
  String get avgPerActiveDay => _t('avgPerActiveDay');
  String get mostActiveDayLabel => _t('mostActiveDayLabel');
  String get overallAccuracyLabel => _t('overallAccuracyLabel');
  String get longestStreakLabel => _t('longestStreakLabel');
  String get totalQuizzesLabel => _t('totalQuizzesLabel');
  String get noQuizzesYetAnalytics => _t('noQuizzesYetAnalytics');
  String get analyticsTab => _t('analyticsTab');
  String get activityTab => _t('activityTab');
  String get achievementsTab => _t('achievementsTab');
  String get categoryProgressLabel => _t('categoryProgressLabel');
  String get streakCalendarLabel => _t('streakCalendarLabel');
  String get dayStreakLabel2 => _t('dayStreakLabel2');
  String get thisWeek => _t('thisWeek');
  String get xpLabel => _t('xpLabel');
  String get lessonsLabel => _t('lessonsLabel');
  String get perDayLabel => _t('perDayLabel');
  String get signsLearned => _t('signsLearned');
  String get totalLearningTime => _t('totalLearningTime');
  String get perfectQuizzes => _t('perfectQuizzes');
  String get hoursLabel => _t('hoursLabel');
  String get daysLabel => _t('daysLabel');
  String get xpToLevel => _t('xpToLevel');
  String get noGoalsToday => _t('noGoalsToday');
  String get noAchievementsEarned => _t('noAchievementsEarned');
  String get noLearningHistory => _t('noLearningHistory');
  String get completeLessonsHistory => _t('completeLessonsHistory');
  String get inProgressLabel => _t('inProgressLabel');
  String get lessonLabel => _t('lessonLabel');
  String get earnedLabel => _t('earnedLabel');
  String get lockedLabel => _t('lockedLabel');

  String get noLessonsYet => _t('noLessonsYet');
  String get masterSignLanguage => _t('masterSignLanguage');
  String get noPathsAvailable => _t('noPathsAvailable');
  String get reviewPath => _t('reviewPath');
  String get continueLearning => _t('continueLearning');
  String get startJourney => _t('startJourney');
  String get yourProgress => _t('yourProgress');
  String get learningJourney => _t('learningJourney');
  String get retryLabel => _t('retryLabel');
  String get progressLabel => _t('progressLabel');
  String get defaultLearningPath => _t('defaultLearningPath');
  String get completedExclamation => _t('completedExclamation');
  String get signToTextQuiz => _t('signToTextQuiz');
  String get textToSignQuiz => _t('textToSignQuiz');
  String get quizLabel => _t('quizLabel');

  // Category lessons certificate
  String get generatingCertificate => _t('generatingCertificate');
  String get completeLessonsForCert => _t('completeLessonsForCert');
  String get getCompletionCertificate => _t('getCompletionCertificate');
  String get allLessonsCompleted => _t('allLessonsCompleted');
  String get errorGeneratingCertificate => _t('errorGeneratingCertificate');
  String get shareProgressCertificate => _t('shareProgressCertificate');

  // Learning paths
  String get failedLoadPaths => _t('failedLoadPaths');

  // Parametric helpers
  String nLetterWord(int n) {
    if (locale.languageCode == 'ms') return 'perkataan $n huruf';
    return '$n-letter word';
  }

  String correctOutOf(int correct, int total) {
    if (locale.languageCode == 'ms') return '$correct daripada $total betul';
    return '$correct out of $total correct';
  }

  String missedCount(int n) {
    if (locale.languageCode == 'ms') return '$n terlepas';
    return '$n missed';
  }
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
