import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/badges/badge_card.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BadgeCategory? _selectedCategory;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBadges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      await Provider.of<BadgeProvider>(context, listen: false)
          .loadUserBadges(authProvider.userId!);
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
            _buildStatsCard(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
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
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Badges',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStatsCard() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        final stats = badgeProvider.stats;
        final unlocked = stats['unlocked'] ?? 0;
        final total = stats['total'] ?? BadgeModel.allBadges.length;
        final percentage = stats['percentage'] ?? 0;

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
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Collection',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$unlocked / $total Badges',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 10,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // Tier counts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTierCount('Bronze', stats['bronze'] ?? 0, const Color(0xFFCD7F32)),
                  _buildTierCount('Silver', stats['silver'] ?? 0, const Color(0xFFC0C0C0)),
                  _buildTierCount('Gold', stats['gold'] ?? 0, const Color(0xFFFFD700)),
                  _buildTierCount('Platinum', stats['platinum'] ?? 0, const Color(0xFF00D9FF)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildTierCount(String tier, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tier,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 10,
          ),
        ),
      ],
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All Badges'),
          Tab(text: 'Unlocked'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllBadgesTab(),
        _buildUnlockedTab(),
      ],
    );
  }

  Widget _buildAllBadgesTab() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Filter
              _buildCategoryFilter(),
              const SizedBox(height: 20),

              // Badges Grid
              ..._buildBadgesByCategory(badgeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(null, 'All'),
          ...BadgeCategory.values.map((category) {
            return _buildFilterChip(category, _getCategoryName(category));
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BadgeCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBadgesByCategory(BadgeProvider badgeProvider) {
    final unlockedIds = badgeProvider.userBadges.map((b) => b.id).toSet();
    
    if (_selectedCategory != null) {
      final categoryBadges = BadgeModel.getBadgesByCategory(_selectedCategory!);
      return [
        _buildBadgeSection(
          _getCategoryName(_selectedCategory!),
          _getCategoryEmoji(_selectedCategory!),
          categoryBadges,
          unlockedIds,
        ),
      ];
    }

    return BadgeCategory.values.map((category) {
      final categoryBadges = BadgeModel.getBadgesByCategory(category);
      return _buildBadgeSection(
        _getCategoryName(category),
        _getCategoryEmoji(category),
        categoryBadges,
        unlockedIds,
      );
    }).toList();
  }

  Widget _buildBadgeSection(
    String title,
    String emoji,
    List<BadgeModel> badges,
    Set<String> unlockedIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${badges.where((b) => unlockedIds.contains(b.id)).length}/${badges.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final isUnlocked = unlockedIds.contains(badge.id);
            return BadgeCard(
              badge: badge,
              isUnlocked: isUnlocked,
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUnlockedTab() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        final unlockedBadges = badgeProvider.userBadges;

        if (unlockedBadges.isEmpty) {
          return _buildEmptyState();
        }

        // Sort by tier (highest first)
        final sortedBadges = [...unlockedBadges]
          ..sort((a, b) => b.tier.index.compareTo(a.tier.index));

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: sortedBadges.length,
          itemBuilder: (context, index) {
            final badge = sortedBadges[index];
            return BadgeCard(
              badge: badge,
              isUnlocked: true,
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No badges yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete lessons and quizzes to earn badges!',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCategoryName(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.learning:
        return 'Learning';
      case BadgeCategory.streak:
        return 'Streaks';
      case BadgeCategory.quiz:
        return 'Quizzes';
      case BadgeCategory.social:
        return 'Social';
      case BadgeCategory.milestone:
        return 'Milestones';
      case BadgeCategory.special:
        return 'Special';
    }
  }

  String _getCategoryEmoji(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.learning:
        return '📚';
      case BadgeCategory.streak:
        return '🔥';
      case BadgeCategory.quiz:
        return '📝';
      case BadgeCategory.social:
        return '👥';
      case BadgeCategory.milestone:
        return '⭐';
      case BadgeCategory.special:
        return '✨';
    }
  }
}