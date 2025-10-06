import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import 'cache_service.dart';
import 'network_service.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService;
  final NetworkService _networkService;

  AnalyticsService(this._cacheService, this._networkService);

  String? get currentUserId => _auth.currentUser?.uid;

  // Get workouts for current user within date range
  Future<List<Workout>> getWorkoutsInRange(DateTime startDate, DateTime endDate) async {
    if (currentUserId == null) return [];

    final userWorkoutsRef = _firestore.collection('users').doc(currentUserId).collection('workouts');

    final querySnapshot = await userWorkoutsRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: false)
        .get();

    return querySnapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
  }

  // Get workouts for the past 7 days
  Future<List<Workout>> getLast7DaysWorkouts() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    return getWorkoutsInRange(startDate, endDate);
  }

  // Get workouts for the previous 7 days (week before last)
  Future<List<Workout>> getPrevious7DaysWorkouts() async {
    final endDate = DateTime.now().subtract(const Duration(days: 7));
    final startDate = endDate.subtract(const Duration(days: 7));
    return getWorkoutsInRange(startDate, endDate);
  }

  // Calculate daily workout frequency for the past 7 days
  Future<Map<DateTime, int>> getDailyWorkoutFrequency() async {
    try {
      // Try to get fresh data from Firestore
      final workouts = await getLast7DaysWorkouts();
      final Map<DateTime, int> dailyFrequency = {};

      // Initialize all 7 days with 0
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        dailyFrequency[dateKey] = 0;
      }

      // Count workouts per day
      for (final workout in workouts) {
        final workoutDate = DateTime(
          workout.createdAt.year,
          workout.createdAt.month,
          workout.createdAt.day,
        );
        if (dailyFrequency.containsKey(workoutDate)) {
          dailyFrequency[workoutDate] = dailyFrequency[workoutDate]! + 1;
        }
      }

      // Cache the fresh data
      final cacheData = dailyFrequency.map((key, value) => MapEntry(key.toIso8601String(), value));
      await _cacheService.saveWorkoutFrequency(cacheData);

      return dailyFrequency;
    } catch (e) {
      print('Error fetching workout frequency from Firestore: $e');
      // Fall back to cached data
      try {
        final cachedData = await _cacheService.loadWorkoutFrequency();
        if (cachedData != null) {
          return cachedData.map((key, value) => MapEntry(DateTime.parse(key), value as int));
        }
      } catch (cacheError) {
        print('Error loading cached workout frequency: $cacheError');
      }

      // Return empty data if both Firestore and cache fail
      final Map<DateTime, int> emptyData = {};
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        emptyData[dateKey] = 0;
      }
      return emptyData;
    }
  }

  // Calculate estimated daily calories burned (simplified calculation)
  Future<Map<DateTime, double>> getDailyCaloriesBurned() async {
    try {
      // Try to get fresh data from Firestore
      final workouts = await getLast7DaysWorkouts();
      final Map<DateTime, double> dailyCalories = {};

      // Initialize all 7 days with 0
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        dailyCalories[dateKey] = 0.0;
      }

      // Estimate calories based on workout duration and intensity
      for (final workout in workouts) {
        final workoutDate = DateTime(
          workout.createdAt.year,
          workout.createdAt.month,
          workout.createdAt.day,
        );

        if (dailyCalories.containsKey(workoutDate)) {
          // Simple calorie estimation: base calories per workout + duration bonus
          double calories = 50.0; // Base calories per workout

          // Add calories based on duration (if available)
          if (workout.duration != null) {
            calories += (workout.duration! / 60.0) * 100; // ~100 calories per hour
          }

          // Add calories based on weight (if available and positive) - rough estimate
          if (workout.weight != null && workout.weight! > 0) {
            calories += workout.weight! * 0.5; // Rough multiplier - only for positive weights
          }

          // Ensure calories are never negative
          calories = calories > 0 ? calories : 0.0;

          dailyCalories[workoutDate] = dailyCalories[workoutDate]! + calories;
        }
      }

      // Cache the fresh data
      final cacheData = dailyCalories.map((key, value) => MapEntry(key.toIso8601String(), value));
      await _cacheService.saveDailyCalories(cacheData);

      return dailyCalories;
    } catch (e) {
      print('Error fetching daily calories from Firestore: $e');
      // Fall back to cached data
      try {
        final cachedData = await _cacheService.loadDailyCalories();
        if (cachedData != null) {
          return cachedData.map((key, value) => MapEntry(DateTime.parse(key), value as double));
        }
      } catch (cacheError) {
        print('Error loading cached daily calories: $cacheError');
      }

      // Return empty data if both Firestore and cache fail
      final Map<DateTime, double> emptyData = {};
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        emptyData[dateKey] = 0.0;
      }
      return emptyData;
    }
  }

  // Get weekly statistics
  Future<WeeklyStats> getWeeklyStats() async {
    try {
      // Try to get fresh data from Firestore
      final currentWeekWorkouts = await getLast7DaysWorkouts();
      final previousWeekWorkouts = await getPrevious7DaysWorkouts();

      final totalWorkouts = currentWeekWorkouts.length;
      final previousWeekTotal = previousWeekWorkouts.length;

      // Calculate average calories per session
      double totalCalories = 0.0;
      for (final workout in currentWeekWorkouts) {
        double calories = 50.0;
        if (workout.duration != null) {
          calories += (workout.duration! / 60.0) * 100;
        }
        if (workout.weight != null) {
          calories += workout.weight! * 0.5;
        }
        totalCalories += calories;
      }

      final avgCaloriesPerSession = totalWorkouts > 0 ? totalCalories / totalWorkouts : 0.0;

      // Calculate week-over-week progress
      double progressPercentage = 0.0;
      if (previousWeekTotal > 0) {
        progressPercentage = ((totalWorkouts - previousWeekTotal) / previousWeekTotal) * 100;
      } else if (totalWorkouts > 0) {
        progressPercentage = 100.0; // If no previous workouts but has current, show 100% improvement
      }

      // Calculate streak (consecutive days with workouts)
      final streak = await calculateStreak();

      final weeklyStats = WeeklyStats(
        totalWorkouts: totalWorkouts,
        avgCaloriesPerSession: avgCaloriesPerSession,
        progressPercentage: progressPercentage,
        streak: streak,
      );

      // Cache the fresh data
      final cacheData = {
        'totalWorkouts': totalWorkouts,
        'avgCaloriesPerSession': avgCaloriesPerSession,
        'progressPercentage': progressPercentage,
        'streak': streak,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await _cacheService.saveWeeklyStats(cacheData);

      return weeklyStats;
    } catch (e) {
      print('Error fetching weekly stats from Firestore: $e');
      // Fall back to cached data
      try {
        final cachedData = await _cacheService.loadWeeklyStats();
        if (cachedData != null) {
          return WeeklyStats(
            totalWorkouts: cachedData['totalWorkouts'] ?? 0,
            avgCaloriesPerSession: cachedData['avgCaloriesPerSession'] ?? 0.0,
            progressPercentage: cachedData['progressPercentage'] ?? 0.0,
            streak: cachedData['streak'] ?? 0,
          );
        }
      } catch (cacheError) {
        print('Error loading cached weekly stats: $cacheError');
      }

      // Return empty stats if both Firestore and cache fail
      return WeeklyStats(
        totalWorkouts: 0,
        avgCaloriesPerSession: 0.0,
        progressPercentage: 0.0,
        streak: 0,
      );
    }
  }

  // Calculate current streak of consecutive active days
  Future<int> calculateStreak() async {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Check up to 30 days back for streak calculation
    for (int i = 0; i < 30; i++) {
      final dateToCheck = DateTime(checkDate.year, checkDate.month, checkDate.day).subtract(Duration(days: i));
      final nextDay = dateToCheck.add(const Duration(days: 1));

      final workoutsOnDate = await getWorkoutsInRange(dateToCheck, nextDay);

      if (workoutsOnDate.isNotEmpty) {
        streak++;
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  // Get workout type distribution for the past 7 days
  Future<Map<String, int>> getWorkoutTypeDistribution() async {
    try {
      final workouts = await getLast7DaysWorkouts();
      final Map<String, int> distribution = {};

      for (final workout in workouts) {
        final type = workout.exerciseName;
        distribution[type] = (distribution[type] ?? 0) + 1;
      }

      // Cache the fresh data
      await _cacheService.saveWorkoutTypeDistribution(distribution);

      return distribution;
    } catch (e) {
      print('Error fetching workout type distribution from Firestore: $e');
      // Fall back to cached data
      try {
        final cachedData = await _cacheService.loadWorkoutTypeDistribution();
        if (cachedData != null) {
          return cachedData;
        }
      } catch (cacheError) {
        print('Error loading cached workout type distribution: $cacheError');
      }

      return {};
    }
  }

  // Get average session duration for the past 7 days
  Future<Map<DateTime, double>> getAverageSessionDuration() async {
    try {
      final workouts = await getLast7DaysWorkouts();
      final Map<DateTime, Map<String, dynamic>> dailyData = {};

      // Initialize all 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        dailyData[dateKey] = {'totalDuration': 0.0, 'count': 0};
      }

      // Aggregate data by day
      for (final workout in workouts) {
        final workoutDate = DateTime(
          workout.createdAt.year,
          workout.createdAt.month,
          workout.createdAt.day,
        );

        if (dailyData.containsKey(workoutDate) && workout.duration != null) {
          dailyData[workoutDate]!['totalDuration'] += workout.duration! / 60.0; // Convert to minutes
          dailyData[workoutDate]!['count'] += 1;
        }
      }

      // Calculate averages
      final Map<DateTime, double> averages = {};
      dailyData.forEach((date, data) {
        final count = data['count'] as int;
        final totalDuration = data['totalDuration'] as double;
        averages[date] = count > 0 ? totalDuration / count : 0.0;
      });

      // Cache the fresh data
      final cacheData = averages.map((key, value) => MapEntry(key.toIso8601String(), value));
      await _cacheService.saveAverageSessionDuration(cacheData);

      return averages;
    } catch (e) {
      print('Error fetching average session duration from Firestore: $e');
      // Fall back to cached data
      try {
        final cachedData = await _cacheService.loadAverageSessionDuration();
        if (cachedData != null) {
          return cachedData.map((key, value) => MapEntry(DateTime.parse(key), value as double));
        }
      } catch (cacheError) {
        print('Error loading cached average session duration: $cacheError');
      }

      // Return empty data
      final Map<DateTime, double> emptyData = {};
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        emptyData[dateKey] = 0.0;
      }
      return emptyData;
    }
  }

  // Get calorie burn efficiency (calories per minute) for the past 7 days
  Future<Map<DateTime, double>> getCalorieBurnEfficiency() async {
    try {
      final workouts = await getLast7DaysWorkouts();
      final Map<DateTime, Map<String, dynamic>> dailyData = {};

      // Initialize all 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        dailyData[dateKey] = {'totalCalories': 0.0, 'totalDuration': 0.0};
      }

      // Aggregate data by day
      for (final workout in workouts) {
        final workoutDate = DateTime(
          workout.createdAt.year,
          workout.createdAt.month,
          workout.createdAt.day,
        );

        if (dailyData.containsKey(workoutDate)) {
          // Calculate calories for this workout
          double calories = 50.0; // Base calories
          if (workout.duration != null) {
            calories += (workout.duration! / 60.0) * 100; // Duration-based calories
          }
          if (workout.weight != null && workout.weight! > 0) {
            calories += workout.weight! * 0.5; // Weight-based calories
          }
          calories = calories > 0 ? calories : 0.0;

          dailyData[workoutDate]!['totalCalories'] += calories;
          if (workout.duration != null) {
            dailyData[workoutDate]!['totalDuration'] += workout.duration! / 60.0; // Convert to minutes
          }
        }
      }

      // Calculate efficiency (calories per minute)
      final Map<DateTime, double> efficiency = {};
      dailyData.forEach((date, data) {
        final totalCalories = data['totalCalories'] as double;
        final totalDuration = data['totalDuration'] as double;
        efficiency[date] = totalDuration > 0 ? totalCalories / totalDuration : 0.0;
      });

      // Cache the fresh data
      final cacheData = efficiency.map((key, value) => MapEntry(key.toIso8601String(), value));
      await _cacheService.saveCalorieBurnEfficiency(cacheData);

      return efficiency;
    } catch (e) {
      print('Error fetching calorie burn efficiency from Firestore: $e');
      // Fall back to cached data
      try {
        final cachedData = await _cacheService.loadCalorieBurnEfficiency();
        if (cachedData != null) {
          return cachedData.map((key, value) => MapEntry(DateTime.parse(key), value as double));
        }
      } catch (cacheError) {
        print('Error loading cached calorie burn efficiency: $cacheError');
      }

      // Return empty data
      final Map<DateTime, double> emptyData = {};
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        emptyData[dateKey] = 0.0;
      }
      return emptyData;
    }
  }
}

class WeeklyStats {
  final int totalWorkouts;
  final double avgCaloriesPerSession;
  final double progressPercentage;
  final int streak;

  WeeklyStats({
    required this.totalWorkouts,
    required this.avgCaloriesPerSession,
    required this.progressPercentage,
    required this.streak,
  });
}