import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'health_service.dart';
import 'cache_service.dart';
import 'network_service.dart';
import '../models/models.dart';

/// WearableSyncService - Manages synchronization of wearable health data
class WearableSyncService {
  final HealthService _healthService;
  final CacheService _cacheService;
  final NetworkService _networkService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WearableSyncService(this._healthService, this._cacheService, this._networkService);

  // Background sync
  Timer? _backgroundSyncTimer;
  bool _isBackgroundSyncEnabled = false;
  static const Duration _backgroundSyncInterval = Duration(hours: 6); // Sync every 6 hours

  String? get currentUserId => _auth.currentUser?.uid;

  /// Sync health data for the last 30 days with error handling
  Future<void> syncHealthData({int days = 30}) async {
    if (currentUserId == null) return;

    try {
      final isOnline = await _networkService.isOnline();
      if (!isOnline) {
        print('Skipping health data sync - offline mode');
        // In offline mode, we could still update local cache or show cached data
        return;
      }

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      print('Starting health data sync from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Check if health data is available before attempting sync
      final isHealthAvailable = await _healthService.isHealthDataAvailable();
      if (!isHealthAvailable) {
        print('Health data not available on this device');
        return;
      }

      // Check permissions
      final hasPermissions = await _healthService.requestPermissions();
      if (!hasPermissions) {
        print('Health permissions not granted - cannot sync data');
        return;
      }

      // Sync daily health data with error handling
      try {
        await _syncDailyHealthData(startDate, endDate);
      } catch (e) {
        print('Error syncing daily health data: $e');
        // Continue with workout sync even if daily data fails
      }

      // Sync workout data from wearables with error handling
      try {
        await _syncWorkoutData(startDate, endDate);
      } catch (e) {
        print('Error syncing workout data: $e');
        // Continue even if workout sync fails
      }

      // Update last sync time
      await updateLastSyncTime();

      print('Health data sync completed successfully');
    } catch (e) {
      print('Critical error during health data sync: $e');
      // In case of critical errors, we might want to retry later or notify the user
    }
  }

  /// Sync daily health metrics (steps, calories, heart rate, sleep)
  Future<void> _syncDailyHealthData(DateTime startDate, DateTime endDate) async {
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      try {
        final healthData = await _healthService.getDailyHealthData(currentDate);
        if (healthData != null) {
          await _saveHealthDataToFirestore(healthData);
          await _saveHealthDataToCache(healthData);
        }
      } catch (e) {
        print('Error syncing health data for ${currentDate.toIso8601String()}: $e');
      }

      currentDate.add(const Duration(days: 1));
    }
  }

  /// Sync workout data from wearables
  Future<void> _syncWorkoutData(DateTime startDate, DateTime endDate) async {
    try {
      final workouts = await _healthService.getWorkoutsInRange(startDate, endDate);

      for (final workout in workouts) {
        // Check if this workout already exists (avoid duplicates)
        final existingWorkout = await _findExistingWorkout(workout);
        if (existingWorkout == null) {
          await _saveWorkoutToFirestore(workout);
        }
      }
    } catch (e) {
      print('Error syncing workout data: $e');
    }
  }

  /// Save health data to Firestore
  Future<void> _saveHealthDataToFirestore(HealthData healthData) async {
    if (currentUserId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('healthData')
        .doc(healthData.date.toIso8601String().split('T')[0]); // Use date as document ID

    await docRef.set(healthData.toFirestore(), SetOptions(merge: true));
  }

  /// Save health data to local cache
  Future<void> _saveHealthDataToCache(HealthData healthData) async {
    final cacheKey = 'health_${healthData.date.toIso8601String().split('T')[0]}';
    await _cacheService.saveData(cacheKey, healthData.toFirestore());
  }

  /// Save workout to Firestore
  Future<void> _saveWorkoutToFirestore(Workout workout) async {
    if (currentUserId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('workouts')
        .doc(); // Auto-generate ID

    await docRef.set(workout.toFirestore());
  }

  /// Find existing workout to avoid duplicates
  Future<Workout?> _findExistingWorkout(Workout workout) async {
    if (currentUserId == null) return null;

    try {
      final query = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('workouts')
          .where('exerciseName', isEqualTo: workout.exerciseName)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(
              workout.createdAt.subtract(const Duration(minutes: 5))))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(
              workout.createdAt.add(const Duration(minutes: 5))))
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Workout.fromFirestore(query.docs.first);
      }
    } catch (e) {
      print('Error finding existing workout: $e');
    }

