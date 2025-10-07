import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout.dart';
import '../models/checkin.dart';
import '../models/models.dart';
import 'network_service.dart';

/// Cache service for offline data storage using Hive
class CacheService {
  final NetworkService _networkService;

  CacheService(this._networkService);
  static const String _workoutsBoxName = 'workouts';
  static const String _checkinsBoxName = 'checkins';
  static const String _syncStatusBoxName = 'sync_status';
  static const String _analyticsBoxName = 'analytics';
  static const String _mealsBoxName = 'meals';
  static const String _foodItemsBoxName = 'food_items';
  static const String _userPreferencesBoxName = 'user_preferences';

  late Box<Workout> _workoutsBox;
  late Box<CheckIn> _checkinsBox;
  late Box _syncStatusBox;
  late Box _analyticsBox;
  late Box _mealsBox;
  late Box _foodItemsBox;
  late Box _userPreferencesBox;

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
      _analyticsBox = await Hive.openBox(_analyticsBoxName);
      _mealsBox = await Hive.openBox(_mealsBoxName);
      _foodItemsBox = await Hive.openBox(_foodItemsBoxName);
      _userPreferencesBox = await Hive.openBox(_userPreferencesBoxName);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize cache: $e');
    }
  }

  /// Check if device is online using NetworkService
  Future<bool> isOnline() async {
    return await _networkService.isOnline();
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

  // ===== ANALYTICS CACHE =====

  /// Save weekly stats to cache
  Future<void> saveWeeklyStats(Map<String, dynamic> stats) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('weekly_stats', stats);
      await _updateSyncStatus('analytics', DateTime.now());
    } catch (e) {
      throw Exception('Failed to save weekly stats to cache: $e');
    }
  }

  /// Load weekly stats from cache
  Future<Map<String, dynamic>?> loadWeeklyStats() async {
    await _ensureInitialized();
    try {
      return _analyticsBox.get('weekly_stats') as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to load weekly stats from cache: $e');
    }
  }

  /// Save daily calories data to cache
  Future<void> saveDailyCalories(Map<String, dynamic> caloriesData) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('daily_calories', caloriesData);
      await _updateSyncStatus('analytics', DateTime.now());
    } catch (e) {
      throw Exception('Failed to save daily calories to cache: $e');
    }
  }

  /// Load daily calories data from cache
  Future<Map<String, dynamic>?> loadDailyCalories() async {
    await _ensureInitialized();
    try {
      return _analyticsBox.get('daily_calories') as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to load daily calories from cache: $e');
    }
  }

  /// Save workout frequency data to cache
  Future<void> saveWorkoutFrequency(Map<String, dynamic> frequencyData) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('workout_frequency', frequencyData);
      await _updateSyncStatus('analytics', DateTime.now());
    } catch (e) {
      throw Exception('Failed to save workout frequency to cache: $e');
    }
  }

  /// Load workout frequency data from cache
  Future<Map<String, dynamic>?> loadWorkoutFrequency() async {
    await _ensureInitialized();
    try {
      final data = _analyticsBox.get('workout_frequency');
      if (data == null) return null;

      // Handle the case where Hive returns Map<dynamic, dynamic>
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }

      return data as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to load workout frequency from cache: $e');
    }
  }

  /// Save workout type distribution data to cache
  Future<void> saveWorkoutTypeDistribution(Map<String, int> distribution) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('workout_type_distribution', distribution);
    } catch (e) {
      throw Exception('Failed to save workout type distribution to cache: $e');
    }
  }

  /// Load workout type distribution data from cache
  Future<Map<String, int>?> loadWorkoutTypeDistribution() async {
    await _ensureInitialized();
    try {
      final data = _analyticsBox.get('workout_type_distribution');
      if (data == null) return null;

      // Handle the case where Hive returns Map<dynamic, dynamic>
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value as int));
      }

      return data as Map<String, int>?;
    } catch (e) {
      throw Exception('Failed to load workout type distribution from cache: $e');
    }
  }

  /// Save average session duration data to cache
  Future<void> saveAverageSessionDuration(Map<String, dynamic> durationData) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('average_session_duration', durationData);
    } catch (e) {
      throw Exception('Failed to save average session duration to cache: $e');
    }
  }

  /// Load average session duration data from cache
  Future<Map<String, dynamic>?> loadAverageSessionDuration() async {
    await _ensureInitialized();
    try {
      final data = _analyticsBox.get('average_session_duration');
      if (data == null) return null;

      // Handle the case where Hive returns Map<dynamic, dynamic>
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }

      return data as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to load average session duration from cache: $e');
    }
  }

  /// Save calorie burn efficiency data to cache
  Future<void> saveCalorieBurnEfficiency(Map<String, dynamic> efficiencyData) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('calorie_burn_efficiency', efficiencyData);
    } catch (e) {
      throw Exception('Failed to save calorie burn efficiency to cache: $e');
    }
  }

  /// Load calorie burn efficiency data from cache
  Future<Map<String, dynamic>?> loadCalorieBurnEfficiency() async {
    await _ensureInitialized();
    try {
      final data = _analyticsBox.get('calorie_burn_efficiency');
      if (data == null) return null;

      // Handle the case where Hive returns Map<dynamic, dynamic>
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }

      return data as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to load calorie burn efficiency from cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'workouts': _workoutsBox.length,
      'checkins': _checkinsBox.length,
      'analytics': _analyticsBox.length,
    };
  }

  /// Save user preferences to cache
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await _ensureInitialized();
    try {
      await _analyticsBox.put('user_preferences', preferences.toCache());
      await _updateSyncStatus('preferences', DateTime.now());
    } catch (e) {
      throw Exception('Failed to save user preferences to cache: $e');
    }
  }

  /// Load user preferences from cache
  Future<UserPreferences?> loadUserPreferences() async {
    await _ensureInitialized();
    try {
      final data = _analyticsBox.get('user_preferences');
      if (data == null) return null;

      // Convert cached data back to UserPreferences
      // Handle the lastUpdated field which is stored as ISO string
      final cacheData = Map<String, dynamic>.from(data);
      if (cacheData['lastUpdated'] is String) {
        cacheData['lastUpdated'] = DateTime.parse(cacheData['lastUpdated']);
      }

      return UserPreferences.fromFirestore(cacheData, 'cached');
    } catch (e) {
      print('Error loading cached user preferences: $e');
      return null;
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ===== MEALS CACHE =====

  /// Save meals to cache
  Future<void> saveMeals(Map<String, Map<String, dynamic>> meals) async {
    await _ensureInitialized();
    try {
      await _mealsBox.clear();
      await _mealsBox.putAll(meals);
    } catch (e) {
      throw Exception('Failed to save meals to cache: $e');
    }
  }

  /// Get cached meals
  Future<Map<String, Map<String, dynamic>>> getCachedMeals() async {
    await _ensureInitialized();
    try {
      final meals = <String, Map<String, dynamic>>{};
      for (final key in _mealsBox.keys) {
        final data = _mealsBox.get(key);
        if (data != null) {
          meals[key.toString()] = Map<String, dynamic>.from(data);
        }
      }
      return meals;
    } catch (e) {
      print('Error getting cached meals: $e');
      return {};
    }
  }

  // ===== FOOD ITEMS CACHE =====

  /// Save food items to cache
  Future<void> saveFoodItems(Map<String, Map<String, dynamic>> foodItems) async {
    await _ensureInitialized();
    try {
      await _foodItemsBox.clear();
      await _foodItemsBox.putAll(foodItems);
    } catch (e) {
      throw Exception('Failed to save food items to cache: $e');
    }
  }

  /// Get cached food items
  Future<Map<String, Map<String, dynamic>>> getCachedFoodItems() async {
    await _ensureInitialized();
    try {
      final foodItems = <String, Map<String, dynamic>>{};
      for (final key in _foodItemsBox.keys) {
        final data = _foodItemsBox.get(key);
        if (data != null) {
          foodItems[key.toString()] = Map<String, dynamic>.from(data);
        }
      }
      return foodItems;
    } catch (e) {
      print('Error getting cached food items: $e');
      return {};
    }
  }

  /// Close all boxes (call when app is terminating)
  Future<void> close() async {
    if (_isInitialized) {
      await _workoutsBox.close();
      await _checkinsBox.close();
      await _syncStatusBox.close();
      await _analyticsBox.close();
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