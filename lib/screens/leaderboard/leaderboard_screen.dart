import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'weekly';
  List<UserModel> _leaderboardUsers = [];
  bool _isLoading = true;
  int _currentUserRank = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedPeriod = 'weekly';
          break;
        case 1:
          _selectedPeriod = 'monthly';
          break;
        case 2:
          _selectedPeriod = 'allTime';
          break;
      }
    });
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userId;

      // Get top users sorted by XP
      final snapshot = await firestore
          .collection('users')
          .orderBy('totalXP', descending: true)
          .limit(50)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Find current user rank
      int rank = 0;
      for (int i = 0; i < users.length; i++) {
        if (users[i].id == currentUserId) {
          rank = i + 1;
          break;
        }
      }

      setState(() {
        _leaderboardUsers = users;
        _currentUserRank = rank;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
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
            _buildCurrentUserCard(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _buildLeaderboardList(),
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
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCurrentUserCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _currentUserRank > 0 ? '#$_currentUserRank' : '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Profile Picture
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(100), width: 2),
                ),
                child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          user.photoUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Ranking',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // XP
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '⭐',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    '${user.totalXP} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
      },
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
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
          Tab(text: 'All Time'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildLeaderboardList() {
    if (_leaderboardUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning to appear on the leaderboard!',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _leaderboardUsers.length,
        itemBuilder: (context, index) {
          final user = _leaderboardUsers[index];
          final rank = index + 1;
          return _buildLeaderboardItem(user, rank, index);
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(UserModel user, int rank, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = user.id == authProvider.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withAlpha(20) : context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : context.borderColor,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: _buildRankBadge(rank),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: user.photoUrl == null || user.photoUrl!.isEmpty
                  ? LinearGradient(
                      colors: _getAvatarColors(rank),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? Colors.transparent
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      user.photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _getAvatarColors(rank)[0],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getAvatarColors(rank),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isCurrentUser ? AppColors.primary : context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '🔥 ${user.currentStreak} day streak',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '🤟 ${user.signsLearned} signs',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.totalXP}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCurrentUser ? AppColors.primary : context.textPrimary,
                ),
              ),
              Text(
                'XP',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      final emojis = ['🥇', '🥈', '🥉'];
      return Text(
        emojis[rank - 1],
        style: const TextStyle(fontSize: 24),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: context.bgElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }

  List<Color> _getAvatarColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [const Color(0xFF8B5CF6), const Color(0xFFEC4899)];
    }
  }
}