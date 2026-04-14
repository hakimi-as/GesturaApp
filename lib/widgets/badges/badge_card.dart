import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';
import '../common/glass_ui.dart';

class BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isUnlocked;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool compact;

  const BadgeCard({
    super.key,
    required this.badge,
    this.isUnlocked = false,
    this.onTap,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(12),
          decoration: AppColors.glassCard(alternate: !isUnlocked),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon with teal glow ring when earned
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [badge.tierGradientStart, badge.tierGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUnlocked ? null : const Color(0xFF0D1A1A),
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isUnlocked
                      ? Icon(
                          Icons.emoji_events_rounded,
                          size: 24,
                          color: Colors.white,
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: AppColorsDark.textMuted,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                style: TextStyle(
                  color: isUnlocked ? AppColorsDark.textPrimary : AppColorsDark.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showBadgeDetails(context),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColors.glassCard(alternate: !isUnlocked).copyWith(
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(40),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon with tier ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer teal glow ring for unlocked
                  if (isUnlocked)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withAlpha(50),
                            AppColors.primary.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  // Tier ring
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked
                          ? LinearGradient(
                              colors: [badge.tierGradientStart, badge.tierGradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUnlocked ? null : const Color(0xFF0D1A1A),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F2020),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isUnlocked
                            ? Icon(
                                Icons.emoji_events_rounded,
                                size: 32,
                                color: Colors.white,
                              )
                            : Icon(
                                badge.isSecret ? Icons.help_rounded : Icons.lock_rounded,
                                size: 28,
                                color: AppColorsDark.textMuted,
                              ),
                      ),
                    ),
                  ),
                  // Tier badge label
                  if (isUnlocked)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [badge.tierGradientStart, badge.tierGradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge.tierName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Badge name
              Text(
                isUnlocked || !badge.isSecret ? badge.name : '???',
                style: TextStyle(
                  color: isUnlocked ? AppColorsDark.textPrimary : AppColorsDark.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              if (showDetails) ...[
                const SizedBox(height: 6),
                Text(
                  isUnlocked || !badge.isSecret ? badge.description : 'Secret Badge',
                  style: const TextStyle(
                    color: AppColorsDark.textMuted,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.success.withAlpha(26)
                        : AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${badge.xpReward} XP',
                    style: TextStyle(
                      color: isUnlocked ? AppColors.success : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: AppColors.glassCard().copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColorsDark.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Large badge icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [badge.tierGradientStart, badge.tierGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUnlocked ? null : const Color(0xFF0D1A1A),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2020),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isUnlocked
                      ? const Icon(Icons.emoji_events_rounded, size: 48, color: Colors.white)
                      : const Icon(Icons.lock_rounded, size: 44, color: AppColorsDark.textMuted),
                ),
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),

            // Tier badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [badge.tierGradientStart, badge.tierGradientEnd]
                      : [const Color(0xFF0D1A1A), const Color(0xFF0D1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.tierName,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : AppColorsDark.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              badge.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsDark.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              badge.description,
              style: const TextStyle(
                color: AppColorsDark.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  icon: Icons.star_rounded,
                  label: '+${badge.xpReward} XP',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                  label: isUnlocked ? 'Unlocked' : 'Locked',
                  color: isUnlocked ? AppColors.success : AppColorsDark.textMuted,
                ),
              ],
            ),

            if (isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Unlocked on ${_formatDate(badge.unlockedAt!)}',
                style: const TextStyle(
                  color: AppColorsDark.textMuted,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Mini badge for displaying in rows
class MiniBadge extends StatelessWidget {
  final BadgeModel badge;
  final bool isUnlocked;
  final double size;

  const MiniBadge({
    super.key,
    required this.badge,
    this.isUnlocked = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [badge.tierGradientStart, badge.tierGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : const Color(0xFF0D1A1A),
          border: Border.all(
            color: isUnlocked ? AppColors.primary : AppColorsDark.border,
            width: 2,
          ),
        ),
        child: Center(
          child: isUnlocked
              ? Icon(Icons.emoji_events_rounded, size: size * 0.45, color: Colors.white)
              : Icon(Icons.lock_rounded, size: size * 0.45, color: AppColorsDark.textMuted),
        ),
      ),
    );
  }
}
