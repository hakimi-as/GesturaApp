import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/category_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _firestoreService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryCard(context, _categories[index], index);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category, int index) {
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
          // Category Icon (Image or Emoji)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: category.hasCustomImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      CloudinaryService.getOptimizedImage(category.imageUrl!, width: 112),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) => Center(
                        child: Text(category.icon, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  )
                : Center(
                    child: Text(category.icon, style: const TextStyle(fontSize: 28)),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${category.lessonCount} lessons',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary, size: 22),
                onPressed: () => _showAddEditDialog(category),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 22),
                onPressed: () => _showDeleteConfirmation(category),
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
          const Text('📁', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first category to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(CategoryModel? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final customEmojiController = TextEditingController();
    
    String selectedIcon = category?.icon ?? '📚';
    String? uploadedImageUrl = category?.imageUrl;
    bool useImage = uploadedImageUrl != null && uploadedImageUrl.isNotEmpty;
    bool isUploading = false;
    int selectedEmojiCategory = 0;

    // Organized emoji categories
    final emojiCategories = {
      '📚 Education': ['📚', '📖', '📝', '✏️', '🎓', '📐', '🔬', '🧪', '📊', '💡', '🎯', '✅'],
      '🔤 Letters': ['🔤', '🔡', '🔠', '🅰️', '🅱️', '🆎', 'ℹ️', '🔣', '🔢', '💯', '🔟', '#️⃣'],
      '👋 Gestures': ['👋', '🤚', '✋', '🖐️', '👌', '🤌', '🤏', '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👈', '👉', '👆', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '🫶', '👐', '🤲', '🤝', '🙏'],
      '😀 Faces': ['😀', '😃', '😄', '😁', '😊', '🥰', '😍', '🤩', '😎', '🤔', '🤗', '😮'],
      '👨‍👩‍👧 People': ['👨‍👩‍👧‍👦', '👨‍👩‍👧', '👨‍👩‍👦', '👪', '👶', '👧', '🧒', '👦', '👩', '🧑', '👨', '👵', '🧓', '👴', '👮', '👷', '💂', '🕵️', '👩‍⚕️', '👨‍🎓', '👩‍🏫', '👨‍⚖️'],
      '🏠 Places': ['🏠', '🏡', '🏢', '🏣', '🏥', '🏦', '🏪', '🏫', '🏛️', '⛪', '🕌', '🏰'],
      '🍎 Food': ['🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🥑', '🥦', '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕'],
      '🐾 Animals': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺'],
      '⚽ Sports': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊'],
      '🚗 Transport': ['🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚', '🚛', '🚜', '🛵', '🏍️', '🚲', '🛴', '✈️', '🚀', '🚁', '🛸', '⛵', '🚢'],
      '⏰ Time': ['⏰', '⌚', '⏱️', '⏲️', '🕰️', '📅', '📆', '🗓️', '⌛', '⏳', '🌅', '🌄', '🌃', '🌙', '🌞', '⭐'],
      '🎨 Arts': ['🎨', '🖼️', '🎭', '🎪', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸', '🪕', '🎻', '🎬', '📷', '📹', '📺', '📻', '🎮', '🕹️', '🎲', '🧩', '🪄'],
      '💼 Work': ['💼', '📁', '📂', '🗂️', '📋', '📌', '📍', '📎', '🖇️', '📏', '📐', '✂️', '🗃️', '🗄️', '🗑️', '🔒', '🔓', '🔑', '🔨', '🪓', '⛏️', '🔧', '🔩', '⚙️'],
      '❤️ Symbols': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '⭐', '🌟', '✨', '💫', '🔥', '💥'],
      '🚨 Emergency': ['🚨', '🚒', '🚑', '🆘', '⚠️', '🚧', '⛔', '🚫', '❌', '❗', '❓', '🔴'],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Type Toggle
                  Text('Icon Type', style: TextStyle(color: context.textMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => useImage = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !useImage ? AppColors.primary.withAlpha(38) : context.bgElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !useImage ? AppColors.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('😀', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text('Emoji', style: TextStyle(
                                  color: !useImage ? AppColors.primary : context.textMuted,
                                  fontWeight: FontWeight.w600,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => useImage = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: useImage ? AppColors.primary.withAlpha(38) : context.bgElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: useImage ? AppColors.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 18, color: useImage ? AppColors.primary : context.textMuted),
                                const SizedBox(width: 6),
                                Text('Image', style: TextStyle(
                                  color: useImage ? AppColors.primary : context.textMuted,
                                  fontWeight: FontWeight.w600,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Emoji Selector or Image Upload
                  if (!useImage) ...[
                    // Custom Emoji Input
                    Row(
                      children: [
                        // Current selected emoji preview
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(38),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Center(
                            child: Text(selectedIcon, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: customEmojiController,
                            style: TextStyle(color: context.textPrimary, fontSize: 20),
                            decoration: InputDecoration(
                              hintText: 'Type or paste emoji',
                              hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                              filled: true,
                              fillColor: context.bgElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check, color: AppColors.primary),
                                onPressed: () {
                                  if (customEmojiController.text.isNotEmpty) {
                                    setDialogState(() {
                                      selectedIcon = customEmojiController.text.characters.first;
                                      customEmojiController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setDialogState(() {
                                  selectedIcon = value.characters.first;
                                  customEmojiController.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Emoji Category Tabs
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: emojiCategories.keys.length,
                        itemBuilder: (context, index) {
                          final categoryName = emojiCategories.keys.elementAt(index);
                          final isSelected = selectedEmojiCategory == index;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedEmojiCategory = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withAlpha(38) : context.bgElevated,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? AppColors.primary : context.textMuted,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Emoji Grid
                    Container(
                      height: 140,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: emojiCategories.values.elementAt(selectedEmojiCategory).length,
                        itemBuilder: (context, index) {
                          final emoji = emojiCategories.values.elementAt(selectedEmojiCategory)[index];
                          final isSelected = selectedIcon == emoji;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedIcon = emoji),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withAlpha(51) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Image Upload
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                        );
                        
                        if (pickedFile != null) {
                          setDialogState(() => isUploading = true);
                          
                          try {
                            // Pass XFile directly to uploadImage
                            final result = await CloudinaryService.uploadImage(
                              pickedFile,
                              folder: 'gestura/category_icons',
                            );
                            
                            if (result != null) {
                              setDialogState(() {
                                uploadedImageUrl = result.secureUrl;
                                isUploading = false;
                              });
                            } else {
                              setDialogState(() => isUploading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to upload image')),
                                );
                              }
                            }
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: context.bgElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor, width: 2),
                        ),
                        child: isUploading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          CloudinaryService.getOptimizedImage(uploadedImageUrl!, width: 300),
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => uploadedImageUrl = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withAlpha(153),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 48, color: context.textMuted),
                                      const SizedBox(height: 8),
                                      Text('Tap to upload image',
                                          style: TextStyle(color: context.textMuted)),
                                      Text('(512x512 recommended)',
                                          style: TextStyle(color: context.textMuted, fontSize: 11)),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Name Field
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: TextStyle(color: context.textMuted),
                      filled: true,
                      fillColor: context.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextField(
                    controller: descController,
                    style: TextStyle(color: context.textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: context.textMuted),
                      filled: true,
                      fillColor: context.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (nameController.text.isEmpty) return;

                Navigator.pop(context);

                final Map<String, dynamic> data = {
                  'name': nameController.text,
                  'description': descController.text,
                  'icon': useImage ? '📁' : selectedIcon,  // Default icon if using image
                  'imageUrl': useImage ? uploadedImageUrl : null,
                };

                if (isEditing) {
                  await _firestoreService.updateCategory(category!.id, data);
                  _showSnackBar('Category updated');
                } else {
                  data['lessonCount'] = 0;
                  data['order'] = _categories.length;
                  data['isActive'] = true;
                  await _firestoreService.addCategory(data);
                  _showSnackBar('Category added');
                }
                _loadCategories();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category?'),
        content: Text(
          'This will delete "${category.name}" and all its lessons. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteCategory(category.id);
              _loadCategories();
              _showSnackBar('Category deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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