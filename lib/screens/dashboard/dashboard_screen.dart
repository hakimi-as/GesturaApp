import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/design_system.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart'; // NEW: Friend Service
import '../../services/app_cache.dart';
import '../../models/challenge_model.dart';
import '../../widgets/common/shimmer_widgets.dart';
import '../../widgets/gamification/streak_freeze_widgets.dart';

import '../translate/translate_screen.dart';
import '../learn/learn_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../challenges/challenges_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/learning/learning_path_widgets.dart';
import '../learn/learning_paths_screen.dart';
import '../social/friends_screen.dart'; // NEW: Friends Screen
import '../badges/badges_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Uint8List? _profileImageBytes;
  bool _isInitialLoading = true;

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? '';

      // Check in-memory cache first (avoids SharedPrefs read + base64 decode)
      final cached = AppCache.instance.getProfileImage(userId);
      if (cached != null && mounted) {
        setState(() => _profileImageBytes = cached);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final imageBase64 = prefs.getString('profileImageBase64');
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        final bytes = base64Decode(imageBase64);
        AppCache.instance.setProfileImage(userId, bytes);
        if (mounted) setState(() => _profileImageBytes = bytes);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      // checkAndResetDailyGoal and refreshUser can run in parallel.
      await Future.wait([
        _firestoreService.checkAndResetDailyGoal(authProvider.userId!),
        authProvider.refreshUser(),
      ]);

      if (mounted) {
        final uid = authProvider.userId!;
        final user = authProvider.currentUser;

        // Fire these off without awaiting — they update UI via notifyListeners.
        Provider.of<ProgressProvider>(context, listen: false).loadUserProgress(uid);
        Provider.of<NotificationProvider>(context, listen: false).loadNotifications(uid);
        if (user != null) {
          Provider.of<ChallengeProvider>(context, listen: false).loadChallenges(uid, user);
        }
      }
    }

    if (mounted) setState(() => _isInitialLoading = false);
  }

  void _showFreezeInfo() {
    HapticService.buttonTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const StreakFreezeModal(),
    );
  }

  void _handleNotificationRoute(String route) {
    Widget? targetScreen;
    switch (route) {
      case '/badges':
        targetScreen = const BadgesScreen();
        break;
      case '/progress':
        targetScreen = const ProgressScreen();
        break;
      case '/challenges':
        targetScreen = const ChallengesScreen();
        break;
      case '/learn':
        targetScreen = const LearnScreen(showBackButton: true);
        break;
      case '/friends':
        targetScreen = const FriendsScreen();
        break;
    }

    if (targetScreen != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetScreen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticService.lightTap();
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.userId == null) return;

            await Future.wait([
              authProvider.refreshUser(),
              Provider.of<ProgressProvider>(context, listen: false)
                  .loadUserProgress(authProvider.userId!),
              _loadProfileImage(),
            ]);

            if (context.mounted) {
              final user = authProvider.currentUser;
              if (user != null) {
                Provider.of<ChallengeProvider>(context, listen: false)
                    .loadChallenges(authProvider.userId!, user);
              }
            }
          },
          color: AppColors.primary,
          child: _isInitialLoading
              ? ShimmerWidgets.dashboardLoading()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildHeader(context),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildHeroSection(context),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStatTiles(context),
                      ),
                      const SizedBox(height: 20),
                      _buildQuickActionsSection(context),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return CurrentPathProgressCard(
                              userId: authProvider.currentUser?.id ?? '',
                              onTap: () {
                                HapticService.buttonTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LearningPathsScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDailyGoalsSection(context),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildCompetitionSection(context),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRecentActivitySection(context),
                      ),
                      const SizedBox(height: 32),
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
                        color: context.textPrimary,
                      ),
                ),
              ],
            ),
            Row(
              children: [
                StreakFreezeWidget(
                  freezeCount: user?.streakFreezes ?? 0,
                  compact: true,
                  onTap: () => _showFreezeInfo(),
                ),
                const SizedBox(width: 8),

                TapScale(
                  onTap: () {
                    HapticService.buttonTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.search,
                      color: context.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TapScale(
                  onTap: () async {
                    HapticService.buttonTap();
                    final route = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                    if (route != null && mounted) {
                      _handleNotificationRoute(route);
                    }
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
                        Consumer<NotificationProvider>(
                          builder: (context, notifProvider, _) {
                            final unreadCount = notifProvider.unreadCount;
                            if (unreadCount == 0) return const SizedBox();
                            return Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
                const SizedBox(width: 8),
                TapScale(
                  onTap: () async {
                    HapticService.buttonTap();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    _loadProfileImage();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (_profileImageBytes == null && user?.photoUrl == null)
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: user?.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: CloudinaryService.getOptimizedImage(user!.photoUrl!, width: 88, height: 88),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _profileImageBytes != null
                                  ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                                  : ShimmerWidgets.circle(size: 44),
                              errorWidget: (context, url, error) {
                                if (_profileImageBytes != null) {
                                  return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                                }
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(
                                        color: AppColors.primary,
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
                                          color: AppColors.primary,
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
                                      color: AppColors.primary,
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

  Widget _buildHeroSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final level = user?.level ?? 1;
        final progress = user?.levelProgress ?? 0.0;
        final xpToNext = user?.xpToNextLevel ?? 100;
        final xpForNext = user?.xpForNextLevel ?? 100;
        final xpEarned = xpForNext - xpToNext;

        final nameParts = (user?.fullName ?? '').trim().split(' ');
        final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty
            ? nameParts.first
            : 'there';

        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Good morning'
            : (hour < 17 ? 'Good afternoon' : 'Good evening');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Level hero block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary.withValues(alpha: 0.71),
                        height: 1,
                      ),
                    ),
                    Text(
                      '$level',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 76,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -3.0,
                        color: AppColors.primary,
                        height: 0.85,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Name + XP block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: context.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatNumber(xpEarned),
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' / ${_formatNumber(xpForNext)} XP',
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: context.bgElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatNumber(xpToNext)} XP to Level ${level + 1}',
                        style: TextStyle(fontSize: 9, color: context.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08);
      },
    );
  }

  Widget _buildStatTiles(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final streak = user?.currentStreak ?? 0;
        final lessons = user?.lessonsCompleted ?? 0;
        final badges = user?.totalBadges ?? 0;
        return Row(
          children: [
            Expanded(child: _buildStatCard(context, emoji: '🔥', value: '$streak', label: 'Streak')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(context, emoji: '📚', value: '$lessons', label: 'Lessons')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(context, emoji: '🏅', value: '$badges', label: 'Badges')),
          ],
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String emoji,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: context.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: context.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Continue',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.26,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LearnScreen(showBackButton: true)));
                },
                child: const Text('See all', style: TextStyle(fontSize: 10, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildHCard(
                context,
                tag: 'Translate',
                color: AppColors.info,
                icon: Icons.translate,
                title: 'Sign to Text',
                subtitle: 'Real-time translation',
                featured: true,
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslateScreen(showBackButton: true)));
                },
              ),
              const SizedBox(width: 8),
              _buildHCard(
                context,
                tag: 'Learn',
                color: AppColors.secondary,
                icon: Icons.menu_book,
                title: 'Continue Lesson',
                subtitle: 'Pick up where you left off',
                featured: false,
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LearnScreen(showBackButton: true)));
                },
              ),
              const SizedBox(width: 8),
              _buildHCard(
                context,
                tag: 'Quiz',
                color: AppColors.error,
                icon: Icons.quiz,
                title: 'Test Knowledge',
                subtitle: 'Quiz yourself now',
                featured: false,
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LearnScreen(showBackButton: true, initialTabIndex: 1)));
                },
              ),
              const SizedBox(width: 8),
              _buildHCard(
                context,
                tag: 'Progress',
                color: AppColors.warning,
                icon: Icons.bar_chart,
                title: 'Your Stats',
                subtitle: 'View detailed progress',
                featured: false,
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildHCard(
    BuildContext context, {
    required String tag,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool featured,
    required VoidCallback onTap,
  }) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: featured ? const Color(0xFF1E1B4B) : context.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: featured ? AppColors.primary : context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color),
              ),
            ),
            const SizedBox(height: 7),
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.24,
                color: context.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 9, color: context.textMuted)),
          ],
        ),
      ),
    );
  }

  // ==================== UPDATED COMPETITION SECTION WITH FRIENDS ====================
  Widget _buildCompetitionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Compete & Connect', emoji: '🏅'),
        const SizedBox(height: 16),
        Row(
          children: [
            // Leaderboard Card
            Expanded(
              child: TapScale(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 10),
                      Text(
                        'Leaderboard',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Compete globally',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // NEW: Friends Card
            Expanded(
              child: TapScale(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('👥', style: TextStyle(fontSize: 26)),
                          const Spacer(),
                          FutureBuilder<int>(
                            future: FriendService.getPendingRequestCount(
                              Provider.of<AuthProvider>(context, listen: false).userId ?? '',
                            ),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              if (count == 0) return const SizedBox();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count NEW',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Friends',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connect & compare',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        // Challenges Card (full width)
        TapScale(
          onTap: () {
            HapticService.buttonTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card(context).copyWith(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
                  ),
                  child: const Text('🎯', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Challenges',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Complete challenges for bonus XP',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<ChallengeProvider>(
                  builder: (context, challengeProvider, child) {
                    final activeChallenges = challengeProvider.dailyChallenges
                        .where((c) => !c.isCompleted)
                        .length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
                      ),
                      child: Text(
                        '$activeChallenges Active',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Activity',
          emoji: '📋',
          trailing: TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
            },
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProgressProvider>(
          builder: (context, progressProvider, child) {
            if (progressProvider.isLoading) {
              return Column(
                children: [
                  ShimmerWidgets.activityItem(),
                  ShimmerWidgets.activityItem(),
                  ShimmerWidgets.activityItem(),
                ],
              );
            }

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

                final isQuiz = item.lessonId.startsWith('quiz_') || 
                             item.categoryId == 'quiz'; 

                return _buildActivityItem(
                  context,
                  icon: isQuiz ? '🎯' : (item.isCompleted ? '✅' : '📚'),
                  iconBgColor: isQuiz
                      ? AppColors.accent
                      : (item.isCompleted
                          ? AppColors.success
                          : AppColors.primary),
                  title: isQuiz
                      ? 'Completed "$title"'
                      : (item.isCompleted
                          ? 'Completed "$title" Lesson'
                          : 'Started "$title" Lesson'),
                  subtitle: _formatTimeAgo(item.lastAccessedAt),
                  xpText: '+$xpEarned XP',
                  xpColor: AppColors.success,
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
        color: context.bgCard,
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
                  color: context.textMuted,
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
      decoration: AppDecorations.card(context).copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(icon, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
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
                        color: context.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: xpColor.withValues(alpha: 0.1),
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
    return Consumer<ChallengeProvider>(
      builder: (context, challengeProvider, child) {
        final dailyChallenges = challengeProvider.dailyChallenges;
        final total = dailyChallenges.length;
        final completed = dailyChallenges.where((c) => c.isCompleted).length;
        final pct = total > 0 ? (completed / total * 100).round() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header row with dot + title + pct
            Row(
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  "Today's Goals",
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.26,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticService.buttonTap();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen()));
                  },
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (challengeProvider.isLoading)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: ShimmerWidgets.challengesLoading(),
              )
            else if (dailyChallenges.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      'Your daily goals are loading',
                      style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(color: context.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: total > 0 ? completed / total : 0,
                        minHeight: 3,
                        backgroundColor: context.bgElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ...dailyChallenges.take(5).map((c) => _buildGoalRow(context, challenge: c)),
                  ],
                ),
              ),
          ],
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  Widget _buildGoalRow(BuildContext context, {required ChallengeModel challenge}) {
    final isCompleted = challenge.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: isCompleted ? AppColors.success : context.textMuted,
                width: 1.5,
              ),
            ),
            child: isCompleted
                ? const Center(child: Icon(Icons.check, color: Colors.white, size: 7))
                : null,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              challenge.title,
              style: TextStyle(
                fontSize: 10,
                color: isCompleted ? context.textMuted : context.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+${challenge.xpReward} XP',
            style: TextStyle(fontSize: 9, color: context.textMuted),
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
