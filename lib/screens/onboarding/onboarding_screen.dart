import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/aurora_scaffold.dart';
import '../../widgets/common/glass_ui.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingData> _pages(AppLocalizations l10n) => [
    _OnboardingData(
      icon: Icons.sign_language_rounded,
      title: l10n.onboardingTitle1,
      subtitle: l10n.onboardingSubtitle1,
    ),
    _OnboardingData(
      icon: Icons.menu_book_rounded,
      title: l10n.onboardingTitle2,
      subtitle: l10n.onboardingSubtitle2,
    ),
    _OnboardingData(
      icon: Icons.track_changes_rounded,
      title: l10n.onboardingTitle3,
      subtitle: l10n.onboardingSubtitle3,
    ),
    _OnboardingData(
      icon: Icons.language_rounded,
      title: l10n.onboardingTitle4,
      subtitle: l10n.onboardingSubtitle4,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(List<_OnboardingData> pages) {
    if (_currentPage < pages.length - 1) {
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
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraScaffold(
        child: SafeArea(
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
                      l10n.skip,
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(pages[index]);
                  },
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? AppColors.primaryGradient
                                : null,
                            color: _currentPage == index
                                ? null
                                : const Color(0xFF1A3030),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Next/Get Started Button
                    GlassPrimaryButton(
                      label: _currentPage == pages.length - 1
                          ? l10n.getStarted
                          : l10n.next,
                      onPressed: () => _nextPage(pages),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glass card with icon
          GlassCard(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                // Icon with teal glow
                TealGradientIcon(icon: page.icon, size: 88)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 1500.ms,
                    ),
                const SizedBox(height: 36),

                // Title
                Text(
                  page.title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                const SizedBox(height: 14),

                // Subtitle
                Text(
                  page.subtitle,
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
