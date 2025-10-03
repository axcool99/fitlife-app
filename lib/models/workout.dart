import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String userId;
  final String exerciseName;
  final int sets;
  final int reps;
  final int? duration; // in seconds
  final double? weight; // in kg or lbs
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Workout({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.duration,
    this.weight,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore document
  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      sets: data['sets'] ?? 0,
      reps: data['reps'] ?? 0,
      duration: data['duration'],
      weight: data['weight']?.toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'weight': weight,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create copy with updated fields
  Workout copyWith({
    String? id,
    String? userId,
    String? exerciseName,
    int? sets,
    int? reps,
    int? duration,
    double? weight,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}