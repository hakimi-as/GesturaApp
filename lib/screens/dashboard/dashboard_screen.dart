import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/progress_model.dart';
import '../../models/challenge_model.dart';
import '../translate/translate_screen.dart';
import '../learn/learn_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/enhanced_progress_screen.dart';
import '../search/search_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../challenges/challenges_screen.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      // First check if user has photoUrl in Firestore
      if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
        // User has cloud photo - we'll display it via Image.network
        // Just load cached bytes for immediate display
        final imageBase64 = prefs.getString('profileImageBase64');
        if (imageBase64 != null && imageBase64.isNotEmpty && mounted) {
          setState(() {
            _profileImageBytes = base64Decode(imageBase64);
          });
        }
      } else {
        // Fallback to local storage
        final imageBase64 = prefs.getString('profileImageBase64');
        if (imageBase64 != null && imageBase64.isNotEmpty && mounted) {
          setState(() {
            _profileImageBytes = base64Decode(imageBase64);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      await _firestoreService.checkAndResetDailyGoal(authProvider.userId!);
      await authProvider.refreshUser();
      if (mounted) {
        Provider.of<ProgressProvider>(context, listen: false)
            .loadUserProgress(authProvider.userId!);
        
        // Load daily challenges
        final user = authProvider.currentUser;
        if (user != null) {
          Provider.of<ChallengeProvider>(context, listen: false)
              .loadChallenges(authProvider.userId!, user);
        }
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,  // ← CHANGED
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.userId != null) {
              await authProvider.refreshUser();
              await Provider.of<ProgressProvider>(context, listen: false)
                  .loadUserProgress(authProvider.userId!);
            }
            await _loadProfileImage();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildWelcomeCard(context),
                const SizedBox(height: 24),
                _buildQuickActionsSection(context),
                const SizedBox(height: 24),
                _buildCompetitionSection(context),
                const SizedBox(height: 24),
                _buildRecentActivitySection(context),
                const SizedBox(height: 24),
                _buildDailyGoalsSection(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('🤟', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  'Gestura',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,  // ← CHANGED
                      ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.bgCard,  // ← CHANGED
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.search,
                      color: context.textPrimary,  // ← CHANGED
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 24,
                          ),
                        ),
                        // Real-time unread badge
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId', isEqualTo: Provider.of<AuthProvider>(context, listen: false).userId)
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final unreadCount = snapshot.data?.docs.length ?? 0;
                            if (unreadCount == 0) return const SizedBox();
                            
                            return Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    // Reload profile image when returning from profile
                    _loadProfileImage();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: (_profileImageBytes == null && user?.photoUrl == null)
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: user?.photoUrl != null
                          ? Image.network(
                              CloudinaryService.getOptimizedImage(user!.photoUrl!, width: 88, height: 88),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                // Show cached image while loading
                                if (_profileImageBytes != null) {
                                  return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to cached image or initials
                                if (_profileImageBytes != null) {
                                  return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                                }
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user?.initials ?? 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : _profileImageBytes != null
                              ? Image.memory(
                                  _profileImageBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        user?.initials ?? 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    user?.initials ?? 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 500.ms);
      },
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Text(
                        'Welcome back! ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('👋', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildWelcomeStatChip(
                        '🔥',
                        '${user?.currentStreak ?? 0}',
                        'Day Streak',
                      ),
                      const SizedBox(width: 12),
                      _buildWelcomeStatChip(
                        '⭐',
                        _formatNumber(user?.totalXP ?? 0),
                        'Total XP',
                      ),
                      const SizedBox(width: 12),
                      _buildWelcomeStatChip(
                        '🤟',
                        '${user?.signsLearned ?? 0}',
                        'Signs',
                      ),
                    ],
                  ),
                ],
              ),
              const Positioned(
                right: -20,
                top: -20,
                child: Opacity(
                  opacity: 0.15,
                  child: Text(
                    '🤟',
                    style: TextStyle(fontSize: 100),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildWelcomeStatChip(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.translate,
                iconBgColor: const Color(0xFF3B82F6),
                title: 'Translate',
                subtitle: 'Real-time sign translation',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TranslateScreen(showBackButton: true),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.menu_book,
                iconBgColor: const Color(0xFF8B5CF6),
                title: 'Learn',
                subtitle: 'Interactive lessons',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LearnScreen(showBackButton: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.quiz,
                iconBgColor: const Color(0xFFF43F5E),
                title: 'Quiz',
                subtitle: 'Test your knowledge',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LearnScreen(
                        showBackButton: true,
                        initialTabIndex: 1, // Quiz tab
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.bar_chart,
                iconBgColor: const Color(0xFFF59E0B),
                title: 'Progress',
                subtitle: 'Track your stats',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EnhancedProgressScreen()),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,  // ← CHANGED
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),  // ← CHANGED
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconBgColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textMuted,  // ← CHANGED
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Compete & Earn',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 28)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Compete globally',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChallengesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 28)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '3 NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Challenges',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daily & weekly',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<ProgressProvider>(
          builder: (context, progressProvider, child) {
            final progress = progressProvider.progressList;

            if (progress.isEmpty) {
              return _buildEmptyActivityState(context);
            }

            return Column(
              children: progress.take(3).map((item) {
                final title = item.displayTitle.isNotEmpty
                    ? item.displayTitle
                    : 'Lesson';
                final xpEarned = item.xpEarned > 0 ? item.xpEarned : 10;

                // Check if it's a quiz activity
                // Ensure your ProgressModel has these fields or logic matches your data structure
                final isQuiz = item.lessonId.startsWith('quiz_') || 
                             (item is dynamic && item.categoryId == 'quiz'); 

                return _buildActivityItem(
                  context,
                  // Use Target icon for quizzes, Check for completed lessons, Book for started
                  icon: isQuiz ? '🎯' : (item.isCompleted ? '✅' : '📚'),
                  
                  // Pink for quizzes, Green for success, Indigo for learning
                  iconBgColor: isQuiz
                      ? const Color(0xFFEC4899)
                      : (item.isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1)),
                  
                  title: isQuiz
                      ? 'Completed "$title"'
                      : (item.isCompleted
                          ? 'Completed "$title" Lesson'
                          : 'Started "$title" Lesson'),
                  
                  subtitle: _formatTimeAgo(item.lastAccessedAt),
                  xpText: '+$xpEarned XP',
                  xpColor: const Color(0xFF10B981),
                );
              }).toList(),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildEmptyActivityState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,  // ← CHANGED
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Start learning to see your progress!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,  // ← CHANGED
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String xpText,
    required Color xpColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,  // ← CHANGED
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),  // ← CHANGED
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,  // ← CHANGED
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: xpColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              xpText,
              style: TextStyle(
                color: xpColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalsSection(BuildContext context) {
    return Consumer2<AuthProvider, ChallengeProvider>(
      builder: (context, authProvider, challengeProvider, child) {
        final dailyChallenges = challengeProvider.dailyChallenges;
        final totalChallenges = dailyChallenges.length;
        final completedChallenges = dailyChallenges.where((c) => c.isCompleted).length;
        final percentage = totalChallenges > 0 
            ? (completedChallenges / totalChallenges).clamp(0.0, 1.0) 
            : 0.0;

        // If challenges not loaded yet, show loading
        if (challengeProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Challenges',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.borderColor),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Challenges',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChallengesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Progress",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: context.textSecondary,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: completedChallenges == totalChallenges && totalChallenges > 0
                              ? context.success.withAlpha(26)
                              : AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$completedChallenges/$totalChallenges completed',
                          style: TextStyle(
                            color: completedChallenges == totalChallenges && totalChallenges > 0
                                ? context.success
                                : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: context.bgElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completedChallenges == totalChallenges && totalChallenges > 0
                            ? context.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (dailyChallenges.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No daily challenges available',
                        style: TextStyle(color: context.textMuted),
                      ),
                    )
                  else
                    ...dailyChallenges.map((challenge) {
                      return _buildChallengeItem(
                        context,
                        challenge: challenge,
                      );
                    }),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms);
      },
    );
  }

  Widget _buildChallengeItem(
    BuildContext context, {
    required ChallengeModel challenge,
  }) {
    final isCompleted = challenge.isCompleted;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? context.success.withAlpha(30) 
                  : challenge.typeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                challenge.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Challenge info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCompleted ? context.textMuted : context.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${challenge.currentValue}/${challenge.targetValue}',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: challenge.progress,
                          minHeight: 4,
                          backgroundColor: context.bgElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? context.success : challenge.typeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // XP reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? context.success.withAlpha(26) 
                  : AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${challenge.xpReward} XP',
              style: TextStyle(
                color: isCompleted ? context.success : AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Keep the old _buildGoalItem for backward compatibility if needed elsewhere
  Widget _buildGoalItem(
    BuildContext context, {
    required String title,
    required int xpReward,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isCompleted ? context.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? context.success : context.borderColor,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isCompleted ? context.textMuted : context.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
          Text(
            '+$xpReward XP',
            style: TextStyle(
              color: isCompleted ? context.success : AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}