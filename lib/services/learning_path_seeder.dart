import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Run this once to seed learning paths based on your existing lessons
/// Call: await LearningPathSeeder.seedLearningPaths();
class LearningPathSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Main method to seed all learning paths
  static Future<void> seedLearningPaths() async {
    debugPrint('🌱 Starting Learning Paths seeding...');

    try {
      // First, get all categories and their lessons
      final categories = await _getCategories();
      debugPrint('📂 Found ${categories.length} categories');

      if (categories.isEmpty) {
        debugPrint('❌ No categories found. Please add categories first.');
        return;
      }

      // Print category names for debugging
      for (var cat in categories) {
        debugPrint('   📁 ${cat['name']} (${(cat['lessons'] as List).length} lessons)');
      }

      // Create learning paths based on difficulty
      await _createBeginnerPath(categories);
      await _createIntermediatePath(categories);
      await _createAdvancedPath(categories);
      await _createQuickStartPath(categories);
      await _createDailyPracticePath(categories);

      debugPrint('✅ Learning Paths seeding complete!');
    } catch (e) {
      debugPrint('❌ Error seeding learning paths: $e');
    }
  }

  /// Get all categories with their lessons
  static Future<List<Map<String, dynamic>>> _getCategories() async {
    final snapshot = await _db.collection('categories')
        .where('isActive', isEqualTo: true)
        .get();
    
    List<Map<String, dynamic>> categoriesWithLessons = [];
    
    for (var doc in snapshot.docs) {
      final categoryData = doc.data();
      categoryData['id'] = doc.id;
      
      // Get lessons for this category
      final lessonsSnapshot = await _db
          .collection('lessons')
          .where('categoryId', isEqualTo: doc.id)
          .where('isActive', isEqualTo: true)
          .get();
      
      categoryData['lessons'] = lessonsSnapshot.docs.map((l) {
        final data = l.data();
        data['id'] = l.id;
        return data;
      }).toList();
      
      // Sort lessons by order
      (categoryData['lessons'] as List).sort((a, b) => 
        (a['order'] ?? 0).compareTo(b['order'] ?? 0)
      );
      
      categoriesWithLessons.add(categoryData);
    }
    
    // Sort categories by order
    categoriesWithLessons.sort((a, b) => 
      (a['order'] ?? 0).compareTo(b['order'] ?? 0)
    );
    
    return categoriesWithLessons;
  }

  /// Get lesson display name - uses signName field
  static String _getLessonName(Map<String, dynamic> lesson) {
    return lesson['signName'] ?? lesson['name'] ?? lesson['title'] ?? 'Unknown Sign';
  }

  /// Create Beginner Path - First categories (Alphabet, Numbers, etc.)
  static Future<void> _createBeginnerPath(List<Map<String, dynamic>> categories) async {
    debugPrint('📚 Creating Beginner Path...');

    List<Map<String, dynamic>> steps = [];
    int stepOrder = 0;
    int totalXP = 0;

    // Get first 2-3 categories for beginner path
    final beginnerCategories = categories.take(3);
    
    for (var category in beginnerCategories) {
      final lessons = (category['lessons'] as List).take(5); // First 5 lessons from each
      
      for (var lesson in lessons) {
        final lessonName = _getLessonName(lesson);
        steps.add({
          'id': 'step_$stepOrder',
          'title': lessonName,
          'description': 'Learn the sign for "$lessonName"',
          'type': 'lesson',
          'targetId': lesson['id'],
          'categoryId': category['id'],
          'xpReward': lesson['xpReward'] ?? 10,
          'order': stepOrder,
          'isRequired': true,
        });
        totalXP += (lesson['xpReward'] ?? 10) as int;
        stepOrder++;
      }
    }

    // Add a quiz at the end
    if (steps.isNotEmpty) {
      steps.add({
        'id': 'step_$stepOrder',
        'title': 'Beginner Quiz',
        'description': 'Test your knowledge of basic signs',
        'type': 'quiz',
        'targetId': 'sign_to_text',
        'xpReward': 50,
        'order': stepOrder,
        'isRequired': true,
      });
      totalXP += 50;
    }

    if (steps.length > 1) {
      await _createPath(
        name: 'MSL Foundations',
        description: 'Master the basics of Malaysian Sign Language. Learn essential signs to build a strong foundation for your signing journey.',
        iconEmoji: '🤟',
        difficulty: 'beginner',
        estimatedDays: 7,
        totalLessons: steps.length,
        totalXP: totalXP,
        steps: steps,
        order: 1,
      );
    }
  }

  /// Create Intermediate Path - Middle categories
  static Future<void> _createIntermediatePath(List<Map<String, dynamic>> categories) async {
    debugPrint('📚 Creating Intermediate Path...');

    List<Map<String, dynamic>> steps = [];
    int stepOrder = 0;
    int totalXP = 0;

    // Skip first 3, take next 3-4 categories
    final intermediateCategories = categories.skip(3).take(4);
    
    for (var category in intermediateCategories) {
      final lessons = (category['lessons'] as List).take(5);
      
      for (var lesson in lessons) {
        final lessonName = _getLessonName(lesson);
        steps.add({
          'id': 'step_$stepOrder',
          'title': lessonName,
          'description': 'Learn to sign "$lessonName"',
          'type': 'lesson',
          'targetId': lesson['id'],
          'categoryId': category['id'],
          'xpReward': lesson['xpReward'] ?? 15,
          'order': stepOrder,
          'isRequired': true,
        });
        totalXP += (lesson['xpReward'] ?? 15) as int;
        stepOrder++;
      }
    }

    // Add quiz
    if (steps.isNotEmpty) {
      steps.add({
        'id': 'step_$stepOrder',
        'title': 'Intermediate Assessment',
        'description': 'Test your vocabulary knowledge',
        'type': 'quiz',
        'targetId': 'text_to_sign',
        'xpReward': 75,
        'order': stepOrder,
        'isRequired': true,
      });
      totalXP += 75;
    }

    if (steps.length > 1) {
      await _createPath(
        name: 'Everyday Vocabulary',
        description: 'Expand your signing vocabulary with common words and phrases for daily conversations.',
        iconEmoji: '💬',
        difficulty: 'intermediate',
        estimatedDays: 14,
        totalLessons: steps.length,
        totalXP: totalXP,
        steps: steps,
        order: 2,
      );
    }
  }

  /// Create Advanced Path - Later categories
  static Future<void> _createAdvancedPath(List<Map<String, dynamic>> categories) async {
    debugPrint('📚 Creating Advanced Path...');

    List<Map<String, dynamic>> steps = [];
    int stepOrder = 0;
    int totalXP = 0;

    // Skip first 7, take remaining categories
    final advancedCategories = categories.skip(7).take(4);
    
    for (var category in advancedCategories) {
      final lessons = (category['lessons'] as List).take(6);
      
      for (var lesson in lessons) {
        final lessonName = _getLessonName(lesson);
        steps.add({
          'id': 'step_$stepOrder',
          'title': lessonName,
          'description': 'Master the sign for "$lessonName"',
          'type': 'lesson',
          'targetId': lesson['id'],
          'categoryId': category['id'],
          'xpReward': lesson['xpReward'] ?? 20,
          'order': stepOrder,
          'isRequired': true,
        });
        totalXP += (lesson['xpReward'] ?? 20) as int;
        stepOrder++;
      }
    }

    // Timed challenge
    if (steps.isNotEmpty) {
      steps.add({
        'id': 'step_$stepOrder',
        'title': 'Speed Challenge',
        'description': 'Test your skills under pressure',
        'type': 'quiz',
        'targetId': 'timed',
        'xpReward': 100,
        'order': stepOrder,
        'isRequired': true,
      });
      totalXP += 100;
    }

    if (steps.length > 1) {
      await _createPath(
        name: 'Fluent Signer',
        description: 'Take your signing to the next level with advanced vocabulary and challenging exercises.',
        iconEmoji: '🎓',
        difficulty: 'advanced',
        estimatedDays: 21,
        totalLessons: steps.length,
        totalXP: totalXP,
        steps: steps,
        order: 3,
      );
    }
  }

  /// Create Quick Start Path - Very short intro (first 5 lessons from first category)
  static Future<void> _createQuickStartPath(List<Map<String, dynamic>> categories) async {
    debugPrint('📚 Creating Quick Start Path...');

    List<Map<String, dynamic>> steps = [];
    int stepOrder = 0;
    int totalXP = 0;

    // Get first 5 lessons total
    for (var category in categories) {
      if (steps.length >= 5) break;
      
      final lessons = category['lessons'] as List;
      for (var lesson in lessons) {
        if (steps.length >= 5) break;
        
        final lessonName = _getLessonName(lesson);
        steps.add({
          'id': 'step_$stepOrder',
          'title': lessonName,
          'description': 'Learn your first sign: "$lessonName"',
          'type': 'lesson',
          'targetId': lesson['id'],
          'categoryId': category['id'],
          'xpReward': lesson['xpReward'] ?? 10,
          'order': stepOrder,
          'isRequired': true,
        });
        totalXP += (lesson['xpReward'] ?? 10) as int;
        stepOrder++;
      }
    }

    if (steps.isNotEmpty) {
      await _createPath(
        name: 'Quick Start',
        description: 'New to sign language? Start here! Learn 5 essential signs in just minutes.',
        iconEmoji: '⚡',
        difficulty: 'beginner',
        estimatedDays: 1,
        totalLessons: steps.length,
        totalXP: totalXP,
        steps: steps,
        order: 0, // First in list
      );
    }
  }

  /// Create Daily Practice Path - Mix from all categories
  static Future<void> _createDailyPracticePath(List<Map<String, dynamic>> categories) async {
    debugPrint('📚 Creating Daily Practice Path...');

    List<Map<String, dynamic>> steps = [];
    int stepOrder = 0;
    int totalXP = 0;

    // Get 2 lessons from each category (up to 5 categories)
    int categoriesUsed = 0;
    for (var category in categories) {
      if (categoriesUsed >= 5) break;
      
      final lessons = (category['lessons'] as List).take(2);
      for (var lesson in lessons) {
        final lessonName = _getLessonName(lesson);
        steps.add({
          'id': 'step_$stepOrder',
          'title': lessonName,
          'description': 'Practice: "$lessonName"',
          'type': 'lesson',
          'targetId': lesson['id'],
          'categoryId': category['id'],
          'xpReward': lesson['xpReward'] ?? 15,
          'order': stepOrder,
          'isRequired': true,
        });
        totalXP += (lesson['xpReward'] ?? 15) as int;
        stepOrder++;
      }
      categoriesUsed++;
    }

    // Add final quiz
    if (steps.isNotEmpty) {
      steps.add({
        'id': 'step_$stepOrder',
        'title': 'Practice Quiz',
        'description': 'Review what you learned',
        'type': 'quiz',
        'targetId': 'sign_to_text',
        'xpReward': 50,
        'order': stepOrder,
        'isRequired': true,
      });
      totalXP += 50;
    }

    if (steps.length > 1) {
      await _createPath(
        name: 'Daily Practice Mix',
        description: 'A varied practice session with signs from multiple categories. Perfect for keeping your skills sharp!',
        iconEmoji: '🔄',
        difficulty: 'intermediate',
        estimatedDays: 3,
        totalLessons: steps.length,
        totalXP: totalXP,
        steps: steps,
        order: 4,
      );
    }
  }

  /// Helper to create a path document
  static Future<void> _createPath({
    required String name,
    required String description,
    required String iconEmoji,
    required String difficulty,
    required int estimatedDays,
    required int totalLessons,
    required int totalXP,
    required List<Map<String, dynamic>> steps,
    required int order,
  }) async {
    // Check if path already exists
    final existing = await _db
        .collection('learningPaths')
        .where('name', isEqualTo: name)
        .get();
    
    if (existing.docs.isNotEmpty) {
      debugPrint('   ⏭️ Path "$name" already exists, skipping...');
      return;
    }

    await _db.collection('learningPaths').add({
      'name': name,
      'description': description,
      'iconEmoji': iconEmoji,
      'difficulty': difficulty,
      'estimatedDays': estimatedDays,
      'totalLessons': totalLessons,
      'totalXP': totalXP,
      'steps': steps,
      'isActive': true,
      'order': order,
      'createdAt': Timestamp.now(),
    });

    debugPrint('   ✅ Created: $name ($totalLessons steps, $totalXP XP)');
  }

  /// Delete all learning paths (for reset)
  static Future<void> deleteAllPaths() async {
    debugPrint('🗑️ Deleting all learning paths...');
    
    final snapshot = await _db.collection('learningPaths').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    
    // Also delete user progress
    final progressSnapshot = await _db.collection('userLearningProgress').get();
    for (var doc in progressSnapshot.docs) {
      await doc.reference.delete();
    }
    
    debugPrint('✅ All learning paths deleted');
  }
}