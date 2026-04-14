import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart'; // NEW: Friend Service
import '../../models/challenge_model.dart';
import '../../widgets/common/shimmer_widgets.dart';
import '../../widgets/common/glass_ui.dart';
import '../../widgets/gamification/streak_freeze_widgets.dart';

import '../translate/translate_screen.dart';
import '../learn/learn_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/enhanced_progress_screen.dart';
import '../search/search_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../challenges/challenges_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/learning/learning_path_widgets.dart';
import '../learn/learning_paths_screen.dart';
import '../social/friends_screen.dart'; // NEW: Friends Screen

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
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
        final imageBase64 = prefs.getString('profileImageBase64');
        if (imageBase64 != null && imageBase64.isNotEmpty && mounted) {
          setState(() {
            _profileImageBytes = base64Decode(imageBase64);
          });
        }
      } else {
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
        
        final user = authProvider.currentUser;
        if (user != null) {
          Provider.of<ChallengeProvider>(context, listen: false)
              .loadChallenges(authProvider.userId!, user);
        }
      }
    }
    
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
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

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticService.lightTap();
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.userId != null) {
              await authProvider.refreshUser();
              await Provider.of<ProgressProvider>(context, listen: false)
                  .loadUserProgress(authProvider.userId!);
              
              final user = authProvider.currentUser;
              if (user != null) {
                await Provider.of<ChallengeProvider>(context, listen: false)
                    .loadChallenges(authProvider.userId!, user);
              }
            }
            await _loadProfileImage();
          },
          color: AppColors.primary,
          child: _isInitialLoading
              ? ShimmerWidgets.dashboardLoading()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildWelcomeCard(context),
                      const SizedBox(height: 24),
    
                      // Learning Path Card
                       Consumer<AuthProvider>(
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
                Icon(Icons.sign_language, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).appTitle,
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
                const SizedBox(width: 10),

                GlassIconButton(
                  icon: Icons.search,
                  onTap: () {
                    HapticService.buttonTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Notification button with badge overlay
                GestureDetector(
                  onTap: () {
                    HapticService.buttonTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GlassIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: null,
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: Provider.of<AuthProvider>(context, listen: false).userId)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data?.docs.length ?? 0;
                          if (unreadCount == 0) return const SizedBox.shrink();

                          return Positioned(
                            right: -2,
                            top: -2,
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
                const SizedBox(width: 10),
                // Profile avatar with teal border
                GestureDetector(
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
                      gradient: (_profileImageBytes == null && user?.photoUrl == null)
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: kGlassRadius,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: kGlassRadius,
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
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.initials,
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
              colors: [Color(0xFF0D2D2D), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: kGlassRadius,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(context),
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).welcomeBackExclaim,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.waving_hand_rounded,
                          color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildWelcomeStatChip(
                        Icons.local_fire_department_rounded,
                        '${user?.currentStreak ?? 0}',
                        AppLocalizations.of(context).dayStreakLabel,
                        AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      _buildWelcomeStatChip(
                        Icons.star_rounded,
                        _formatNumber(user?.totalXP ?? 0),
                        AppLocalizations.of(context).totalXP,
                        const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 12),
                      _buildWelcomeStatChip(
                        Icons.sign_language,
                        '${user?.signsLearned ?? 0}',
                        AppLocalizations.of(context).signsLabel,
                        AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: -16,
                top: -16,
                child: Opacity(
                  opacity: 0.10,
                  child: Icon(Icons.sign_language,
                      color: Colors.white, size: 100),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildWelcomeStatChip(
      IconData iconData, String value, String label, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: kGlassRadius,
          border: Border.all(
            color: Colors.white.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: iconColor, size: 18),
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
        GlassSectionHeader(title: AppLocalizations.of(context).quickActions),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.translate,
                iconBgColor: const Color(0xFF3B82F6),
                title: AppLocalizations.of(context).navTranslate,
                subtitle: AppLocalizations.of(context).realTimeTranslation,
                onTap: () {
                  HapticService.buttonTap();
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
                title: AppLocalizations.of(context).navLearn,
                subtitle: AppLocalizations.of(context).interactiveLessons,
                onTap: () {
                  HapticService.buttonTap();
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
                title: AppLocalizations.of(context).quizTitle,
                subtitle: AppLocalizations.of(context).testKnowledge,
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LearnScreen(
                        showBackButton: true,
                        initialTabIndex: 1,
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
                title: AppLocalizations.of(context).progressTitle,
                subtitle: AppLocalizations.of(context).trackStats,
                onTap: () {
                  HapticService.buttonTap();
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
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TealGradientIcon(icon: icon, size: 44),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 12,
              ),
            ),
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
        GlassSectionHeader(title: AppLocalizations.of(context).competeConnect),
        const SizedBox(height: 16),
        Row(
          children: [
            // Leaderboard Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  );
                },
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TealGradientIcon(icon: Icons.emoji_events_rounded, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).leaderboard,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).competeGlobally,
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Friends Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                },
                child: GlassCard(
                  alternate: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TealGradientIcon(icon: Icons.group_rounded, size: 40),
                          const Spacer(),
                          // Pending requests badge
                          FutureBuilder<int>(
                            future: FriendService.getPendingRequestCount(
                              Provider.of<AuthProvider>(context, listen: false).userId ?? '',
                            ),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              if (count == 0) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Text(
                                  '$count NEW',
                                  style: const TextStyle(
                                    color: AppColors.primary,
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
                        AppLocalizations.of(context).friends,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).connectCompare,
                        style: TextStyle(
                          color: context.textMuted,
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
        const SizedBox(height: 12),
        // Challenges Card (full width) — amber accent
        GestureDetector(
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
            decoration: context.glassCardDecoration().copyWith(
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: kGlassRadius,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(Icons.track_changes_rounded,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).dailyChallenges,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).challengesBonusXP,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        '$activeChallenges ${AppLocalizations.of(context).activeLabel}',
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
        GlassSectionHeader(
          title: AppLocalizations.of(context).recentActivity,
          trailing: GestureDetector(
            onTap: () {
              HapticService.buttonTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
            },
            child: Text(
              AppLocalizations.of(context).viewAll,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
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
                    : AppLocalizations.of(context).lessonActivity;
                final xpEarned = item.xpEarned > 0 ? item.xpEarned : 10;

                final isQuiz = item.lessonId.startsWith('quiz_') || 
                             item.categoryId == 'quiz'; 

                return _buildActivityItem(
                  context,
                  icon: isQuiz
                      ? Icons.track_changes_rounded
                      : (item.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.menu_book_rounded),
                  iconBgColor: isQuiz
                      ? AppColors.primary
                      : (item.isCompleted
                          ? const Color(0xFF10B981)
                          : AppColors.primary),
                  title: isQuiz
                      ? '${AppLocalizations.of(context).completedActivity} "$title"'
                      : (item.isCompleted
                          ? '${AppLocalizations.of(context).completedActivity} "$title" ${AppLocalizations.of(context).lessonActivity}'
                          : '${AppLocalizations.of(context).startedActivity} "$title" ${AppLocalizations.of(context).lessonActivity}'),
                  subtitle: _formatTimeAgo(item.lastAccessedAt, context),
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
    return GlassCard(
      alternate: true,
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: context.textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).noActivityYet,
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).startLearningProgress,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String xpText,
    required Color xpColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassTile(
        alternate: true,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor.withValues(alpha: 0.15),
            borderRadius: kGlassRadius,
            border: Border.all(
              color: iconBgColor.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, color: iconBgColor, size: 20),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: xpColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: xpColor.withValues(alpha: 0.25),
            ),
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

        if (challengeProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassSectionHeader(
                  title: AppLocalizations.of(context).dailyChallenges),
              const SizedBox(height: 16),
              GlassCard(
                child: ShimmerWidgets.challengesLoading(),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassSectionHeader(
              title: AppLocalizations.of(context).dailyChallenges,
              trailing: GestureDetector(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChallengesScreen(),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context).viewAll,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).todaysProgress,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: completedChallenges == totalChallenges &&
                                  totalChallenges > 0
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: completedChallenges == totalChallenges &&
                                    totalChallenges > 0
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.30)
                                : AppColors.primary.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          '$completedChallenges/$totalChallenges ${AppLocalizations.of(context).completed}',
                          style: TextStyle(
                            color: completedChallenges == totalChallenges &&
                                    totalChallenges > 0
                                ? const Color(0xFF10B981)
                                : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassProgressBar(value: percentage),
                  const SizedBox(height: 18),
                  if (dailyChallenges.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        AppLocalizations.of(context).noDailyChallenges,
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
    
    final accentColor =
        isCompleted ? const Color(0xFF10B981) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: kGlassRadius,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.track_changes_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    color: isCompleted
                        ? context.textMuted
                        : context.textPrimary,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (challenge.isPersonalized ||
                    challenge.difficultyMultiplier != 1.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Row(
                      children: [
                        if (challenge.isPersonalized) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'For You',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (challenge.difficultyMultiplier != 1.0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: challenge.difficultyTierColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              challenge.difficultyTierLabel,
                              style: TextStyle(
                                  color: challenge.difficultyTierColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${challenge.currentValue}/${challenge.targetValue}',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassProgressBar(
                        value: challenge.progress,
                        height: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '+${challenge.xpReward} XP',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${l10n.minAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${l10n.hoursAgo}';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else {
      return '${difference.inDays} ${l10n.daysAgoLabel}';
    }
  }
}