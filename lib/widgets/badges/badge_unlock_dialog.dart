import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';

class BadgeUnlockDialog extends StatefulWidget {
  final BadgeModel badge;
  final VoidCallback? onDismiss;

  const BadgeUnlockDialog({
    super.key,
    required this.badge,
    this.onDismiss,
  });

  static Future<void> show(BuildContext context, BadgeModel badge) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => BadgeUnlockDialog(badge: badge),
    );
  }

  static Future<void> showMultiple(BuildContext context, List<BadgeModel> badges) async {
    for (final badge in badges) {
      await show(context, badge);
    }
  }

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Start confetti after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main content
          Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.badge.tierColor.withAlpha(100),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.badge.tierColor.withAlpha(50),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  '🎉 Badge Unlocked!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.badge.tierColor,
                      ),
                ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                const SizedBox(height: 24),

                // Badge Icon with animation
                _buildBadgeIcon(),
                const SizedBox(height: 20),

                // Tier Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.badge.tierGradientStart,
                        widget.badge.tierGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.badge.tierColor.withAlpha(100),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.badge.tierName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, delay: 600.ms),
                const SizedBox(height: 20),

                // Badge Name
                Text(
                  widget.badge.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.badge.description,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 900.ms),
                const SizedBox(height: 20),

                // XP Reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        '+${widget.badge.xpReward} XP',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1000.ms).scale(delay: 1000.ms),
                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.badge.tierColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3, delay: 1200.ms),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

          // Confetti
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                widget.badge.tierGradientStart,
                widget.badge.tierGradientEnd,
                Colors.white,
                AppColors.primary,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated glow rings
        ...List.generate(3, (index) {
          return Container(
            width: 120 + (index * 20),
            height: 120 + (index * 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.badge.tierColor.withAlpha(50 - (index * 15)),
                width: 2,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: Duration(milliseconds: 1500 + (index * 200)),
              )
              .fadeOut(duration: Duration(milliseconds: 1500 + (index * 200)));
        }),

        // Main badge circle
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.badge.tierGradientStart,
                widget.badge.tierGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.badge.tierColor.withAlpha(150),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: context.bgCard,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.badge.icon,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            )
            .then()
            .shake(duration: 500.ms, hz: 2, offset: const Offset(0, 5)),
      ],
    );
  }
}

// Simple notification style badge unlock (for less intrusive notification)
class BadgeUnlockSnackBar {
  static void show(BuildContext context, BadgeModel badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [badge.tierGradientStart, badge.tierGradientEnd],
                ),
              ),
              child: Center(
                child: Text(badge.icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 Badge Unlocked!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${badge.xpReward} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: badge.tierColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}