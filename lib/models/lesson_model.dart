import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String categoryId;
  final String signName;
  final String description;
  final String emoji;
  final String? imageUrl;
  final String? videoUrl;
  final String? animation3DUrl;
  final List<String> tips;
  final String difficulty;
  final int order;
  final int xpReward;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonModel({
    required this.id,
    required this.categoryId,
    required this.signName,
    required this.description,
    required this.emoji,
    this.imageUrl,
    this.videoUrl,
    this.animation3DUrl,
    this.tips = const [],
    required this.difficulty,
    this.order = 0,
    this.xpReward = 10,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      signName: data['signName'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '🤟',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      animation3DUrl: data['animation3DUrl'],
      tips: List<String>.from(data['tips'] ?? []),
      difficulty: data['difficulty'] ?? 'beginner',
      order: data['order'] ?? 0,
      xpReward: data['xpReward'] ?? 10,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'signName': signName,
      'description': description,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'animation3DUrl': animation3DUrl,
      'tips': tips,
      'difficulty': difficulty,
      'order': order,
      'xpReward': xpReward,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LessonModel copyWith({
    String? id,
    String? categoryId,
    String? signName,
    String? description,
    String? emoji,
    String? imageUrl,
    String? videoUrl,
    String? animation3DUrl,
    List<String>? tips,
    String? difficulty,
    int? order,
    int? xpReward,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      signName: signName ?? this.signName,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      animation3DUrl: animation3DUrl ?? this.animation3DUrl,
      tips: tips ?? this.tips,
      difficulty: difficulty ?? this.difficulty,
      order: order ?? this.order,
      xpReward: xpReward ?? this.xpReward,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Sample alphabet lessons
  static List<LessonModel> get alphabetLessons {
    final now = DateTime.now();
    final letters = [
      {'sign': 'A', 'emoji': '✊', 'desc': 'Fist with thumb at side'},
      {'sign': 'B', 'emoji': '🖐️', 'desc': 'Flat hand, thumb tucked'},
      {'sign': 'C', 'emoji': '🤏', 'desc': 'Curved like holding ball'},
      {'sign': 'D', 'emoji': '☝️', 'desc': 'Index up, others touch thumb'},
      {'sign': 'E', 'emoji': '✊', 'desc': 'Fingers curled, thumb across'},
      {'sign': 'F', 'emoji': '👌', 'desc': 'Thumb and index touch'},
    ];

    return letters.asMap().entries.map((entry) {
      return LessonModel(
        id: 'alphabet_${entry.value['sign']!.toLowerCase()}',
        categoryId: 'alphabet',
        signName: entry.value['sign']!,
        description: entry.value['desc']!,
        emoji: entry.value['emoji']!,
        tips: [
          'Keep hand at chest level',
          'Palm faces forward',
          'Practice with a mirror',
        ],
        difficulty: 'beginner',
        order: entry.key + 1,
        xpReward: 10,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  // Sample greetings lessons
  static List<LessonModel> get greetingsLessons {
    final now = DateTime.now();
    final greetings = [
      {'sign': 'Hello', 'emoji': '👋', 'desc': 'Wave near head'},
      {'sign': 'Goodbye', 'emoji': '👋', 'desc': 'Wave away'},
      {'sign': 'Thank You', 'emoji': '🙏', 'desc': 'Touch chin forward'},
      {'sign': 'Please', 'emoji': '🤲', 'desc': 'Circle on chest'},
      {'sign': 'Sorry', 'emoji': '😔', 'desc': 'Fist circles on chest'},
      {'sign': 'Help', 'emoji': '🆘', 'desc': 'Thumbs up on palm, lift'},
    ];

    return greetings.asMap().entries.map((entry) {
      return LessonModel(
        id: 'greetings_${entry.value['sign']!.toLowerCase().replaceAll(' ', '_')}',
        categoryId: 'greetings',
        signName: entry.value['sign']!,
        description: entry.value['desc']!,
        emoji: entry.value['emoji']!,
        tips: [
          'Maintain eye contact',
          'Use appropriate facial expression',
          'Practice the motion slowly',
        ],
        difficulty: 'beginner',
        order: entry.key + 1,
        xpReward: 10,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }
}