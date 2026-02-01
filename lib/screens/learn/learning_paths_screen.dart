import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/firestore_service.dart';
import '../../services/learning_path_service.dart';
import '../../models/learning_path_model.dart';
import '../../models/category_model.dart';
import 'lesson_detail_screen.dart';
import '../quiz/quiz_list_screen.dart';

class LearningPathsScreen extends StatefulWidget {
  const LearningPathsScreen({super.key});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen>
    with SingleTickerProviderStateMixin {
  List<LearningPath> _allPaths = [];
  Map<String, UserLearningPathProgress> _userProgress = {};
  bool _isLoading = true;
  String? _error;
  int _selectedFilter = 0;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Beginner', 'icon': Icons.eco_rounded, 'color': 0xFF10B981},
    {'label': 'Intermediate', 'icon': Icons.trending_up_rounded, 'color': 0xFFF59E0B},
    {'label': 'Advanced', 'icon': Icons.rocket_launch_rounded, 'color': 0xFFEF4444},
  ];

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '';

      final paths = await LearningPathService.getAllPaths();
      final progressList = await LearningPathService.getUserProgress(userId);
      final progressMap = <String, UserLearningPathProgress>{};
      for (final progress in progressList) {
        progressMap[progress.pathId] = progress;
      }

      setState(() {
        _allPaths = paths;
        _userProgress = progressMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading paths: $e');
      setState(() {
        _error = 'Failed to load learning paths';
        _isLoading = false;
      });
    }
  }

  List<LearningPath> _getFilteredPaths() {
    if (_selectedFilter == 0) return _allPaths;
    final difficulty = _filters[_selectedFilter]['label'].toString().toLowerCase();
    return _allPaths.where((p) => p.difficulty == difficulty).toList();
  }

  int get _totalCompletedPaths {
    return _userProgress.values.where((p) => p.isCompleted).length;
  }

  int get _totalXPEarned {
    return _userProgress.values.fold(0, (sum, p) => sum + p.xpEarned);
  }

  int get _pathsInProgress {
    return _userProgress.values.where((p) => !p.isCompleted).length;
  }

  Future<void> _startPath(LearningPath path) async {
    HapticService.buttonTap();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';

    final progress = await LearningPathService.startPath(userId, path.id);
    
    if (progress != null) {
      setState(() {
        _userProgress[path.id] = progress;
      });
      HapticService.success();
      _openPathDetail(path);
    }
  }

  void _openPathDetail(LearningPath path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathDetailScreen(
          path: path,
          progress: _userProgress[path.id],
        ),
      ),
    ).then((_) => _loadPaths());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Hero Header
          SliverToBoxAdapter(
            child: _buildHeroHeader(),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),

          // Content
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? SliverFillRemaining(child: _buildErrorState())
                  : _buildPathsGrid(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
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
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${_allPaths.length} Paths',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Hero Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
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
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Master sign language step by step',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      _buildHeroStat(
                        icon: Icons.check_circle_outline,
                        value: '$_totalCompletedPaths',
                        label: 'Completed',
                      ),
                      const SizedBox(width: 16),
                      _buildHeroStat(
                        icon: Icons.play_circle_outline,
                        value: '$_pathsInProgress',
                        label: 'In Progress',
                      ),
                      const SizedBox(width: 16),
                      _buildHeroStat(
                        icon: Icons.star_outline,
                        value: _formatXP(_totalXPEarned),
                        label: 'XP Earned',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Curved bottom
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == index;
            final color = filter['color'] != null
                ? Color(filter['color'] as int)
                : AppColors.primary;

            return Padding(
              padding: EdgeInsets.only(right: index < _filters.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  setState(() => _selectedFilter = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [color, color.withAlpha(200)],
                          )
                        : null,
                    color: isSelected ? null : context.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : context.borderColor,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(60),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : context.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1);
  }

  Widget _buildPathsGrid() {
    final filteredPaths = _getFilteredPaths();

    if (filteredPaths.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final path = filteredPaths[index];
            final progress = _userProgress[path.id];

            return _LearningPathCard(
              path: path,
              progress: progress,
              onTap: () => _openPathDetail(path),
              onStart: () => _startPath(path),
              index: index,
            );
          },
          childCount: filteredPaths.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('📚', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No paths available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new learning paths!',
            style: TextStyle(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPaths,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}k';
    }
    return xp.toString();
  }
}

// ==================== REDESIGNED PATH CARD ====================

