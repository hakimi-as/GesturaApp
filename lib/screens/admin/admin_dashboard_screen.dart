import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/glass_ui.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_lessons_screen.dart';
import 'admin_quizzes_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_badges_screen.dart';
import 'admin_sign_library_screen.dart';
import '../../services/learning_path_seeder.dart';
import '../../services/learning_path_diagnostic.dart';
import '../../services/quiz_seeder.dart';

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
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: AppLocalizations.of(context).adminPanel,
        actions: [
          GlassIconButton(
            icon: Icons.refresh_rounded,
            onTap: _loadStats,
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
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
                      AppLocalizations.of(context).overview,
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                    _buildStatsGrid(context),
                    const SizedBox(height: 24),

                    // Manage Section
                    Text(
                      AppLocalizations.of(context).manage,
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 16),
                    _buildManageSection(context),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      AppLocalizations.of(context).quickActions,
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

        return GlassCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).welcomeAdmin,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.fullName ?? AppLocalizations.of(context).administrator,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).adminContentDesc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: kGlassRadius,
                ),
                child: const Center(
                  child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 32),
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
          icon: Icons.group_rounded,
          value: '$_totalUsers',
          label: AppLocalizations.of(context).totalUsers,
          color: AppColors.primary,
          index: 0,
        ),
        _buildStatCard(
          context,
          icon: Icons.folder_rounded,
          value: '$_totalCategories',
          label: AppLocalizations.of(context).categories,
          color: AppColors.secondary,
          index: 1,
        ),
        _buildStatCard(
          context,
          icon: Icons.menu_book_rounded,
          value: '$_totalLessons',
          label: AppLocalizations.of(context).lessonsAdmin,
          color: AppColors.accent,
          index: 2,
        ),
        _buildStatCard(
          context,
          icon: Icons.quiz_rounded,
          value: '$_totalQuizzes',
          label: AppLocalizations.of(context).quizzesLabel,
          color: AppColors.warning,
          index: 3,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int index,
  }) {
    return GlassCard(
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: kGlassRadius,
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 20),
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
            style: TextStyle(
              color: context.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
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
          icon: Icons.group_rounded,
          title: AppLocalizations.of(context).users,
          subtitle: AppLocalizations.of(context).viewManageUsers,
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
          icon: Icons.folder_rounded,
          title: AppLocalizations.of(context).categories,
          subtitle: AppLocalizations.of(context).addEditDeleteCategories,
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
          icon: Icons.menu_book_rounded,
          title: AppLocalizations.of(context).lessonsAdmin,
          subtitle: AppLocalizations.of(context).manageLessonContent,
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
          icon: Icons.quiz_rounded,
          title: AppLocalizations.of(context).quizzesLabel,
          subtitle: AppLocalizations.of(context).createManageQuizzes,
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
          icon: Icons.emoji_events_rounded,
          title: AppLocalizations.of(context).dailyChallenges,
          subtitle: AppLocalizations.of(context).manageChallengesDesc,
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminChallengesScreen()),
          ),
          index: 4,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: Icons.military_tech_rounded,
          title: AppLocalizations.of(context).badgesTitle,
          subtitle: AppLocalizations.of(context).manageAchievementBadges,
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminBadgesScreen()),
          ),
          index: 5,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: Icons.sign_language_rounded,
          title: AppLocalizations.of(context).signLibrary,
          subtitle: AppLocalizations.of(context).viewDeleteUploadSigns,
          color: const Color(0xFF06B6D4),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminSignLibraryScreen()),
          ),
          index: 6,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: Icons.map_rounded,
          title: AppLocalizations.of(context).learningPaths,
          subtitle: AppLocalizations.of(context).seedPathsFromLessons,
          color: AppColors.primary,
          onTap: () => _showLearningPathsDialog(context),
          index: 7,
        ),
        const SizedBox(height: 12),
        _buildManageCard(
          context,
          icon: Icons.casino_rounded,
          title: AppLocalizations.of(context).seedQuizzes,
          subtitle: AppLocalizations.of(context).generate3QuizzesPerType,
          color: AppColors.accent,
          onTap: () => _showQuizSeederDialog(context),
          index: 8,
        ),
      ],
    );
  }

  Widget _buildManageCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: GlassTile(
        onTap: onTap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: kGlassRadius,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
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
            label: AppLocalizations.of(context).addCategory,
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
            label: AppLocalizations.of(context).addLesson,
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
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
  void _showLearningPathsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(30),
                borderRadius: kGlassRadius,
              ),
              child: const Center(
                child: Icon(Icons.map_rounded, color: Color(0xFF10B981), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context).learningPaths),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will create 5 learning paths based on your existing lessons:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPathPreview(Icons.bolt_rounded, 'Quick Start', 'Beginner'),
            _buildPathPreview(Icons.sign_language_rounded, 'ASL Foundations', 'Beginner'),
            _buildPathPreview(Icons.chat_bubble_rounded, 'Everyday Vocabulary', 'Intermediate'),
            _buildPathPreview(Icons.loop_rounded, 'Daily Practice Mix', 'Intermediate'),
            _buildPathPreview(Icons.school_rounded, 'Fluent Signer', 'Advanced'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _runDiagnostic();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withAlpha(30),
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('🔍 Diagnose'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteLearningPaths();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(30),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete All'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _seedLearningPaths();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Seed Paths'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathPreview(IconData icon, String name, String difficulty) {
    Color diffColor;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        diffColor = const Color(0xFF10B981);
        break;
      case 'intermediate':
        diffColor = const Color(0xFFF59E0B);
        break;
      case 'advanced':
        diffColor = const Color(0xFFEF4444);
        break;
      default:
        diffColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: diffColor),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: diffColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              difficulty,
              style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedLearningPaths() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      await LearningPathSeeder.seedLearningPaths();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Learning paths created successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteLearningPaths() async {
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Learning Paths?'),
        content: const Text(
          'This will delete all learning paths and user progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    try {
      await LearningPathSeeder.deleteAllPaths();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('All learning paths deleted'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  void _showQuizSeederDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(30),
                borderRadius: kGlassRadius,
              ),
              child: const Center(
                child: Icon(Icons.casino_rounded, color: AppColors.accent, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context).seedQuizzes),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will create 3 quizzes for each quiz type using existing lessons:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPathPreview(Icons.image_rounded, 'Sign to Text (×3)', 'Beginner→Hard'),
            _buildPathPreview(Icons.text_fields_rounded, 'Text to Sign (×3)', 'Beginner→Hard'),
            _buildPathPreview(Icons.timer_rounded, 'Timed Challenge (×3)', 'Sprint→Expert'),
            _buildPathPreview(Icons.spellcheck_rounded, 'Spelling Quiz (×3)', 'Short→Challenge'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSeededQuizzes();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(30),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Seeded'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _seedQuizzes();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context).seedQuizzes),
          ),
        ],
      ),
    );
  }

  Future<void> _seedQuizzes() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFEC4899)),
      ),
    );

    try {
      final result = await QuizSeederService.seedAllQuizzes();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(result.success ? '✅' : '❌'),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
            backgroundColor: result.success ? const Color(0xFFEC4899) : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (result.success) _loadStats();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteSeededQuizzes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Seeded Quizzes?'),
        content: const Text(
          'This will delete all quizzes that were created by the seeder. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    try {
      await QuizSeederService.deleteAllSeededQuizzes();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Text('🗑️'),
                SizedBox(width: 8),
                Text('Seeded quizzes deleted'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _runDiagnostic() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      ),
    );

    try {
      await LearningPathDiagnostic.checkStructure();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Text('🔍'),
                SizedBox(width: 8),
                Text('Check your console for structure details!'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}