import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart'; // Import for HeartRateZone, GPSRoute

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

  // Wearable integration fields
  final List<HeartRatePoint>? heartRateData; // Heart rate throughout workout
  final List<HeartRateZone>? heartRateZones; // Time spent in each zone
  final double? averageHeartRate; // Average HR during workout
  final double? maxHeartRate; // Peak HR during workout
  final GPSRoute? route; // GPS route for outdoor activities
  final String? deviceSource; // 'manual', 'healthkit', 'fitbit', 'garmin', etc.
  final double? caloriesBurned; // Calories burned during workout (from wearable)

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
    this.heartRateData,
    this.heartRateZones,
    this.averageHeartRate,
    this.maxHeartRate,
    this.route,
    this.deviceSource = 'manual',
    this.caloriesBurned,
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
      // Wearable data fields
      heartRateData: (data['heartRateData'] as List<dynamic>?)
          ?.map((point) => HeartRatePoint.fromFirestore(point))
          .toList(),
      heartRateZones: (data['heartRateZones'] as List<dynamic>?)
          ?.map((zone) => HeartRateZone.fromFirestore(zone))
          .toList(),
      averageHeartRate: data['averageHeartRate']?.toDouble(),
      maxHeartRate: data['maxHeartRate']?.toDouble(),
      route: data['route'] != null ? GPSRoute.fromFirestore(data['route']) : null,
      deviceSource: data['deviceSource'] ?? 'manual',
      caloriesBurned: data['caloriesBurned']?.toDouble(),
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
      // Wearable data fields
      'heartRateData': heartRateData?.map((point) => point.toFirestore()).toList(),
      'heartRateZones': heartRateZones?.map((zone) => zone.toFirestore()).toList(),
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'route': route?.toFirestore(),
      'deviceSource': deviceSource,
      'caloriesBurned': caloriesBurned,
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
    List<HeartRatePoint>? heartRateData,
    List<HeartRateZone>? heartRateZones,
    double? averageHeartRate,
    double? maxHeartRate,
    GPSRoute? route,
    String? deviceSource,
    double? caloriesBurned,
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
      heartRateData: heartRateData ?? this.heartRateData,
      heartRateZones: heartRateZones ?? this.heartRateZones,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      route: route ?? this.route,
      deviceSource: deviceSource ?? this.deviceSource,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}