    return null;
  }

  /// Get cached health data for a specific date
  Future<HealthData?> getCachedHealthData(DateTime date) async {
    try {
      final cacheKey = 'health_${date.toIso8601String().split('T')[0]}';
      final cachedData = await _cacheService.loadData(cacheKey);

      if (cachedData != null) {
        // Ensure proper type casting for cached data
        final Map<String, dynamic> typedData = Map<String, dynamic>.from(cachedData);
        return HealthData.fromFirestore(typedData);
      }
    } catch (e) {
      print('Error loading cached health data: $e');
    }

    return null;
  }

  /// Get health data from Firestore for a specific date
  Future<HealthData?> getHealthDataFromFirestore(DateTime date) async {
    if (currentUserId == null) return null;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('healthData')
          .doc(date.toIso8601String().split('T')[0]);

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return HealthData.fromFirestore(snapshot.data()!);
      }
    } catch (e) {
      print('Error loading health data from Firestore: $e');
    }

    return null;
  }

  /// Get health data for a date (cache first, then Firestore, then fetch fresh)
  Future<HealthData?> getHealthData(DateTime date) async {
    // Try cache first
    var healthData = await getCachedHealthData(date);
    if (healthData != null) return healthData;

    // Try Firestore
    healthData = await getHealthDataFromFirestore(date);
    if (healthData != null) {
      // Cache it for future use
      await _saveHealthDataToCache(healthData);
      return healthData;
    }

    // Fetch fresh data
    try {
      healthData = await _healthService.getDailyHealthData(date);
      if (healthData != null) {
        await _saveHealthDataToFirestore(healthData);
        await _saveHealthDataToCache(healthData);
      }
      return healthData;
    } catch (e) {
      print('Error fetching fresh health data: $e');
      return null;
    }
  }

  /// Get health data for multiple dates
  Future<List<HealthData>> getHealthDataRange(DateTime startDate, DateTime endDate) async {
    final healthDataList = <HealthData>[];
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      final data = await getHealthData(currentDate);
      if (data != null) {
        healthDataList.add(data);
      }
      currentDate.add(const Duration(days: 1));
    }

    return healthDataList;
  }

  /// Check if wearable data is available and permissions granted
  Future<bool> isWearableDataAvailable() async {
    try {
      final hasPermissions = await _healthService.requestPermissions();
      final isAvailable = await _healthService.isHealthDataAvailable();
      return hasPermissions && isAvailable;
    } catch (e) {
      print('Error checking wearable data availability: $e');
      return false;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final cachedData = await _cacheService.loadData('last_health_sync');
      if (cachedData != null && cachedData['timestamp'] != null) {
        return DateTime.parse(cachedData['timestamp']);
      }
    } catch (e) {
      print('Error getting last sync time: $e');
    }
    return null;
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime() async {
    final syncData = {
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _cacheService.saveData('last_health_sync', syncData);
  }

  /// Clear all cached health data
  Future<void> clearCache() async {
    // This would need to be implemented in CacheService
    // For now, we'll just clear the sync timestamp
    await _cacheService.saveData('last_health_sync', {});
  }

  /// Get wearable connection status
  Future<Map<String, dynamic>> getWearableStatus() async {
    final isAvailable = await isWearableDataAvailable();
    final lastSync = await getLastSyncTime();

    return {
      'available': isAvailable,
      'lastSync': lastSync,
      'source': isAvailable ? 'healthkit' : 'none', // Could be expanded for other wearables
    };
  }

  /// Sync data in background (for periodic sync)
  Future<void> backgroundSync() async {
    try {
      final status = await getWearableStatus();
      if (status['available'] == true) {
        await syncHealthData(days: 7); // Sync last 7 days in background
        await updateLastSyncTime();
      }
    } catch (e) {
      print('Error in background sync: $e');
    }
  }

  /// Start background sync timer
  void startBackgroundSync() {
    if (_isBackgroundSyncEnabled) return;

    _isBackgroundSyncEnabled = true;
    print('Starting background health data sync (every ${_backgroundSyncInterval.inHours} hours)');

    // Run initial sync
    backgroundSync();

    // Set up periodic sync
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (timer) async {
      try {
        await backgroundSync();
      } catch (e) {
        print('Error in periodic background sync: $e');
      }
    });
  }

  /// Stop background sync timer
  void stopBackgroundSync() {
    _isBackgroundSyncEnabled = false;
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
    print('Stopped background health data sync');
  }

  /// Check if background sync is enabled
  bool get isBackgroundSyncEnabled => _isBackgroundSyncEnabled;

  /// Force immediate background sync
  Future<void> forceBackgroundSync() async {
    await backgroundSync();
  }

  /// Get next sync time
  DateTime? getNextSyncTime() {
    if (!_isBackgroundSyncEnabled || _backgroundSyncTimer == null) return null;

    final lastSync = _backgroundSyncTimer!.tick == 0 ? DateTime.now() : DateTime.now().subtract(
      Duration(milliseconds: _backgroundSyncTimer!.tick * _backgroundSyncInterval.inMilliseconds)
    );

    return lastSync.add(_backgroundSyncInterval);
  }

  /// Cleanup resources
  void dispose() {
    stopBackgroundSync();
  }
}