import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/challenge_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService().initialize();

  // Check if user has seen onboarding
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(MyApp(
    hasSeenOnboarding: hasSeenOnboarding,
    themeProvider: themeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final ThemeProvider themeProvider;

  const MyApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gestura',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            home: hasSeenOnboarding 
                ? const SplashScreen()  // Shows splash, then goes to MainNavigator or Login
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

// AuthWrapper for cases where we need to check auth without splash
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) {
          return const Scaffold(
            backgroundColor: AppColors.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const MainNavigator();
        }

        return const LoginScreen();
      },
    );
  }
}