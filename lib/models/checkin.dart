import 'package:cloud_firestore/cloud_firestore.dart';

/// CheckIn model for daily wellness tracking
class CheckIn {
  final String id;
  final String userId;
  final DateTime date;
  final double weight; // in kg
  final String mood; // "Good", "Okay", "Bad"
  final int energyLevel; // 1-5 scale
  final String? notes;

  CheckIn({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.mood,
    required this.energyLevel,
    this.notes,
  });

  // Mood options for the dropdown
  static const List<String> moodOptions = ['Good', 'Okay', 'Bad'];

  // Energy level labels
  static String getEnergyLabel(int level) {
    switch (level) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Moderate';
      case 4: return 'High';
      case 5: return 'Very High';
      default: return 'Unknown';
    }
  }

  // Create from Firestore document
  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckIn(
      id: doc.id,
      userId: data['userId'] ?? '',
      // Use 'timestamp' field if available, otherwise fall back to 'date'
      // This provides migration support for existing data without 'timestamp'
      date: (data['timestamp'] as Timestamp?)?.toDate() ??
            (data['date'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      mood: data['mood'] ?? 'Okay',
      energyLevel: data['energyLevel'] ?? 3,
      notes: data['notes'],
    );
  }

  // Create from map (for cache deserialization)
  factory CheckIn.fromMap(Map<String, dynamic> data, String id) {
    return CheckIn(
      id: id,
      userId: data['userId'] ?? '',
      // Use 'timestamp' field if available, otherwise fall back to 'date'
      date: (data['timestamp'] as Timestamp?)?.toDate() ??
            (data['date'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      mood: data['mood'] ?? 'Okay',
      energyLevel: data['energyLevel'] ?? 3,
      notes: data['notes'],
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      // Store both 'timestamp' (new) and 'date' (legacy) for backward compatibility
      'timestamp': Timestamp.fromDate(date),
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'mood': mood,
      'energyLevel': energyLevel,
      'notes': notes,
    };
  }

  // Create a copy with updated fields
  CheckIn copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    String? mood,
    int? energyLevel,
    String? notes,
  }) {
    return CheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
      notes: notes ?? this.notes,
    );
  }
}