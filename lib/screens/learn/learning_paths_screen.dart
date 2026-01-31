import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/firestore_service.dart';
import '../../services/learning_path_service.dart';
import '../../models/learning_path_model.dart';
import '../../models/category_model.dart';
import '../../widgets/learning_path_widgets.dart';
import 'lesson_detail_screen.dart';
import '../quiz/quiz_list_screen.dart';

class LearningPathsScreen extends StatefulWidget {
  const LearningPathsScreen({super.key});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<LearningPath> _allPaths = [];
  Map<String, UserLearningPathProgress> _userProgress = {};
  bool _isLoading = true;
  String? _error;

  final List<String> _difficulties = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _difficulties.length, vsync: this);
    _loadPaths();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '';

      // Load all paths
      final paths = await LearningPathService.getAllPaths();
      
      // Load user progress for each path
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

  List<LearningPath> _getFilteredPaths(int tabIndex) {
    if (tabIndex == 0) return _allPaths;
    
    final difficulty = _difficulties[tabIndex].toLowerCase();
    return _allPaths.where((p) => p.difficulty == difficulty).toList();
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
      
      // Navigate to path detail
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
      appBar: AppBar(
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
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Learning Paths'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${_allPaths.length} Paths',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              dividerColor: Colors.transparent,
              tabs: _difficulties.map((d) => Tab(text: d)).toList(),
              onTap: (_) => setState(() {}),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildPathsList(),
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
          Text(
            _error!,
            style: TextStyle(color: context.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPaths,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathsList() {
    final filteredPaths = _getFilteredPaths(_tabController.index);

    if (filteredPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No paths available',
              style: Theme.of(context).textTheme.titleMedium,
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

    return RefreshIndicator(
      onRefresh: _loadPaths,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: filteredPaths.length,
        itemBuilder: (context, index) {
          final path = filteredPaths[index];
          final progress = _userProgress[path.id];

          return LearningPathCard(
            path: path,
            progress: progress,
            onTap: () => _openPathDetail(path),
            onStart: () => _startPath(path),
          );
        },
      ),
    );
  }
}

// ==================== PATH DETAIL SCREEN ====================

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
  
  // Track completed lessons from normal category flow
  Set<String> _completedLessonIds = {};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
    _syncWithLessonProgress();
  }

  /// Sync learning path progress with lessons completed in Categories
  Future<void> _syncWithLessonProgress() async {
    setState(() => _isSyncing = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '';
      
      if (userId.isEmpty) {
        setState(() => _isSyncing = false);
        return;
      }

      // Get user's lesson progress from the 'progress' collection
      final progressSnapshot = await _db
          .collection('progress')
          .where('odlerndId', isEqualTo: userId)
          .get();
      
      // Also try with 'userId' field name
      final progressSnapshot2 = await _db
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .get();

      // Collect all completed lesson IDs
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
      
      for (final doc in progressSnapshot2.docs) {
        final data = doc.data();
        if (data['completed'] == true || data['isCompleted'] == true) {
          final lessonId = data['lessonId'] as String?;
          if (lessonId != null) {
            completedIds.add(lessonId);
          }
        }
      }

      debugPrint('📊 Found ${completedIds.length} completed lessons');

      setState(() {
        _completedLessonIds = completedIds;
        _isSyncing = false;
      });

      // Auto-sync: Mark path steps complete for already-completed lessons
      await _autoSyncPathProgress(userId, completedIds);
      
    } catch (e) {
      debugPrint('Error syncing lesson progress: $e');
      setState(() => _isSyncing = false);
    }
  }

  /// Auto-mark path steps as complete if lesson was already done
  Future<void> _autoSyncPathProgress(String userId, Set<String> completedLessonIds) async {
    if (_progress == null) {
      // Start the path first if not started
      final newProgress = await LearningPathService.startPath(userId, widget.path.id);
      if (newProgress != null) {
        setState(() => _progress = newProgress);
      } else {
        return;
      }
    }

    // Find steps that should be marked complete
    final stepsToComplete = <String>[];
    
    for (final step in widget.path.steps) {
      if (step.type == 'lesson' && step.targetId != null) {
        if (completedLessonIds.contains(step.targetId) && 
            !(_progress?.completedStepIds.contains(step.id) ?? false)) {
          stepsToComplete.add(step.id);
        }
      }
    }

    // Mark each step as complete
    for (final stepId in stepsToComplete) {
      await LearningPathService.completeStep(userId, widget.path.id, stepId);
    }

    // Refresh progress if any steps were synced
    if (stepsToComplete.isNotEmpty) {
      final updatedProgress = await LearningPathService.getUserPathProgress(userId, widget.path.id);
      if (mounted) {
        setState(() => _progress = updatedProgress);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 Synced ${stepsToComplete.length} completed lessons'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _isStepUnlocked(int stepIndex) {
    // First step is always unlocked
    if (stepIndex == 0) return true;
    
    // Step is unlocked ONLY if ALL previous steps are completed
    for (int i = 0; i < stepIndex; i++) {
      final prevStepId = widget.path.steps[i].id;
      if (!_isStepCompleted(prevStepId)) {
        return false; // A previous step is not complete, so this one is locked
      }
    }
    return true;
  }

  bool _isStepCompleted(String stepId) {
    // Check path progress first
    if (_progress?.completedStepIds.contains(stepId) ?? false) {
      return true;
    }
    
    // Also check if the lesson was completed in normal flow
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
    
    debugPrint('Opening step: ${step.title} (type: ${step.type})');
    
    if (step.type == 'lesson') {
      await _openLesson(step, stepIndex);
    } else if (step.type == 'quiz') {
      await _openQuiz(step, stepIndex);
    }
  }

  /// Fetch category by ID
  Future<CategoryModel?> _getCategory(String categoryId) async {
    try {
      final doc = await _db.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting category: $e');
      return null;
    }
  }

  /// Open the actual lesson
  Future<void> _openLesson(LearningPathStep step, int stepIndex) async {
    if (step.targetId == null) {
      _showError('Lesson not found');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      // Fetch the lesson from Firestore
      final lesson = await _firestoreService.getLesson(step.targetId!);
      
      if (lesson == null) {
        if (mounted) Navigator.pop(context); // Close loading
        _showError('Lesson not found');
        return;
      }

      // Fetch the category
      CategoryModel? category;
      if (step.categoryId != null) {
        category = await _getCategory(step.categoryId!);
      }
      
      // If no category found, create a placeholder
      category ??= CategoryModel(
        id: step.categoryId ?? 'unknown',
        name: 'Learning Path',
        description: widget.path.name,
        icon: '📚',
        order: 0,
        lessonCount: 0,
      );

      if (!mounted) return;
      
      Navigator.pop(context); // Close loading

      // Navigate to lesson detail screen and wait for result
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            lesson: lesson,
            category: category!,
          ),
        ),
      );

      // Mark step as complete if user pressed Complete OR if lesson is now in completed set
      // Re-sync to catch any new completions
      await _refreshProgress();
      
      // If explicitly completed through the lesson screen
      if (completed == true && !_isStepCompleted(step.id)) {
        await _markStepComplete(step);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      debugPrint('Error opening lesson: $e');
      _showError('Failed to open lesson');
    }
  }

  /// Refresh progress from Firestore
  Future<void> _refreshProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    
    // Re-fetch completed lessons
    await _syncWithLessonProgress();
    
    // Re-fetch path progress
    final updatedProgress = await LearningPathService.getUserPathProgress(userId, widget.path.id);
    if (mounted) {
      setState(() => _progress = updatedProgress);
    }
  }

  /// Open quiz
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
      case 'spelling':
        title = 'Spelling Quiz';
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

    // Mark quiz step as complete after taking it
    await _markStepComplete(step);
  }

  /// Mark a step as completed
  Future<void> _markStepComplete(LearningPathStep step) async {
    if (_isStepCompleted(step.id)) return; // Already completed
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    
    // Make sure path is started
    if (_progress == null) {
      final newProgress = await LearningPathService.startPath(userId, widget.path.id);
      if (newProgress == null) return;
      setState(() => _progress = newProgress);
    }
    
    final success = await LearningPathService.completeStep(
      userId,
      widget.path.id,
      step.id,
    );
    
    if (success) {
      HapticService.success();
      
      // Refresh progress
      final newProgress = await LearningPathService.getUserPathProgress(
        userId,
        widget.path.id,
      );
      
      if (mounted) {
        setState(() {
          _progress = newProgress;
        });
        
        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✅'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Completed "${step.title}" +${step.xpReward} XP'),
                ),
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _progress?.progressPercent(widget.path.steps.length) ?? 0.0;
    final completedSteps = _progress?.completedStepIds.length ?? 0;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Color(widget.path.difficultyColor),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isSyncing ? null : _refreshProgress,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(widget.path.difficultyColor),
                      Color(widget.path.difficultyColor).withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  widget.path.iconEmoji ?? '📚',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(50),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${widget.path.difficultyLabel} · ${widget.path.steps.length} steps',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.path.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressPercent,
                                  backgroundColor: Colors.white.withAlpha(50),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$completedSteps/${widget.path.steps.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Syncing indicator
          if (_isSyncing)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Syncing progress...'),
                    ],
                  ),
                ),
              ),
            ),

          // Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.path.description,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip('📚', '${widget.path.totalLessons} lessons'),
                      const SizedBox(width: 12),
                      _buildInfoChip('⭐', '${widget.path.totalXP} XP'),
                      const SizedBox(width: 12),
                      _buildInfoChip('📅', '~${widget.path.estimatedDays} days'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Steps',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Steps List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final step = widget.path.steps[index];
                  final isUnlocked = _isStepUnlocked(index);
                  final isCompleted = _isStepCompleted(step.id);
                  final isCurrent = _isCurrentStep(step.id);

                  return LearningPathStepItem(
                    step: step,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent && !isCompleted,
                    isLocked: !isUnlocked && !isCompleted,
                    onTap: (isUnlocked || isCompleted) ? () => _onStepTap(step, index) : null,
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                  );
                },
                childCount: widget.path.steps.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}