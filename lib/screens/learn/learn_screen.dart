import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../models/category_model.dart';
import '../../models/lesson_model.dart';
import '../../models/badge_model.dart';
import '../../models/challenge_model.dart';
import '../../models/progress_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common/shimmer_widgets.dart';
import '../../widgets/gamification/xp_chart_widget.dart';
import 'category_lessons_screen.dart';
import '../quiz/quiz_list_screen.dart';
import '../badges/badges_screen.dart';
import '../challenges/challenges_screen.dart';
import 'learning_paths_screen.dart';
import '../../services/haptic_service.dart';
import '../../l10n/app_localizations.dart';

class LearnScreen extends StatefulWidget {
  final bool showBackButton;
  final int initialTabIndex;

  const LearnScreen({
    super.key,
    this.showBackButton = false,
    this.initialTabIndex = 0,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late int _selectedTabIndex;

  List<CategoryModel> _categories = [];
  Map<String, int> _actualLessonCounts = {};
  Map<String, int> _completedLessonCounts = {};
  int _totalLessons = 0;
  int _totalCompletedLessons = 0;
  bool _isLoading = true;

  // For progress calendar
  List<DateTime> _activeDays = [];
  
  // For quiz accuracy
  double _averageQuizAccuracy = 0.0;
  Map<String, int> _bestScoresByType = {};

  static const _cacheKeyCategories = 'learn_cats_v3';
  static const _cacheKeyUser = 'learn_user_v3_';
  static const _cacheTtlMs = 10 * 60 * 1000; // 10 minutes

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _initLoad();
  }

  Future<void> _initLoad() async {
    // 1. Render from cache instantly (if available)
    final cacheHit = await _tryLoadCache();
    // 2. Always refresh from Firestore in background
    //    If cache was hit, do it silently (no shimmer). Otherwise show shimmer.
    if (!cacheHit) setState(() => _isLoading = true);
    _loadData();
  }

  // ── Cache helpers ──────────────────────────────────────────────────────

  Future<bool> _tryLoadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      final catJson = prefs.getString(_cacheKeyCategories);
      if (catJson == null) return false;

      final catData = jsonDecode(catJson) as Map<String, dynamic>;
      final cachedAt = catData['cachedAt'] as int? ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - cachedAt > _cacheTtlMs) {
        return false; // stale
      }

      final catList = (catData['categories'] as List)
          .map((m) => _categoryFromMap(m as Map<String, dynamic>))
          .toList();
      final lessonCounts = Map<String, int>.from(catData['lessonCounts'] as Map);
      final totalLessons = catData['totalLessons'] as int? ?? 0;

      Map<String, int> completedCounts = {};
      int totalCompleted = 0;

