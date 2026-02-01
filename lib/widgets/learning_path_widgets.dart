import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../config/theme.dart';
import '../services/haptic_service.dart';
import '../models/learning_path_model.dart';
import '../services/learning_path_service.dart';

/// Compact learning path card for dashboard - REDESIGNED
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
    final isCompleted = progress?.isCompleted ?? false;
    final pathColor = Color(path.difficultyColor);

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        onTap?.call();
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withAlpha(100)
                : context.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: pathColor.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pathColor.withAlpha(40), pathColor.withAlpha(20)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 24)
                        : Text(path.iconEmoji ?? '📚', style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const Spacer(),
                if (isStarted)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          value: progressPercent,
                          strokeWidth: 3,
                          backgroundColor: pathColor.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? const Color(0xFF10B981) : pathColor,
                          ),
                        ),
                      ),
                      Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: TextStyle(
                          color: pathColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pathColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        color: pathColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              path.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Difficulty Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: pathColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: pathColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    path.difficultyLabel,
                    style: TextStyle(
                      color: pathColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Stats Row
            Row(
              children: [
                Text('📚 ${path.totalLessons}',
                    style: TextStyle(color: context.textMuted, fontSize: 11)),
                const SizedBox(width: 12),
                Text('⭐ ${path.totalXP}',
                    style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Current path progress card for dashboard - REDESIGNED
class CurrentPathProgressCard extends StatefulWidget {
  final String userId;
  final VoidCallback? onTap;

  const CurrentPathProgressCard({
    super.key,
    required this.userId,
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
      final path = await LearningPathService.getCurrentActivePath(widget.userId);
      if (path != null) {
        final progress = await LearningPathService.getUserPathProgress(
          widget.userId,
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
    if (_isLoading) {
      return Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_currentPath == null) {
      return _buildStartPathCard(context);
    }

    final progressPercent = _progress?.progressPercent(_currentPath!.steps.length) ?? 0.0;
    final completedSteps = _progress?.completedStepIds.length ?? 0;
    final totalSteps = _currentPath!.steps.length;
    final pathColor = Color(_currentPath!.difficultyColor);
    final nextStep = _getNextStep();

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        widget.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [pathColor, pathColor.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: pathColor.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _currentPath!.iconEmoji ?? '📚',
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue Learning',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentPath!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Circular Progress
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: progressPercent,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withAlpha(40),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Next Step Preview
                  if (nextStep != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(nextStep.typeIcon, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next: ${nextStep.title}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '+${nextStep.xpReward} XP • Step ${completedSteps + 1}/$totalSteps',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: pathColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPercent,
                              backgroundColor: Colors.white.withAlpha(40),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  LearningPathStep? _getNextStep() {
    if (_currentPath == null || _progress == null) return null;
    
    for (final step in _currentPath!.steps) {
      if (!_progress!.completedStepIds.contains(step.id)) {
        return step;
      }
    }
    return null;
  }

  Widget _buildStartPathCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        widget.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Your Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a learning path to begin',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF6366F1),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

/// Step item in learning path detail - kept for backward compatibility
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
      onTap: isLocked
          ? null
          : () {
              HapticService.buttonTap();
              onTap?.call();
            },
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary.withAlpha(15)
                : context.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary.withAlpha(100)
                  : isCompleted
                      ? const Color(0xFF10B981).withAlpha(80)
                      : context.borderColor,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        )
                      : isCurrent
                          ? LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                            )
                          : null,
                  color: (isCompleted || isCurrent) ? null : context.bgElevated,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: (isCompleted || isCurrent)
                      ? [
                          BoxShadow(
                            color: (isCompleted ? const Color(0xFF10B981) : AppColors.primary)
                                .withAlpha(50),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                      : isLocked
                          ? Icon(Icons.lock_rounded, color: context.textMuted, size: 20)
                          : Text(step.typeIcon, style: const TextStyle(fontSize: 24)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981).withAlpha(20)
                                : AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: isCompleted ? const Color(0xFF10B981) : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${step.xpReward}',
                                style: TextStyle(
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : AppColors.primary,
                                  fontSize: 12,
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
                isCurrent ? Icons.play_circle_fill_rounded : Icons.chevron_right_rounded,
                color: isCurrent ? AppColors.primary : context.textMuted,
                size: isCurrent ? 32 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card showing a learning path overview - DEPRECATED, use the one in screen
@Deprecated('Use _LearningPathCard in learning_paths_screen.dart instead')
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
    final pathColor = Color(path.difficultyColor);

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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    pathColor.withAlpha(30),
                    pathColor.withAlpha(10),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(path.iconEmoji ?? '📚', style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pathColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            path.difficultyLabel,
                            style: TextStyle(
                              color: pathColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.description,
                    style: TextStyle(color: context.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('📚 ${path.totalLessons}', style: TextStyle(color: context.textMuted, fontSize: 12)),
                      const SizedBox(width: 16),
                      Text('⭐ ${path.totalXP} XP', style: TextStyle(color: context.textMuted, fontSize: 12)),
                      const SizedBox(width: 16),
                      Text('📅 ~${path.estimatedDays}d', style: TextStyle(color: context.textMuted, fontSize: 12)),
                    ],
                  ),
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
                                isCompleted ? const Color(0xFF10B981) : pathColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
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
                        backgroundColor: isCompleted ? const Color(0xFF10B981) : pathColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isCompleted ? 'Review Path' : isStarted ? 'Continue' : 'Start Learning',
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
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}