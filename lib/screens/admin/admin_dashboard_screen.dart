import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_lessons_screen.dart';
import 'admin_quizzes_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_badges_screen.dart';
// CHANGE: Import the Library screen instead of just the Upload screen
import 'admin_sign_library_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _totalUsers = 0;
  int _totalCategories = 0;
  int _totalLessons = 0;
  int _totalQuizzes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final users = await _firestoreService.getAllUsers();
      final categories = await _firestoreService.getCategories();
      final lessons = await _firestoreService.getAllLessons();
      final quizzes = await _firestoreService.getQuizzes();

      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _totalCategories = categories.length;
          _totalLessons = lessons.length;
          _totalQuizzes = quizzes.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(context),
                    const SizedBox(height: 24),

                    // Stats Grid
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                    _buildStatsGrid(context),
                    const SizedBox(height: 24),

                    // Manage Section
                    Text(
                      'Manage',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 16),
                    _buildManageSection(context),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3), // Fixed deprecation
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9), // Fixed deprecation
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.fullName ?? 'Administrator',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your app content here',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), // Fixed deprecation
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), // Fixed deprecation
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('👨‍💼', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          icon: '👥',
          value: '$_totalUsers',
          label: 'Total Users',
          color: AppColors.primary,
          index: 0,
        ),
        _buildStatCard(
          context,
          icon: '📁',
          value: '$_totalCategories',
          label: 'Categories',
          color: AppColors.secondary,
          index: 1,
        ),
        _buildStatCard(
          context,
          icon: '📚',
          value: '$_totalLessons',
          label: 'Lessons',
          color: AppColors.accent,
          index: 2,
        ),
        _buildStatCard(
          context,
          icon: '🎯',
          value: '$_totalQuizzes',
          label: 'Quizzes',
          color: AppColors.warning,
          index: 3,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
    required Color color,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), // Fixed deprecation
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 100)));
  }

  Widget _buildManageSection(BuildContext context) {
    return Column(
      children: [
        _buildManageCard(
          context,
          icon: '👥',
          title: 'Users',
          subtitle: 'View and manage users',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
          ),
          index: 0,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: '📁',
          title: 'Categories',
          subtitle: 'Add, edit, delete categories',
          color: AppColors.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
          ),
          index: 1,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: '📚',
          title: 'Lessons',
          subtitle: 'Manage lesson content',
          color: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminLessonsScreen()),
          ),
          index: 2,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: '🎯',
          title: 'Quizzes',
          subtitle: 'Create and manage quizzes',
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminQuizzesScreen()),
          ),
          index: 3,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: '🏆',
          title: 'Challenges',
          subtitle: 'Manage daily/weekly challenges',
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminChallengesScreen()),
          ),
          index: 4,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: '🎖️',
          title: 'Badges',
          subtitle: 'Manage achievement badges',
          color: const Color(0xFFFFD700),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminBadgesScreen()),
          ),
          index: 5,
        ),
        
        // 2. UPDATED: Points to "Sign Library" which lets you View AND Upload
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: '🤟', 
          title: 'Sign Library', // Renamed
          subtitle: 'View, Delete & Upload Signs',
          color: Colors.purple, 
          onTap: () => Navigator.push(
            context,
            // NAVIGATES TO LIBRARY SCREEN
            MaterialPageRoute(builder: (_) => const AdminSignLibraryScreen()), 
          ),
          index: 6,
        ),
      ],
    );
  }

  Widget _buildManageCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), // Fixed deprecation
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 500 + (index * 100))).slideX(begin: 0.1);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.add_circle_outline,
            label: 'Add Category',
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.post_add,
            label: 'Add Lesson',
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLessonsScreen()),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15), // Fixed deprecation
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)), // Fixed deprecation
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}