      if (userId != null) {
        final userJson = prefs.getString('$_cacheKeyUser$userId');
        if (userJson != null) {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          completedCounts = Map<String, int>.from(userData['completedCounts'] as Map);
          totalCompleted = userData['totalCompleted'] as int? ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _categories = catList;
          _actualLessonCounts = lessonCounts;
          _completedLessonCounts = completedCounts;
          _totalLessons = totalLessons;
          _totalCompletedLessons = totalCompleted;
          _isLoading = false;
        });
      }
      return true;
    } catch (e) {
      debugPrint('Cache read error (non-fatal): $e');
      return false;
    }
  }

  Future<void> _saveToCache({
    required List<CategoryModel> categories,
    required Map<String, int> lessonCounts,
    required int totalLessons,
    String? userId,
    Map<String, int>? completedCounts,
    int? totalCompleted,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      final catData = {
        'categories': categories.map(_categoryToMap).toList(),
        'lessonCounts': lessonCounts,
        'totalLessons': totalLessons,
        'cachedAt': now,
      };
      await prefs.setString(_cacheKeyCategories, jsonEncode(catData));

      if (userId != null && completedCounts != null) {
        final userData = {
          'completedCounts': completedCounts,
          'totalCompleted': totalCompleted ?? 0,
          'cachedAt': now,
        };
        await prefs.setString('$_cacheKeyUser$userId', jsonEncode(userData));
      }
    } catch (e) {
      debugPrint('Cache write error (non-fatal): $e');
    }
  }

  Map<String, dynamic> _categoryToMap(CategoryModel c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'icon': c.icon,
        'imageUrl': c.imageUrl,
        'lessonCount': c.lessonCount,
        'order': c.order,
        'isActive': c.isActive,
        'difficulty': c.difficulty,
        'signLanguage': c.signLanguage,
      };

  CategoryModel _categoryFromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String,
        icon: m['icon'] as String,
        imageUrl: m['imageUrl'] as String?,
        lessonCount: m['lessonCount'] as int? ?? 0,
        order: m['order'] as int? ?? 0,
        isActive: m['isActive'] as bool? ?? true,
        difficulty: m['difficulty'] as String?,
        signLanguage: m['signLanguage'] as String?,
      );

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      // ── 3 parallel queries (was N+2 sequential per-category calls) ─────────
      final results = await Future.wait<dynamic>([
        _firestoreService.getCategories(),
        _firestoreService.getAllLessons(),
        userId != null
            ? _firestoreService.getCompletedLessonIdsForUser(userId)
            : Future.value(<String>{}),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final allLessons = results[1] as List<LessonModel>;
      final completedIds = results[2] as Set<String>;

      // Group lessons by categoryId client-side — no per-category queries needed
      final Map<String, int> lessonCounts = {};
      final Map<String, int> completedCounts = {};
      int totalLessons = 0;
      int totalCompleted = 0;

      for (final lesson in allLessons) {
        lessonCounts[lesson.categoryId] =
            (lessonCounts[lesson.categoryId] ?? 0) + 1;
        totalLessons++;
        if (completedIds.contains(lesson.id)) {
          completedCounts[lesson.categoryId] =
              (completedCounts[lesson.categoryId] ?? 0) + 1;
          totalCompleted++;
        }
      }

      // ── Show categories immediately — don't block on stats ───────────────
      if (mounted) {
        setState(() {
          _categories = categories;
          _actualLessonCounts = lessonCounts;
          _completedLessonCounts = completedCounts;
          _totalLessons = totalLessons;
          _totalCompletedLessons = totalCompleted;
          _isLoading = false;
        });
      }

      // Save fresh data to cache for next launch
      _saveToCache(
        categories: categories,
        lessonCounts: lessonCounts,
        totalLessons: totalLessons,
        userId: userId,
        completedCounts: completedCounts,
        totalCompleted: totalCompleted,
      );

      // ── Phase 3: user stats — isolated, won't crash categories if it fails ─
      if (userId != null) {
        final user = authProvider.currentUser;
        if (user != null && mounted) {
          Provider.of<ChallengeProvider>(context, listen: false)
              .loadChallenges(userId, user);
        }
        _loadUserStats(userId); // fire and forget — has its own error handling
      }
    } catch (e) {
      debugPrint('Error loading learn data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

      final results = await Future.wait<dynamic>([
        badgeProvider.loadUserBadges(userId),
        _firestoreService.getUserProgress(userId),
        _firestoreService.getAverageQuizAccuracy(userId),
        _firestoreService.getRecentQuizAttempts(userId, limit: 20),
      ]);

      final progress = results[1] as List<LearningProgressModel>;
      final quizAccuracy = (results[2] as num).toDouble();
      final recentAttempts = results[3] as List<Map<String, dynamic>>;

      final activeDays = progress
          .where((p) => p.isCompleted)
          .map((p) {
            final dt = p.completedAt ?? DateTime.now();
            return DateTime(dt.year, dt.month, dt.day);
          })
          .toSet()
          .toList();

      final Map<String, int> bestScores = {};
      for (final attempt in recentAttempts) {
        final type = attempt['quizType'] as String? ?? '';
        final total = attempt['totalQuestions'] as int? ?? 0;
        final correct = attempt['correctAnswers'] as int? ?? 0;
        final score = total > 0 ? (correct / total * 100).round() : 0;
        if (!bestScores.containsKey(type) || bestScores[type]! < score) {
          bestScores[type] = score;
        }
      }

      if (mounted) {
        setState(() {
          _activeDays = activeDays;
          _averageQuizAccuracy = quizAccuracy;
          _bestScoresByType = bestScores;
        });
      }
    } catch (e) {
      debugPrint('Error loading user stats (non-fatal): $e');
      // Categories are already visible — this is non-fatal
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = widget.showBackButton || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context).learnTitle),
                ],
              ),
              actions: [
                _buildHeaderStats(),
                const SizedBox(width: 16),
              ],
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: Column(
            children: [
              // Header (only if no AppBar)
              if (!canPop) _buildHeader(),

              // Tab Bar
              _buildTabBar(),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build shimmer loading state based on current tab
  Widget _buildLoadingState() {
    switch (_selectedTabIndex) {
      case 0: // Learn tab
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShimmerWidgets.welcomeCard(),
              ),
              const SizedBox(height: 24),
              // Section title shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShimmerWidgets.text(width: 150, height: 24),
              ),
              const SizedBox(height: 16),
              // Categories grid shimmer
              ShimmerWidgets.categoriesLoading(),
              const SizedBox(height: 24),
              // Daily goals shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: ShimmerWidgets.challengesLoading(),
                ),
              ),
            ],
          ),
        );
      case 1: // Quiz tab
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShimmerWidgets.welcomeCard(),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShimmerWidgets.text(width: 150, height: 24),
              ),
              const SizedBox(height: 16),
              ShimmerWidgets.categoriesLoading(),
            ],
          ),
        );
      case 2: // Progress tab
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: List.generate(4, (_) => ShimmerWidgets.statsCard()),
                ),
                const SizedBox(height: 24),
                // Chart shimmer
                ShimmerWidgets.card(height: 280, borderRadius: 20),
                const SizedBox(height: 24),
                // Calendar shimmer
                ShimmerWidgets.card(height: 300, borderRadius: 20),
              ],
            ),
          ),
        );
      case 3: // Badges tab
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShimmerWidgets.welcomeCard(),
              ),
              const SizedBox(height: 24),
              ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: ShimmerWidgets.card(height: 90, borderRadius: 16),
              )),
            ],
          ),
        );
      default:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Learn',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          _buildHeaderStats(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildHeaderStats() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${user?.currentStreak ?? 0}',
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                _formatNumber(user?.totalXP ?? 0),
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          _buildTabItem(0, '📚', 'Learn'),
          _buildTabItem(1, '❓', 'Quiz'),
          _buildTabItem(2, '📊', 'Progress'),
          _buildTabItem(3, '🏆', 'Badges'),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTabItem(int index, String emoji, String label) {
    final isSelected = _selectedTabIndex == index;

    Color getTabColor() {
      if (!isSelected) return Colors.transparent;
      switch (index) {
        case 0:
          return AppColors.primary;
        case 1:
          return AppColors.primary;
        case 2:
          return AppColors.primary;
        case 3:
          return AppColors.primary;
        default:
          return AppColors.primary;
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: getTabColor(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildLearnTab();
      case 1:
        return _buildQuizTab();
      case 2:
        return _buildProgressTab();
      case 3:
        return _buildBadgesTab();
      default:
        return _buildLearnTab();
    }
  }

  // ==================== LEARN TAB ====================

  Widget _buildLearnTab() {
    final progress = _totalLessons > 0 ? _totalCompletedLessons / _totalLessons : 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Welcome back, Learner! ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('👋', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "You're making great progress! Keep it up.",
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withAlpha(50),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$_totalCompletedLessons / $_totalLessons signs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 20),
          _buildLearningPathsCard(),

          // Section Title
          _buildSectionTitle('📚', 'Lesson Categories'),

          // Categories Grid
          if (_categories.isEmpty)
            _buildEmptyState()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(_categories[index], index);
                },
              ),
            ),

          // Daily Goals
          _buildDailyGoalsSection(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    final actualLessonCount = _actualLessonCounts[category.id] ?? 0;
    final completedCount = _completedLessonCounts[category.id] ?? 0;
    final progress = actualLessonCount > 0 ? completedCount / actualLessonCount : 0.0;
    final percentage = (progress * 100).toInt();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryLessonsScreen(category: category),
          ),
        );
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: percentage == 100 && actualLessonCount > 0
                ? AppColors.success.withAlpha(128)
                : context.borderColor,
            width: percentage == 100 && actualLessonCount > 0 ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCategoryColor(index).withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: category.hasCustomImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        CloudinaryService.getOptimizedImage(category.imageUrl!, width: 96),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(category.icon, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              category.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textMuted,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$actualLessonCount+ ${AppLocalizations.of(context).signsLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                        fontSize: 11,
                      ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: percentage == 100 && actualLessonCount > 0
                        ? AppColors.success
                        : _getCategoryColor(index),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: context.bgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage == 100 && actualLessonCount > 0
                      ? AppColors.success
                      : _getCategoryColor(index),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 350 + (index * 50)),
        ).slideY(begin: 0.1);
  }

  Widget _buildDailyGoalsSection() {
    return Consumer2<AuthProvider, ChallengeProvider>(
      builder: (context, authProvider, challengeProvider, child) {
        final dailyChallenges = challengeProvider.dailyChallenges;
        final totalChallenges = dailyChallenges.length;
        final completedChallenges = dailyChallenges.where((c) => c.isCompleted).length;
        final percentage = totalChallenges > 0 
            ? (completedChallenges / totalChallenges).clamp(0.0, 1.0) 
            : 0.0;

        // If challenges not loaded yet, show shimmer loading
        if (challengeProvider.isLoading) {
          return Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor),
            ),
            child: ShimmerWidgets.challengesLoading(),
          );
        }

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Challenges',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChallengesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: context.bgElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completedChallenges == totalChallenges && totalChallenges > 0
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedChallenges/$totalChallenges',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (dailyChallenges.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No daily challenges available',
                    style: TextStyle(color: context.textMuted),
                  ),
                )
              else
                ...dailyChallenges.map((challenge) {
                  return _buildChallengeItem(challenge);
                }),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms);
      },
    );
  }
  // ==================== LEARNING PATHS CARD ====================
  
  Widget _buildLearningPathsCard() {
    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LearningPathsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Paths',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Structured courses for all levels',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildChallengeItem(ChallengeModel challenge) {
    final isCompleted = challenge.isCompleted;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppColors.success.withAlpha(30) 
                  : challenge.typeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                challenge.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Challenge info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    color: isCompleted ? context.textMuted : context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${challenge.currentValue}/${challenge.targetValue}',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: challenge.progress,
                          minHeight: 3,
                          backgroundColor: context.bgElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? AppColors.success : challenge.typeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // XP reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppColors.success.withAlpha(26) 
                  : AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${challenge.xpReward} XP',
              style: TextStyle(
                color: isCompleted ? AppColors.success : AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUIZ TAB ====================

  Widget _buildQuizTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Test Your Knowledge ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('🎯', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Challenge yourself and earn XP!',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          // Section Title
          _buildSectionTitle('📝', AppLocalizations.of(context).chooseQuizType),

          // Quiz Types Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Builder(builder: (context) {
              final l10n = AppLocalizations.of(context);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.80,
                children: [
                  _buildQuizTypeCard(
                    icon: '👁️',
                    iconBgColor: const Color(0xFF6366F1),
                    title: l10n.signToText,
                    subtitle: l10n.signToTextDesc,
                    info: '10 ${l10n.questions}',
                    xpReward: '+50 XP',
                    bestScore: _bestScoresByType['sign_to_text'] ?? 0,
                    onTap: () => _startQuiz('sign_to_text'),
                  ),
                  _buildQuizTypeCard(
                    icon: '👆',
                    iconBgColor: const Color(0xFFF59E0B),
                    title: l10n.textToSign,
                    subtitle: l10n.textToSignDesc,
                    info: '10 ${l10n.questions}',
                    xpReward: '+50 XP',
                    bestScore: _bestScoresByType['text_to_sign'] ?? 0,
                    onTap: () => _startQuiz('text_to_sign'),
                  ),
                  _buildQuizTypeCard(
                    icon: '⏱️',
                    iconBgColor: const Color(0xFF10B981),
                    title: l10n.timedChallenge,
                    subtitle: l10n.timedChallengeDesc,
                    info: '15 ${l10n.questions}',
                    xpReward: '+5 XP each',
                    bestScore: _bestScoresByType['timed'] ?? 0,
                    onTap: () => _startQuiz('timed'),
                  ),
                  _buildQuizTypeCard(
                    icon: '🔤',
                    iconBgColor: const Color(0xFFEF4444),
                    title: l10n.spellingQuiz,
                    subtitle: l10n.spellingQuizDesc,
                    info: '10 ${l10n.questions}',
                    xpReward: '+50 XP',
                    bestScore: _bestScoresByType['spelling'] ?? 0,
                    onTap: () => _startQuiz('spelling'),
                  ),
                ],
              );
            }),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuizTypeCard({
    required String icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String info,
    required String xpReward,
    required VoidCallback onTap,
    int bestScore = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textMuted,
                      fontSize: 11,
                    ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                        fontSize: 11,
                      ),
                ),
                Text(
                  xpReward,
                  style: TextStyle(
                    color: iconBgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bestScore / 100,
                minHeight: 6,
                backgroundColor: iconBgColor.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(iconBgColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bestScore > 0
                  ? '${AppLocalizations.of(context).bestScore}: $bestScore%'
                  : AppLocalizations.of(context).notPlayedYet,
              style: TextStyle(
                color: bestScore > 0 ? iconBgColor : context.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reloadBestScores() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId == null) return;
    try {
      final recentAttempts = await _firestoreService.getRecentQuizAttempts(
        authProvider.userId!,
        limit: 20,
      );
      final Map<String, int> bestScores = {};
      for (final attempt in recentAttempts) {
        final type = attempt['quizType'] as String? ?? '';
        final total = attempt['totalQuestions'] as int? ?? 0;
        final correct = attempt['correctAnswers'] as int? ?? 0;
        final score = total > 0 ? (correct / total * 100).round() : 0;
        if (!bestScores.containsKey(type) || bestScores[type]! < score) {
          bestScores[type] = score;
        }
      }
      if (mounted) setState(() => _bestScoresByType = bestScores);
    } catch (_) {}
  }

  void _startQuiz(String type) {
    String title;
    switch (type) {
      case 'sign_to_text':
        title = 'Sign to Text';
        break;
      case 'text_to_sign':
        title = 'Text to Sign';
        break;
      case 'timed':
        title = 'Timed Challenge';
        break;
      case 'spelling':
        title = 'Spelling Quiz';
        break;
      default:
        title = 'Quiz';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizListScreen(quizType: type, title: title),
      ),
    ).then((_) => _reloadBestScores());
  }

  // ==================== PROGRESS TAB ====================

  Widget _buildProgressTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      icon: '🤟',
                      iconBgColor: const Color(0xFF6366F1),
                      value: '${user?.signsLearned ?? 0}',
                      label: 'Signs Learned',
                    ),
                    _buildStatCard(
                      icon: '⏱️',
                      iconBgColor: const Color(0xFFEC4899),
                      value: user?.formattedTimeSpent ?? '0m',
                      label: 'Total Time',
                    ),
                    _buildStatCard(
                      icon: '🎯',
                      iconBgColor: const Color(0xFFF59E0B),
                      value: '${_averageQuizAccuracy.toInt()}%',
                      label: 'Quiz Accuracy',
                    ),
                    _buildStatCard(
                      icon: '🔥',
                      iconBgColor: const Color(0xFFEF4444),
                      value: '${user?.currentStreak ?? 0}',
                      label: 'Day Streak',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // XP Progress Chart - NEW!
              if (authProvider.userId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: XPProgressChart(
                    userId: authProvider.userId!,
                    totalXP: user?.totalXP ?? 0,
                    currentStreak: user?.currentStreak ?? 0,
                  ),
                ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // Calendar Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                        const Text('📅', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          _getMonthYearString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCalendar(),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String icon,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  String _getMonthYearString() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayLabels.map((day) {
            return SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: context.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 42, // 6 weeks max
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekday + 1;
            
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(now.year, now.month, dayNumber);
            final isToday = dayNumber == now.day;
            final isActive = _activeDays.any((d) =>
                d.year == date.year && d.month == date.month && d.day == date.day);
            final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

            return Container(
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : isToday
                        ? AppColors.primary.withAlpha(50)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isActive
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : isPast
                            ? context.textMuted
                            : context.textPrimary,
                    fontWeight: isToday || isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==================== BADGES TAB ====================

  Widget _buildBadgesTab() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        final unlockedBadges = badgeProvider.userBadges;
        final lockedBadges = badgeProvider.lockedBadges;
        final totalBadges = BadgeModel.allBadges.length;
        final unlockedCount = unlockedBadges.length;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Summary Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Your Achievements ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('🏆', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$unlockedCount of $totalBadges badges earned',
                            style: TextStyle(
                              color: Colors.white.withAlpha(220),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BadgesScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              // Earned Section
              if (unlockedBadges.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Earned',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                // Earned badges
                ...unlockedBadges.map((badge) => _buildBadgeCard(badge: badge, isEarned: true)),
              ],

              // Locked Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Locked',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Locked badges (show first 5)
              ...lockedBadges.take(5).map((badge) => _buildBadgeCard(badge: badge, isEarned: false)),

              // View all button if more badges
              if (lockedBadges.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          'View All ${lockedBadges.length - 5} More Badges',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard({required BadgeModel badge, required bool isEarned}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned ? badge.tierColor.withAlpha(100) : context.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isEarned
                  ? badge.tierColor.withAlpha(30)
                  : context.bgElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isEarned ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEarned ? context.textPrimary : context.textMuted,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badge.tierColor.withAlpha(isEarned ? 30 : 15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${badge.tierName} • ${badge.xpReward} XP',
                        style: TextStyle(
                          color: isEarned ? badge.tierColor : context.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status
          if (isEarned)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or contact admin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textMuted,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _firestoreService.seedInitialData();
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Seed Demo Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFFF472B6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
    ];
    return colors[index % colors.length];
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}