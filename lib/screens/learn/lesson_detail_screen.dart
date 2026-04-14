import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/lesson_model.dart';
import '../../models/category_model.dart';
import '../../models/badge_model.dart';
import '../../models/challenge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

// --- Phase 2 Integration: Imports ---
import '../../widgets/offline/download_widgets.dart';
import '../../widgets/video/cached_video_player.dart';
import '../../services/haptic_service.dart';
import '../../services/offline_service.dart';
import '../../services/video_cache_service.dart';

import '../../widgets/badges/badge_unlock_dialog.dart';
import '../../widgets/challenges/challenge_complete_dialog.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_service.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/common/glass_ui.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  final CategoryModel category;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.category,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isCompleting = false;
  bool _isCompleted = false;

  /// Check if this is an alphabet category
  bool get isAlphabetCategory {
    final categoryId = widget.category.id.toLowerCase();
    final categoryName = widget.category.name.toLowerCase();
    return categoryId == 'alphabet' || 
           categoryId == 'alphabets' ||
           categoryName.contains('alphabet') ||
           categoryName.contains('letter');
  }

  /// Get display name (adds "Letter" prefix for alphabet lessons)
  String get displayName {
    if (isAlphabetCategory && widget.lesson.signName.length == 1) {
      return 'Letter ${widget.lesson.signName.toUpperCase()}';
    }
    return widget.lesson.signName;
  }

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
    AnalyticsService.logLessonStarted(
      lessonId: widget.lesson.id,
      lessonName: widget.lesson.signName,
      categoryId: widget.category.id,
      categoryName: widget.category.name,
    );
  }

  void _checkIfCompleted() {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    _isCompleted = progressProvider.progressList
        .any((p) => p.lessonId == widget.lesson.id && p.isCompleted);
  }

  Future<void> _completeLesson() async {
    if (_isCompleting || _isCompleted) return;

    setState(() => _isCompleting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);

      if (authProvider.userId == null) return;

      // ── Offline-first: queue if no connection ───────────────────────────
      if (ConnectivityService.isOffline) {
        await OfflineService.queueLessonComplete(
          userId: authProvider.userId!,
          lessonId: widget.lesson.id,
          xpEarned: widget.lesson.xpReward,
          lessonName: widget.lesson.signName,
          categoryName: widget.category.name,
        );

        setState(() {
          _isCompleted = true;
          _isCompleting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Progress saved — will sync when online'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
          await _showCompletionDialog();
        }
        return;
      }

      // ── Online: normal Firestore completion ─────────────────────────────
      final levelBefore = authProvider.currentUser?.level ?? 1;

      await _firestoreService.completeLesson(
        authProvider.userId!,
        widget.lesson.id,
        widget.lesson.xpReward,
        lessonName: widget.lesson.signName,
        categoryName: widget.category.name,
      );

      // Cancel streak-at-risk reminder since user practiced today
      NotificationService().cancelStreakAtRiskReminder();

      // Refresh user data
      await authProvider.refreshUser();

      // Check for new badges
      List<BadgeModel> newBadges = [];
      List<ChallengeModel> completedChallenges = [];
      
      if (authProvider.currentUser != null) {
        // Check badges
        newBadges = await badgeProvider.checkForNewBadges(
          userId: authProvider.userId!,
          user: authProvider.currentUser!,
          completedLessonToday: true,
          lessonsCompletedToday: authProvider.currentUser!.lessonsCompletedToday,
        );

        // Check challenges
        completedChallenges = await challengeProvider.updateProgress(
          userId: authProvider.userId!,
          user: authProvider.currentUser!,
          lessonsCompleted: 1,
          xpEarned: widget.lesson.xpReward,
        );
      }

      await AnalyticsService.logLessonCompleted(
        lessonId: widget.lesson.id,
        lessonName: widget.lesson.signName,
        categoryId: widget.category.id,
        categoryName: widget.category.name,
        xpEarned: widget.lesson.xpReward,
      );

      // Refresh progress provider
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      await progressProvider.loadUserProgress(authProvider.userId!);
      progressProvider.refreshDailyGoals(authProvider.currentUser?.lessonsCompletedToday ?? 0);

      setState(() {
        _isCompleted = true;
        _isCompleting = false;
      });

      // Fire level-up notification + analytics if level changed
      final levelAfter = authProvider.currentUser?.level ?? 1;
      if (levelAfter > levelBefore) {
        NotificationService().showLevelUp(levelAfter);
        AnalyticsService.logLevelUp(
          newLevel: levelAfter,
          totalXP: authProvider.currentUser?.totalXP ?? 0,
        );
      }

      if (mounted) {
        // Show completion dialog first
        await _showCompletionDialog();

        // Then show badge dialogs if any new badges were unlocked
        if (newBadges.isNotEmpty && mounted) {
          await BadgeUnlockDialog.showMultiple(context, newBadges);
          // Also fire local notification for each badge
          for (final badge in newBadges) {
            NotificationService().showAchievementUnlocked(badge.name, badge.xpReward);
          }
        }

        // Show challenge completion dialogs
        if (completedChallenges.isNotEmpty && mounted) {
          await ChallengeCompleteDialog.showMultiple(context, completedChallenges);
          for (final challenge in completedChallenges) {
            NotificationService().showChallengeCompleted(challenge.title, challenge.xpReward);
          }
        }
      }
    } catch (e) {
      setState(() => _isCompleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showCompletionDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60))
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Lesson Complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You earned +${widget.lesson.xpReward} XP',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Show updated stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '🤟',
                    '${user?.signsLearned ?? 0}',
                    'Signs',
                  ),
                  _buildStatItem(
                    '🔥',
                    '${user?.currentStreak ?? 0}',
                    'Streak',
                  ),
                  _buildStatItem(
                    '🎯',
                    '${user?.dailyGoalProgress ?? 0}/${user?.dailyGoalTarget ?? 3}',
                    'Daily',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to lesson list with refresh flag
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // --- Phase 2: Save for Offline Button ---
  Widget _buildSaveOfflineButton() {
    return FutureBuilder<bool>(
      future: OfflineService.isLessonAvailable(widget.lesson.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          child: OutlinedButton.icon(
            onPressed: isSaved ? null : () async {
              HapticService.buttonTap();
              
              // Save lesson data
              await OfflineService.saveLesson(widget.lesson.id, {
                'id': widget.lesson.id,
                'signName': widget.lesson.signName,
                'category': widget.category.id, // ID for filtering
                'categoryName': widget.category.name,
                'videoUrl': widget.lesson.videoUrl,
                'imageUrl': widget.lesson.imageUrl,
                'description': widget.lesson.description,
                'xpReward': widget.lesson.xpReward,
                'emoji': widget.lesson.emoji,
              });
              
              // Cache video if available
              if (widget.lesson.videoUrl != null) {
                await VideoCacheService.cacheVideo(widget.lesson.videoUrl!);
              }
              
              HapticService.success();
              
              if (mounted) {
                setState(() {}); // Refresh to show "Saved" state
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✓ Saved for offline'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              isSaved ? Icons.offline_pin : Icons.download_outlined,
              color: isSaved ? const Color(0xFF10B981) : context.textPrimary,
            ),
            label: Text(
              isSaved ? 'Saved Offline' : 'Save for Offline Practice',
              style: TextStyle(
                color: isSaved ? const Color(0xFF10B981) : context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isSaved 
                    ? const Color(0xFF10B981).withAlpha(100) 
                    : context.borderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isSaved 
                  ? const Color(0xFF10B981).withAlpha(10)
                  : Colors.transparent,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: displayName,
        actions: [
          // --- Phase 2: AppBar Download Button ---
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DownloadButton(
              lessonId: widget.lesson.id,
              videoUrl: widget.lesson.videoUrl,
              lessonData: {
                'id': widget.lesson.id,
                'signName': widget.lesson.signName,
                'category': widget.category.id,
                'categoryName': widget.category.name,
                'videoUrl': widget.lesson.videoUrl,
                'imageUrl': widget.lesson.imageUrl,
                'description': widget.lesson.description,
                'xpReward': widget.lesson.xpReward,
                'emoji': widget.lesson.emoji,
              },
              size: 24,
            ),
          ),
          
          if (_isCompleted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sign Display Card
            _buildSignCard(context),
            const SizedBox(height: 16),
            
            // --- Phase 2: Big Save Button ---
            _buildSaveOfflineButton(),
            
            // Description
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassSectionHeader(title: 'How to Sign'),
            ).animate().fadeIn(delay: 200.ms),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.lesson.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                  height: 1.6,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            const SizedBox(height: 24),

            // Tips Section
            if (widget.lesson.tips.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: GlassSectionHeader(title: 'Tips'),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              ...widget.lesson.tips.asMap().entries.map((entry) {
                return _buildTipCard(context, entry.key + 1, entry.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 500 + (entry.key * 100)));
              }),
              const SizedBox(height: 24),
            ],

            // Practice Hint
            GlassCard(
              padding: const EdgeInsets.all(16),
              decorationOverride: context.glassCardDecoration().copyWith(
                border: Border.all(color: AppColors.primary.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 24, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Practice in front of a mirror to check your hand positions!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSignCard(BuildContext context) {
    final hasVideo = widget.lesson.videoUrl != null;
    final hasImage = widget.lesson.imageUrl != null;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(38),
              borderRadius: kPillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  widget.category.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Phase 2: Cached Video Player ---
          if (hasVideo)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                // Replaced VideoPlayerWidget with CachedVideoPlayer
                child: CachedVideoPlayer(
                  videoUrl: widget.lesson.videoUrl!,
                  autoPlay: true, // Auto-play for better engagement
                  looping: true,
                  showControls: true,
                  placeholder: Container(
                    color: context.bgElevated,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            )
          else if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                CloudinaryService.getOptimizedImage(
                  widget.lesson.imageUrl!,
                  width: 400,
                  height: 400,
                ),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: context.bgElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(75),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(51),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.lesson.emoji,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),

          // Sign Name
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // XP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(38),
              borderRadius: kPillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  '+${widget.lesson.xpReward} XP',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTipCard(BuildContext context, int number, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassPrimaryButton(
          label: _isCompleted ? 'Completed!' : 'Mark as Complete',
          onPressed: _isCompleted ? null : _completeLesson,
          loading: _isCompleting,
        ),
      ),
    );
  }
}