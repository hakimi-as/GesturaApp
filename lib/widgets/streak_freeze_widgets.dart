import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/haptic_service.dart';

/// Streak Freeze Display Widget - shows current freeze count
class StreakFreezeWidget extends StatelessWidget {
  final int freezeCount;
  final int maxFreezes;
  final VoidCallback? onTap;
  final bool compact;

  const StreakFreezeWidget({
    super.key,
    required this.freezeCount,
    this.maxFreezes = 2,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: freezeCount > 0 
              ? const Color(0xFF06B6D4).withAlpha(26)
              : context.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: freezeCount > 0 
                ? const Color(0xFF06B6D4).withAlpha(77)
                : context.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧊', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$freezeCount',
              style: TextStyle(
                color: freezeCount > 0 ? const Color(0xFF06B6D4) : context.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: freezeCount > 0
              ? const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: freezeCount == 0 ? context.bgCard : null,
          borderRadius: BorderRadius.circular(16),
          border: freezeCount == 0 
              ? Border.all(color: context.borderColor)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: freezeCount > 0 
                    ? Colors.white.withAlpha(51)
                    : const Color(0xFF06B6D4).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🧊', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Freezes',
                    style: TextStyle(
                      color: freezeCount > 0 ? Colors.white : context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    freezeCount > 0
                        ? 'Protects your streak if you miss a day'
                        : 'Earn freezes by maintaining 7-day streaks',
                    style: TextStyle(
                      color: freezeCount > 0 
                          ? Colors.white.withAlpha(180)
                          : context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Freeze indicators
            Row(
              children: List.generate(maxFreezes, (index) {
                final isActive = index < freezeCount;
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withAlpha(51)
                        : (freezeCount > 0 
                            ? Colors.white.withAlpha(26)
                            : context.bgElevated),
                    borderRadius: BorderRadius.circular(8),
                    border: !isActive
                        ? Border.all(
                            color: freezeCount > 0
                                ? Colors.white.withAlpha(77)
                                : context.borderColor,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      isActive ? '🧊' : '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}


/// Streak Freeze Card for Dashboard - More detailed view
class StreakFreezeCard extends StatelessWidget {
  final int freezeCount;
  final int currentStreak;
  final int daysUntilNextFreeze;
  final VoidCallback? onBuyFreeze;
  final VoidCallback? onLearnMore;

  const StreakFreezeCard({
    super.key,
    required this.freezeCount,
    required this.currentStreak,
    this.daysUntilNextFreeze = 0,
    this.onBuyFreeze,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    final canBuy = freezeCount < 2;
    final nextFreezeIn = 7 - (currentStreak % 7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🧊', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Freeze',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Protect your streak when life gets busy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Freeze indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFreezeSlot(context, 0, freezeCount),
              const SizedBox(width: 16),
              _buildFreezeSlot(context, 1, freezeCount),
            ],
          ),

          const SizedBox(height: 20),

          // Status text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (freezeCount == 2)
                  const Text(
                    '✅ You have maximum freezes!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  )
                else if (freezeCount == 1)
                  Text(
                    '1 freeze available • Next in $nextFreezeIn days',
                    style: TextStyle(color: context.textSecondary),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'No freezes • Earn one in $nextFreezeIn days',
                    style: TextStyle(color: context.textMuted),
                    textAlign: TextAlign.center,
                  ),
                
                if (currentStreak > 0) ...[
                  const SizedBox(height: 8),
                  // Progress to next freeze
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (currentStreak % 7) / 7,
                            backgroundColor: context.borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF06B6D4),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentStreak % 7}/7',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onLearnMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimary,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Learn More'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: canBuy ? onBuyFreeze : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    disabledBackgroundColor: context.bgElevated,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    canBuy ? 'Buy (500 XP)' : 'Max Reached',
                    style: TextStyle(
                      color: canBuy ? Colors.white : context.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildFreezeSlot(BuildContext context, int index, int count) {
    final isActive = index < count;
    
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF06B6D4).withAlpha(26)
                : context.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF06B6D4)
                  : context.borderColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: isActive
                ? const Text('🧊', style: TextStyle(fontSize: 32))
                : Icon(
                    Icons.add,
                    color: context.textMuted,
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isActive ? 'Ready' : 'Empty',
          style: TextStyle(
            color: isActive ? const Color(0xFF06B6D4) : context.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


/// Streak Freeze Dialog - Shows when freeze is used or earned
class StreakFreezeDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isEarned; // true = earned, false = used
  final int remainingFreezes;
  final VoidCallback? onClose;

  const StreakFreezeDialog({
    super.key,
    required this.title,
    required this.message,
    required this.isEarned,
    required this.remainingFreezes,
    this.onClose,
  });

  /// Show freeze earned dialog
  static Future<void> showEarned(BuildContext context, int remaining) {
    HapticService.achievement();
    return showDialog(
      context: context,
      builder: (_) => StreakFreezeDialog(
        title: 'Streak Freeze Earned! 🧊',
        message: 'You earned a streak freeze for maintaining your streak!',
        isEarned: true,
        remainingFreezes: remaining,
      ),
    );
  }

  /// Show freeze used dialog
  static Future<void> showUsed(BuildContext context, int remaining, int streakProtected) {
    HapticService.streakFreezeUsed();
    return showDialog(
      context: context,
      builder: (_) => StreakFreezeDialog(
        title: 'Streak Protected! 🛡️',
        message: 'Your $streakProtected-day streak was saved by a freeze!',
        isEarned: false,
        remainingFreezes: remaining,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEarned
                    ? const Color(0xFF06B6D4).withAlpha(26)
                    : AppColors.success.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isEarned ? '🧊' : '🛡️',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ).animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Remaining freezes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '$remainingFreezes freeze${remainingFreezes != 1 ? 's' : ''} remaining',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticService.buttonTap();
                  Navigator.of(context).pop();
                  onClose?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEarned 
                      ? const Color(0xFF06B6D4)
                      : AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}


/// Buy Freeze Confirmation Dialog
class BuyFreezeDialog extends StatelessWidget {
  final int currentXP;
  final int cost;
  final VoidCallback onConfirm;

  const BuyFreezeDialog({
    super.key,
    required this.currentXP,
    required this.cost,
    required this.onConfirm,
  });

  static Future<bool?> show(BuildContext context, int currentXP) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BuyFreezeDialog(
        currentXP: currentXP,
        cost: 500,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = currentXP >= cost;

    return Dialog(
      backgroundColor: context.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Buy Streak Freeze?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Protect your streak when you miss a day.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Cost display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost:',
                    style: TextStyle(color: context.textSecondary),
                  ),
                  Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '$cost XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Your XP
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: canAfford 
                    ? AppColors.success.withAlpha(26)
                    : AppColors.error.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your XP:',
                    style: TextStyle(color: context.textSecondary),
                  ),
                  Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '$currentXP XP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: canAfford ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!canAfford) ...[
              const SizedBox(height: 12),
              Text(
                'You need ${cost - currentXP} more XP',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAfford ? onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      disabledBackgroundColor: context.bgElevated,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Buy',
                      style: TextStyle(
                        color: canAfford ? Colors.white : context.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ==================== STREAK FREEZE MODAL (INFO SHEET) ====================

/// Bottom sheet that explains how streak freezes work
/// Used when user taps "Learn More" or the freeze icon
class StreakFreezeModal extends StatelessWidget {
  const StreakFreezeModal({super.key});

  /// Show the modal as a bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const StreakFreezeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🧊', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Streak Freeze',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Protect your streak when life gets busy',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Info cards
          _buildInfoItem(
            context,
            icon: '🎯',
            title: 'Earn Freezes',
            description: 'Get 1 freeze for every 7-day streak',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: '💰',
            title: 'Buy with XP',
            description: 'Purchase freezes for 500 XP each',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: '📦',
            title: 'Max Storage',
            description: 'Hold up to 2 freezes at a time',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: '🛡️',
            title: 'Auto-Protection',
            description: 'Automatically used when you miss a day',
          ),

          const SizedBox(height: 28),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticService.buttonTap();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}