import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/design_system.dart';
import '../../config/theme.dart';
import '../../models/challenge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    
    if (authProvider.userId != null && authProvider.currentUser != null) {
      await challengeProvider.loadChallenges(
        authProvider.userId!,
        authProvider.currentUser!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Consumer<ChallengeProvider>(
          builder: (context, challengeProvider, child) {
            final dailyChallenges = challengeProvider.dailyChallenges;
            final weeklyChallenges = challengeProvider.weeklyChallenges;
            final specialChallenges = challengeProvider.specialChallenges;

            return Column(
              children: [
                _buildHeader(),
                _buildStatsCard(challengeProvider),
                _buildTabBar(challengeProvider),
                Expanded(
                  child: challengeProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildChallengesList(dailyChallenges, 'daily'),
                            _buildChallengesList(weeklyChallenges, 'weekly'),
                            _buildChallengesList(specialChallenges, 'special'),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          if (canPop) ...[
            TapScale(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios, color: context.textSecondary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            'Challenges',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.04 * 22,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStatsCard(ChallengeProvider challengeProvider) {
    final dailyChallenges = challengeProvider.dailyChallenges;
    final weeklyChallenges = challengeProvider.weeklyChallenges;
    final activeToday = dailyChallenges.where((c) => !c.isCompleted).length;
    final completedWeekly = weeklyChallenges.where((c) => c.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Text(
        '$activeToday active today · $completedWeekly completed this week',
        style: TextStyle(fontSize: 10, color: context.textMuted),
      ),
    );
  }

  Widget _buildTabBar(ChallengeProvider challengeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: context.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
          Tab(text: 'Special'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildChallengesList(List<ChallengeModel> challenges, String type) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              type == 'daily'
                  ? 'No daily goals yet'
                  : type == 'weekly'
                      ? 'No weekly challenges yet'
                      : 'No special missions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'daily'
                  ? 'Pull down to load today\'s goals'
                  : 'New challenges appear regularly — check back soon',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        return _buildChallengeCard(challenges[index], index);
      },
    );
  }

  void _showChallengeDetail(ChallengeModel challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(challenge.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: context.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress: ${challenge.currentValue} / ${challenge.targetValue}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(challenge.progress * 100).toInt()}%',
                  style: TextStyle(color: challenge.typeColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: challenge.progress,
                minHeight: 8,
                backgroundColor: context.bgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  challenge.isCompleted ? AppColors.success : challenge.typeColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '+${challenge.xpReward} XP reward',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  challenge.remainingTimeText,
                  style: TextStyle(
                    color: challenge.remainingTime < 6 ? AppColors.error : context.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, int index) {
    final isInProgress = !challenge.isCompleted && challenge.progress > 0;
    return TapScale(
      onTap: () => _showChallengeDetail(challenge),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: challenge.isCompleted
              ? AppColors.success.withValues(alpha: 0.31)
              : isInProgress
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : context.borderColor,
        ),
      ),
      child: Column(
        children: [
          // Top row: emoji + title/desc + XP
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.24,
                        color: challenge.isCompleted ? context.textMuted : context.textPrimary,
                        height: 1.2,
                        decoration: challenge.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: TextStyle(fontSize: 9, color: context.textMuted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${challenge.xpReward} XP',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: challenge.isCompleted ? AppColors.success : AppColors.warning,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: TextStyle(fontSize: 9, color: context.textMuted)),
              Text(
                '${challenge.currentValue} / ${challenge.targetValue}',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 3,
              backgroundColor: context.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                challenge.isCompleted ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index));
  }
}
