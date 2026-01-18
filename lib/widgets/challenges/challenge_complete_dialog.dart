import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../../config/theme.dart';
import '../../models/challenge_model.dart';

class ChallengeCompleteDialog extends StatefulWidget {
  final ChallengeModel challenge;
  final VoidCallback? onDismiss;

  const ChallengeCompleteDialog({
    super.key,
    required this.challenge,
    this.onDismiss,
  });

  static Future<void> show(BuildContext context, ChallengeModel challenge) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => ChallengeCompleteDialog(challenge: challenge),
    );
  }

  static Future<void> showMultiple(BuildContext context, List<ChallengeModel> challenges) async {
    for (final challenge in challenges) {
      await show(context, challenge);
    }
  }

  @override
  State<ChallengeCompleteDialog> createState() => _ChallengeCompleteDialogState();
}

class _ChallengeCompleteDialogState extends State<ChallengeCompleteDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    Future.delayed(const Duration(milliseconds: 300), () {
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
                color: widget.challenge.typeColor.withAlpha(100),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.challenge.typeColor.withAlpha(50),
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
                  '🎯 Challenge Complete!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.challenge.typeColor,
                      ),
                ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                const SizedBox(height: 24),

                // Challenge Icon with animation
                _buildChallengeIcon(),
                const SizedBox(height: 20),

                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.challenge.typeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.challenge.typeLabel,
                    style: TextStyle(
                      color: widget.challenge.typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 12),

                // Challenge name
                Text(
                  widget.challenge.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.challenge.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),

                // XP Reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.challenge.typeColor,
                        widget.challenge.typeColor.withAlpha(200),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.challenge.xpReward} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms).scale(delay: 700.ms),
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
                      backgroundColor: widget.challenge.typeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),

          // Confetti
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: [
                widget.challenge.typeColor,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.challenge.typeColor,
            widget.challenge.typeColor.withAlpha(150),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: widget.challenge.typeColor.withAlpha(100),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.challenge.emoji,
          style: const TextStyle(fontSize: 50),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .shimmer(delay: 900.ms, duration: 1000.ms);
  }
}