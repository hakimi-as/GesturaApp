import 'dart:typed_data';
import '../models/category_model.dart';
import '../models/lesson_model.dart';

/// In-memory cache shared across the app session.
/// Eliminates redundant Firestore reads for hot-path data.
class AppCache {
  AppCache._();
  static final AppCache instance = AppCache._();

  // ── Categories ───────────────────────────────────────────────────────────
  List<CategoryModel>? _categories;
  DateTime? _categoriesLoadedAt;
  static const _categoryTtl = Duration(minutes: 10);

  List<CategoryModel>? get categories {
    if (_categories == null) return null;
    if (DateTime.now().difference(_categoriesLoadedAt!) > _categoryTtl) return null;
    return _categories;
  }

  void setCategories(List<CategoryModel> cats) {
    _categories = cats;
    _categoriesLoadedAt = DateTime.now();
  }

  // ── Lessons per category ──────────────────────────────────────────────────
  final Map<String, List<LessonModel>> _lessonsByCategory = {};
  final Map<String, DateTime> _lessonsLoadedAt = {};
  static const _lessonTtl = Duration(minutes: 10);

  List<LessonModel>? lessons(String categoryId) {
    final loaded = _lessonsLoadedAt[categoryId];
    if (loaded == null) return null;
    if (DateTime.now().difference(loaded) > _lessonTtl) return null;
    return _lessonsByCategory[categoryId];
  }

  void setLessons(String categoryId, List<LessonModel> lessons) {
    _lessonsByCategory[categoryId] = lessons;
    _lessonsLoadedAt[categoryId] = DateTime.now();
  }

  // ── Completed lesson IDs per user ────────────────────────────────────────
  Set<String>? _completedLessonIds;
  String? _completedForUserId;
  DateTime? _completedLoadedAt;
  static const _completedTtl = Duration(seconds: 60);

  Set<String>? completedIds(String userId) {
    if (_completedForUserId != userId) return null;
    if (_completedLoadedAt == null) return null;
    if (DateTime.now().difference(_completedLoadedAt!) > _completedTtl) return null;
    return _completedLessonIds;
  }

  void setCompletedIds(String userId, Set<String> ids) {
    _completedLessonIds = ids;
    _completedForUserId = userId;
    _completedLoadedAt = DateTime.now();
  }

  void invalidateCompleted() {
    _completedLessonIds = null;
    _completedLoadedAt = null;
  }

  // ── Profile image bytes ───────────────────────────────────────────────────
  Uint8List? _profileImageBytes;
  String? _profileImageUserId;

  Uint8List? getProfileImage(String userId) {
    if (_profileImageUserId != userId) return null;
    return _profileImageBytes;
  }

  void setProfileImage(String userId, Uint8List bytes) {
    _profileImageBytes = bytes;
    _profileImageUserId = userId;
  }

  // ── Badge pool seeded flag (session-level) ────────────────────────────────
  bool badgePoolSeeded = false;

  // ── Full clear (on logout) ────────────────────────────────────────────────
  void clear() {
    _categories = null;
    _categoriesLoadedAt = null;
    _lessonsByCategory.clear();
    _lessonsLoadedAt.clear();
    _completedLessonIds = null;
    _completedForUserId = null;
    _completedLoadedAt = null;
    _profileImageBytes = null;
    _profileImageUserId = null;
    badgePoolSeeded = false;
  }
}
