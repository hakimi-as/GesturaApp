import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String? imageUrl;  // Custom image for category icon
  final int lessonCount;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? difficulty;
  final String? signLanguage;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.lessonCount = 0,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.difficulty,
    this.signLanguage,
  });

  /// Check if category has a custom image
  bool get hasCustomImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '📚',
      imageUrl: data['imageUrl'],
      lessonCount: data['lessonCount'] ?? 0,
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      difficulty: data['difficulty'],
      signLanguage: data['signLanguage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'imageUrl': imageUrl,
      'lessonCount': lessonCount,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'difficulty': difficulty,
      'signLanguage': signLanguage,
    };
  }

  double getProgressPercentage(int completedLessons) {
    if (lessonCount == 0) return 0;
    return (completedLessons / lessonCount) * 100;
  }

  static List<CategoryModel> get defaultCategories {
    return [
      CategoryModel(
        id: 'alphabet',
        name: 'Alphabet',
        description: 'Learn the ASL alphabet',
        icon: '🔤',
        lessonCount: 26,
        order: 0,
        isActive: true,
      ),
      CategoryModel(
        id: 'numbers',
        name: 'Numbers',
        description: 'Learn to sign numbers',
        icon: '🔢',
        lessonCount: 10,
        order: 1,
        isActive: true,
      ),
      CategoryModel(
        id: 'greetings',
        name: 'Greetings',
        description: 'Common greeting signs',
        icon: '👋',
        lessonCount: 8,
        order: 2,
        isActive: true,
      ),
      CategoryModel(
        id: 'family',
        name: 'Family',
        description: 'Family member signs',
        icon: '👨‍👩‍👧‍👦',
        lessonCount: 12,
        order: 3,
        isActive: true,
      ),
      CategoryModel(
        id: 'colors',
        name: 'Colors',
        description: 'Learn color signs',
        icon: '🎨',
        lessonCount: 10,
        order: 4,
        isActive: true,
      ),
      CategoryModel(
        id: 'food',
        name: 'Food & Drinks',
        description: 'Food related signs',
        icon: '🍎',
        lessonCount: 15,
        order: 5,
        isActive: true,
      ),
      CategoryModel(
        id: 'animals',
        name: 'Animals',
        description: 'Animal signs',
        icon: '🐾',
        lessonCount: 12,
        order: 6,
        isActive: true,
      ),
      CategoryModel(
        id: 'common',
        name: 'Common Phrases',
        description: 'Everyday phrases',
        icon: '💬',
        lessonCount: 20,
        order: 7,
        isActive: true,
      ),
    ];
  }
}