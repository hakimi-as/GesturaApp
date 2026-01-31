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
import '../../widgets/download_widgets.dart';
import '../../widgets/video/cached_video_player.dart';
import '../../services/haptic_service.dart';
import '../../services/offline_service.dart';
import '../../services/video_cache_service.dart';

import '../../widgets/badges/badge_unlock_dialog.dart';
import '../../widgets/challenges/challenge_complete_dialog.dart';

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

      // Pass lesson and category names
      await _firestoreService.completeLesson(
        authProvider.userId!,
        widget.lesson.id,
        widget.lesson.xpReward,
        lessonName: widget.lesson.signName,
        categoryName: widget.category.name,
      );

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

      // Refresh progress provider
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      await progressProvider.loadUserProgress(authProvider.userId!);

      setState(() {
        _isCompleted = true;
        _isCompleting = false;
      });

      if (mounted) {
        // Show completion dialog first
        await _showCompletionDialog();
        
        // Then show badge dialogs if any new badges were unlocked
        if (newBadges.isNotEmpty && mounted) {
          await BadgeUnlockDialog.showMultiple(context, newBadges);
        }

        // Show challenge completion dialogs
        if (completedChallenges.isNotEmpty && mounted) {
          await ChallengeCompleteDialog.showMultiple(context, completedChallenges);
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
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(displayName),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sign Display Card
            _buildSignCard(context),
            const SizedBox(height: 16),
            
            // --- Phase 2: Big Save Button ---
            _buildSaveOfflineButton(),
            
            // Description
            Text(
              'How to Sign',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.lesson.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                  height: 1.6,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),

            // Tips Section
            if (widget.lesson.tips.isNotEmpty) ...[
              Text(
                'Tips',
                style: Theme.of(context).textTheme.titleLarge,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 24)),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.bgCard,
            context.bgElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.category.icon, style: const TextStyle(fontSize: 14)),
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
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
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isCompleted ? null : _completeLesson,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
              disabledBackgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isCompleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCompleted ? Icons.check_circle : Icons.school,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCompleted ? 'Completed!' : 'Mark as Complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}