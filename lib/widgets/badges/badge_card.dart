import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';

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
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked ? context.bgCard : context.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? badge.tierColor.withAlpha(100) : context.borderColor,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
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
                color: isUnlocked ? null : context.bgElevated,
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: badge.tierColor.withAlpha(50),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  isUnlocked ? badge.icon : '🔒',
                  style: TextStyle(
                    fontSize: isUnlocked ? 24 : 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Badge Name
            Text(
              badge.name,
              style: TextStyle(
                color: isUnlocked ? context.textPrimary : context.textMuted,
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
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showBadgeDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? badge.tierColor.withAlpha(100) : context.borderColor,
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: badge.tierColor.withAlpha(30),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon with Tier Ring
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow for unlocked
                if (isUnlocked)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          badge.tierColor.withAlpha(50),
                          badge.tierColor.withAlpha(0),
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
                    color: isUnlocked ? null : context.bgElevated,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnlocked ? context.bgCard : context.bgElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isUnlocked ? badge.icon : (badge.isSecret ? '❓' : '🔒'),
                        style: TextStyle(
                          fontSize: isUnlocked ? 32 : 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // Tier badge
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

            // Badge Name
            Text(
              isUnlocked || !badge.isSecret ? badge.name : '???',
              style: TextStyle(
                color: isUnlocked ? context.textPrimary : context.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            if (showDetails) ...[
              const SizedBox(height: 6),
              // Description
              Text(
                isUnlocked || !badge.isSecret ? badge.description : 'Secret Badge',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // XP Reward
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
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Large Badge Icon
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
                color: isUnlocked ? null : context.bgElevated,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: badge.tierColor.withAlpha(100),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  color: context.bgCard,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? badge.icon : '🔒',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),

            // Tier Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [badge.tierGradientStart, badge.tierGradientEnd]
                      : [context.bgElevated, context.bgElevated],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.tierName,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : context.textMuted,
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
                  ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              badge.description,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  icon: '⭐',
                  label: '+${badge.xpReward} XP',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: isUnlocked ? '✅' : '🔒',
                  label: isUnlocked ? 'Unlocked' : 'Locked',
                  color: isUnlocked ? AppColors.success : context.textMuted,
                ),
              ],
            ),

            if (isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Unlocked on ${_formatDate(badge.unlockedAt!)}',
                style: TextStyle(
                  color: context.textMuted,
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
    required String icon,
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
          Text(icon, style: const TextStyle(fontSize: 16)),
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
    return Container(
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
        color: isUnlocked ? null : context.bgElevated,
        border: Border.all(
          color: isUnlocked ? badge.tierColor : context.borderColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isUnlocked ? badge.icon : '🔒',
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}