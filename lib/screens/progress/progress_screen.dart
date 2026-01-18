import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/achievement_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    if (authProvider.userId != null) {
      await progressProvider.loadUserProgress(authProvider.userId!);
      await progressProvider.loadAchievements(authProvider.userId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Progress'),
      ),
      body: Column(
        children: [
          // Stats Summary Card
          _buildStatsSummary(context),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Achievements'),
                Tab(text: 'History'),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context),
                _buildAchievementsTab(context),
                _buildHistoryTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    return Consumer2<AuthProvider, ProgressProvider>(
      builder: (context, authProvider, progressProvider, child) {
        final user = authProvider.currentUser;
        final stats = progressProvider.userStats;

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('⭐', '${user?.totalXP ?? 0}', 'Total XP'),
                  _buildSummaryItem('🔥', '${user?.currentStreak ?? 0}', 'Day Streak'),
                  _buildSummaryItem('📚', '${stats.totalSignsLearned}', 'Signs Learned'),
                ],
              ),
              const SizedBox(height: 16),
              // Level Progress
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${user?.level ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${user?.xpToNextLevel ?? 100} XP to Level ${(user?.level ?? 1) + 1}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: user?.levelProgress ?? 0,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
      },
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final stats = progressProvider.userStats;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Activity
              Text(
                'Weekly Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              _buildWeeklyActivity(context),
              const SizedBox(height: 24),

              // Detailed Stats
              Text(
                'Detailed Stats',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
              _buildDetailedStats(context, stats),
              const SizedBox(height: 24),

              // Daily Goals
              Text(
                'Daily Goals',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
              _buildDailyGoals(context),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyActivity(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isToday = index == today;
          final isActive = index <= today; // Simulated activity

          return Column(
            children: [
              Text(
                day,
                style: TextStyle(
                  color: isToday ? AppColors.primary : context.textMuted,
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isToday ? AppColors.primary : AppColors.success.withOpacity(0.2))
                      : context.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isActive
                      ? Icon(
                          Icons.check,
                          color: isToday ? Colors.white : AppColors.success,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildDetailedStats(BuildContext context, stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatRow(context, '⏱️', 'Total Learning Time', '${stats.totalTimeHours.toStringAsFixed(1)} hours'),
          Divider(color: context.borderColor, height: 24),
          _buildStatRow(context, '🎯', 'Quiz Accuracy', '${stats.averageAccuracy.toInt()}%'),
          Divider(color: context.borderColor, height: 24),
          _buildStatRow(context, '📝', 'Quizzes Completed', '${stats.quizzesCompleted}'),
          Divider(color: context.borderColor, height: 24),
          _buildStatRow(context, '🏆', 'Perfect Quizzes', '${stats.perfectQuizzes}'),
          Divider(color: context.borderColor, height: 24),
          _buildStatRow(context, '🔥', 'Longest Streak', '${stats.longestStreak} days'),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms);
  }

  Widget _buildStatRow(BuildContext context, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoals(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final goals = progressProvider.dailyGoals;

        if (goals.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No goals set for today',
                style: TextStyle(color: context.textMuted),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: goals.map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          goal.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: goal.isCompleted ? AppColors.success : context.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: TextStyle(
                              color: goal.isCompleted
                                  ? context.textMuted
                                  : context.textPrimary,
                              decoration: goal.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          '+${goal.xpReward} XP',
                          style: TextStyle(
                            color: goal.isCompleted
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal.progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: context.bgElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goal.isCompleted ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 650.ms);
      },
    );
  }

  Widget _buildAchievementsTab(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final earned = progressProvider.earnedAchievementsList;
        final locked = progressProvider.lockedAchievementsList;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earned Achievements
              Text(
                'Earned (${earned.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (earned.isEmpty)
                _buildEmptyAchievements(context, 'No achievements earned yet')
              else
                ...earned.asMap().entries.map((entry) =>
                    _buildAchievementCard(context, entry.value, true, entry.key)),
              const SizedBox(height: 24),

              // Locked Achievements
              Text(
                'Locked (${locked.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...locked.asMap().entries.map((entry) =>
                  _buildAchievementCard(context, entry.value, false, entry.key)),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyAchievements(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    AchievementModel achievement,
    bool isEarned,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned
            ? context.bgCard
            : context.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: isEarned
            ? Border.all(
                color: Color(int.parse(achievement.tierColor.replaceFirst('#', '0xFF'))).withOpacity(0.5),
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEarned
                  ? Color(int.parse(achievement.tierColor.replaceFirst('#', '0xFF'))).withOpacity(0.15)
                  : context.bgElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                isEarned ? achievement.icon : '🔒',
                style: TextStyle(
                  fontSize: 28,
                  color: isEarned ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isEarned ? context.textPrimary : context.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse(achievement.tierColor.replaceFirst('#', '0xFF'))).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  achievement.tierDisplayName,
                  style: TextStyle(
                    color: Color(int.parse(achievement.tierColor.replaceFirst('#', '0xFF'))),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${achievement.xpReward} XP',
                style: TextStyle(
                  color: isEarned ? AppColors.success : context.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
  }

  Widget _buildHistoryTab(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final progress = progressProvider.progressList;

        if (progress.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📜', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                Text(
                  'No learning history yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete lessons to see your history here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: progress.length,
          itemBuilder: (context, index) {
            final item = progress[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        item.isCompleted ? Icons.check_circle : Icons.access_time,
                        color: item.isCompleted ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lesson: ${item.lessonId}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.isCompleted ? 'Completed' : 'In Progress',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatHistoryDate(item.lastAccessedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
          },
        );
      },
    );
  }

  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}