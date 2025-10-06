import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout.dart';
import '../models/checkin.dart';

/// Cache service for offline data storage using Hive
class CacheService {
  static const String _workoutsBoxName = 'workouts';
  static const String _checkinsBoxName = 'checkins';
  static const String _syncStatusBoxName = 'sync_status';

  late Box<Workout> _workoutsBox;
  late Box<CheckIn> _checkinsBox;
  late Box _syncStatusBox;

  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WorkoutAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CheckInAdapter());
      }

      // Open boxes
      _workoutsBox = await Hive.openBox<Workout>(_workoutsBoxName);
      _checkinsBox = await Hive.openBox<CheckIn>(_checkinsBoxName);
      _syncStatusBox = await Hive.openBox(_syncStatusBoxName);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize cache: $e');
    }
  }

  /// Check if device is online (basic connectivity check)
  Future<bool> isOnline() async {
    try {
      // Simple connectivity check - in a real app, you'd use connectivity_plus
      return true; // For now, assume online
    } catch (e) {
      return false;
    }
  }

  // ===== WORKOUTS CACHE =====

  /// Save workouts to cache
  Future<void> saveWorkouts(List<Workout> workouts) async {
    await _ensureInitialized();
    try {
      await _workoutsBox.clear(); // Clear existing data
      for (final workout in workouts) {
        await _workoutsBox.put(workout.id, workout);
      }
      await _updateSyncStatus('workouts', DateTime.now());
    } catch (e) {
      throw Exception('Failed to save workouts to cache: $e');
    }
  }

  /// Load workouts from cache
  Future<List<Workout>> loadWorkouts() async {
    await _ensureInitialized();
    try {
      return _workoutsBox.values.toList();
    } catch (e) {
      throw Exception('Failed to load workouts from cache: $e');
    }
  }

  /// Add or update a single workout in cache
  Future<void> saveWorkout(Workout workout) async {
    await _ensureInitialized();
    try {
      await _workoutsBox.put(workout.id, workout);
    } catch (e) {
      throw Exception('Failed to save workout to cache: $e');
    }
  }

  /// Remove workout from cache
  Future<void> removeWorkout(String workoutId) async {
    await _ensureInitialized();
    try {
      await _workoutsBox.delete(workoutId);
    } catch (e) {
      throw Exception('Failed to remove workout from cache: $e');
    }
  }

  // ===== CHECK-INS CACHE =====

  /// Save check-ins to cache
  Future<void> saveCheckIns(List<CheckIn> checkIns) async {
    await _ensureInitialized();
    try {
      await _checkinsBox.clear(); // Clear existing data
      for (final checkIn in checkIns) {
        await _checkinsBox.put(checkIn.id, checkIn);
      }
      await _updateSyncStatus('checkins', DateTime.now());
    } catch (e) {
      throw Exception('Failed to save check-ins to cache: $e');
    }
  }

  /// Load check-ins from cache
  Future<List<CheckIn>> loadCheckIns() async {
    await _ensureInitialized();
    try {
      return _checkinsBox.values.toList();
    } catch (e) {
      throw Exception('Failed to load check-ins from cache: $e');
    }
  }

  /// Add or update a single check-in in cache
  Future<void> saveCheckIn(CheckIn checkIn) async {
    await _ensureInitialized();
    try {
      await _checkinsBox.put(checkIn.id, checkIn);
    } catch (e) {
      throw Exception('Failed to save check-in to cache: $e');
    }
  }

  /// Remove check-in from cache
  Future<void> removeCheckIn(String checkInId) async {
    await _ensureInitialized();
    try {
      await _checkinsBox.delete(checkInId);
    } catch (e) {
      throw Exception('Failed to remove check-in from cache: $e');
    }
  }

  // ===== SYNC STATUS =====

  /// Update sync status for a data type
  Future<void> _updateSyncStatus(String dataType, DateTime lastSync) async {
    await _ensureInitialized();
    try {
      await _syncStatusBox.put('${dataType}_last_sync', lastSync.toIso8601String());
    } catch (e) {
      // Don't throw here as sync status is not critical
      print('Warning: Failed to update sync status: $e');
    }
  }

  /// Get last sync time for a data type
  DateTime? getLastSyncTime(String dataType) {
    try {
      final lastSyncStr = _syncStatusBox.get('${dataType}_last_sync') as String?;
      return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensureInitialized();
    try {
      await _workoutsBox.clear();
      await _checkinsBox.clear();
      await _syncStatusBox.clear();
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'workouts': _workoutsBox.length,
      'checkins': _checkinsBox.length,
    };
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Close all boxes (call when app is terminating)
  Future<void> close() async {
    if (_isInitialized) {
      await _workoutsBox.close();
      await _checkinsBox.close();
      await _syncStatusBox.close();
      _isInitialized = false;
    }
  }
}

// ===== HIVE ADAPTERS =====

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 0;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Workout(
      id: fields[0] as String,
      userId: fields[1] as String,
      exerciseName: fields[2] as String,
      sets: fields[3] as int,
      reps: fields[4] as int,
      duration: fields[5] as int?,
      weight: fields[6] as double?,
      notes: fields[7] as String?,
      createdAt: DateTime.parse(fields[8] as String),
      updatedAt: fields[9] != null ? DateTime.parse(fields[9] as String) : null,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(10) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.reps)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.weight)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(9)
      ..write(obj.updatedAt?.toIso8601String());
  }
}

class CheckInAdapter extends TypeAdapter<CheckIn> {
  @override
  final int typeId = 1;

  @override
  CheckIn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return CheckIn(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: DateTime.parse(fields[2] as String),
      weight: fields[3] as double,
      mood: fields[4] as String,
      energyLevel: fields[5] as int,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CheckIn obj) {
    writer
      ..writeByte(7) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.date.toIso8601String())
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.energyLevel)
      ..writeByte(6)
      ..write(obj.notes);
  }
}