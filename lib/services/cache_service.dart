import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// Provides lightweight local caching for API responses and app data.
/// Uses Hive for persistent key-value storage with automatic TTL validation.
class CacheService {
  static const String _boxName = 'fitlife_cache';
  late Box _box;
  bool _isInitialized = false;

  /// Initialize Hive and open the cache box.
  /// Should be called once during app startup.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
    } catch (e) {
      print('CacheService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Save data to cache with optional TTL.
  /// [key] Unique identifier for the cached item
  /// [value] The data to cache (must be JSON serializable)
  /// [ttlSeconds] Time-to-live in seconds (default: 7 days = 604800)
  Future<void> save(String key, dynamic value, {int ttlSeconds = 604800}) async {
    await _ensureInitialized();
    try {
      final cacheEntry = {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': value,
        'ttl': ttlSeconds,
      };
      await _box.put(key, cacheEntry);
      print('CacheService: Cache saved for key: $key');
    } catch (e) {
      print('CacheService: Failed to save cache for key $key: $e');
    }
  }

  /// Retrieve cached data by key.
  /// Returns null if key doesn't exist or on error.
  Future<dynamic> get(String key) async {
    await _ensureInitialized();
    try {
      final cachedItem = _box.get(key);
      if (cachedItem == null) {
        print('CacheService: Cache miss for key: $key');
        return null;
      }

      print('CacheService: Cache hit for key: $key');
      return cachedItem;
    } catch (e) {
      print('CacheService: Failed to get cache for key $key: $e');
      return null;
    }
  }

  /// Clear a specific cache entry.
  Future<void> clear(String key) async {
    await _ensureInitialized();
    try {
      await _box.delete(key);
      print('CacheService: Cache cleared for key: $key');
    } catch (e) {
      print('CacheService: Failed to clear cache for key $key: $e');
    }
  }

  /// Clear all cached data.
  Future<void> clearAll() async {
    await _ensureInitialized();
    try {
      await _box.clear();
      print('CacheService: All cache cleared');
    } catch (e) {
      print('CacheService: Failed to clear all cache: $e');
    }
  }

  /// Check if cached item is still valid based on TTL.
  /// [cachedItem] The cached item returned from get()
  /// [ttlSeconds] Override default TTL (optional)
  bool isCacheValid(dynamic cachedItem, {int? ttlSeconds}) {
    if (cachedItem == null || cachedItem is! Map) return false;

    try {
      final timestamp = cachedItem['timestamp'] as int?;
      final itemTtl = ttlSeconds ?? (cachedItem['ttl'] as int? ?? 604800);

      if (timestamp == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isValid = now - timestamp < itemTtl;

      if (!isValid) {
        print('CacheService: Cache expired for timestamp: $timestamp');
      }

      return isValid;
    } catch (e) {
      print('CacheService: Error validating cache: $e');
      return false;
    }
  }

  /// Ensure the service is initialized, auto-initializing if needed.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  /// Close the cache box (call on app termination).
  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }

  // ===== BACKWARD COMPATIBILITY METHODS =====
  // These methods maintain compatibility with existing services

  /// Save workouts to cache (backward compatibility)
  Future<void> saveWorkouts(List<dynamic> workouts) async {
    await _ensureInitialized();
    try {
      await _box.put('workouts', {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': workouts,
        'ttl': 604800, // 7 days
      });
    } catch (e) {
      print('CacheService: Failed to save workouts: $e');
    }
  }

  /// Load workouts from cache (backward compatibility)
  Future<List<dynamic>> loadWorkouts() async {
    await _ensureInitialized();
    try {
      final cachedItem = _box.get('workouts');
      if (cachedItem != null && isCacheValid(cachedItem)) {
        return cachedItem['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('CacheService: Failed to load workouts: $e');
      return [];
    }
  }

  /// Save a single workout (backward compatibility)
  Future<void> saveWorkout(dynamic workout) async {
    await _ensureInitialized();
    try {
      await _box.put('workout_${workout.id}', {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': workout,
        'ttl': 604800,
      });
    } catch (e) {
      print('CacheService: Failed to save workout: $e');
    }
  }

  /// Remove workout from cache (backward compatibility)
  Future<void> removeWorkout(String workoutId) async {
    await _ensureInitialized();
    try {
      await _box.delete('workout_$workoutId');
    } catch (e) {
      print('CacheService: Failed to remove workout: $e');
    }
  }

  /// Save check-ins to cache (backward compatibility)
  Future<void> saveCheckIns(List<dynamic> checkIns) async {
    await _ensureInitialized();
    try {
      await _box.put('checkins', {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': checkIns,
        'ttl': 604800,
      });
    } catch (e) {
      print('CacheService: Failed to save checkins: $e');
    }
  }

  /// Load check-ins from cache (backward compatibility)
  Future<List<dynamic>> loadCheckIns() async {
    await _ensureInitialized();
    try {
      final cachedItem = _box.get('checkins');
      if (cachedItem != null && isCacheValid(cachedItem)) {
        return cachedItem['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('CacheService: Failed to load checkins: $e');
      return [];
    }
  }

  /// Save a single check-in (backward compatibility)
  Future<void> saveCheckIn(dynamic checkIn) async {
    await _ensureInitialized();
    try {
      await _box.put('checkin_${checkIn.id}', {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': checkIn,
        'ttl': 604800,
      });
    } catch (e) {
      print('CacheService: Failed to save checkin: $e');
    }
  }

  /// Remove check-in from cache (backward compatibility)
  Future<void> removeCheckIn(String checkInId) async {
    await _ensureInitialized();
    try {
      await _box.delete('checkin_$checkInId');
    } catch (e) {
      print('CacheService: Failed to remove checkin: $e');
    }
  }

  /// Save weekly stats (backward compatibility)
  Future<void> saveWeeklyStats(Map<String, dynamic> stats) async {
    await save('weekly_stats', stats);
  }

  /// Load weekly stats (backward compatibility)
  Future<Map<String, dynamic>?> loadWeeklyStats() async {
    final data = await get('weekly_stats');
    return data != null ? data['data'] as Map<String, dynamic>? : null;
  }

  /// Save daily calories (backward compatibility)
  Future<void> saveDailyCalories(Map<String, dynamic> caloriesData) async {
    await save('daily_calories', caloriesData);
  }

  /// Load daily calories (backward compatibility)
  Future<Map<String, dynamic>?> loadDailyCalories() async {
    final data = await get('daily_calories');
    return data != null ? data['data'] as Map<String, dynamic>? : null;
  }

  /// Save workout frequency (backward compatibility)
  Future<void> saveWorkoutFrequency(Map<String, dynamic> frequencyData) async {
    await save('workout_frequency', frequencyData);
  }

  /// Load workout frequency (backward compatibility)
  Future<Map<String, dynamic>?> loadWorkoutFrequency() async {
    final data = await get('workout_frequency');
    return data != null ? data['data'] as Map<String, dynamic>? : null;
  }

  /// Save workout type distribution (backward compatibility)
  Future<void> saveWorkoutTypeDistribution(Map<String, int> distribution) async {
    await save('workout_type_distribution', distribution);
  }

  /// Load workout type distribution (backward compatibility)
  Future<Map<String, int>?> loadWorkoutTypeDistribution() async {
    final data = await get('workout_type_distribution');
    return data != null ? data['data'] as Map<String, int>? : null;
  }

  /// Save average session duration (backward compatibility)
  Future<void> saveAverageSessionDuration(Map<String, dynamic> durationData) async {
    await save('average_session_duration', durationData);
  }

  /// Load average session duration (backward compatibility)
  Future<Map<String, dynamic>?> loadAverageSessionDuration() async {
    final data = await get('average_session_duration');
    return data != null ? data['data'] as Map<String, dynamic>? : null;
  }

  /// Save calorie burn efficiency (backward compatibility)
  Future<void> saveCalorieBurnEfficiency(Map<String, dynamic> efficiencyData) async {
    await save('calorie_burn_efficiency', efficiencyData);
  }

  /// Load calorie burn efficiency (backward compatibility)
  Future<Map<String, dynamic>?> loadCalorieBurnEfficiency() async {
    final data = await get('calorie_burn_efficiency');
    return data != null ? data['data'] as Map<String, dynamic>? : null;
  }

  /// Save user preferences (backward compatibility)
  Future<void> saveUserPreferences(dynamic preferences) async {
    await save('user_preferences', preferences.toCache());
  }

  /// Load user preferences (backward compatibility)
  Future<dynamic?> loadUserPreferences() async {
    final data = await get('user_preferences');
    if (data != null) {
      final cacheData = Map<String, dynamic>.from(data['data']);
      if (cacheData['lastUpdated'] is String) {
        cacheData['lastUpdated'] = DateTime.parse(cacheData['lastUpdated']);
      }
      return UserPreferences.fromFirestore(cacheData, 'cached');
    }
    return null;
  }

  /// Save meals (backward compatibility)
  Future<void> saveMeals(Map<String, Map<String, dynamic>> meals) async {
    await save('meals', meals);
  }

  /// Get cached meals (backward compatibility)
  Future<Map<String, Map<String, dynamic>>> getCachedMeals() async {
    final data = await get('meals');
    return data != null ? data['data'] as Map<String, Map<String, dynamic>> : {};
  }

  /// Save food items (backward compatibility)
  Future<void> saveFoodItems(Map<String, Map<String, dynamic>> foodItems) async {
    await save('food_items', foodItems);
  }

  /// Get cached food items (backward compatibility)
  Future<Map<String, Map<String, dynamic>>> getCachedFoodItems() async {
    final data = await get('food_items');
    return data != null ? data['data'] as Map<String, Map<String, dynamic>> : {};
  }

  /// Generic save data (backward compatibility)
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    await save(key, data);
  }

  /// Generic load data (backward compatibility)
  Future<Map<String, dynamic>?> loadData(String key) async {
    final data = await get(key);
    return data != null ? data['data'] as Map<String, dynamic>? : null;
  }

  /// Clear all cached data (backward compatibility)
  Future<void> clearCache() async {
    await clearAll();
  }

  /// Get last sync time (backward compatibility)
  DateTime? getLastSyncTime(String dataType) {
    try {
      final data = _box.get('${dataType}_last_sync');
      return data != null ? DateTime.parse(data as String) : null;
    } catch (e) {
      return null;
    }
  }

  /// Update sync status (backward compatibility)
  Future<void> _updateSyncStatus(String dataType, DateTime lastSync) async {
    await _ensureInitialized();
    try {
      await _box.put('${dataType}_last_sync', lastSync.toIso8601String());
    } catch (e) {
      print('CacheService: Failed to update sync status: $e');
    }
  }

  /// Get cache statistics (backward compatibility)
  Map<String, int> getCacheStats() {
    return {
      'workouts': _box.containsKey('workouts') ? 1 : 0,
      'checkins': _box.containsKey('checkins') ? 1 : 0,
      'analytics': _box.keys.where((key) => key.startsWith('analytics_')).length,
    };
  }
}