import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import 'fitness_data_service.dart';
import 'cache_service.dart';
import 'stream_transformers.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FitnessDataService _fitnessDataService;
  final CacheService _cacheService;

  WorkoutService(this._cacheService, this._fitnessDataService);

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference for workouts
  CollectionReference get _workoutsCollection {
    if (currentUserId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(currentUserId).collection('workouts');
  }

  // Get workouts for current user (with offline support)
  Stream<List<Workout>> getWorkouts() {
    if (currentUserId == null) return Stream.value([]);

    return _workoutsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final workouts = snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();

          // Cache the workouts for offline use
          try {
            await _cacheService.saveWorkouts(workouts);
          } catch (e) {
            print('Warning: Failed to cache workouts: $e');
          }

          return workouts;
        })
        .transform(StreamTransformers.fallbackToCache<List<Workout>>(() => _cacheService.loadWorkouts()));
  }

  // Add new workout (with offline support)
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
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID for offline
      userId: currentUserId!,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      duration: duration,
      weight: weight,
      notes: notes,
      createdAt: DateTime.now(),
    );

    try {
      // Try to save to Firestore first
      final docRef = await _workoutsCollection.add(workout.toFirestore());
      // Update with Firestore-generated ID
      final firestoreWorkout = workout.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Cache the workout
      await _cacheService.saveWorkout(firestoreWorkout);

      // Sync fitness data after adding workout
      await _fitnessDataService.syncTodayData();
    } catch (e) {
      print('Failed to save to Firestore, saving to cache: $e');
      // Save to cache for offline sync later
      await _cacheService.saveWorkout(workout);
      // Note: Fitness data sync will happen when back online
    }
  }

  // Update existing workout (with offline support)
  Future<void> updateWorkout(Workout workout) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final updatedWorkout = workout.copyWith(updatedAt: DateTime.now());

    try {
      // Try to update in Firestore
      await _workoutsCollection
          .doc(workout.id)
          .update(updatedWorkout.toFirestore());

      // Update cache
      await _cacheService.saveWorkout(updatedWorkout);

      // Sync fitness data after updating workout
      await _fitnessDataService.syncTodayData();
    } catch (e) {
      print('Failed to update in Firestore, updating cache: $e');
      // Update in cache for offline sync later
      await _cacheService.saveWorkout(updatedWorkout);
    }
  }

  // Delete workout (with offline support)
  Future<void> deleteWorkout(String workoutId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Try to delete from Firestore
      await _workoutsCollection.doc(workoutId).delete();

      // Remove from cache
      await _cacheService.removeWorkout(workoutId);

      // Sync fitness data after deleting workout
      await _fitnessDataService.syncTodayData();
    } catch (e) {
      print('Failed to delete from Firestore, marking for deletion in cache: $e');
      // For offline deletion, we could mark the workout as deleted in cache
      // For simplicity, we'll just remove it from cache
      await _cacheService.removeWorkout(workoutId);
    }
  }

  // Get workouts for today (with offline support)
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
        .asyncMap((snapshot) async {
          final todaysWorkouts = snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();

          // Cache today's workouts (this will be part of the full workouts cache)
          try {
            final allWorkouts = await _cacheService.loadWorkouts();
            final updatedWorkouts = allWorkouts.where((w) =>
              !todaysWorkouts.any((tw) => tw.id == w.id)).toList() + todaysWorkouts;
            await _cacheService.saveWorkouts(updatedWorkouts);
          } catch (e) {
            print('Warning: Failed to cache today\'s workouts: $e');
          }

          return todaysWorkouts;
        })
        .transform(StreamTransformers.fallbackToCache<List<Workout>>(() async {
          final allCachedWorkouts = await _cacheService.loadWorkouts();
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final todaysCachedWorkouts = allCachedWorkouts
              .where((workout) =>
                  workout.createdAt.isAfter(startOfDay) &&
                  workout.createdAt.isBefore(endOfDay))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return todaysCachedWorkouts;
        }));
  }
}