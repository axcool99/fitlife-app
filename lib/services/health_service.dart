import 'dart:io';
import 'package:health/health.dart';
import '../models/models.dart';

/// HealthService - Platform-specific health data access using HealthKit/Google Fit
class HealthService {
  // Health plugin instance
  Health get health => Health();

  // Health data types we want to access
  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.WORKOUT,
  ];

  // Platform-specific permissions
  List<HealthDataAccess> get _permissions => _dataTypes.map((type) =>
    Platform.isIOS
      ? HealthDataAccess.READ
      : HealthDataAccess.READ_WRITE
  ).toList();

  /// Request health data permissions
  Future<bool> requestPermissions() async {
    try {
      final granted = await health.requestAuthorization(_dataTypes, permissions: _permissions);

      if (!granted) {
        print('Health permissions denied by user');
        // Cache the permission denial to avoid repeated requests
        // Note: In a real app, you'd use proper caching here
      }

      return granted;
    } catch (e) {
      print('Error requesting health permissions: $e');
      return false;
    }
  }

  /// Check if permissions were previously denied (to avoid repeated requests)
  Future<bool> werePermissionsPreviouslyDenied() async {
    try {
      // In a real implementation, you'd check cached permission status
      // For now, we'll just return false to allow permission requests
      return false;
    } catch (e) {
      print('Error checking permission status: $e');
      return false;
    }
  }

  /// Get health data with offline fallback
  Future<HealthData?> getDailyHealthDataWithFallback(DateTime date) async {
    try {
      // First try to get fresh data
      final freshData = await getDailyHealthData(date);
      if (freshData != null) {
        return freshData;
      }

      // If fresh data fails, try to get cached data
      // In a real implementation, you'd have a caching layer here
      print('No fresh health data available, using defaults');
      return null;
    } catch (e) {
      print('Error getting health data with fallback: $e');
      return null;
    }
  }

  /// Check if health data is available on this device
  Future<bool> isHealthDataAvailable() async {
    try {
      // For now, just return true - will be implemented with correct API
      return true;
    } catch (e) {
      print('Error checking health data availability: $e');
      return false;
    }
  }

  /// Get daily health data for a specific date
  Future<HealthData?> getDailyHealthData(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      // Get steps
      final steps = await _getStepsInRange(startDate, endDate);

      // Get active energy (calories burned)
      final caloriesBurned = await _getActiveEnergyInRange(startDate, endDate);

      // Get resting heart rate
      final restingHeartRate = await _getRestingHeartRate(date);

      // Get heart rate points for the day
      final heartRatePoints = await _getHeartRatePoints(startDate, endDate);

      // Get sleep data for the night before this date
      final sleepData = await _getSleepData(date);

      // Get distance
      final distance = await _getDistanceInRange(startDate, endDate);

      return HealthData(
        date: date,
        steps: steps,
        caloriesBurned: caloriesBurned,
        restingHeartRate: restingHeartRate,
        heartRatePoints: heartRatePoints,
        sleepData: sleepData,
        distance: distance,
        source: Platform.isIOS ? 'healthkit' : 'google_fit',
      );
    } catch (e) {
      print('Error getting daily health data: $e');
      return null;
    }
  }

  /// Get steps for a date range
  Future<int> _getStepsInRange(DateTime start, DateTime end) async {
    try {
      final steps = await health.getTotalStepsInInterval(start, end);
      return steps?.toInt() ?? 0;
    } catch (e) {
      print('Error getting steps: $e');
      return 0;
    }
  }

  /// Get active energy burned for a date range
  Future<double> _getActiveEnergyInRange(DateTime start, DateTime end) async {
    try {
      // TODO: Implement with correct health package API
      // For now, return mock data
      return 150.0; // Mock calories burned
    } catch (e) {
      print('Error getting active energy: $e');
      return 0.0;
    }
  }

  /// Get resting heart rate for a specific date
  Future<double> _getRestingHeartRate(DateTime date) async {
    try {
      // TODO: Implement with correct health package API
      // For now, return mock data
      return 72.0; // Mock resting heart rate
    } catch (e) {
      print('Error getting resting heart rate: $e');
      return 70.0;
    }
  }

  /// Get heart rate points for a date range
  Future<List<HeartRatePoint>> _getHeartRatePoints(DateTime start, DateTime end) async {
    try {
      // TODO: Implement with correct health package API
      // For now, return mock data
      return [
        HeartRatePoint(timestamp: start.add(const Duration(hours: 1)), heartRate: 75.0),
        HeartRatePoint(timestamp: start.add(const Duration(hours: 2)), heartRate: 80.0),
        HeartRatePoint(timestamp: start.add(const Duration(hours: 3)), heartRate: 78.0),
      ];
    } catch (e) {
      print('Error getting heart rate points: $e');
      return [];
    }
  }

  /// Get sleep data for a specific date (night before)
  Future<SleepData?> _getSleepData(DateTime date) async {
    try {
      // TODO: Implement with correct health package API
      // For now, return mock data
      return SleepData(
        date: date,
        totalSleep: const Duration(hours: 7, minutes: 30),
        deepSleep: const Duration(hours: 1, minutes: 45),
        remSleep: const Duration(hours: 1, minutes: 30),
        lightSleep: const Duration(hours: 4, minutes: 15),
        awakeTime: const Duration(minutes: 45),
        sleepEfficiency: 85,
        bedTime: DateTime(date.year, date.month, date.day, 22, 30),
        wakeTime: DateTime(date.year, date.month, date.day, 6, 0),
      );
    } catch (e) {
      print('Error getting sleep data: $e');
      return null;
    }
  }

  /// Get distance traveled for a date range
  Future<double> _getDistanceInRange(DateTime start, DateTime end) async {
    try {
      // TODO: Implement with correct health package API
      // For now, return mock data
      return 3.5; // Mock distance in km
    } catch (e) {
      print('Error getting distance: $e');
      return 0.0;
    }
  }

  /// Get workout data from HealthKit/Google Fit
  Future<List<Workout>> getWorkoutsInRange(DateTime start, DateTime end) async {
    try {
      // TODO: Implement with correct health package API
      // For now, return empty list
      return [];
    } catch (e) {
      print('Error getting workouts: $e');
      return [];
    }
  }

  /// Convert HealthKit/Google Fit workout type to exercise name
  String _convertHealthWorkoutType(HealthDataPoint workout) {
    // This is a simplified conversion - in a real app you'd map all workout types
    // For now, return a generic workout name
    return 'Workout';
  }

  /// Get real-time heart rate (if available)
  Stream<double> getHeartRateStream() async* {
    // This would require continuous monitoring permissions
    // Implementation depends on specific wearable integration
    yield 0.0;
  }

  /// Check if specific health data type is available
  Future<bool> isDataTypeAvailable(HealthDataType type) async {
    try {
      return await health.isDataTypeAvailable(type);
    } catch (e) {
      return false;
    }
  }
}