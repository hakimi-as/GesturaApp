import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/challenge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/common/glass_ui.dart';

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
      backgroundColor: Colors.transparent,
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
                _buildTabBar(),
                Expanded(
                  child: challengeProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: AppColors.primary,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 26),
          const SizedBox(width: 8),
          Text(
            'Challenges',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
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
    final specialChallenges = challengeProvider.specialChallenges;

    final completedDaily = dailyChallenges.where((c) => c.isCompleted).length;
    final completedWeekly = weeklyChallenges.where((c) => c.isCompleted).length;
    final completedSpecial = specialChallenges.where((c) => c.isCompleted).length;
    final totalCompleted = completedDaily + completedWeekly + completedSpecial;
    final totalXpAvailable = challengeProvider.totalXPAvailable;

    return Container(
      margin: const EdgeInsets.all(20),
      child: GlassCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Challenges',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCompleted Completed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '$totalXpAvailable XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniStat('Daily', '$completedDaily/${dailyChallenges.length}'),
                const SizedBox(width: 16),
                _buildMiniStat('Weekly', '$completedWeekly/${weeklyChallenges.length}'),
                const SizedBox(width: 16),
                _buildMiniStat('Special', '$completedSpecial/${specialChallenges.length}'),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: context.glassCardDecoration(),
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
      return GlassEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No $type challenges',
        subtitle: 'Check back later for new challenges!',
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

  Widget _buildChallengeCard(ChallengeModel challenge, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        alternate: index.isOdd,
        padding: const EdgeInsets.all(16),
        decorationOverride: AppColors.glassCard(alternate: index.isOdd).copyWith(
          border: Border.all(
            color: challenge.isCompleted
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColorsDark.border,
            width: challenge.isCompleted ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: challenge.typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: challenge.typeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getChallengeIcon(challenge.type.name),
                      color: challenge.typeColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GlassChip(
                            label: challenge.typeLabel,
                            active: true,
                            onTap: null,
                          ),
                          if (challenge.isPersonalized || challenge.isAutoGenerated) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.auto_awesome,
                                      color: Color(0xFF6366F1), size: 10),
                                  SizedBox(width: 3),
                                  Text(
                                    'For You',
                                    style: TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            challenge.remainingTimeText,
                            style: TextStyle(
                              color: challenge.remainingTime < 6
                                  ? AppColors.error
                                  : context.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
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
            const SizedBox(height: 16),
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${challenge.currentValue}/${challenge.targetValue}',
                            style: TextStyle(
                              color: challenge.isCompleted
                                  ? AppColors.success
                                  : context.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${(challenge.progress * 100).toInt()}%',
                            style: TextStyle(
                              color: challenge.isCompleted
                                  ? AppColors.success
                                  : context.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GlassProgressBar(value: challenge.progress),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // XP Reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: challenge.isCompleted
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: challenge.isCompleted
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        challenge.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.star_rounded,
                        color: challenge.isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${challenge.xpReward}',
                        style: TextStyle(
                          color: challenge.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'XP',
                        style: TextStyle(
                          color: challenge.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
  }

  IconData _getChallengeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.date_range_rounded;
      case 'special':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
