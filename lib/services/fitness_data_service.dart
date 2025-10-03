import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FitnessData model for daily fitness metrics
class FitnessData {
  final String id;
  final String userId;
  final DateTime date;
  final int caloriesBurned;
  final int stepsCount;
  final int workoutsCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  FitnessData({
    required this.id,
    required this.userId,
    required this.date,
    required this.caloriesBurned,
    required this.stepsCount,
    required this.workoutsCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create FitnessData from Firestore document
  factory FitnessData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FitnessData(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      caloriesBurned: data['caloriesBurned'] ?? 0,
      stepsCount: data['stepsCount'] ?? 0,
      workoutsCompleted: data['workoutsCompleted'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert FitnessData to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'caloriesBurned': caloriesBurned,
      'stepsCount': stepsCount,
      'workoutsCompleted': workoutsCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated values
  FitnessData copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? caloriesBurned,
    int? stepsCount,
    int? workoutsCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FitnessData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      stepsCount: stepsCount ?? this.stepsCount,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service for managing fitness data in Firestore
class FitnessDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get today's fitness data document reference
  DocumentReference _getTodayDocRef() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fitnessData')
        .doc(dateKey);
  }

  /// Get today's fitness data as a stream
  Stream<FitnessData?> getTodayFitnessData() {
    return _getTodayDocRef().snapshots().map((doc) {
      if (doc.exists) {
        return FitnessData.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get today's fitness data (one-time fetch)
  Future<FitnessData?> getTodayFitnessDataOnce() async {
    final doc = await _getTodayDocRef().get();
    if (doc.exists) {
      return FitnessData.fromFirestore(doc);
    }
    return null;
  }

  /// Initialize today's fitness data if it doesn't exist
  Future<FitnessData> initializeTodayData() async {
    final existingData = await getTodayFitnessDataOnce();
    if (existingData != null) {
      return existingData;
    }

    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final newData = FitnessData(
      id: dateKey,
      userId: user.uid,
      date: today,
      caloriesBurned: 0,
      stepsCount: 0,
      workoutsCompleted: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _getTodayDocRef().set(newData.toFirestore());
    return newData;
  }

  /// Update today's fitness data
  Future<void> updateTodayData({
    int? caloriesBurned,
    int? stepsCount,
    int? workoutsCompleted,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (caloriesBurned != null) updates['caloriesBurned'] = caloriesBurned;
    if (stepsCount != null) updates['stepsCount'] = stepsCount;
    if (workoutsCompleted != null) updates['workoutsCompleted'] = workoutsCompleted;

    await _getTodayDocRef().update(updates);
  }

  /// Calculate today's calories from workouts
  Future<int> calculateTodayCalories() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final workouts = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // Simple calorie calculation: assume 100 calories per workout + duration-based calculation
    int totalCalories = 0;
    for (final doc in workouts.docs) {
      final data = doc.data();
      final duration = data['duration'] as int? ?? 0;
      final sets = data['sets'] as int? ?? 0;
      final reps = data['reps'] as int? ?? 0;

      // Rough estimate: base 50 calories + 5 calories per minute + 10 calories per set
      totalCalories += 50 + (duration * 5) + (sets * 10);
    }

    return totalCalories;
  }

  /// Get today's workout count
  Future<int> getTodayWorkoutCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final workouts = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return workouts.docs.length;
  }

  /// Sync today's data with calculated values
  Future<void> syncTodayData() async {
    final calories = await calculateTodayCalories();
    final workoutCount = await getTodayWorkoutCount();

    // For now, steps are mocked - in a real app, this would come from health APIs
    final steps = await _getMockStepsForToday();

    await updateTodayData(
      caloriesBurned: calories,
      workoutsCompleted: workoutCount,
      stepsCount: steps,
    );
  }

  /// Mock steps data - replace with actual health API integration
  Future<int> _getMockStepsForToday() async {
    // Mock implementation - in production, integrate with health APIs
    // For now, return a random number between 5000-15000
    final now = DateTime.now();
    final seed = now.day + now.month + now.year;
    return 5000 + (seed % 10000); // Deterministic "random" based on date
  }

  /// Get weekly fitness data for charts
  Future<List<FitnessData>> getWeeklyData() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final query = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fitnessData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .orderBy('date', descending: false)
        .get();

    return query.docs.map((doc) => FitnessData.fromFirestore(doc)).toList();
  }
}