import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/category_model.dart';
import '../../models/lesson_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<LessonModel> _lessons = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _firestoreService.getCategories();
      final lessons = await _firestoreService.getAllLessons();
      if (mounted) {
        setState(() {
          _categories = categories;
          _lessons = lessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<LessonModel> get _filteredLessons {
    if (_selectedCategoryId == null) return _lessons;
    return _lessons.where((l) => l.categoryId == _selectedCategoryId).toList();
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
        title: const Text('Manage Lessons'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips - scrollable (with drag support for web)
          Container(
            height: 56,
            margin: const EdgeInsets.only(top: 10),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(cat.name, cat.id),
                  )),
                  const SizedBox(width: 20), // Extra padding at end for scroll
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_filteredLessons.length} lessons',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textMuted,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredLessons.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                          itemCount: _filteredLessons.length,
                          itemBuilder: (context, index) {
                            return _buildLessonCard(context, _filteredLessons[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _categories.isEmpty
            ? () => _showSnackBar('Please add a category first')
            : () => _showAddEditDialog(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Lesson'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = categoryId),
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

  Widget _buildLessonCard(BuildContext context, LessonModel lesson, int index) {
    final category = _categories.firstWhere(
      (c) => c.id == lesson.categoryId,
      orElse: () => CategoryModel(
        id: '', name: 'Unknown', description: '', icon: '📚',
        lessonCount: 0, order: 0, isActive: true,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        difficulty: 'easy', signLanguage: 'ASL',
      ),
    );

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
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
              image: lesson.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(CloudinaryService.getOptimizedImage(
                        lesson.imageUrl!, width: 112, height: 112,
                      )),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: lesson.imageUrl == null
                ? Center(child: Text(lesson.emoji, style: const TextStyle(fontSize: 28)))
                : lesson.videoUrl != null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                        ),
                      )
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.signName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (lesson.videoUrl != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, size: 12, color: AppColors.success),
                            SizedBox(width: 2),
                            Text('Video', style: TextStyle(fontSize: 9, color: AppColors.success)),
                          ],
                        ),
                      ),
                    if (lesson.imageUrl != null && lesson.videoUrl == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 12, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text('Image', style: TextStyle(fontSize: 9, color: AppColors.primary)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(category.name, style: TextStyle(color: context.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${lesson.xpReward} XP',
                        style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary, size: 22),
                onPressed: () => _showAddEditDialog(lesson),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 22),
                onPressed: () => _showDeleteConfirmation(lesson),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No lessons yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            _categories.isEmpty
                ? 'Add a category first, then add lessons'
                : 'Add your first lesson to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(LessonModel? lesson) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LessonDialog(
        lesson: lesson,
        categories: _categories,
        firestoreService: _firestoreService,
        existingLessonsCount: _lessons.where((l) => l.categoryId == (lesson?.categoryId ?? _categories.first.id)).length,
      ),
    );
    
    if (result == true) {
      _loadData();
      _showSnackBar(lesson != null ? 'Lesson updated' : 'Lesson added');
    }
  }

  void _showDeleteConfirmation(LessonModel lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Lesson?'),
        content: Text('This will delete "${lesson.signName}". This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteLesson(lesson.id);
              _loadData();
              _showSnackBar('Lesson deleted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Separate StatefulWidget for the dialog to properly handle mounted state
class _LessonDialog extends StatefulWidget {
  final LessonModel? lesson;
  final List<CategoryModel> categories;
  final FirestoreService firestoreService;
  final int existingLessonsCount;

  const _LessonDialog({
    required this.lesson,
    required this.categories,
    required this.firestoreService,
    required this.existingLessonsCount,
  });

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController xpController;
  late TextEditingController tipsController;
  late String selectedCategoryId;
  
  String? imageUrl;
  String? videoUrl;
  XFile? selectedImageFile;
  XFile? selectedVideoFile;
  Uint8List? selectedImageBytes;
  Uint8List? selectedVideoBytes;
  bool isUploadingImage = false;
  bool isUploadingVideo = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.lesson?.signName ?? '');
    descController = TextEditingController(text: widget.lesson?.description ?? '');
    xpController = TextEditingController(text: widget.lesson?.xpReward.toString() ?? '10');
    tipsController = TextEditingController(text: widget.lesson?.tips.join('\n') ?? '');
    selectedCategoryId = widget.lesson?.categoryId ?? widget.categories.first.id;
    imageUrl = widget.lesson?.imageUrl;
    videoUrl = widget.lesson?.videoUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    xpController.dispose();
    tipsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            selectedImageFile = picked;
            selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            selectedVideoFile = picked;
            selectedVideoBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _save() async {
    if (nameController.text.isEmpty) return;
    
    setState(() => isSaving = true);

    try {
      // Upload image if selected
      if (selectedImageFile != null) {
        setState(() => isUploadingImage = true);
        final result = await CloudinaryService.uploadImage(
          selectedImageFile!,
          folder: 'gestura/lessons',
        );
        if (result != null) {
          imageUrl = result.secureUrl;
        }
        if (mounted) setState(() => isUploadingImage = false);
      }

      // Upload video if selected
      if (selectedVideoFile != null) {
        setState(() => isUploadingVideo = true);
        final result = await CloudinaryService.uploadVideo(
          selectedVideoFile!,
          folder: 'gestura/lessons',
        );
        if (result != null) {
          videoUrl = result.secureUrl;
        }
        if (mounted) setState(() => isUploadingVideo = false);
      }

      final tips = tipsController.text
          .split('\n')
          .where((t) => t.trim().isNotEmpty)
          .toList();

      final lessonData = {
        'signName': nameController.text,
        'description': descController.text,
        'emoji': widget.lesson?.emoji ?? '🤟', // Keep existing or use default
        'categoryId': selectedCategoryId,
        'xpReward': int.tryParse(xpController.text) ?? 10,
        'tips': tips,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'updatedAt': DateTime.now(),
      };

      if (widget.lesson != null) {
        await widget.firestoreService.updateLesson(widget.lesson!.id, lessonData);
      } else {
        lessonData['signLanguage'] = 'ASL';
        lessonData['order'] = widget.existingLessonsCount;
        lessonData['isActive'] = true;
        lessonData['createdAt'] = DateTime.now();
        await widget.firestoreService.addLesson(lessonData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving lesson: $e');
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lesson != null;
    final hasImageMedia = imageUrl != null || selectedImageFile != null;
    final hasVideoMedia = videoUrl != null || selectedVideoFile != null;

    return AlertDialog(
      backgroundColor: context.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isEditing ? 'Edit Lesson' : 'Add Lesson'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selector
              Text('Category', style: TextStyle(color: context.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: selectedCategoryId,
                  isExpanded: true,
                  dropdownColor: context.bgCard,
                  underline: const SizedBox(),
                  items: widget.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Row(children: [Text(cat.icon), const SizedBox(width: 8), Text(cat.name)]),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategoryId = value!),
                ),
              ),
              const SizedBox(height: 16),

              // Media Upload Section
              Text('Media', style: TextStyle(color: context.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMediaCard(
                      title: 'Image',
                      icon: Icons.image,
                      isUploading: isUploadingImage,
                      hasMedia: hasImageMedia,
                      previewBytes: selectedImageBytes,
                      mediaUrl: imageUrl,
                      onTap: _pickImage,
                      onRemove: () => setState(() {
                        selectedImageFile = null;
                        selectedImageBytes = null;
                        imageUrl = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMediaCard(
                      title: 'Video',
                      icon: Icons.videocam,
                      isUploading: isUploadingVideo,
                      hasMedia: hasVideoMedia,
                      previewBytes: null,
                      mediaUrl: videoUrl,
                      onTap: _pickVideo,
                      onRemove: () => setState(() {
                        selectedVideoFile = null;
                        selectedVideoBytes = null;
                        videoUrl = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sign Name
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Sign Name',
                  filled: true,
                  fillColor: context.bgElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: context.bgElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // XP Reward
              TextField(
                controller: xpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'XP Reward',
                  filled: true,
                  fillColor: context.bgElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Tips
              TextField(
                controller: tipsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Tips (one per line)',
                  filled: true,
                  fillColor: context.bgElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildMediaCard({
    required String title,
    required IconData icon,
    required bool isUploading,
    required bool hasMedia,
    Uint8List? previewBytes,
    String? mediaUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasMedia ? AppColors.success : context.borderColor,
            width: hasMedia ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Preview
            if (previewBytes != null && title == 'Image')
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(previewBytes, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              )
            else if (mediaUrl != null && title == 'Image')
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  CloudinaryService.getOptimizedImage(mediaUrl, width: 200, height: 200),
                  width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(hasMedia ? Icons.check_circle : icon, color: hasMedia ? AppColors.success : context.textMuted, size: 28),
                    const SizedBox(height: 4),
                    Text(hasMedia ? '$title Added' : 'Add $title', style: TextStyle(color: hasMedia ? AppColors.success : context.textMuted, fontSize: 12)),
                  ],
                ),
              ),

            // Loading overlay
            if (isUploading)
              Container(
                decoration: BoxDecoration(color: Colors.black.withAlpha(128), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              ),

            // Remove button
            if (hasMedia && !isUploading)
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}