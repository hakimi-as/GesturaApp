import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';
import '../../models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/firestore_service.dart';
import '../badges/badges_screen.dart';

class EnhancedProgressScreen extends StatefulWidget {
  const EnhancedProgressScreen({super.key});

  @override
  State<EnhancedProgressScreen> createState() => _EnhancedProgressScreenState();
}

class _EnhancedProgressScreenState extends State<EnhancedProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Category progress data
  List<Map<String, dynamic>> _categoryProgress = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      await Provider.of<BadgeProvider>(context, listen: false)
          .loadUserBadges(authProvider.userId!);
      await Provider.of<ProgressProvider>(context, listen: false)
          .loadUserProgress(authProvider.userId!);
      
      // Load category progress
      await _loadCategoryProgress(authProvider.userId!);
    }
  }

  Future<void> _loadCategoryProgress(String userId) async {
    try {
      // Get all categories
      final categories = await _firestoreService.getCategories();
      
      // Get user's completed lesson IDs
      final completedIds = await _firestoreService.getCompletedLessonIdsForUser(userId);
      
      // Calculate progress for each category
      List<Map<String, dynamic>> progressList = [];
      
      // Define colors for categories
      final colors = [
        const Color(0xFF6366F1), // Purple
        const Color(0xFF10B981), // Green
        const Color(0xFFF59E0B), // Orange
        const Color(0xFFEC4899), // Pink
        const Color(0xFF3B82F6), // Blue
        const Color(0xFF8B5CF6), // Violet
        const Color(0xFFEF4444), // Red
        const Color(0xFF14B8A6), // Teal
      ];
      
      int colorIndex = 0;
      for (var category in categories) {
        // Get lessons for this category
        final lessons = await _firestoreService.getLessons(category.id);
        final totalLessons = lessons.length;
        
        // Count completed lessons in this category
        int completedCount = 0;
        for (var lesson in lessons) {
          if (completedIds.contains(lesson.id)) {
            completedCount++;
          }
        }
        
        // Calculate progress percentage
        final progress = totalLessons > 0 ? completedCount / totalLessons : 0.0;
        
        progressList.add({
          'name': category.name,
          'emoji': category.icon,
          'progress': progress,
          'completed': completedCount,
          'total': totalLessons,
          'color': colors[colorIndex % colors.length],
        });
        
        colorIndex++;
      }
      
      if (mounted) {
        setState(() {
          _categoryProgress = progressList;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading category progress: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsOverview(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildActivityTab(),
                  _buildAchievementsTab(),
                ],
              ),
            ),
          ],
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
          const Text('📊', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStatsOverview() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Level Progress
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${user?.level ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${user?.level ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user?.xpToNextLevel ?? 100} XP to next level',
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: user?.levelProgress ?? 0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withAlpha(50),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Quick Stats
              Row(
                children: [
                  _buildQuickStat('🔥', '${user?.currentStreak ?? 0}', 'Day Streak'),
                  _buildQuickStat('⭐', _formatNumber(user?.totalXP ?? 0), 'Total XP'),
                  _buildQuickStat('🤟', '${user?.signsLearned ?? 0}', 'Signs'),
                  _buildQuickStat('🏆', '${user?.totalBadges ?? 0}', 'Badges'),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
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
          Tab(text: 'Overview'),
          Tab(text: 'Activity'),
          Tab(text: 'Achievements'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyChart(),
          const SizedBox(height: 24),
          _buildStreakCalendar(),
          const SizedBox(height: 24),
          _buildCategoryProgress(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Consumer2<AuthProvider, ProgressProvider>(
      builder: (context, authProvider, progressProvider, child) {
        // Get real weekly data from ProgressProvider
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final weekData = progressProvider.getWeeklyLessonsCount();
        final maxValue = weekData.reduce((a, b) => a > b ? a : b).clamp(1, 100);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  // Chart
                  SizedBox(
                    height: 170,  // Increased from 150 to fix overflow
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final value = weekData[index];
                        final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;  // Reduced max bar height from 120 to 100
                        final isToday = index == DateTime.now().weekday - 1;

                        return SizedBox(
                          width: 36,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$value',
                                style: TextStyle(
                                  color: isToday ? AppColors.primary : context.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 500 + (index * 100)),
                                width: 32,
                                height: height.clamp(8, 100).toDouble(),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isToday
                                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                        : value > 0
                                            ? [const Color(0xFF10B981).withAlpha(150), const Color(0xFF10B981)]
                                            : [context.bgElevated, context.bgElevated],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isToday || value > 0
                                      ? null
                                      : Border.all(color: context.borderColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                weekDays[index],
                                style: TextStyle(
                                  color: isToday ? AppColors.primary : context.textMuted,
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildChartStat('Total', '${progressProvider.weeklyTotal}', 'lessons'),
                      _buildChartStat('Average', progressProvider.weeklyAverage.toStringAsFixed(1), 'per day'),
                      _buildChartStat('Best', '${progressProvider.weeklyBest}', 'lessons'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  Widget _buildChartStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Streak Calendar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              // Month header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCurrentMonthName(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) => Text(
                        '${auth.currentUser?.currentStreak ?? 0} day streak',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Day labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((day) => SizedBox(
                          width: 36,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Calendar grid
              _buildCalendarGrid(),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        // Get real active days from ProgressProvider
        final activeDays = progressProvider.getActiveDaysForMonth(now.year, now.month);

        return Column(
          children: List.generate(6, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = (weekIndex * 7) + dayIndex - startWeekday + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }

                  final isActive = activeDays.contains(dayNumber);
                  final isToday = dayNumber == now.day;

                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isToday ? AppColors.primary : const Color(0xFF10B981).withAlpha(50))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isActive
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isActive
                              ? (isToday ? Colors.white : const Color(0xFF10B981))
                              : (isToday ? AppColors.primary : context.textMuted),
                          fontSize: 13,
                          fontWeight: isToday || isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCategoryProgress() {
    if (_isLoadingCategories) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_categoryProgress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              const Text('📚', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'No categories yet',
                style: TextStyle(color: context.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📚', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Category Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: _categoryProgress.map((cat) {
              final progress = cat['progress'] as double;
              final completed = cat['completed'] as int;
              final total = cat['total'] as int;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          cat['emoji'] as String,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cat['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$completed/$total',
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: cat['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: context.bgElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cat['color'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildActivityTab() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final activities = progressProvider.progressList;

        if (activities.isEmpty) {
          return _buildEmptyState(
            '📭',
            'No activity yet',
            'Start learning to see your progress here!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityItem(activity).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * index),
                );
          },
        );
      },
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    final isCompleted = activity.isCompleted;
    final title = activity.displayTitle.isNotEmpty ? activity.displayTitle : 'Lesson';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withAlpha(30)
                  : const Color(0xFF6366F1).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isCompleted ? '✅' : '📚',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Completed "$title"' : 'Started "$title"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(activity.lastAccessedAt),
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${activity.xpEarned > 0 ? activity.xpEarned : 10} XP',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        final stats = badgeProvider.stats;
        final unlockedBadges = badgeProvider.userBadges;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Stats Card
              _buildBadgeStatsCard(stats),
              const SizedBox(height: 24),

              // Recent Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Your Badges',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (unlockedBadges.isEmpty)
                _buildEmptyState(
                  '🔒',
                  'No badges yet',
                  'Complete lessons and quizzes to earn badges!',
                )
              else
                _buildBadgesGrid(unlockedBadges),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgeStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Badge Collection',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats['unlocked'] ?? 0} / ${stats['total'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${stats['percentage'] ?? 0}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTierStat('Bronze', stats['bronze'] ?? 0, const Color(0xFFCD7F32)),
              _buildTierStat('Silver', stats['silver'] ?? 0, const Color(0xFFC0C0C0)),
              _buildTierStat('Gold', stats['gold'] ?? 0, const Color(0xFFFFD700)),
              _buildTierStat('Platinum', stats['platinum'] ?? 0, const Color(0xFF00D9FF)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTierStat(String tier, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tier,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid(List<BadgeModel> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length > 8 ? 8 : badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [badge.tierGradientStart, badge.tierGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: badge.tierColor.withAlpha(50),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).scale(
              delay: Duration(milliseconds: 50 * index),
              duration: 300.ms,
            );
      },
    );
  }

  Widget _buildEmptyState(String emoji, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _getCurrentMonthName() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[DateTime.now().month - 1]} ${DateTime.now().year}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}