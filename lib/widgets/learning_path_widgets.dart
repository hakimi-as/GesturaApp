import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../services/haptic_service.dart';
import '../models/learning_path_model.dart';
import '../services/learning_path_service.dart';

/// Card showing a learning path overview
class LearningPathCard extends StatelessWidget {
  final LearningPath path;
  final UserLearningPathProgress? progress;
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  const LearningPathCard({
    super.key,
    required this.path,
    this.progress,
    this.onTap,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isStarted = progress != null;
    final isCompleted = progress?.isCompleted ?? false;
    final progressPercent = progress?.progressPercent(path.steps.length) ?? 0.0;

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withAlpha(100)
                : context.borderColor,
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(path.difficultyColor).withAlpha(30),
                    Color(path.difficultyColor).withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(path.difficultyColor).withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        path.iconEmoji ?? '📚',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title and difficulty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                path.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color(path.difficultyColor).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            path.difficultyLabel,
                            style: TextStyle(
                              color: Color(path.difficultyColor),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description and stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    children: [
                      _buildStat(context, '📚', '${path.totalLessons} lessons'),
                      const SizedBox(width: 16),
                      _buildStat(context, '⭐', '${path.totalXP} XP'),
                      const SizedBox(width: 16),
                      _buildStat(context, '📅', '~${path.estimatedDays} days'),
                    ],
                  ),

                  // Progress bar (if started)
                  if (isStarted) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPercent,
                              backgroundColor: context.bgElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted
                                    ? const Color(0xFF10B981)
                                    : Color(path.difficultyColor),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Start/Continue button
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.buttonTap();
                        if (isStarted) {
                          onTap?.call();
                        } else {
                          onStart?.call();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? const Color(0xFF10B981)
                            : Color(path.difficultyColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Review Path'
                            : isStarted
                                ? 'Continue'
                                : 'Start Learning',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStat(BuildContext context, String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Compact learning path card for dashboard
class LearningPathMiniCard extends StatelessWidget {
  final LearningPath path;
  final UserLearningPathProgress? progress;
  final VoidCallback? onTap;

  const LearningPathMiniCard({
    super.key,
    required this.path,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = progress?.progressPercent(path.steps.length) ?? 0.0;
    final isStarted = progress != null;

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        onTap?.call();
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(path.difficultyColor).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      path.iconEmoji ?? '📚',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const Spacer(),
                if (isStarted)
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      color: Color(path.difficultyColor),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              path.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Progress bar
            if (isStarted)
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: context.bgElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(path.difficultyColor),
                  ),
                  minHeight: 4,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(path.difficultyColor).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  path.difficultyLabel,
                  style: TextStyle(
                    color: Color(path.difficultyColor),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Step item in learning path detail
class LearningPathStepItem extends StatelessWidget {
  final LearningPathStep step;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onTap;

  const LearningPathStepItem({
    super.key,
    required this.step,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : () {
        HapticService.buttonTap();
        onTap?.call();
      },
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary.withAlpha(20)
                : context.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary.withAlpha(100)
                  : isCompleted
                      ? const Color(0xFF10B981).withAlpha(100)
                      : context.borderColor,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : isLocked
                          ? context.bgElevated
                          : AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : isLocked
                          ? Icon(Icons.lock, color: context.textMuted, size: 20)
                          : Text(step.typeIcon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? context.textMuted : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                '+${step.xpReward}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (step.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                isCurrent ? Icons.play_arrow : Icons.chevron_right,
                color: isCurrent ? AppColors.primary : context.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Current path progress card for dashboard
/// Current path progress card for dashboard
class CurrentPathProgressCard extends StatefulWidget {
  final String userId;  // ← Changed from odlerndId
  final VoidCallback? onTap;

  const CurrentPathProgressCard({
    super.key,
    required this.userId,  // ← Changed from odlerndId
    this.onTap,
  });

  @override
  State<CurrentPathProgressCard> createState() => _CurrentPathProgressCardState();
}

class _CurrentPathProgressCardState extends State<CurrentPathProgressCard> {
  LearningPath? _currentPath;
  UserLearningPathProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    setState(() => _isLoading = true);

    try {
      final path = await LearningPathService.getCurrentActivePath(widget.userId);  // ← Changed
      if (path != null) {
        final progress = await LearningPathService.getUserPathProgress(
          widget.userId,  // ← Changed
          path.id,
        );
        if (mounted) {
          setState(() {
            _currentPath = path;
            _progress = progress;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current path: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentPath == null) {
      return const SizedBox.shrink();
    }

    final progressPercent = _progress?.progressPercent(_currentPath!.steps.length) ?? 0.0;
    final completedSteps = _progress?.completedStepIds.length ?? 0;
    final totalSteps = _currentPath!.steps.length;

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        widget.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(_currentPath!.difficultyColor),
              Color(_currentPath!.difficultyColor).withAlpha(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _currentPath!.iconEmoji ?? '📚',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue Learning',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPath!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.white.withAlpha(50),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completedSteps/$totalSteps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}