import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart';
import '../../models/user_model.dart';
import '../../models/friend_model.dart';
import '../social/friend_profile_screen.dart';
import '../../widgets/common/glass_ui.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedScope = 'global';

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
        await _loadGlobalLeaderboard(currentUserId, _tabController.index);
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

  String _getSortField(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'currentStreak';
      case 1:
        return 'lessonsCompleted';
      default:
        return 'totalXP';
    }
  }

  Future<void> _loadGlobalLeaderboard(String currentUserId, int tabIndex) async {
    final firestore = FirebaseFirestore.instance;
    final sortField = _getSortField(tabIndex);

    final snapshot = await firestore
        .collection('users')
        .orderBy(sortField, descending: true)
        .limit(50)
        .get();

    final users =
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

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
    if (odlernId == authProvider.userId) return;

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
      backgroundColor: Colors.transparent,
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
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: AppColors.primary,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 26),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).leaderboard,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
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
          child: GlassCard(
            gradient: AppColors.primaryGradient,
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank > 0 ? '#$rank' : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedScope == 'global'
                            ? AppLocalizations.of(context).globalRanking
                            : AppLocalizations.of(context).friendsRanking,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      _tabController.index == 0
                          ? Icons.local_fire_department_rounded
                          : _tabController.index == 1
                              ? Icons.menu_book_rounded
                              : Icons.star_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    Text(
                      _tabController.index == 0
                          ? '${user.currentStreak} ${AppLocalizations.of(context).daysLabel}'
                          : _tabController.index == 1
                              ? '${user.lessonsCompleted} ${AppLocalizations.of(context).lessonsLabel}'
                              : '${user.totalXP} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedScope == 'global'
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedScope == 'global'
                        ? AppColors.primary
                        : AppColorsDark.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: _selectedScope == 'global'
                          ? Colors.white
                          : context.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).global,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedScope == 'friends'
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedScope == 'friends'
                        ? AppColors.primary
                        : AppColorsDark.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 18,
                      color: _selectedScope == 'friends'
                          ? Colors.white
                          : context.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).friends,
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
        tabs: [
          Tab(text: AppLocalizations.of(context).weekly),
          Tab(text: AppLocalizations.of(context).monthly),
          Tab(text: AppLocalizations.of(context).allTime),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGlobalLeaderboardList() {
    if (_globalLeaderboard.isEmpty) {
      return GlassEmptyState(
        icon: Icons.emoji_events_outlined,
        title: AppLocalizations.of(context).noRankingsYet,
        subtitle: AppLocalizations.of(context).startLearningLeaderboard,
      );
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

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).noFriendsYet,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).addFriendsCompete,
              style: TextStyle(color: context.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GlassPrimaryButton(
              label: AppLocalizations.of(context).findFriends,
              onPressed: () => Navigator.pushNamed(context, '/friends'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboardItem(UserModel user, int rank, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = user.id == authProvider.userId;
    final isTopThree = rank <= 3;

    return GestureDetector(
      onTap: () => _openFriendProfile(user.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          alternate: index.isOdd,
          padding: const EdgeInsets.all(14),
          decorationOverride: isCurrentUser
              ? AppColors.glassCard(alternate: index.isOdd).copyWith(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                )
              : isTopThree
                  ? AppColors.glassCard(alternate: index.isOdd).copyWith(
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    )
                  : null,
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
                              color: isCurrentUser
                                  ? AppColors.primary
                                  : context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppLocalizations.of(context).youLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: Colors.orange, size: 12),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${user.currentStreak} ${AppLocalizations.of(context).streakStat}',
                                  style: TextStyle(
                                      color: context.textMuted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sign_language_rounded,
                                  color: AppColors.primary, size: 12),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${user.signsLearned} ${AppLocalizations.of(context).signsStat}',
                                  style: TextStyle(
                                      color: context.textMuted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tabController.index == 0
                        ? '${user.currentStreak}'
                        : _tabController.index == 1
                            ? '${user.lessonsCompleted}'
                            : '${user.totalXP}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isCurrentUser
                          ? AppColors.primary
                          : context.textPrimary,
                    ),
                  ),
                  Text(
                    _tabController.index == 0
                        ? AppLocalizations.of(context).daysLabel
                        : _tabController.index == 1
                            ? AppLocalizations.of(context).lessonsLabel
                            : 'XP',
                    style: TextStyle(
                        color: context.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildFriendLeaderboardItem(FriendWithUser friend, int rank, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendUser = friend.friendUser;
    final isCurrentUser = friendUser.id == authProvider.userId;
    final isTopThree = rank <= 3;

    return GestureDetector(
      onTap: () => _openFriendProfile(friendUser.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          alternate: index.isOdd,
          padding: const EdgeInsets.all(14),
          decorationOverride: isCurrentUser
              ? AppColors.glassCard(alternate: index.isOdd).copyWith(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                )
              : isTopThree
                  ? AppColors.glassCard(alternate: index.isOdd).copyWith(
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    )
                  : null,
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
                              color: isCurrentUser
                                  ? AppColors.primary
                                  : context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppLocalizations.of(context).youLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Colors.orange, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${friendUser.currentStreak} streak',
                          style: TextStyle(
                              color: context.textMuted, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.sign_language_rounded,
                            color: AppColors.primary, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${friendUser.signsLearned} signs',
                          style: TextStyle(
                              color: context.textMuted, fontSize: 12),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isCurrentUser
                          ? AppColors.primary
                          : context.textPrimary,
                    ),
                  ),
                  Text('XP',
                      style: TextStyle(
                          color: context.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildAvatar(String? photoUrl, String initials, int rank) {
    final colors = _getAvatarColors(rank);
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: photoUrl == null || photoUrl.isEmpty
              ? LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback(initials, colors),
                )
              : _avatarFallback(initials, colors),
        ),
      ),
    );
  }

  Widget _avatarFallback(String initials, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      final icons = [
        Icons.looks_one_rounded,
        Icons.looks_two_rounded,
        Icons.looks_3_rounded,
      ];
      final colors = [
        const Color(0xFFFFD700),
        const Color(0xFFC0C0C0),
        const Color(0xFFCD7F32),
      ];
      return Icon(icons[rank - 1], color: colors[rank - 1], size: 28);
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColorsDark.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
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
        return [const Color(0xFF14B8A6), const Color(0xFF06B6D4)];
    }
  }
}
