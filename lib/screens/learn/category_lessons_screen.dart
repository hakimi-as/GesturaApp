import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/category_model.dart';
import '../../models/lesson_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/certificate_service.dart';
import 'lesson_detail_screen.dart';

class CategoryLessonsScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryLessonsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryLessonsScreen> createState() => _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends State<CategoryLessonsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<LessonModel> _lessons = [];
  Set<String> _completedLessonIds = {};
  bool _isLoading = true;

  /// Check if this category is an alphabet/letters category
  bool get isAlphabetCategory {
    final categoryId = widget.category.id.toLowerCase();
    final categoryName = widget.category.name.toLowerCase();
    return categoryId == 'alphabet' || 
           categoryId == 'alphabets' ||
           categoryName.contains('alphabet') ||
           categoryName.contains('letter');
  }

  /// Get display name for a lesson (adds "Letter" prefix for alphabet lessons)
  String getDisplayName(LessonModel lesson) {
    if (isAlphabetCategory && lesson.signName.length == 1) {
      return 'Letter ${lesson.signName.toUpperCase()}';
    }
    return lesson.signName;
  }

  /// Get completed count for this category
  int get _completedCount => _lessons.where((l) => _completedLessonIds.contains(l.id)).length;
  
  /// Get total lessons count
  int get _totalLessons => _lessons.length;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);

    try {
      final lessons = await _firestoreService.getLessons(widget.category.id);
      debugPrint('📚 Loaded ${lessons.length} lessons for ${widget.category.name}');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Set<String> completedIds = {};

      if (authProvider.userId != null) {
        completedIds = await _firestoreService.getCompletedLessonIdsForUser(authProvider.userId!);
        debugPrint('✅ User completed ${completedIds.length} lessons total');
      }

      setState(() {
        _lessons = lessons;
        _completedLessonIds = completedIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading lessons: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Generate and share certificate
  Future<void> _generateCertificate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'Generating Certificate...',
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    try {
      final pdfBytes = await CertificateService.generateCategoryCertificate(
        userName: user.fullName,
        categoryName: widget.category.name,
        signsLearned: _completedCount,
        totalXP: _completedCount * 10,
        completionDate: DateTime.now(),
        totalSigns: _totalLessons,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Share/Save the certificate
      await CertificateService.shareCertificate(
        pdfBytes,
        'Gestura_${widget.category.name.replaceAll(' ', '_')}_Certificate.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating certificate: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedCount;
    final totalLessons = _totalLessons;
    final progress = totalLessons > 0 ? completedCount / totalLessons : 0.0;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _loadLessons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadLessons,
              color: AppColors.primary,
              child: Column(
                children: [
                  _buildHeader(context, completedCount, totalLessons, progress),
                  _buildCertificateButton(), // Certificate button added here
                  Expanded(
                    child: _lessons.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _lessons.length,
                            itemBuilder: (context, index) {
                              return _buildLessonCard(
                                context,
                                _lessons[index],
                                index,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Certificate button widget
  Widget _buildCertificateButton() {
    final isCompleted = _completedCount == _totalLessons && _totalLessons > 0;
    final percentage = _totalLessons > 0 
        ? (_completedCount / _totalLessons * 100).toInt() 
        : 0;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _completedCount > 0 ? _generateCertificate : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: _completedCount > 0
                  ? LinearGradient(
                      colors: isCompleted
                          ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: _completedCount == 0 ? context.bgCard : null,
              borderRadius: BorderRadius.circular(14),
              border: _completedCount == 0 
                  ? Border.all(color: context.borderColor) 
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.workspace_premium : Icons.card_membership,
                  color: _completedCount > 0 ? Colors.white : context.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _completedCount == 0
                        ? 'Complete lessons to get certificate'
                        : isCompleted
                            ? 'Get Completion Certificate 🎓'
                            : 'Share Progress Certificate ($percentage%)',
                    style: TextStyle(
                      color: _completedCount > 0 ? Colors.white : context.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_completedCount > 0) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.share,
                    color: Colors.white.withAlpha(200),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildHeader(BuildContext context, int completedCount, int totalLessons, double progress) {
    final isAllCompleted = completedCount == totalLessons && totalLessons > 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isAllCompleted
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAllCompleted ? AppColors.success : AppColors.primary).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: isAllCompleted
                      ? const Icon(Icons.check_circle, color: Colors.white, size: 32)
                      : Text(
                          widget.category.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAllCompleted
                          ? '🎉 All lessons completed!'
                          : widget.category.description,
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedCount of $totalLessons completed',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withAlpha(51),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildLessonCard(BuildContext context, LessonModel lesson, int index) {
    final isCompleted = _completedLessonIds.contains(lesson.id);
    final displayName = getDisplayName(lesson);
    
    debugPrint('🎯 Lesson ${lesson.signName} (${lesson.id}) - Display: $displayName - Completed: $isCompleted');

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              lesson: lesson,
              category: widget.category,
            ),
          ),
        );

        if (result == true) {
          _loadLessons();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? AppColors.success.withAlpha(128) : context.borderColor,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Lesson thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withAlpha(38)
                    : AppColors.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: lesson.imageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            CloudinaryService.getOptimizedImage(lesson.imageUrl!, width: 112, height: 112),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(lesson.emoji, style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              color: AppColors.success.withAlpha(180),
                              child: const Center(
                                child: Icon(Icons.check, color: Colors.white, size: 28),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: AppColors.success, size: 28)
                            : Text(lesson.emoji, style: const TextStyle(fontSize: 28)),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Lesson info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textMuted,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withAlpha(26)
                              : AppColors.warning.withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCompleted ? '✅' : '⭐',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted ? 'Earned ${lesson.xpReward} XP' : '+${lesson.xpReward} XP',
                              style: TextStyle(
                                color: isCompleted ? AppColors.success : AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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

            Icon(
              isCompleted ? Icons.replay : Icons.chevron_right,
              color: isCompleted ? AppColors.success : context.textMuted,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.category.icon,
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 16),
          Text(
            'No lessons yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Lessons for ${widget.category.name} will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadLessons,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}