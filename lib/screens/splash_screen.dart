import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'main_navigator.dart';  // ← ADD THIS IMPORT

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
          // ← CHANGED: Navigate to MainNavigator instead of DashboardScreen
          return authProvider.isLoggedIn 
              ? const MainNavigator()  // ← THIS HAS THE BOTTOM NAV BAR
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
      backgroundColor: context.bgPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.bgPrimary,
              context.bgSecondary,
              AppColors.primary.withAlpha(25),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(100),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🤟',
                  style: TextStyle(fontSize: 60),
                ),
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
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 10),
            
            // Tagline
            Text(
              'Breaking Silence, Building Bridges',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 60),
            
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withAlpha(180),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}