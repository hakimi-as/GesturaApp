import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/share_service.dart';

class ShareProgressCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onClose;

  const ShareProgressCard({
    super.key,
    required this.user,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Text('📤', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Show off your achievements!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Share Options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildShareOption(
                  context,
                  icon: '📊',
                  title: 'Share Stats',
                  subtitle: 'XP, streak, signs learned',
                  onTap: () async {
                    await ShareService().shareTextStats(user);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  context,
                  icon: '🔥',
                  title: 'Share Streak',
                  subtitle: '${user.currentStreak} day learning streak',
                  onTap: () async {
                    await ShareService().shareStreakMilestone(user.currentStreak);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  context,
                  icon: '🎯',
                  title: 'Share Level',
                  subtitle: 'Level ${user.level} achievement',
                  onTap: () async {
                    await ShareService().shareLevelUp(user.level);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildShareOption(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet to show share options
void showShareProgressSheet(BuildContext context, UserModel user) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ShareProgressCard(
      user: user,
      onClose: () => Navigator.pop(context),
    ),
  );
}