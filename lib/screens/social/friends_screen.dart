import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/glass_ui.dart';
import 'friend_profile_screen.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<FriendWithUser> _friends = [];
  List<FriendWithUser> _pendingRequests = [];
  List<FriendChallenge> _incomingChallenges = [];
  List<UserModel> _searchResults = [];

  bool _isLoadingFriends = true;
  bool _isLoadingRequests = true;
  bool _isLoadingChallenges = true;
  bool _isSearching = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.userId;

    if (_currentUserId != null) {
      await Future.wait([
        _loadFriends(),
        _loadPendingRequests(),
        _loadChallenges(),
      ]);
    }
  }

  Future<void> _loadChallenges() async {
    if (_currentUserId == null) return;
    setState(() => _isLoadingChallenges = true);
    try {
      final challenges = await FriendService.getIncomingChallenges(_currentUserId!);
      if (mounted) {
        setState(() {
          _incomingChallenges = challenges;
          _isLoadingChallenges = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChallenges = false);
    }
  }

  Future<void> _loadFriends() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoadingFriends = true);
    
    try {
      final friends = await FriendService.getFriends(_currentUserId!);
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
      if (mounted) {
        setState(() => _isLoadingFriends = false);
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoadingRequests = true);
    
    try {
      final requests = await FriendService.getPendingRequests(_currentUserId!);
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2 || _currentUserId == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await FriendService.searchUsers(query, _currentUserId!);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    HapticService.buttonTap();
    
    final result = await FriendService.acceptFriendRequest(
      _currentUserId!,
      friendshipId,
    );
    
    if (result['success'] == true && mounted) {
      HapticService.success();
      await _loadData();
    }
  }

  Future<void> _declineRequest(String friendshipId) async {
    HapticService.buttonTap();
    
    final success = await FriendService.declineFriendRequest(friendshipId);
    
    if (success) {
      await _loadPendingRequests();
    }
  }

  Future<void> _sendRequest(String toUserId) async {
    HapticService.buttonTap();
    
    final result = await FriendService.sendFriendRequest(
      _currentUserId!,
      toUserId,
    );
    
    if (mounted) {
      if (result['success']) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: AppLocalizations.of(context).friends,
        showBack: false,
        actions: [
          GlassIconButton(
            icon: Icons.qr_code_scanner_rounded,
            iconColor: AppColors.primary,
            onTap: () {
              HapticService.buttonTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFriendScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: context.glassCardDecoration(),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(text: AppLocalizations.of(context).friendsTab),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).requestsTab),
                      if (_pendingRequests.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_pendingRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).challengesTab),
                      if (_incomingChallenges.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_incomingChallenges.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: AppLocalizations.of(context).findTab),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
                _buildChallengesTab(),
                _buildFindTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem({double height = 80}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF0D1A1A),
      highlightColor: const Color(0xFF122020),
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: context.glassCardDecoration(),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoadingFriends) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerItem(),
      );
    }

    if (_friends.isEmpty) {
      return GlassEmptyState(
        icon: Icons.people_outline,
        title: AppLocalizations.of(context).noFriendsYet,
        subtitle: AppLocalizations.of(context).searchFriendsQr,
        actionLabel: AppLocalizations.of(context).addFriendsBtn,
        onAction: () {
          HapticService.buttonTap();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFriendScreen()),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend).animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: -0.1);
        },
      ),
    );
  }

  Widget _buildFriendCard(FriendWithUser friendWithUser) {
    final user = friendWithUser.friendUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassTile(
        onTap: () {
          HapticService.buttonTap();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendProfileScreen(
                friendId: user.id,
                friendshipId: friendWithUser.friendship.id,
              ),
            ),
          );
        },
        leading: _buildAvatarWithRing(user, 48),
        title: Text(user.fullName),
        subtitle: Row(
          children: [
            _buildStatBadge(Icons.star_rounded, '${user.totalXP}'),
            const SizedBox(width: 6),
            _buildStatBadge(Icons.local_fire_department_rounded, '${user.currentStreak}'),
            const SizedBox(width: 6),
            _buildStatBadge(Icons.military_tech_rounded, 'Lv ${user.level}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 18),
      ),
    );
  }

  Widget _buildAvatarWithRing(dynamic user, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        gradient: user.photoUrl == null
            ? const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
              )
            : null,
      ),
      child: ClipOval(
        child: user.photoUrl != null
            ? CachedNetworkImage(
                imageUrl: user.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.3,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) => _buildShimmerItem(height: 120),
      );
    }

    if (_pendingRequests.isEmpty) {
      return GlassEmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: AppLocalizations.of(context).noPendingRequests,
        subtitle: AppLocalizations.of(context).requestsWillAppear,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildRequestCard(request).animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: -0.1);
        },
      ),
    );
  }

  Widget _buildRequestCard(FriendWithUser request) {
    final user = request.friendUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatarWithRing(user, 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatBadge(Icons.star_rounded, '${user.totalXP} XP'),
                          const SizedBox(width: 6),
                          _buildStatBadge(Icons.military_tech_rounded, 'Lv ${user.level}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _declineRequest(request.friendship.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A1A),
                        borderRadius: kGlassRadiusAlt,
                        border: Border.all(color: const Color(0xFF1A3030)),
                      ),
                      child: Text(
                        AppLocalizations.of(context).decline,
                        style: TextStyle(
                          color: context.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _acceptRequest(request.friendship.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                        ),
                        borderRadius: kGlassRadius,
                      ),
                      child: Text(
                        AppLocalizations.of(context).accept,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildChallengesTab() {
    if (_isLoadingChallenges) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) => _buildShimmerItem(height: 130),
      );
    }

    if (_incomingChallenges.isEmpty) {
      return GlassEmptyState(
        icon: Icons.emoji_events_outlined,
        title: AppLocalizations.of(context).noIncomingChallenges,
        subtitle: AppLocalizations.of(context).challengesWillAppear,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _incomingChallenges.length,
        itemBuilder: (context, index) {
          return _buildChallengeCard(_incomingChallenges[index])
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideX(begin: -0.1);
        },
      ),
    );
  }

  Widget _buildChallengeCard(FriendChallenge challenge) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
      alternate: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                ),
                child: Center(
                  child: Text(
                    challenge.userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.challengeFrom} ${challenge.challengerName}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            challenge.quizTypeLabel,
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          challenge.timeLeftText,
                          style: TextStyle(color: context.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (challenge.challengerScore > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    '${l10n.beatThisScore} ${challenge.challengerScore}!',
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                  ),
                ],
              ),
            ),
          ],
          if (challenge.message != null && challenge.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${challenge.message}"',
              style: TextStyle(color: context.textMuted, fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    HapticService.buttonTap();
                    final ok = await FriendService.declineChallenge(challenge.id);
                    if (ok && mounted) {
                      await _loadChallenges();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.challengeDeclined),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1A1A),
                      borderRadius: kGlassRadiusAlt,
                      border: Border.all(color: const Color(0xFF1A3030)),
                    ),
                    child: Text(
                      l10n.declineChallenge,
                      style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    HapticService.buttonTap();
                    await FriendService.acceptChallenge(challenge.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.acceptChallenge} — ${challenge.quizTypeLabel}'),
                          backgroundColor: const Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      await _loadChallenges();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      borderRadius: kGlassRadius,
                    ),
                    child: Text(
                      l10n.acceptChallenge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildFindTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: GlassTextField(
            controller: _searchController,
            hint: AppLocalizations.of(context).searchByNameEmail,
            prefixIcon: Icons.search_rounded,
            suffixWidget: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: context.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : null,
            onFieldSubmitted: (_) => _searchUsers(_searchController.text),
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _searchController.text.length < 2
                  ? _buildSearchPlaceholder()
                  : _searchResults.isEmpty
                      ? GlassEmptyState(
                          icon: Icons.search_off_rounded,
                          title: AppLocalizations.of(context).noUsersFound,
                          subtitle: AppLocalizations.of(context).tryDifferentSearch,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildSearchResultCard(_searchResults[index])
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: index * 50))
                              .slideX(begin: -0.1);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildSearchPlaceholder() {
    return GlassEmptyState(
      icon: Icons.person_search_rounded,
      title: AppLocalizations.of(context).findNewFriends,
      subtitle: AppLocalizations.of(context).searchByNameEmail,
      actionLabel: AppLocalizations.of(context).addByQrCode,
      onAction: () {
        HapticService.buttonTap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFriendScreen()),
        );
      },
    );
  }

  Widget _buildSearchResultCard(UserModel user) {
    return FutureBuilder<String>(
      future: FriendService.getFriendshipStatus(_currentUserId!, user.id),
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'none';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassTile(
            onTap: () {
              HapticService.buttonTap();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendProfileScreen(friendId: user.id),
                ),
              );
            },
            leading: _buildAvatarWithRing(user, 46),
            title: Text(user.fullName),
            subtitle: Row(
              children: [
                const Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  '${user.totalXP} XP  •  Lv ${user.level}',
                  style: TextStyle(color: context.textMuted, fontSize: 12),
                ),
              ],
            ),
            trailing: _buildStatusButton(status, user.id),
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(String status, String userId) {
    switch (status) {
      case 'friends':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(26),
            borderRadius: kGlassRadiusAlt,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: AppColors.success, size: 14),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).friendsTab,
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ],
          ),
        );
      case 'sent':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1A1A),
            borderRadius: kGlassRadiusAlt,
          ),
          child: Text(
            AppLocalizations.of(context).pendingChallenge,
            style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        );
      case 'received':
        return GestureDetector(
          onTap: () => _tabController.animateTo(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)]),
              borderRadius: kGlassRadius,
            ),
            child: Text(
              AppLocalizations.of(context).accept,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        );
      default:
        return GestureDetector(
          onTap: () => _sendRequest(userId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)]),
              borderRadius: kGlassRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context).addFriendsBtn,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ],
            ),
          ),
        );
    }
  }
}