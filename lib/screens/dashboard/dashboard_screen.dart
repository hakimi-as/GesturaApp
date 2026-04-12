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
                const Text('🤟', style: TextStyle(fontSize: 28)),
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
                
                GestureDetector(
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
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    HapticService.buttonTap();
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
                      const Text('👋', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildWelcomeStatChip(
                        '🔥',
                        '${user?.currentStreak ?? 0}',
                        AppLocalizations.of(context).dayStreakLabel,
                      ),
                      const SizedBox(width: 12),
                      _buildWelcomeStatChip(
                        '⭐',
                        _formatNumber(user?.totalXP ?? 0),
                        AppLocalizations.of(context).totalXP,
                      ),
                      const SizedBox(width: 12),
                      _buildWelcomeStatChip(
                        '🤟',
                        '${user?.signsLearned ?? 0}',
                        AppLocalizations.of(context).signsLabel,
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
              AppLocalizations.of(context).quickActions,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
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
                    color: context.textMuted,
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
        Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).competeConnect,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
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
                      const Text('🏆', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).leaderboard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).competeGlobally,
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
            // NEW: Friends Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
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
                          const Text('👥', style: TextStyle(fontSize: 28)),
                          const Spacer(),
                          // Pending requests badge
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
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count NEW',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).connectCompare,
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
        const SizedBox(height: 12),
        // Challenges Card (full width)
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).dailyChallenges,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).challengesBonusXP,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
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
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeChallenges ${AppLocalizations.of(context).activeLabel}',
                        style: const TextStyle(
                          color: Colors.white,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).recentActivity,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                HapticService.buttonTap();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                );
              },
              child: Text(
                AppLocalizations.of(context).viewAll,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
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
                  icon: isQuiz ? '🎯' : (item.isCompleted ? '✅' : '📚'),
                  iconBgColor: isQuiz
                      ? const Color(0xFFEC4899)
                      : (item.isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1)),
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
            AppLocalizations.of(context).noActivityYet,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).startLearningProgress,
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
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
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
                        color: context.textMuted,
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

        if (challengeProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).dailyChallenges,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
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
                child: ShimmerWidgets.challengesLoading(),
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
                      AppLocalizations.of(context).dailyChallenges,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                GestureDetector(
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
                        AppLocalizations.of(context).todaysProgress,
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
                          '$completedChallenges/$totalChallenges ${AppLocalizations.of(context).completed}',
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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
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
                if (challenge.isPersonalized || challenge.difficultyMultiplier != 1.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Row(
                      children: [
                        if (challenge.isPersonalized) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('✨ For You',
                                style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (challenge.difficultyMultiplier != 1.0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  challenge.difficultyTierColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(challenge.difficultyTierLabel,
                                style: TextStyle(
                                    color: challenge.difficultyTierColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
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