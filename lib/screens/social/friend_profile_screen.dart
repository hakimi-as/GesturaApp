import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart';
import '../../models/user_model.dart';

class FriendProfileScreen extends StatefulWidget {
  final String odlerndId;
  final String? friendshipId;

  const FriendProfileScreen({
    super.key,
    required this.odlerndId,
    this.friendshipId,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  UserModel? _friend;
  UserModel? _currentUser;
  String _friendshipStatus = 'none';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUser = authProvider.currentUser;

      // Load friend data
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.odlerndId)
          .get();

      if (friendDoc.exists) {
        _friend = UserModel.fromFirestore(friendDoc);
      }

      // Check friendship status
      if (_currentUser != null) {
        _friendshipStatus = await FriendService.getFriendshipStatus(
          _currentUser!.id,
          widget.odlerndId,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading friend profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFriendAction() async {
    HapticService.buttonTap();

    switch (_friendshipStatus) {
      case 'none':
        // Send friend request
        final result = await FriendService.sendFriendRequest(
          _currentUser!.id,
          widget.odlerndId,
        );
        if (result['success'] && mounted) {
          HapticService.success();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _friendshipStatus = 'sent');
        }
        break;

      case 'received':
        // Accept friend request
        final friendshipId = await FriendService.getFriendshipId(
          _currentUser!.id,
          widget.odlerndId,
        );
        if (friendshipId != null) {
          final success = await FriendService.acceptFriendRequest(
            _currentUser!.id,
            friendshipId,
          );
          if (success && mounted) {
            HapticService.success();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ You are now friends with ${_friend?.fullName}!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _friendshipStatus = 'friends');
          }
        }
        break;

      case 'friends':
        // Remove friend
        _showRemoveFriendDialog();
        break;

      default:
        break;
    }
  }

  void _showRemoveFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${_friend?.fullName} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (widget.friendshipId != null) {
                final success = await FriendService.removeFriend(widget.friendshipId!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend removed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() => _friendshipStatus = 'none');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_friend == null) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                'User not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFriendActionButton(),
                  const SizedBox(height: 24),
                  _buildStatsComparison(),
                  const SizedBox(height: 24),
                  _buildDetailedStats(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withAlpha(100), width: 3),
                    ),
                    child: _friend!.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: Image.network(
                              _friend!.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _friend!.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 36,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _friend!.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _friend!.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${_friend!.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendActionButton() {
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;

    switch (_friendshipStatus) {
      case 'friends':
        buttonText = 'Friends';
        buttonColor = AppColors.success;
        buttonIcon = Icons.check;
        break;
      case 'sent':
        buttonText = 'Request Sent';
        buttonColor = context.textMuted;
        buttonIcon = Icons.hourglass_empty;
        break;
      case 'received':
        buttonText = 'Accept Request';
        buttonColor = AppColors.primary;
        buttonIcon = Icons.person_add;
        break;
      default:
        buttonText = 'Add Friend';
        buttonColor = AppColors.primary;
        buttonIcon = Icons.person_add;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _friendshipStatus == 'sent' ? null : _handleFriendAction,
        icon: Icon(buttonIcon, size: 20),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: context.bgElevated,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatsComparison() {
    if (_currentUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Stats Comparison',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildComparisonRow(
            label: 'Total XP',
            emoji: '⭐',
            myValue: _currentUser!.totalXP,
            friendValue: _friend!.totalXP,
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            label: 'Current Streak',
            emoji: '🔥',
            myValue: _currentUser!.currentStreak,
            friendValue: _friend!.currentStreak,
            suffix: ' days',
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            label: 'Signs Learned',
            emoji: '🤟',
            myValue: _currentUser!.signsLearned,
            friendValue: _friend!.signsLearned,
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            label: 'Level',
            emoji: '🏆',
            myValue: _currentUser!.level,
            friendValue: _friend!.level,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildComparisonRow({
    required String label,
    required String emoji,
    required int myValue,
    required int friendValue,
    String suffix = '',
  }) {
    final iAmBetter = myValue > friendValue;
    final friendIsBetter = friendValue > myValue;
    final total = myValue + friendValue;
    final myPercent = total > 0 ? myValue / total : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // My value
            Expanded(
              child: Row(
                children: [
                  Text(
                    'You: $myValue$suffix',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: iAmBetter ? AppColors.success : context.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  if (iAmBetter) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_upward, color: AppColors.success, size: 14),
                  ],
                ],
              ),
            ),
            // Friend value
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (friendIsBetter) ...[
                    const Icon(Icons.arrow_upward, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${_friend!.fullName.split(' ').first}: $friendValue$suffix',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: friendIsBetter ? AppColors.success : context.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar comparison
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: myPercent,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You',
              style: TextStyle(fontSize: 10, color: context.textMuted),
            ),
            Text(
              _friend!.fullName.split(' ').first,
              style: TextStyle(fontSize: 10, color: context.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '${_friend!.fullName.split(' ').first}\'s Stats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  emoji: '⭐',
                  value: '${_friend!.totalXP}',
                  label: 'Total XP',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '🏆',
                  value: 'Lv ${_friend!.level}',
                  label: 'Level',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  emoji: '🔥',
                  value: '${_friend!.currentStreak}',
                  label: 'Current Streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '🏅',
                  value: '${_friend!.longestStreak}',
                  label: 'Best Streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  emoji: '🤟',
                  value: '${_friend!.signsLearned}',
                  label: 'Signs Learned',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '📚',
                  value: '${_friend!.lessonsCompleted}',
                  label: 'Lessons Done',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  emoji: '🎯',
                  value: '${_friend!.quizzesCompleted}',
                  label: 'Quizzes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '💯',
                  value: '${_friend!.perfectQuizzes}',
                  label: 'Perfect Quizzes',
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatBox({
    required String emoji,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}