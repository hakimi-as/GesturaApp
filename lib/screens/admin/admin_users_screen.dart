import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _firestoreService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesFilter = _selectedFilter == 'all' ||
            user.userType == _selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
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
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: context.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterUsers();
                    },
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: context.textMuted),
                      prefixIcon: Icon(Icons.search, color: context.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Learners', 'learner'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Deaf/HoH', 'deaf'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Educators', 'educator'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admins', 'admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_filteredUsers.length} users',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total XP: ${_filteredUsers.fold(0, (sum, user) => sum + user.totalXP)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(context, _filteredUsers[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _filterUsers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            color: isSelected ? Colors.white : context.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, int index) {
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
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: user.isAdmin
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    )
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
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
          ),
          const SizedBox(width: 14),

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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildUserStat(context, '⭐', '${user.totalXP}'),
                    _buildUserStat(context, '🔥', '${user.currentStreak}'),
                    _buildUserStat(context, '🤟', '${user.signsLearned}'),
                    _buildUserStat(context, '🏆', 'Lv${user.level}'),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.textMuted),
            color: context.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) => _handleUserAction(value, user),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20, color: context.textSecondary),
                    SizedBox(width: 12),
                    Text('View Details'),
                  ],
                ),
              ),
              if (!user.isAdmin)
                const PopupMenuItem(
                  value: 'make_admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Text('Make Admin'),
                    ],
                  ),
                ),
              if (user.isAdmin)
                const PopupMenuItem(
                  value: 'remove_admin',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20, color: AppColors.warning),
                      SizedBox(width: 12),
                      Text('Remove Admin'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'reset_progress',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Reset Progress'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildUserStat(BuildContext context, String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.bgElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'make_admin':
        await _firestoreService.updateUser(user.id, {'isAdmin': true});
        _loadUsers();
        _showSnackBar('${user.fullName} is now an admin', isSuccess: true);
        break;
      case 'remove_admin':
        await _firestoreService.updateUser(user.id, {'isAdmin': false});
        _loadUsers();
        _showSnackBar('Admin access removed from ${user.fullName}', isSuccess: true);
        break;
      case 'reset_progress':
        _showResetConfirmation(user);
        break;
    }
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: user.isAdmin
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name & Email
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textMuted,
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '👑 Admin',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Stats Row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailStat('Total XP', '${user.totalXP}', '⭐'),
                _buildDetailStat('Level', '${user.level}', '🏆'),
                _buildDetailStat('Signs', '${user.signsLearned}', '🤟'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailStat('Streak', '${user.currentStreak}', '🔥'),
                _buildDetailStat('Best', '${user.longestStreak}', '📈'),
                _buildDetailStat('Daily', '${user.dailyGoalProgress}/${user.dailyGoalTarget}', '🎯'),
              ],
            ),
            const SizedBox(height: 24),
            
            // User Type & Join Date
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: context.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'User Type: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                      Text(
                        user.userType.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: context.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Joined: ${_formatDate(user.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: context.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Last Active: ${_formatDate(user.lastActiveAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.textMuted,
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Text('Reset Progress'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset all progress for ${user.fullName}?'),
            const SizedBox(height: 16),
            
            // User info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Warning box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will permanently reset:',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildResetItem('Total XP', '${user.totalXP} → 0'),
                  _buildResetItem('Signs Learned', '${user.signsLearned} → 0'),
                  _buildResetItem('Current Streak', '${user.currentStreak} → 0'),
                  _buildResetItem('Longest Streak', '${user.longestStreak} → 0'),
                  _buildResetItem('Daily Goal Progress', 'Reset'),
                  _buildResetItem('All Lesson Progress', 'Deleted'),
                  _buildResetItem('All Quiz Attempts', 'Deleted'),
                  _buildResetItem('All Badges', 'Deleted'),
                  _buildResetItem('All Notifications', 'Deleted'),
                  _buildResetItem('Challenge Progress', 'Deleted'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ This action cannot be undone!',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _resetUserProgress(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.remove_circle, color: AppColors.error, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUserProgress(UserModel user) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Resetting progress...',
                  style: TextStyle(color: context.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );

      // Call the complete reset method
      await _firestoreService.resetUserProgress(user.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        _showSnackBar('✅ All progress reset for ${user.fullName}', isSuccess: true);
      }

      // Refresh user list
      _loadUsers();
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        _showSnackBar('❌ Error: $e', isSuccess: false);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}