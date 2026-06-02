import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';

/// Hive-backed disk cache. Survives app restarts.
/// Key/value store — values are JSON strings to avoid Hive adapters.
/// NOTE: Hive.initFlutter() is called by OfflineService.initialize() before
/// this is initialised, so we only need to open the box here.
class PersistentCache {
  PersistentCache._();
  static final PersistentCache instance = PersistentCache._();

  static const _boxName = 'gestura_cache';
  static const _keyCategories = 'categories_v1';
  static const _keyLessonsPrefix = 'lessons_v1_';
  static const _keyBadgePool = 'badge_pool_v1';
  static const _ttlHours = 24;

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  bool _isFresh(String tsKey) {
    final ts = _box.get('${tsKey}_ts') as int?;
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < _ttlHours * 3600 * 1000;
  }

  void _setTs(String key) =>
      _box.put('${key}_ts', DateTime.now().millisecondsSinceEpoch);

  List<CategoryModel>? getCategories() {
    if (!_isFresh(_keyCategories)) return null;
    final raw = _box.get(_keyCategories) as String?;
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(CategoryModel.fromJson).toList();
  }

  Future<void> setCategories(List<CategoryModel> cats) async {
    await _box.put(_keyCategories, jsonEncode(cats.map((c) => c.toJson()).toList()));
    _setTs(_keyCategories);
  }

  List<LessonModel>? getLessons(String categoryId) {
    final key = '$_keyLessonsPrefix$categoryId';
    if (!_isFresh(key)) return null;
    final raw = _box.get(key) as String?;
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(LessonModel.fromJson).toList();
  }

  Future<void> setLessons(String categoryId, List<LessonModel> lessons) async {
    final key = '$_keyLessonsPrefix$categoryId';
    await _box.put(key, jsonEncode(lessons.map((l) => l.toJson()).toList()));
    _setTs(key);
  }

  List<Map<String, dynamic>>? getBadgePool() {
    if (!_isFresh(_keyBadgePool)) return null;
    final raw = _box.get(_keyBadgePool) as String?;
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setBadgePool(List<Map<String, dynamic>> pool) async {
    await _box.put(_keyBadgePool, jsonEncode(pool));
    _setTs(_keyBadgePool);
  }

  Future<void> clear() => _box.clear();
}
