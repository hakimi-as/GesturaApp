import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.odlerndId)
          .get();

      if (friendDoc.exists) {
        _friend = UserModel.fromFirestore(friendDoc);
      }

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

  void _showQRCode() {
    HapticService.buttonTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildQRCodeModal(),
    );
  }

  Widget _buildQRCodeModal() {
    final friendCode = _friend?.id ?? '';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.textMuted.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Scan to Add Friend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this QR code to connect',
            style: TextStyle(color: context.textMuted),
          ),
          const SizedBox(height: 24),
          
          // QR Code Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: QrImageView(
              data: 'gestura://add-friend/$friendCode',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.roundedRect,
                color: Color(0xFF6366F1),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.roundedRect,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Friend Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: context.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Code: ',
                  style: TextStyle(color: context.textMuted),
                ),
                Text(
                  friendCode.length > 10 
                      ? '${friendCode.substring(0, 10)}...' 
                      : friendCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: friendCode));
                    HapticService.lightTap();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Friend code copied!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
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
              Text('User not found', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  _buildStatsComparison(),
                  const SizedBox(height: 24),
                  _buildAchievements(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
                    onPressed: _showQRCode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      // Show more options
                    },
                  ),
                ],
              ),
            ),
            
            // Profile Info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  // Avatar with ring
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(100), width: 3),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(50),
                        image: _friend!.photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_friend!.photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _friend!.photoUrl == null
                          ? Center(
                              child: Text(
                                _friend!.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _friend!.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Level & Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Level ${_friend!.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '${_friend!.currentStreak} days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Main Friend Action Button
        Expanded(
          flex: 3,
          child: _buildFriendButton(),
        ),
        const SizedBox(width: 12),
        // QR Button
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: IconButton(
            onPressed: _showQRCode,
            icon: Icon(
              Icons.qr_code_rounded,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildFriendButton() {
    IconData icon;
    String text;
    List<Color> gradientColors;
    bool isEnabled = true;

    switch (_friendshipStatus) {
      case 'friends':
        icon = Icons.check_circle_rounded;
        text = 'Friends';
        gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
        break;
      case 'sent':
        icon = Icons.schedule_rounded;
        text = 'Request Sent';
        gradientColors = [context.textMuted, context.textMuted];
        isEnabled = false;
        break;
      case 'received':
        icon = Icons.person_add_rounded;
        text = 'Accept Request';
        gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
        break;
      default:
        icon = Icons.person_add_rounded;
        text = 'Add Friend';
        gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }

    return GestureDetector(
      onTap: isEnabled ? _handleFriendAction : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: gradientColors.first.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              emoji: '⭐',
              value: _formatNumber(_friend!.totalXP),
              label: 'Total XP',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              emoji: '🤟',
              value: '${_friend!.signsLearned}',
              label: 'Signs',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              emoji: '📚',
              value: '${_friend!.lessonsCompleted}',
              label: 'Lessons',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              emoji: '🎯',
              value: '${_friend!.quizzesCompleted}',
              label: 'Quizzes',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: context.borderColor,
    );
  }

  Widget _buildStatItem({
    required String emoji,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                'Stats Comparison',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildComparisonBar(
            label: 'Total XP',
            myValue: _currentUser!.totalXP,
            friendValue: _friend!.totalXP,
            myColor: const Color(0xFF6366F1),
            friendColor: const Color(0xFFEC4899),
          ),
          const SizedBox(height: 20),
          
          _buildComparisonBar(
            label: 'Current Streak',
            myValue: _currentUser!.currentStreak,
            friendValue: _friend!.currentStreak,
            myColor: const Color(0xFFF59E0B),
            friendColor: const Color(0xFFEF4444),
            suffix: ' days',
          ),
          const SizedBox(height: 20),
          
          _buildComparisonBar(
            label: 'Signs Learned',
            myValue: _currentUser!.signsLearned,
            friendValue: _friend!.signsLearned,
            myColor: const Color(0xFF10B981),
            friendColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 20),
          
          _buildComparisonBar(
            label: 'Quizzes Completed',
            myValue: _currentUser!.quizzesCompleted,
            friendValue: _friend!.quizzesCompleted,
            myColor: const Color(0xFF3B82F6),
            friendColor: const Color(0xFFEC4899),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildComparisonBar({
    required String label,
    required int myValue,
    required int friendValue,
    required Color myColor,
    required Color friendColor,
    String suffix = '',
  }) {
    final total = myValue + friendValue;
    final myPercent = total > 0 ? myValue / total : 0.5;
    final iAmBetter = myValue > friendValue;
    final friendIsBetter = friendValue > myValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        
        // Progress Bar
        Container(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.bgElevated,
          ),
          child: Stack(
            children: [
              // My portion (left side)
              FractionallySizedBox(
                widthFactor: myPercent.clamp(0.05, 0.95),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [myColor, myColor.withAlpha(200)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Labels on bar
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'You: $myValue$suffix',
                          style: TextStyle(
                            color: myPercent > 0.3 ? Colors.white : context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          '${_friend!.fullName.split(' ').first}: $friendValue$suffix',
                          style: TextStyle(
                            color: myPercent < 0.7 ? context.textPrimary : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Winner indicator
        if (iAmBetter || friendIsBetter)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: iAmBetter ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        iAmBetter ? 'You\'re ahead!' : '${_friend!.fullName.split(' ').first} leads',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAchievements() {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Achievements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Achievement badges
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge('🔥', 'Week Streak', _friend!.currentStreak >= 7),
              _buildAchievementBadge('📚', '10 Lessons', _friend!.lessonsCompleted >= 10),
              _buildAchievementBadge('🎯', 'Quiz Master', _friend!.perfectQuizzes >= 1),
              _buildAchievementBadge('🤟', '50 Signs', _friend!.signsLearned >= 50),
              _buildAchievementBadge('⭐', '1000 XP', _friend!.totalXP >= 1000),
              _buildAchievementBadge('🏅', 'Level 5', _friend!.level >= 5),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAchievementBadge(String emoji, String label, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.primary.withAlpha(20) : context.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? AppColors.primary.withAlpha(50) : context.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 18,
              color: unlocked ? null : context.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: unlocked ? context.textPrimary : context.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          if (unlocked) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, color: AppColors.success, size: 14),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}