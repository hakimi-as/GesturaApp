import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';

class LessonProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CategoryModel> _categories = [];
  Map<String, List<LessonModel>> _lessonsByCategory = {};
  CategoryModel? _selectedCategory;
  LessonModel? _selectedLesson;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  Map<String, List<LessonModel>> get lessonsByCategory => _lessonsByCategory;
  CategoryModel? get selectedCategory => _selectedCategory;
  LessonModel? get selectedLesson => _selectedLesson;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load categories
  Future<void> loadCategories({bool forceRefresh = false}) async {
  // Skip if already loaded and not forcing refresh
  if (_categories.isNotEmpty && !forceRefresh) return;

  _isLoading = true;
  notifyListeners();

  try {
    _categories = await _firestoreService.getCategories();
  } catch (e) {
    debugPrint('Error loading categories: $e');
  }

  _isLoading = false;
  notifyListeners();
}

  // Load lessons for a category
  Future<void> loadLessons(String categoryId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final lessons = await _firestoreService.getLessonsByCategory(categoryId);
      _lessonsByCategory[categoryId] = lessons;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get lessons for a category
  List<LessonModel> getLessonsForCategory(String categoryId) {
    return _lessonsByCategory[categoryId] ?? [];
  }

  // Select category
  void selectCategory(CategoryModel category) {
    _selectedCategory = category;
    notifyListeners();
    loadLessons(category.id);
  }

  // Select lesson
  void selectLesson(LessonModel lesson) {
    _selectedLesson = lesson;
    notifyListeners();
  }

  // Clear selections
  void clearSelections() {
    _selectedCategory = null;
    _selectedLesson = null;
    notifyListeners();
  }

  // Seed data
  Future<void> seedData() async {
    try {
      await _firestoreService.seedInitialData();
      await loadCategories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}