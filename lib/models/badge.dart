import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeCategory {
  streak,
  workouts,
  strength,
  consistency,
  achievement,
}

class Badge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final DateTime earnedAt;
  final BadgeCategory category;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.earnedAt,
    required this.category,
  });

  // Create from Firestore document
  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Badge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'emoji_events',
      color: data['color'] ?? '#FFD700',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: BadgeCategory.values.firstWhere(
        (e) => e.toString() == 'BadgeCategory.${data['category']}',
        orElse: () => BadgeCategory.achievement,
      ),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'category': category.toString().split('.').last,
    };
  }

  // Get category display name
  String get categoryName {
    switch (category) {
      case BadgeCategory.streak:
        return 'Streak';
      case BadgeCategory.workouts:
        return 'Workouts';
      case BadgeCategory.strength:
        return 'Strength';
      case BadgeCategory.consistency:
        return 'Consistency';
      case BadgeCategory.achievement:
        return 'Achievement';
    }
  }

  // Get color value for UI
  int get colorValue {
    final hex = color.replaceAll('#', '');
    return int.parse(hex, radix: 16);
  }

  // Alias for title to maintain compatibility
  String get name => title;
}