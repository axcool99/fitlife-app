import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import 'fitness_data_service.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FitnessDataService _fitnessDataService = FitnessDataService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference for workouts
  CollectionReference get _workoutsCollection {
    if (currentUserId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(currentUserId).collection('workouts');
  }

  // Get workouts for current user
  Stream<List<Workout>> getWorkouts() {
    if (currentUserId == null) return Stream.value([]);

    return _workoutsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList());
  }

  // Add new workout
  Future<void> addWorkout({
    required String exerciseName,
    required int sets,
    required int reps,
    int? duration,
    double? weight,
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final workout = Workout(
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      duration: duration,
      weight: weight,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _workoutsCollection.add(workout.toFirestore());

    // Sync fitness data after adding workout
    await _fitnessDataService.syncTodayData();
  }

  // Update existing workout
  Future<void> updateWorkout(Workout workout) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _workoutsCollection
        .doc(workout.id)
        .update(workout.copyWith(updatedAt: DateTime.now()).toFirestore());

    // Sync fitness data after updating workout
    await _fitnessDataService.syncTodayData();
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _workoutsCollection.doc(workoutId).delete();

    // Sync fitness data after deleting workout
    await _fitnessDataService.syncTodayData();
  }

  // Get workouts for today
  Stream<List<Workout>> getTodaysWorkouts() {
    if (currentUserId == null) return Stream.value([]);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _workoutsCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList());
  }
}