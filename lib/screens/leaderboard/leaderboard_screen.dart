import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart';
import '../../models/user_model.dart';
import '../../models/friend_model.dart';
import '../social/friend_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedScope = 'global'; // 'global' or 'friends'
  
  List<UserModel> _globalLeaderboard = [];
  List<FriendWithUser> _friendsLeaderboard = [];
  bool _isLoading = true;
  int _currentUserGlobalRank = 0;
  int _currentUserFriendRank = 0;

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
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userId ?? '';

      if (_selectedScope == 'global') {
        await _loadGlobalLeaderboard(currentUserId);
      } else {
        await _loadFriendsLeaderboard(currentUserId);
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGlobalLeaderboard(String currentUserId) async {
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore
        .collection('users')
        .orderBy('totalXP', descending: true)
        .limit(50)
        .get();

    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    int rank = 0;
    for (int i = 0; i < users.length; i++) {
      if (users[i].id == currentUserId) {
        rank = i + 1;
        break;
      }
    }

    _globalLeaderboard = users;
    _currentUserGlobalRank = rank;
  }

  Future<void> _loadFriendsLeaderboard(String currentUserId) async {
    final friends = await FriendService.getLeaderboard(currentUserId);

    int rank = 0;
    for (int i = 0; i < friends.length; i++) {
      if (friends[i].friendUser.id == currentUserId) {
        rank = i + 1;
        break;
      }
    }

    _friendsLeaderboard = friends;
    _currentUserFriendRank = rank;
  }

  void _toggleScope(String scope) {
    if (_selectedScope == scope) return;
    HapticService.buttonTap();
    setState(() => _selectedScope = scope);
    _loadLeaderboard();
  }

  void _openFriendProfile(String odlernId) {
    HapticService.buttonTap();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (odlernId == authProvider.userId) return; // Don't open own profile
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(friendId: odlernId),
      ),
    );
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
            _buildScopeToggle(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _selectedScope == 'global'
                      ? _buildGlobalLeaderboardList()
                      : _buildFriendsLeaderboardList(),
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

        final rank = _selectedScope == 'global' 
            ? _currentUserGlobalRank 
            : _currentUserFriendRank;

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
                    rank > 0 ? '#$rank' : '-',
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
                      _selectedScope == 'global' ? 'Global Ranking' : 'Friends Ranking',
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

  Widget _buildScopeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleScope('global'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedScope == 'global' 
                      ? AppColors.primary 
                      : context.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedScope == 'global' 
                        ? AppColors.primary 
                        : context.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public,
                      size: 18,
                      color: _selectedScope == 'global' 
                          ? Colors.white 
                          : context.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Global',
                      style: TextStyle(
                        color: _selectedScope == 'global' 
                            ? Colors.white 
                            : context.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleScope('friends'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedScope == 'friends' 
                      ? AppColors.primary 
                      : context.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedScope == 'friends' 
                        ? AppColors.primary 
                        : context.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 18,
                      color: _selectedScope == 'friends' 
                          ? Colors.white 
                          : context.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Friends',
                      style: TextStyle(
                        color: _selectedScope == 'friends' 
                            ? Colors.white 
                            : context.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
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

  Widget _buildGlobalLeaderboardList() {
    if (_globalLeaderboard.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _globalLeaderboard.length,
        itemBuilder: (context, index) {
          final user = _globalLeaderboard[index];
          final rank = index + 1;
          return _buildGlobalLeaderboardItem(user, rank, index);
        },
      ),
    );
  }

  Widget _buildFriendsLeaderboardList() {
    if (_friendsLeaderboard.isEmpty) {
      return _buildEmptyFriendsState();
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _friendsLeaderboard.length,
        itemBuilder: (context, index) {
          final friend = _friendsLeaderboard[index];
          final rank = index + 1;
          return _buildFriendLeaderboardItem(friend, rank, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to compete with them!',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to friends screen
              Navigator.pushNamed(context, '/friends');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Find Friends'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboardItem(UserModel user, int rank, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = user.id == authProvider.userId;

    return GestureDetector(
      onTap: () => _openFriendProfile(user.id),
      child: Container(
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
            SizedBox(width: 40, child: _buildRankBadge(rank)),
            const SizedBox(width: 12),
            _buildAvatar(user.photoUrl, user.initials, rank),
            const SizedBox(width: 12),
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
                        '🔥 ${user.currentStreak} streak',
                        style: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '🤟 ${user.signsLearned} signs',
                        style: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                Text('XP', style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildFriendLeaderboardItem(FriendWithUser friend, int rank, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendUser = friend.friendUser; // Access the UserModel
    final isCurrentUser = friendUser.id == authProvider.userId;

    return GestureDetector(
      onTap: () => _openFriendProfile(friendUser.id),
      child: Container(
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
            SizedBox(width: 40, child: _buildRankBadge(rank)),
            const SizedBox(width: 12),
            _buildAvatar(friendUser.photoUrl, friendUser.initials, rank),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          friendUser.fullName,
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
                        '🔥 ${friendUser.currentStreak} streak',
                        style: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '🤟 ${friendUser.signsLearned} signs',
                        style: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${friendUser.totalXP}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCurrentUser ? AppColors.primary : context.textPrimary,
                  ),
                ),
                Text('XP', style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildAvatar(String? photoUrl, String initials, int rank) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: photoUrl == null || photoUrl.isEmpty
            ? LinearGradient(
                colors: _getAvatarColors(rank),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _getAvatarColors(rank)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      final emojis = ['🥇', '🥈', '🥉'];
      return Text(emojis[rank - 1], style: const TextStyle(fontSize: 24));
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