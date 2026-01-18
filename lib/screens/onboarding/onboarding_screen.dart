import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      emoji: '🤟',
      title: 'Welcome to Gestura',
      subtitle: 'Learn sign language through interactive lessons, quizzes, and real-time translation.',
      backgroundColor: Color(0xFF6366F1),
    ),
    const OnboardingPage(
      emoji: '📚',
      title: 'Interactive Lessons',
      subtitle: 'Master signs step-by-step with video tutorials, practice exercises, and instant feedback.',
      backgroundColor: Color(0xFF8B5CF6),
    ),
    const OnboardingPage(
      emoji: '🎯',
      title: 'Track Your Progress',
      subtitle: 'Earn XP, unlock badges, maintain streaks, and watch your skills grow every day.',
      backgroundColor: Color(0xFFEC4899),
    ),
    const OnboardingPage(
      emoji: '🌐',
      title: 'Real-Time Translation',
      subtitle: 'Use your camera to translate signs to text or type text to see sign demonstrations.',
      backgroundColor: Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pages[_currentPage].backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withAlpha(100),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next/Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Emoji
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 1500.ms,
              ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });
}