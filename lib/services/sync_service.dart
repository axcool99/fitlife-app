import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cache_service.dart';
import 'workout_service.dart';
import 'checkin_service.dart';
import '../models/workout.dart';
import '../models/checkin.dart';

/// Service for synchronizing cached data with Firestore when back online
class SyncService {
  final CacheService _cacheService;
  final WorkoutService _workoutService;
  final CheckInService _checkInService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SyncService(this._cacheService, this._workoutService, this._checkInService);

  /// Sync all cached data with Firestore
  Future<void> syncAllData() async {
    if (_auth.currentUser == null) return;

    try {
      await _syncWorkouts();
      await _syncCheckIns();
      print('Data synchronization completed successfully');
    } catch (e) {
      print('Error during data synchronization: $e');
      rethrow;
    }
  }

  /// Sync cached workouts with Firestore
  Future<void> _syncWorkouts() async {
    try {
      final cachedWorkouts = await _cacheService.loadWorkouts();
      final syncedIds = <String>{};

      for (final workout in cachedWorkouts) {
        try {
          // Check if workout already exists in Firestore
          final workoutDoc = await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('workouts')
              .doc(workout.id)
              .get();

          if (!workoutDoc.exists) {
            // Workout doesn't exist in Firestore, add it
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('workouts')
                .doc(workout.id)
                .set(workout.toFirestore());
          } else {
            // Workout exists, check if local version is newer
            final firestoreWorkout = Workout.fromFirestore(workoutDoc);
            if (workout.updatedAt != null &&
                (firestoreWorkout.updatedAt == null ||
                 workout.updatedAt!.isAfter(firestoreWorkout.updatedAt!))) {
              // Local version is newer, update Firestore
              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('workouts')
                  .doc(workout.id)
                  .update(workout.toFirestore());
            }
          }

          syncedIds.add(workout.id);
        } catch (e) {
          print('Error syncing workout ${workout.id}: $e');
        }
      }

      print('Synced ${syncedIds.length} workouts');
    } catch (e) {
      print('Error syncing workouts: $e');
      rethrow;
    }
  }

  /// Sync cached check-ins with Firestore
  Future<void> _syncCheckIns() async {
    try {
      final cachedCheckIns = await _cacheService.loadCheckIns();
      final syncedIds = <String>{};

      for (final checkIn in cachedCheckIns) {
        try {
          // Check if check-in already exists in Firestore
          final checkInDoc = await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('checkins')
              .doc(checkIn.id)
              .get();

          if (!checkInDoc.exists) {
            // Check-in doesn't exist in Firestore, add it
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('checkins')
                .doc(checkIn.id)
                .set(checkIn.toFirestore());
          }
          // For check-ins, we don't update existing ones to avoid conflicts
          // They are typically immutable once created

          syncedIds.add(checkIn.id);
        } catch (e) {
          print('Error syncing check-in ${checkIn.id}: $e');
        }
      }

      print('Synced ${syncedIds.length} check-ins');
    } catch (e) {
      print('Error syncing check-ins: $e');
      rethrow;
    }
  }

  /// Check if there is pending data to sync
  Future<bool> hasPendingSync() async {
    try {
      final workouts = await _cacheService.loadWorkouts();
      final checkIns = await _cacheService.loadCheckIns();
      return workouts.isNotEmpty || checkIns.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    try {
      final workouts = await _cacheService.loadWorkouts();
      final checkIns = await _cacheService.loadCheckIns();
      return {
        'pendingWorkouts': workouts.length,
        'pendingCheckIns': checkIns.length,
      };
    } catch (e) {
      return {
        'pendingWorkouts': 0,
        'pendingCheckIns': 0,
      };
    }
  }

  /// Clear synced data from cache after successful sync
  Future<void> clearSyncedCache() async {
    // Note: In a production app, you might want to be more selective
    // about what to clear. For now, we'll keep the cache for offline viewing.
    // The cache will be updated naturally when data is fetched from Firestore.
  }
}