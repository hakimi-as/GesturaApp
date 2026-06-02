import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/design_system.dart';
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
    return TapScale(
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
                color: isUnlocked ? badge.tierColor.withAlpha(30) : context.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? badge.tierColor.withAlpha(120) : context.borderColor,
                  width: isUnlocked ? 2 : 1,
                ),
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
    return TapScale(
      onTap: onTap ?? () => _showBadgeDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? badge.tierColor.withAlpha(100) : context.borderColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon with Tier Ring
            Stack(
              alignment: Alignment.center,
              children: [
                // Tier ring — border-only (no solid fill)
                _buildIconRing(context),
                // Tier pill at bottom
                if (isUnlocked)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badge.tierColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badge.tierName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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

  Widget _buildIconRing(BuildContext context) {
    final ring = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked ? badge.tierColor.withAlpha(30) : context.bgElevated,
        border: Border.all(
          color: isUnlocked ? badge.tierColor : context.borderColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isUnlocked ? badge.icon : (badge.isSecret ? '❓' : '🔒'),
          style: TextStyle(fontSize: isUnlocked ? 32 : 26),
        ),
      ),
    );

    if (isUnlocked) return ring;

    // Locked: desaturate + reduce opacity
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      0.45, 0,
      ]),
      child: ring,
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
                color: isUnlocked ? badge.tierColor.withAlpha(30) : context.bgElevated,
                border: Border.all(
                  color: isUnlocked ? badge.tierColor : context.borderColor,
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? badge.icon : '🔒',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),

            // Tier Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isUnlocked ? badge.tierColor.withAlpha(26) : context.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnlocked ? badge.tierColor.withAlpha(80) : context.borderColor,
                ),
              ),
              child: Text(
                badge.tierName.toUpperCase(),
                style: TextStyle(
                  color: isUnlocked ? badge.tierColor : context.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
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
        color: isUnlocked ? badge.tierColor.withAlpha(40) : context.bgElevated,
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