import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
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
                      const SizedBox(height: 24),
                      _buildHeroSection(context),
                      const SizedBox(height: 16),
                      _buildStatTiles(context),
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
                const SizedBox(width: 10),
                
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
                const SizedBox(width: 10),
                TapScale(
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
                          ? AppColors.primary.withAlpha(20)
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
                                    color: AppColors.primary.withAlpha(20),
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
                                        style: TextStyle(
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
                                    style: TextStyle(
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
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$firstName 👋',
              style: GoogleFonts.familjenGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: context.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: context.textMuted,
                        height: 1,
                      ),
                    ),
                    Text(
                      '$level',
                      style: GoogleFonts.familjenGrotesk(
                        fontSize: 50,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2.0,
                        color: AppColors.primary,
                        height: 0.88,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_formatNumber(xpForNext - xpToNext)} ',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '/ ${_formatNumber(xpForNext)} XP',
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: context.bgElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatNumber(xpToNext)} XP to Level ${level + 1}',
                          style: TextStyle(
                            fontSize: 9,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildStatTiles(BuildContext context) {
    return Consumer2<AuthProvider, ChallengeProvider>(
      builder: (context, authProvider, challengeProvider, child) {
        final user = authProvider.currentUser;
        final streak = user?.currentStreak ?? 0;

        final challenges = challengeProvider.dailyChallenges;
        final total = challenges.length;
        final completed = challenges.where((c) => c.isCompleted).length;
        final pct = total > 0 ? (completed / total * 100).round() : 0;
        final dotCount = total.clamp(0, 7);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak tile — narrower (20 of 47 parts)
            Expanded(
              flex: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(
                      '$streak',
                      style: GoogleFonts.familjenGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: context.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day streak',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Goals tile — wider (27 of 47 parts ≈ 1.35×)
            Expanded(
              flex: 27,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completed / $total',
                              style: GoogleFonts.familjenGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: context.textPrimary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Today's goals",
                              style: TextStyle(
                                fontSize: 9,
                                color: context.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.success.withAlpha(26),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: context.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (dotCount > 0) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: List.generate(
                          dotCount,
                          (i) => Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i < dotCount - 1 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: i < completed ? context.success : context.bgElevated,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
      },
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
        const SectionHeader(title: 'Quick Actions', emoji: '⚡'),
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
                title: 'Learn',
                subtitle: 'Interactive lessons',
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
                title: 'Quiz',
                subtitle: 'Test your knowledge',
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
                title: 'Progress',
                subtitle: 'Track your stats',
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
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(context).copyWith(
          borderRadius: BorderRadius.circular(20),
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
              child: Icon(icon, color: iconBgColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 3),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(height: 12),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('👥', style: TextStyle(fontSize: 22))),
                          ),
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
                                  color: AppColors.accent.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count NEW',
                                  style: TextStyle(
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
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withAlpha(60)),
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
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withAlpha(60)),
                      ),
                      child: Text(
                        '$activeChallenges Active',
                        style: TextStyle(
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
            child: Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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

        if (challengeProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Daily Challenges', emoji: '🎯'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppDecorations.card(context).copyWith(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ShimmerWidgets.challengesLoading(),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Daily Challenges',
              dotColor: AppColors.accent,
              trailing: TextButton(
                onPressed: () {
                  HapticService.buttonTap();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen()));
                },
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
            if (dailyChallenges.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.borderColor),
                ),
                child: Center(
                  child: Text(
                    'No daily challenges available',
                    style: TextStyle(color: context.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ...dailyChallenges.map((challenge) {
                return _buildChallengeItem(context, challenge: challenge);
              }),
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
    final tagColor = isCompleted ? context.success : challenge.typeColor;
    final tagLabel = isCompleted
        ? '✓ Done'
        : (challenge.isPersonalized
            ? '✨ For You'
            : '${challenge.emoji} ${challenge.typeLabel}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag (top-left) + XP (top-right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: tagColor,
                    ),
                  ),
                ),
                Text(
                  '+${challenge.xpReward} XP',
                  style: GoogleFonts.familjenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? context.success : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Title
            Text(
              challenge.title,
              style: GoogleFonts.familjenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: isCompleted ? context.textMuted : context.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (!isCompleted && challenge.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                challenge.description,
                style: TextStyle(
                  fontSize: 10,
                  color: context.textMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // Progress bar — 3px
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: challenge.progress,
                minHeight: 3,
                backgroundColor: context.bgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? context.success : challenge.typeColor,
                ),
              ),
            ),
            const SizedBox(height: 7),
            // Footer: count + continue/begin button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge.currentValue} of ${challenge.targetValue} completed',
                  style: TextStyle(fontSize: 9, color: context.textMuted),
                ),
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: Text(
                      challenge.progress > 0 ? 'Continue →' : 'Begin →',
                      style: GoogleFonts.familjenGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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