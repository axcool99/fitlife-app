import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    return dailyFrequency;
  }

  // Calculate estimated daily calories burned (simplified calculation)
  Future<Map<DateTime, double>> getDailyCaloriesBurned() async {
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

    return dailyCalories;
  }

  // Get weekly statistics
  Future<WeeklyStats> getWeeklyStats() async {
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
    final streak = await _calculateStreak();

    return WeeklyStats(
      totalWorkouts: totalWorkouts,
      avgCaloriesPerSession: avgCaloriesPerSession,
      progressPercentage: progressPercentage,
      streak: streak,
    );
  }

  // Calculate current streak of consecutive active days
  Future<int> _calculateStreak() async {
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