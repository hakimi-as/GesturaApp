import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/aurora_scaffold.dart';
import 'auth/login_screen.dart';
import 'main_navigator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth state to be determined
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return authProvider.isLoggedIn
              ? const MainNavigator()
              : const LoginScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo — teal gradient rounded square with sign icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

              const SizedBox(height: 30),

              // App Name
              Text(
                'Gestura',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: context.textPrimary,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 10),

              // Tagline
              Text(
                'Breaking Silence, Building Bridges',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),

              const SizedBox(height: 60),

              // Loading indicator — teal ring
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.75),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
