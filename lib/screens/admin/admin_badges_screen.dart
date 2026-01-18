import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/emoji_picker_widget.dart';

class AdminBadgesScreen extends StatefulWidget {
  const AdminBadgesScreen({super.key});

  @override
  State<AdminBadgesScreen> createState() => _AdminBadgesScreenState();
}

class _AdminBadgesScreenState extends State<AdminBadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BadgeTemplate> _badges = [];
  List<Map<String, dynamic>> _lessonCategories = [];
  bool _isLoading = true;

  final List<BadgeCategory> _categories = BadgeCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadBadges();
      }
    });
    _loadBadges();
    _loadLessonCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BadgeCategory get _currentCategory => _categories[_tabController.index];

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<BadgeProvider>(context, listen: false);
      final badges = await provider.getBadgePoolByCategory(_currentCategory);
      if (mounted) {
        setState(() {
          _badges = badges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLessonCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .get();
      
      if (mounted) {
        setState(() {
          _lessonCategories = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'icon': data['icon'] ?? '📁',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.success,
      ),
    );
  }

  String _getCategoryEmoji(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.learning:
        return '📚';
      case BadgeCategory.streak:
        return '🔥';
      case BadgeCategory.quiz:
        return '🎯';
      case BadgeCategory.social:
        return '👥';
      case BadgeCategory.milestone:
        return '⭐';
      case BadgeCategory.special:
        return '✨';
    }
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFF00D9FF);
    }
  }

  Color _getTierGradientStart(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFE8E8E8);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFF00D9FF);
    }
  }

  Color _getTierGradientEnd(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFF8B4513);
      case BadgeTier.silver:
        return const Color(0xFF808080);
      case BadgeTier.gold:
        return const Color(0xFFFF8C00);
      case BadgeTier.platinum:
        return const Color(0xFF9D00FF);
    }
  }

  String _getTierName(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.platinum:
        return 'Platinum';
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
        title: const Text('Manage Badges'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textMuted,
          tabs: _categories.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getCategoryEmoji(cat)),
                  const SizedBox(width: 6),
                  Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _badges.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadBadges,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                          itemCount: _badges.length,
                          itemBuilder: (context, index) {
                            return _buildBadgeCard(_badges[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Badge'),
      ),
    );
  }

  Widget _buildStats() {
    final activeCount = _badges.where((b) => b.isActive).length;
    final categoryCount = _badges.where((b) => b.lessonCategoryId != null).length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _badges.length.toString(), Icons.emoji_events),
          _buildStatItem('Active', activeCount.toString(), Icons.check_circle, color: AppColors.success),
          _buildStatItem('Category', categoryCount.toString(), Icons.folder, color: AppColors.primary),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? context.textMuted, size: 24),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: context.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_getCategoryEmoji(_currentCategory), style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No ${_currentCategory.name} badges yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Add badges to the pool', style: TextStyle(color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeTemplate badge, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.isActive ? context.borderColor : Colors.orange.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: badge.isActive
                    ? [_getTierGradientStart(badge.tier), _getTierGradientEnd(badge.tier)]
                    : [Colors.grey.shade400, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: badge.isActive
                  ? [BoxShadow(color: _getTierColor(badge.tier).withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Center(child: Text(badge.icon, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(badge.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: badge.isActive ? context.textPrimary : context.textMuted))),
                    if (!badge.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Inactive', style: TextStyle(color: Colors.orange, fontSize: 10)),
                      ),
                    if (badge.isSecret)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.purple.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Secret', style: TextStyle(color: Colors.purple, fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(badge.description, style: TextStyle(color: context.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildTag(_getTierName(badge.tier), Icons.military_tech, color: _getTierColor(badge.tier)),
                    _buildTag('Req: ${badge.requirement}', Icons.flag),
                    _buildTag('+${badge.xpReward} XP', Icons.star, color: AppColors.primary),
                    if (badge.lessonCategoryId != null)
                      _buildTag(badge.lessonCategoryName ?? 'Category', Icons.folder, color: Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: Icon(Icons.edit, color: context.textMuted, size: 20), onPressed: () => _showAddEditDialog(badge)),
              IconButton(
                icon: Icon(badge.isActive ? Icons.visibility : Icons.visibility_off, color: badge.isActive ? AppColors.success : Colors.orange, size: 20),
                onPressed: () => _toggleActive(badge),
              ),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _confirmDelete(badge)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
  }

  Widget _buildTag(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (color ?? context.textMuted).withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? context.textMuted),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color ?? context.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _toggleActive(BadgeTemplate badge) async {
    try {
      final provider = Provider.of<BadgeProvider>(context, listen: false);
      await provider.toggleBadgeActive(badge.id, !badge.isActive);
      _loadBadges();
      _showSnackBar(badge.isActive ? 'Badge deactivated' : 'Badge activated');
    } catch (e) {
      _showSnackBar('Error updating badge', isError: true);
    }
  }

  Future<void> _confirmDelete(BadgeTemplate badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        title: const Text('Delete Badge?'),
        content: Text('Are you sure you want to delete "${badge.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = Provider.of<BadgeProvider>(context, listen: false);
        await provider.deleteBadge(badge.id);
        if (!mounted) return;
        _loadBadges();
        _showSnackBar('Badge deleted');
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Error deleting badge', isError: true);
      }
    }
  }

  Future<void> _showAddEditDialog(BadgeTemplate? badge) async {
    final isEditing = badge != null;

    final nameController = TextEditingController(text: badge?.name ?? '');
    final descController = TextEditingController(text: badge?.description ?? '');
    final reqController = TextEditingController(text: badge?.requirement.toString() ?? '1');
    final xpController = TextEditingController(text: badge?.xpReward.toString() ?? '50');

    String selectedEmoji = badge?.icon ?? '🏆';
    BadgeTier selectedTier = badge?.tier ?? BadgeTier.bronze;
    BadgeCategory selectedCategory = badge?.category ?? _currentCategory;
    String selectedTrackingField = badge?.trackingField ?? 'signsLearned';
    String? selectedLessonCategoryId = badge?.lessonCategoryId;
    String? selectedLessonCategoryName = badge?.lessonCategoryName;
    bool isSecret = badge?.isSecret ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final requiresCategory = BadgeTemplate.requiresCategory(selectedTrackingField);
          
          return AlertDialog(
            backgroundColor: context.bgCard,
            title: Text(isEditing ? 'Edit Badge' : 'Add Badge'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji picker
                    EmojiPickerWidget(
                      selectedEmoji: selectedEmoji,
                      onEmojiSelected: (emoji) => setDialogState(() => selectedEmoji = emoji),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Badge Name', hintText: 'e.g., Sign Master', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(labelText: 'Description', hintText: 'e.g., Learn 100 signs', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 12),

                    // Tier dropdown
                    DropdownButtonFormField<BadgeTier>(
                      value: selectedTier,
                      decoration: InputDecoration(labelText: 'Tier', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: BadgeTier.values.map((tier) => DropdownMenuItem(
                        value: tier,
                        child: Row(
                          children: [
                            Container(width: 16, height: 16, decoration: BoxDecoration(color: _getTierColor(tier), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(_getTierName(tier)),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedTier = v!),
                    ),
                    const SizedBox(height: 12),

                    // Badge Category dropdown
                    DropdownButtonFormField<BadgeCategory>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Badge Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: BadgeCategory.values.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(_getCategoryEmoji(cat)),
                            const SizedBox(width: 8),
                            Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),

                    // Tracking field dropdown
                    DropdownButtonFormField<String>(
                      value: selectedTrackingField,
                      decoration: InputDecoration(labelText: 'What to Track', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: BadgeTemplate.trackingFieldOptions.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          selectedTrackingField = v!;
                          if (!BadgeTemplate.requiresCategory(v)) {
                            selectedLessonCategoryId = null;
                            selectedLessonCategoryName = null;
                          }
                        });
                      },
                    ),
                    
                    // Lesson Category dropdown (shown only if tracking requires it)
                    if (requiresCategory) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedLessonCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Select Lesson Category *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: AppColors.primary.withAlpha(10),
                          filled: true,
                        ),
                        items: _lessonCategories.map((cat) => DropdownMenuItem(
                          value: cat['id'] as String,
                          child: Row(
                            children: [
                              Text(cat['icon'] as String),
                              const SizedBox(width: 8),
                              Text(cat['name'] as String),
                            ],
                          ),
                        )).toList(),
                        onChanged: (v) {
                          final cat = _lessonCategories.firstWhere((c) => c['id'] == v);
                          setDialogState(() {
                            selectedLessonCategoryId = v;
                            selectedLessonCategoryName = cat['name'] as String;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ This tracking type requires a specific lesson category',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Requirement and XP
                    Row(
                      children: [
                        Expanded(child: TextField(controller: reqController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Requirement', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: xpController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'XP Reward', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Secret badge toggle
                    SwitchListTile(
                      title: const Text('Secret Badge'),
                      subtitle: const Text('Hidden until unlocked'),
                      value: isSecret,
                      onChanged: (v) => setDialogState(() => isSecret = v),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || descController.text.isEmpty) {
                    _showSnackBar('Please fill all fields', isError: true);
                    return;
                  }
                  
                  if (requiresCategory && selectedLessonCategoryId == null) {
                    _showSnackBar('Please select a lesson category', isError: true);
                    return;
                  }

                  final newBadge = BadgeTemplate(
                    id: badge?.id ?? '',
                    name: nameController.text,
                    description: descController.text,
                    icon: selectedEmoji,
                    tier: selectedTier,
                    category: selectedCategory,
                    requirement: int.tryParse(reqController.text) ?? 1,
                    trackingField: selectedTrackingField,
                    lessonCategoryId: requiresCategory ? selectedLessonCategoryId : null,
                    lessonCategoryName: requiresCategory ? selectedLessonCategoryName : null,
                    xpReward: int.tryParse(xpController.text) ?? 50,
                    isSecret: isSecret,
                    isActive: badge?.isActive ?? true,
                    createdAt: badge?.createdAt ?? DateTime.now(),
                  );

                  try {
                    final provider = Provider.of<BadgeProvider>(context, listen: false);
                    if (isEditing) {
                      await provider.updateBadge(newBadge);
                    } else {
                      await provider.addBadge(newBadge);
                    }
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _loadBadges();
                    _showSnackBar(isEditing ? 'Badge updated' : 'Badge added');
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackBar('Error saving badge', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}