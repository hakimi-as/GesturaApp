import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../models/lesson_model.dart';
import '../../models/category_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../learn/lesson_detail_screen.dart';
import '../learn/category_lessons_screen.dart';
import '../../widgets/common/glass_ui.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();

  String _searchQuery = '';
  String _selectedFilter = 'all';

  List<LessonModel> _allLessons = [];
  List<CategoryModel> _allCategories = [];
  Map<String, CategoryModel> _categoryMap = {};

  List<LessonModel> _lessonResults = [];
  List<CategoryModel> _categoryResults = [];

  bool _isLoading = true;
  bool _isSearching = false;

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadAllData();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _firestoreService.getCategories();
      final lessons = await _firestoreService.getAllLessons();

      final categoryMap = <String, CategoryModel>{};
      for (var cat in categories) {
        categoryMap[cat.id] = cat;
      }

      if (mounted) {
        setState(() {
          _allCategories = categories;
          _allLessons = lessons;
          _categoryMap = categoryMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading search data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recentSearches') ?? [];
      if (mounted) {
        setState(() => _recentSearches = searches);
      }
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      _recentSearches.remove(query);
      _recentSearches.insert(0, query);

      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }

      await prefs.setStringList('recentSearches', _recentSearches);
      setState(() {});
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recentSearches');
      setState(() => _recentSearches = []);
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _lessonResults = [];
        _categoryResults = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase().trim();

    final lessonResults = _allLessons.where((lesson) {
      final nameMatch = lesson.signName.toLowerCase().contains(lowerQuery);
      final descMatch = lesson.description.toLowerCase().contains(lowerQuery);
      return nameMatch || descMatch;
    }).toList();

    final categoryResults = _allCategories.where((category) {
      final nameMatch = category.name.toLowerCase().contains(lowerQuery);
      final descMatch = category.description.toLowerCase().contains(lowerQuery);
      return nameMatch || descMatch;
    }).toList();

    setState(() {
      _lessonResults = lessonResults;
      _categoryResults = categoryResults;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
    _focusNode.requestFocus();
  }

  void _onLessonTap(LessonModel lesson) {
    _saveRecentSearch(lesson.signName);

    final category = _categoryMap[lesson.categoryId];
    if (category == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(
          lesson: lesson,
          category: category,
        ),
      ),
    );
  }

  void _onCategoryTap(CategoryModel category) {
    _saveRecentSearch(category.name);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryLessonsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_isSearching && !_isLoading) _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _isSearching
                      ? _buildSearchResults()
                      : _buildSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: AppColors.primary,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 8),
          Text(
            'Search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
          ),
          const Spacer(),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.textMuted,
              ),
            )
          else
            Text(
              '${_allLessons.length} lessons',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 12,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassTextField(
        controller: _searchController,
        hint: 'Search for any sign... (e.g. "cat", "hello")',
        prefixIcon: Icons.search_rounded,
        suffixWidget: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color: context.textMuted),
                onPressed: _clearSearch,
              )
            : null,
        onFieldSubmitted: (query) {
          if (query.isNotEmpty) {
            _saveRecentSearch(query);
          }
        },
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFilterChips() {
    final lessonCount = _lessonResults.length;
    final categoryCount = _categoryResults.length;

    final filters = [
      {'id': 'all', 'label': 'All (${lessonCount + categoryCount})'},
      {'id': 'lessons', 'label': 'Signs ($lessonCount)'},
      {'id': 'categories', 'label': 'Categories ($categoryCount)'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GlassChip(
              label: filter['label']!,
              active: isSelected,
              onTap: () => setState(() => _selectedFilter = filter['id']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults() {
    final showLessons = _selectedFilter == 'all' || _selectedFilter == 'lessons';
    final showCategories =
        _selectedFilter == 'all' || _selectedFilter == 'categories';

    final hasResults = (showLessons && _lessonResults.isNotEmpty) ||
        (showCategories && _categoryResults.isNotEmpty);

    if (!hasResults) {
      return GlassEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results for "$_searchQuery"',
        subtitle: 'Try a different search term',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Categories section
        if (showCategories && _categoryResults.isNotEmpty) ...[
          GlassSectionHeader(
            title: 'Categories (${_categoryResults.length})',
            trailing: Icon(Icons.folder_open_rounded,
                color: context.textMuted, size: 16),
          ),
          const SizedBox(height: 12),
          ..._categoryResults.map((category) => _buildCategoryResult(category)),
          const SizedBox(height: 20),
        ],

        // Lessons section
        if (showLessons && _lessonResults.isNotEmpty) ...[
          GlassSectionHeader(
            title: 'Signs (${_lessonResults.length})',
            trailing: Icon(Icons.sign_language_rounded,
                color: context.textMuted, size: 16),
          ),
          const SizedBox(height: 12),
          ..._lessonResults.map((lesson) => _buildLessonResult(lesson)),
        ],
      ],
    );
  }

  Widget _buildCategoryResult(CategoryModel category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassTile(
        onTap: () => _onCategoryTap(category),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: category.hasCustomImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    CloudinaryService.getOptimizedImage(category.imageUrl!, width: 96),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.category_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                  ),
                )
              : Center(
                  child: Icon(Icons.category_rounded,
                      color: AppColors.primary, size: 24),
                ),
        ),
        title: Text(category.name,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text('${category.lessonCount} lessons'),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: context.textMuted, size: 16),
      ),
    );
  }

  Widget _buildLessonResult(LessonModel lesson) {
    final category = _categoryMap[lesson.categoryId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassTile(
        onTap: () => _onLessonTap(lesson),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColorsDark.bgElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: lesson.imageUrl != null && lesson.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    CloudinaryService.getOptimizedImage(lesson.imageUrl!, width: 112),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        lesson.signName.isNotEmpty
                            ? lesson.signName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    lesson.signName.isNotEmpty
                        ? lesson.signName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.textMuted,
                    ),
                  ),
                ),
        ),
        title: _buildHighlightedText(lesson.signName, _searchQuery),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category != null)
              Row(
                children: [
                  Icon(Icons.folder_rounded,
                      color: context.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                        color: context.textMuted, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${lesson.xpReward} XP',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(lesson.difficulty)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lesson.difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(lesson.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: context.textMuted, size: 16),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      );
    }

    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: context.textPrimary,
        ),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.25),
              color: AppColors.primary,
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            GlassSectionHeader(
              title: 'Recent Searches',
              trailing: TextButton(
                onPressed: _clearRecentSearches,
                child: Text(
                  'Clear',
                  style: TextStyle(color: context.textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recentSearches.map((query) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            color: context.textMuted, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          query,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 28),
          ],

          // All Categories
          const GlassSectionHeader(title: 'All Categories'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _allCategories.length,
            itemBuilder: (context, index) {
              final category = _allCategories[index];
              return GestureDetector(
                onTap: () => _onCategoryTap(category),
                child: GlassCard(
                  alternate: index.isOdd,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: category.hasCustomImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  CloudinaryService.getOptimizedImage(
                                      category.imageUrl!, width: 88),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.category_rounded,
                                        color: AppColors.primary, size: 22),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.category_rounded,
                                    color: AppColors.primary, size: 22),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: context.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 30 * index));
            },
          ),

          const SizedBox(height: 28),

          // Quick tip
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Type any word to instantly search through ${_allLessons.length} signs!',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
