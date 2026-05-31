import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/design_system.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
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

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0=All-time, 1=Weekly, 2=Monthly
  String _selectedScope = 'global'; // 'global' or 'friends'

  List<UserModel> _globalLeaderboard = [];
  List<FriendWithUser> _friendsLeaderboard = [];
  bool _isLoading = true;

  final Map<String, List<UserModel>> _globalCache = {};
  final Map<String, List<FriendWithUser>> _friendsCache = {};
  DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 3);
  bool _hasError = false;

  bool get _cacheValid =>
      _cacheTime != null && DateTime.now().difference(_cacheTime!) < _cacheTtl;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  String _getSortField(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'totalXP';
      case 1:
        return 'currentStreak';
      default:
        return 'lessonsCompleted';
    }
  }

  Future<void> _loadLeaderboard({bool forceRefresh = false}) async {
    final key = '${_selectedScope}_$_selectedTab';

    if (!forceRefresh && _cacheValid) {
      if (_selectedScope == 'global' && _globalCache.containsKey(key)) {
        if (mounted) setState(() { _globalLeaderboard = _globalCache[key]!; _isLoading = false; });
        return;
      }
      if (_selectedScope == 'friends' && _friendsCache.containsKey(key)) {
        if (mounted) setState(() { _friendsLeaderboard = _friendsCache[key]!; _isLoading = false; });
        return;
      }
    }

    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userId ?? '';
      if (_selectedScope == 'global') {
        await _loadGlobalLeaderboard(currentUserId, _selectedTab);
        _globalCache[key] = List.from(_globalLeaderboard);
      } else {
        await _loadFriendsLeaderboard(currentUserId);
        _friendsCache[key] = List.from(_friendsLeaderboard);
      }
      _cacheTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading leaderboard: $e');
      if (mounted) setState(() => _hasError = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadGlobalLeaderboard(String currentUserId, int tabIndex) async {
    final firestore = FirebaseFirestore.instance;
    final sortField = _getSortField(tabIndex);
    final snapshot = await firestore
        .collection('users')
        .orderBy(sortField, descending: true)
        .limit(50)
        .get();
    final users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    _globalLeaderboard = users;
  }

  Future<void> _loadFriendsLeaderboard(String currentUserId) async {
    final friends = await FriendService.getLeaderboard(currentUserId);
    _friendsLeaderboard = friends;
  }

  void _openFriendProfile(String userId) {
    HapticService.buttonTap();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (userId == authProvider.userId) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friendId: userId)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabPills(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            TapScale(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios, color: context.textSecondary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              'Rankings',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04 * 22,
                color: context.textPrimary,
              ),
            ),
          ),
          _buildScopePill('global', AppLocalizations.of(context).global),
          const SizedBox(width: 6),
          _buildScopePill('friends', AppLocalizations.of(context).friends),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildScopePill(String scope, String label) {
    final isActive = _selectedScope == scope;
    return TapScale(
      onTap: () {
        if (_selectedScope == scope) return;
        HapticService.buttonTap();
        setState(() => _selectedScope = scope);
        _loadLeaderboard();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : context.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : context.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTabPills() {
    final tabs = [
      AppLocalizations.of(context).allTime,
      AppLocalizations.of(context).weekly,
      AppLocalizations.of(context).monthly,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _selectedTab == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 6 : 0),
              child: TapScale(
                onTap: () {
                  if (_selectedTab == i) return;
                  HapticService.buttonTap();
                  setState(() => _selectedTab = i);
                  _loadLeaderboard();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : context.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? AppColors.primary : context.borderColor),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? Colors.white : context.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_hasError && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'Could not load leaderboard',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _loadLeaderboard(forceRefresh: true),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final users = _selectedScope == 'global'
        ? _globalLeaderboard
        : _friendsLeaderboard.map((f) => f.friendUser).toList();

    if (users.isEmpty) {
      return _selectedScope == 'global' ? _buildEmptyState() : _buildEmptyFriendsState();
    }

    final hasPodium = users.length >= 3;
    final listUsers = hasPodium ? users.skip(3).toList() : users;

    return RefreshIndicator(
      onRefresh: () => _loadLeaderboard(forceRefresh: true),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (hasPodium) ...[
            _buildPodium(users),
            Divider(height: 1, color: context.borderColor, indent: 16, endIndent: 16),
            const SizedBox(height: 8),
          ],
          ...listUsers.asMap().entries.map((e) {
            final rank = (hasPodium ? 4 : 1) + e.key;
            return _buildLeaderboardRow(e.value, rank, e.key);
          }),
        ],
      ),
    );
  }

  // ── Podium ─────────────────────────────────────────────────────────────────

  Widget _buildPodium(List<UserModel> users) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumSlot(users[1], 2, currentUserId)),
          const SizedBox(width: 8),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: _buildPodiumSlot(users[0], 1, currentUserId),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumSlot(users[2], 3, currentUserId)),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildPodiumSlot(UserModel user, int rank, String? currentUserId) {
    final isMe = user.id == currentUserId;
    const rankColors = {
      1: Color(0xFFFFD700),
      2: Color(0xFFC0C0C0),
      3: Color(0xFFCD7F32),
    };
    final rankColor = rankColors[rank]!;
    final avatarSize = rank == 1 ? 52.0 : 44.0;
    final initialsSize = rank == 1 ? 16.0 : 14.0;

    return TapScale(
      onTap: () => _openFriendProfile(user.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rank',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: rankColor,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.15),
              border: Border.all(color: isMe ? AppColors.primary : rankColor, width: 2),
            ),
            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? ClipOval(child: Image.network(user.photoUrl!, fit: BoxFit.cover, width: avatarSize, height: avatarSize))
                : Center(
                    child: Text(
                      user.initials,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: initialsSize,
                        fontWeight: FontWeight.w800,
                        color: isMe ? AppColors.primary : rankColor,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 5),
          Text(
            isMe ? '${_shortName(user.fullName)} (You)' : _shortName(user.fullName),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isMe ? AppColors.primary : context.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          Text(
            _podiumSubValue(user),
            style: TextStyle(fontSize: 8, color: context.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _shortName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1][0]}.';
  }

  String _podiumSubValue(UserModel user) {
    switch (_selectedTab) {
      case 0:
        return '${_formatXP(user.totalXP)} XP';
      case 1:
        return '${user.currentStreak} streak';
      default:
        return '${user.lessonsCompleted} lessons';
    }
  }

  // ── List rows ──────────────────────────────────────────────────────────────

  Widget _buildLeaderboardRow(UserModel user, int rank, int animIndex) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMe = user.id == authProvider.userId;

    return TapScale(
      onTap: () => _openFriendProfile(user.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 5),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.08) : context.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isMe ? AppColors.primary : context.borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '#$rank',
                textAlign: TextAlign.right,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isMe ? AppColors.primary : context.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.bgElevated,
                border: Border.all(
                  color: isMe ? AppColors.primary : context.borderColor,
                  width: 1.5,
                ),
              ),
              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(user.photoUrl!, fit: BoxFit.cover, width: 30, height: 30))
                  : Center(
                      child: Text(
                        user.initials,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isMe ? AppColors.primary : context.textSecondary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? '${user.fullName} (You)' : user.fullName,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMe ? AppColors.primary : context.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    _rowSubLabel(user),
                    style: TextStyle(fontSize: 8, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              _rowMainValue(user),
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * animIndex));
  }

  String _rowMainValue(UserModel user) {
    switch (_selectedTab) {
      case 0:
        return '${_formatXP(user.totalXP)} XP';
      case 1:
        return '${user.currentStreak} days';
      default:
        return '${user.lessonsCompleted} lessons';
    }
  }

  String _rowSubLabel(UserModel user) {
    switch (_selectedTab) {
      case 0:
        return 'Streak: ${user.currentStreak}';
      case 1:
        return '${_formatXP(user.totalXP)} XP total';
      default:
        return 'Streak: ${user.currentStreak}';
    }
  }

  String _formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}k';
    return '$xp';
  }

  // ── Empty states ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noRankingsYet,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).startLearningLeaderboard,
            style: TextStyle(color: context.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
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
            AppLocalizations.of(context).noFriendsYet,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).addFriendsCompete,
            style: TextStyle(color: context.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TapScale(
            onTap: () => Navigator.pushNamed(context, '/friends'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context).findFriends,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
