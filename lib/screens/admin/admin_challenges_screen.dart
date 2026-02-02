import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../models/challenge_model.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/emoji_picker_widget.dart';

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({super.key});

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChallengeTemplate> _challenges = [];
  List<Map<String, dynamic>> _lessonCategories = [];
  bool _isLoading = true;
  bool _isSeeding = false;

  final List<ChallengeType> _types = ChallengeType.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadChallenges();
      }
    });
    _loadChallenges();
    _loadLessonCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ChallengeType get _currentType => _types[_tabController.index];

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final challenges = await provider.getChallengesByType(_currentType);
      if (mounted) {
        setState(() {
          _challenges = challenges;
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

  /// Seed default challenges
  Future<void> _seedDefaultChallenges() async {
    final totalCount = ChallengeTemplate.defaultDailyChallenges.length +
        ChallengeTemplate.defaultWeeklyChallenges.length +
        ChallengeTemplate.defaultSpecialChallenges.length;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        title: const Row(
          children: [
            Text('🌱', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Text('Seed Default Challenges?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will:'),
            const SizedBox(height: 12),
            _buildBulletPoint('Delete ALL existing challenges'),
            _buildBulletPoint('Clear active challenge selections'),
            _buildBulletPoint('Add $totalCount default challenges'),
            _buildBulletPoint('Daily: ${ChallengeTemplate.defaultDailyChallenges.length}'),
            _buildBulletPoint('Weekly: ${ChallengeTemplate.defaultWeeklyChallenges.length}'),
            _buildBulletPoint('Special: ${ChallengeTemplate.defaultSpecialChallenges.length}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Seed Challenges'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSeeding = true);
      
      try {
        final provider = Provider.of<ChallengeProvider>(context, listen: false);
        final success = await provider.forceSeedDefaultChallenges();
        
        if (success && mounted) {
          _showSnackBar('✅ Seeded $totalCount challenges!');
          await _loadChallenges();
        } else if (mounted) {
          _showSnackBar('Failed to seed challenges', isError: true);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error: $e', isError: true);
        }
      }
      
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _getTypeEmoji(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return '📅';
      case ChallengeType.weekly:
        return '📆';
      case ChallengeType.special:
        return '✨';
    }
  }

  String _getTypeName(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.weekly:
        return 'Weekly';
      case ChallengeType.special:
        return 'Special';
    }
  }

  Color _getTypeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return const Color(0xFF10B981);
      case ChallengeType.weekly:
        return const Color(0xFF6366F1);
      case ChallengeType.special:
        return const Color(0xFFF59E0B);
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
        title: const Text('Manage Challenges'),
        actions: [
          // Seed button
          if (_isSeeding)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: AppColors.primary),
              tooltip: 'Seed Default Challenges',
              onPressed: _seedDefaultChallenges,
            ),
          // Refresh active challenges
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Active Selections',
            onPressed: () async {
              try {
                final provider = Provider.of<ChallengeProvider>(context, listen: false);
                await provider.forceRefreshActiveChallenges();
                _showSnackBar('Active challenge selections cleared');
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textMuted,
          tabs: _types.map((type) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getTypeEmoji(type)),
                  const SizedBox(width: 6),
                  Text(_getTypeName(type)),
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
                : _challenges.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChallenges,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                          itemCount: _challenges.length,
                          itemBuilder: (context, index) {
                            return _buildChallengeCard(_challenges[index], index);
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
        label: const Text('Add Challenge'),
      ),
    );
  }

  Widget _buildStats() {
    final activeCount = _challenges.where((c) => c.isActive).length;
    final categoryCount = _challenges.where((c) => c.categoryId != null).length;

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
          _buildStatItem('Total', _challenges.length.toString(), Icons.flag),
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
          Text(_getTypeEmoji(_currentType), style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No ${_getTypeName(_currentType).toLowerCase()} challenges yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Add challenges to the pool', style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 24),
          // Quick seed button in empty state
          ElevatedButton.icon(
            onPressed: _seedDefaultChallenges,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Seed Default Challenges'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeTemplate challenge, int index) {
    final typeColor = _getTypeColor(challenge.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: challenge.isActive ? context.borderColor : Colors.orange.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: challenge.isActive 
                  ? typeColor.withAlpha(30) 
                  : Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(challenge.emoji, style: const TextStyle(fontSize: 28))),
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
                        challenge.title, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15, 
                          color: challenge.isActive ? context.textPrimary : context.textMuted,
                        ),
                      ),
                    ),
                    if (!challenge.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(30), 
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Inactive', style: TextStyle(color: Colors.orange, fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(challenge.description, style: TextStyle(color: context.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildTag(_getTypeName(challenge.type), Icons.category, color: typeColor),
                    _buildTag('Target: ${challenge.targetValue}', Icons.flag),
                    _buildTag('+${challenge.xpReward} XP', Icons.star, color: AppColors.primary),
                    if (challenge.categoryId != null)
                      _buildTag(challenge.categoryName ?? 'Category', Icons.folder, color: Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: context.textMuted, size: 20), 
                onPressed: () => _showAddEditDialog(challenge),
              ),
              IconButton(
                icon: Icon(
                  challenge.isActive ? Icons.visibility : Icons.visibility_off, 
                  color: challenge.isActive ? AppColors.success : Colors.orange, 
                  size: 20,
                ),
                onPressed: () => _toggleActive(challenge),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20), 
                onPressed: () => _confirmDelete(challenge),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
  }

  Widget _buildTag(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? context.textMuted).withAlpha(20), 
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? context.textMuted),
          const SizedBox(width: 4),
          Text(
            text, 
            style: TextStyle(
              fontSize: 11, 
              color: color ?? context.textMuted, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ChallengeTemplate challenge) async {
    try {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      await provider.toggleChallengeActive(challenge.id, !challenge.isActive);
      _loadChallenges();
      _showSnackBar(challenge.isActive ? 'Challenge deactivated' : 'Challenge activated');
    } catch (e) {
      _showSnackBar('Error updating challenge', isError: true);
    }
  }

  Future<void> _confirmDelete(ChallengeTemplate challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        title: const Text('Delete Challenge?'),
        content: Text('Are you sure you want to delete "${challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red), 
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = Provider.of<ChallengeProvider>(context, listen: false);
        await provider.deleteChallenge(challenge.id);
        if (!mounted) return;
        _loadChallenges();
        _showSnackBar('Challenge deleted');
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Error deleting challenge', isError: true);
      }
    }
  }

  Future<void> _showAddEditDialog(ChallengeTemplate? challenge) async {
    final isEditing = challenge != null;

    final titleController = TextEditingController(text: challenge?.title ?? '');
    final descController = TextEditingController(text: challenge?.description ?? '');
    final targetController = TextEditingController(text: challenge?.targetValue.toString() ?? '1');
    final xpController = TextEditingController(text: challenge?.xpReward.toString() ?? '50');

    String selectedEmoji = challenge?.emoji ?? '🎯';
    ChallengeType selectedType = challenge?.type ?? _currentType;
    String selectedTrackingField = challenge?.trackingField ?? 'lessonsToday';
    String? selectedCategoryId = challenge?.categoryId;
    String? selectedCategoryName = challenge?.categoryName;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final requiresCategory = ChallengeTemplate.requiresCategory(selectedTrackingField);
          
          return AlertDialog(
            backgroundColor: context.bgCard,
            title: Text(isEditing ? 'Edit Challenge' : 'Add Challenge'),
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

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Challenge Title',
                        hintText: 'e.g., Lesson Streak',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Complete 3 lessons today',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Type dropdown
                    DropdownButtonFormField<ChallengeType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Challenge Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ChallengeType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Text(_getTypeEmoji(type)),
                            const SizedBox(width: 8),
                            Text(_getTypeName(type)),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 12),

                    // Tracking field dropdown
                    DropdownButtonFormField<String>(
                      value: selectedTrackingField,
                      decoration: InputDecoration(
                        labelText: 'What to Track',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ChallengeTemplate.trackingFieldOptions.map((opt) => DropdownMenuItem(
                        value: opt['value'], 
                        child: Text(opt['label']!, style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          selectedTrackingField = v!;
                          if (!ChallengeTemplate.requiresCategory(v)) {
                            selectedCategoryId = null;
                            selectedCategoryName = null;
                          }
                        });
                      },
                    ),
                    
                    // Category dropdown (shown only if tracking requires it)
                    if (requiresCategory) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
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
                            selectedCategoryId = v;
                            selectedCategoryName = cat['name'] as String;
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

                    // Target and XP
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Target Value',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: xpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'XP Reward',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || descController.text.isEmpty) {
                    _showSnackBar('Please fill all fields', isError: true);
                    return;
                  }
                  
                  if (requiresCategory && selectedCategoryId == null) {
                    _showSnackBar('Please select a lesson category', isError: true);
                    return;
                  }

                  final newChallenge = ChallengeTemplate(
                    id: challenge?.id ?? '',
                    title: titleController.text,
                    description: descController.text,
                    emoji: selectedEmoji,
                    type: selectedType,
                    targetValue: int.tryParse(targetController.text) ?? 1,
                    xpReward: int.tryParse(xpController.text) ?? 50,
                    trackingField: selectedTrackingField,
                    categoryId: requiresCategory ? selectedCategoryId : null,
                    categoryName: requiresCategory ? selectedCategoryName : null,
                    isActive: challenge?.isActive ?? true,
                    createdAt: challenge?.createdAt ?? DateTime.now(),
                  );

                  try {
                    final provider = Provider.of<ChallengeProvider>(context, listen: false);
                    if (isEditing) {
                      await provider.updateChallenge(newChallenge);
                    } else {
                      await provider.addChallenge(newChallenge);
                    }
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _loadChallenges();
                    _showSnackBar(isEditing ? 'Challenge updated' : 'Challenge added');
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackBar('Error saving challenge', isError: true);
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