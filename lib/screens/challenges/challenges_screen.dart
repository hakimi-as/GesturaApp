import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(
                Icons.arrow_back,
                color: context.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('🎯', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Challenges',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCompleted Completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '$totalXpAvailable XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
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
            const Text('🎯', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'No $type challenges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new challenges!',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 14,
              ),
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

  Widget _buildChallengeCard(ChallengeModel challenge, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: challenge.isCompleted
              ? AppColors.success.withAlpha(100)
              : context.borderColor,
          width: challenge.isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: challenge.typeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    challenge.emoji,
                    style: const TextStyle(fontSize: 28),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: challenge.typeColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            challenge.typeLabel,
                            style: TextStyle(
                              color: challenge.typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: challenge.progress,
                        minHeight: 8,
                        backgroundColor: context.bgElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          challenge.isCompleted
                              ? AppColors.success
                              : challenge.typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // XP Reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: challenge.isCompleted
                      ? AppColors.success.withAlpha(26)
                      : AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      challenge.isCompleted ? '✅' : '⭐',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+${challenge.xpReward}',
                      style: TextStyle(
                        color: challenge.isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
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
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
  }
}