/// Exercise model for ExerciseDB API integration
class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String targetMuscle;
  final String equipment;
  final String gifUrl;
  final List<String> aiTags;

  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.targetMuscle,
    required this.equipment,
    required this.gifUrl,
    this.aiTags = const [],
  });

  // Create from ExerciseDB API response
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bodyPart: json['bodyPart'] ?? '',
      targetMuscle: json['target'] ?? '',
      equipment: json['equipment'] ?? '',
      gifUrl: json['gifUrl'] ?? '',
      aiTags: List<String>.from(json['aiTags'] ?? []),
    );
  }

  // Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'targetMuscle': targetMuscle,
      'equipment': equipment,
      'gifUrl': gifUrl,
      'aiTags': aiTags,
    };
  }

  // Create from cached JSON
  factory Exercise.fromCache(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bodyPart: json['bodyPart'] ?? '',
      targetMuscle: json['targetMuscle'] ?? '',
      equipment: json['equipment'] ?? '',
      gifUrl: json['gifUrl'] ?? '',
      aiTags: List<String>.from(json['aiTags'] ?? []),
    );
  }

  // Get display name (capitalize first letter of each word)
  String get displayName {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Get formatted body part for display
  String get bodyPartDisplay {
    return bodyPart.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Get formatted target muscle for display
  String get targetDisplay {
    return targetMuscle.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Get formatted equipment for display
  String get equipmentDisplay {
    return equipment.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Get all muscles worked (primary + aiTags)
  List<String> get allMuscles => [targetMuscle, ...aiTags];

  // Check if exercise matches search query
  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
            bodyPart.toLowerCase().contains(lowerQuery) ||
            targetMuscle.toLowerCase().contains(lowerQuery) ||
            equipment.toLowerCase().contains(lowerQuery) ||
            aiTags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  // Check if exercise matches filters
  bool matchesFilters({String? bodyPartFilter, String? equipmentFilter}) {
    if (bodyPartFilter != null && bodyPartFilter != 'all' && bodyPart != bodyPartFilter) {
      return false;
    }
    if (equipmentFilter != null && equipmentFilter != 'all' && equipment != equipmentFilter) {
      return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, bodyPart: $bodyPart, targetMuscle: $targetMuscle, equipment: $equipment)';
  }
}