class _LearningPathCard extends StatelessWidget {
  final LearningPath path;
  final UserLearningPathProgress? progress;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final int index;

  const _LearningPathCard({
    required this.path,
    this.progress,
    this.onTap,
    this.onStart,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isStarted = progress != null;
    final isCompleted = progress?.isCompleted ?? false;
    final progressPercent = progress?.progressPercent(path.steps.length) ?? 0.0;
    final completedSteps = progress?.completedStepIds.length ?? 0;
    final pathColor = Color(path.difficultyColor);

    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withAlpha(100)
                : context.borderColor,
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: pathColor.withAlpha(isStarted ? 30 : 10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    pathColor.withAlpha(25),
                    pathColor.withAlpha(5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Circular Progress with Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: progressPercent,
                          strokeWidth: 4,
                          backgroundColor: pathColor.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? const Color(0xFF10B981) : pathColor,
                          ),
                        ),
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: context.bgCard,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: pathColor.withAlpha(40),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 32)
                              : Text(path.iconEmoji ?? '📚', style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Title and Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: pathColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                path.difficultyLabel,
                                style: TextStyle(
                                  color: pathColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, color: Color(0xFF10B981), size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Done',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          path.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.description,
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Stats Pills
                  Row(
                    children: [
                      _buildStatPill(context, '📚', '${path.totalLessons}', 'lessons'),
                      const SizedBox(width: 10),
                      _buildStatPill(context, '⭐', '${path.totalXP}', 'XP'),
                      const SizedBox(width: 10),
                      _buildStatPill(context, '📅', '~${path.estimatedDays}', 'days'),
                    ],
                  ),

                  // Progress Section
                  if (isStarted) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.bgElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Step indicators
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    color: context.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStepIndicators(context, path.steps.length, completedSteps, pathColor),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Percentage
                          Column(
                            children: [
                              Text(
                                '${(progressPercent * 100).toInt()}%',
                                style: TextStyle(
                                  color: pathColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$completedSteps/${path.steps.length}',
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompleted
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [pathColor, pathColor.withAlpha(200)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isCompleted ? const Color(0xFF10B981) : pathColor).withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticService.buttonTap();
                            if (isStarted) {
                              onTap?.call();
                            } else {
                              onStart?.call();
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.replay_rounded
                                      : isStarted
                                          ? Icons.play_arrow_rounded
                                          : Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCompleted
                                      ? 'Review Path'
                                      : isStarted
                                          ? 'Continue Learning'
                                          : 'Start Journey',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1);
  }

  Widget _buildStatPill(BuildContext context, String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$value $label',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicators(BuildContext context, int total, int completed, Color color) {
    return Row(
      children: List.generate(
        math.min(total, 8), // Max 8 dots
        (index) {
          final isComplete = index < completed;
          final isCompact = total > 8;
          
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: index < math.min(total, 8) - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isComplete ? color : context.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== REDESIGNED PATH DETAIL SCREEN ====================

class LearningPathDetailScreen extends StatefulWidget {
  final LearningPath path;
  final UserLearningPathProgress? progress;

  const LearningPathDetailScreen({
    super.key,
    required this.path,
    this.progress,
  });

  @override
  State<LearningPathDetailScreen> createState() => _LearningPathDetailScreenState();
}

class _LearningPathDetailScreenState extends State<LearningPathDetailScreen> {
  late UserLearningPathProgress? _progress;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Set<String> _completedLessonIds = {};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
    _syncWithLessonProgress();
  }

  Future<void> _syncWithLessonProgress() async {
    setState(() => _isSyncing = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '';
      
      if (userId.isEmpty) {
        setState(() => _isSyncing = false);
        return;
      }

      final progressSnapshot = await _db
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .get();

      final completedIds = <String>{};
      
      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        if (data['completed'] == true || data['isCompleted'] == true) {
          final lessonId = data['lessonId'] as String?;
          if (lessonId != null) {
            completedIds.add(lessonId);
          }
        }
      }

      setState(() {
        _completedLessonIds = completedIds;
        _isSyncing = false;
      });

      await _autoSyncPathProgress(userId, completedIds);
      
    } catch (e) {
      debugPrint('Error syncing lesson progress: $e');
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _autoSyncPathProgress(String userId, Set<String> completedLessonIds) async {
    if (_progress == null) {
      final newProgress = await LearningPathService.startPath(userId, widget.path.id);
      if (newProgress != null) {
        setState(() => _progress = newProgress);
      } else {
        return;
      }
    }

    final stepsToComplete = <String>[];
    
    for (final step in widget.path.steps) {
      if (step.type == 'lesson' && step.targetId != null) {
        if (completedLessonIds.contains(step.targetId) && 
            !(_progress?.completedStepIds.contains(step.id) ?? false)) {
          stepsToComplete.add(step.id);
        }
      }
    }

    for (final stepId in stepsToComplete) {
      await LearningPathService.completeStep(userId, widget.path.id, stepId);
    }

    if (stepsToComplete.isNotEmpty) {
      final updatedProgress = await LearningPathService.getUserPathProgress(userId, widget.path.id);
      if (mounted) {
        setState(() => _progress = updatedProgress);
      }
    }
  }

  bool _isStepUnlocked(int stepIndex) {
    if (stepIndex == 0) return true;
    
    for (int i = 0; i < stepIndex; i++) {
      final prevStepId = widget.path.steps[i].id;
      if (!_isStepCompleted(prevStepId)) {
        return false;
      }
    }
    return true;
  }

  bool _isStepCompleted(String stepId) {
    if (_progress?.completedStepIds.contains(stepId) ?? false) {
      return true;
    }
    
    final step = widget.path.steps.firstWhere(
      (s) => s.id == stepId,
      orElse: () => widget.path.steps.first,
    );
    
    if (step.type == 'lesson' && step.targetId != null) {
      return _completedLessonIds.contains(step.targetId);
    }
    
    return false;
  }

  bool _isCurrentStep(String stepId) {
    return _progress?.currentStepId == stepId;
  }

  Future<void> _onStepTap(LearningPathStep step, int stepIndex) async {
    HapticService.buttonTap();
    
    if (step.type == 'lesson') {
      await _openLesson(step, stepIndex);
    } else if (step.type == 'quiz') {
      await _openQuiz(step, stepIndex);
    }
  }

  Future<CategoryModel?> _getCategory(String categoryId) async {
    try {
      final doc = await _db.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _openLesson(LearningPathStep step, int stepIndex) async {
    if (step.targetId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      final lesson = await _firestoreService.getLesson(step.targetId!);
      
      if (lesson == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      CategoryModel? category;
      if (step.categoryId != null) {
        category = await _getCategory(step.categoryId!);
      }
      
      category ??= CategoryModel(
        id: step.categoryId ?? 'unknown',
        name: 'Learning Path',
        description: widget.path.name,
        icon: '📚',
        order: 0,
        lessonCount: 0,
      );

      if (!mounted) return;
      
      Navigator.pop(context);

      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            lesson: lesson,
            category: category!,
          ),
        ),
      );

      await _refreshProgress();
      
      if (completed == true && !_isStepCompleted(step.id)) {
        await _markStepComplete(step);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _refreshProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    
    await _syncWithLessonProgress();
    
    final updatedProgress = await LearningPathService.getUserPathProgress(userId, widget.path.id);
    if (mounted) {
      setState(() => _progress = updatedProgress);
    }
  }

  Future<void> _openQuiz(LearningPathStep step, int stepIndex) async {
    String quizType = step.targetId ?? 'sign_to_text';
    String title;
    
    switch (quizType) {
      case 'sign_to_text':
        title = 'Sign to Text';
        break;
      case 'text_to_sign':
        title = 'Text to Sign';
        break;
      case 'timed':
        title = 'Timed Challenge';
        break;
      default:
        title = 'Quiz';
        quizType = 'sign_to_text';
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizListScreen(quizType: quizType, title: title),
      ),
    );

    await _markStepComplete(step);
  }

  Future<void> _markStepComplete(LearningPathStep step) async {
    if (_isStepCompleted(step.id)) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    
    if (_progress == null) {
      final newProgress = await LearningPathService.startPath(userId, widget.path.id);
      if (newProgress == null) return;
      setState(() => _progress = newProgress);
    }
    
    final success = await LearningPathService.completeStep(userId, widget.path.id, step.id);
    
    if (success) {
      HapticService.success();
      
      final newProgress = await LearningPathService.getUserPathProgress(userId, widget.path.id);
      
      if (mounted) {
        setState(() => _progress = newProgress);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✅'),
                const SizedBox(width: 8),
                Expanded(child: Text('Completed "${step.title}" +${step.xpReward} XP')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _progress?.progressPercent(widget.path.steps.length) ?? 0.0;
    final completedSteps = _progress?.completedStepIds.length ?? 0;
    final pathColor = Color(widget.path.difficultyColor);
    final isCompleted = _progress?.isCompleted ?? false;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Immersive Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: pathColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: _isSyncing ? null : _refreshProgress,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pathColor, pathColor.withAlpha(200), pathColor.withAlpha(150)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and Title Row
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.emoji_events, color: Colors.amber, size: 40)
                                    : Text(widget.path.iconEmoji ?? '📚', style: const TextStyle(fontSize: 40)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.path.difficultyLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.path.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Progress Bar Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isCompleted ? 'Completed! 🎉' : 'Your Progress',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '$completedSteps of ${widget.path.steps.length} steps',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progressPercent,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withAlpha(100),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
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
                ),
              ),
            ),
          ),

          // Syncing Indicator
          if (_isSyncing)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Syncing progress...'),
                  ],
                ),
              ),
            ),

          // Description Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.path.description,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoChip(context, '📚', '${widget.path.totalLessons} lessons'),
                            const SizedBox(width: 10),
                            _buildInfoChip(context, '⭐', '${widget.path.totalXP} XP'),
                            const SizedBox(width: 10),
                            _buildInfoChip(context, '📅', '~${widget.path.estimatedDays} days'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: pathColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.route_rounded, color: pathColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Learning Journey',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Steps List with Journey Line
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final step = widget.path.steps[index];
                  final isUnlocked = _isStepUnlocked(index);
                  final isStepCompleted = _isStepCompleted(step.id);
                  final isCurrent = _isCurrentStep(step.id) && !isStepCompleted;
                  final isLast = index == widget.path.steps.length - 1;

                  return _JourneyStepItem(
                    step: step,
                    stepNumber: index + 1,
                    isCompleted: isStepCompleted,
                    isCurrent: isCurrent,
                    isLocked: !isUnlocked && !isStepCompleted,
                    isLast: isLast,
                    pathColor: pathColor,
                    onTap: (isUnlocked || isStepCompleted) ? () => _onStepTap(step, index) : null,
                  ).animate(delay: Duration(milliseconds: 50 * index))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1);
                },
                childCount: widget.path.steps.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String emoji, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(color: context.textMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== JOURNEY STEP ITEM WITH CONNECTOR ====================

class _JourneyStepItem extends StatelessWidget {
  final LearningPathStep step;
  final int stepNumber;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final bool isLast;
  final Color pathColor;
  final VoidCallback? onTap;

  const _JourneyStepItem({
    required this.step,
    required this.stepNumber,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.isLast,
    required this.pathColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journey Line and Node
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Node
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                        : isCurrent
                            ? LinearGradient(colors: [pathColor, pathColor.withAlpha(200)])
                            : null,
                    color: isCompleted || isCurrent ? null : context.bgElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : isCurrent
                              ? pathColor
                              : context.borderColor,
                      width: isCurrent ? 3 : 2,
                    ),
                    boxShadow: (isCompleted || isCurrent)
                        ? [
                            BoxShadow(
                              color: (isCompleted ? const Color(0xFF10B981) : pathColor).withAlpha(60),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : isLocked
                            ? Icon(Icons.lock_rounded, color: context.textMuted, size: 18)
                            : Text(
                                step.typeIcon,
                                style: const TextStyle(fontSize: 20),
                              ),
                  ),
                ),
                // Connector Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFF10B981) : context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Card
          Expanded(
            child: GestureDetector(
              onTap: isLocked
                  ? null
                  : () {
                      HapticService.buttonTap();
                      onTap?.call();
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? pathColor.withAlpha(15)
                      : context.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? pathColor.withAlpha(100)
                        : isCompleted
                            ? const Color(0xFF10B981).withAlpha(60)
                            : context.borderColor,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Step $stepNumber',
                                  style: TextStyle(
                                    color: isCurrent ? pathColor : context.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pathColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        color: pathColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    color: isCompleted ? context.textMuted : null,
                                  ),
                            ),
                            if (step.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                step.description!,
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF10B981).withAlpha(20)
                                  : AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: isCompleted ? const Color(0xFF10B981) : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${step.xpReward}',
                                  style: TextStyle(
                                    color: isCompleted ? const Color(0xFF10B981) : AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            isCurrent
                                ? Icons.play_circle_filled_rounded
                                : Icons.chevron_right_rounded,
                            color: isCurrent ? pathColor : context.textMuted,
                            size: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}