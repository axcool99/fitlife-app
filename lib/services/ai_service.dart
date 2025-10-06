import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../models/models.dart';
import 'analytics_service.dart';
import 'profile_service.dart';

/// AI Service for generating workout suggestions based on user history and goals
class AIService {
  final AnalyticsService _analyticsService;
  final ProfileService _profileService;

  AIService(this._analyticsService, this._profileService);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Common exercise categories and their variations
  static const Map<String, List<String>> exerciseCategories = {
    'upper_body': [
      'push-ups', 'bench press', 'shoulder press', 'pull-ups', 'rows', 'bicep curls', 'tricep extensions',
      'chest press', 'overhead press', 'lat pulldowns', 'chest flyes', 'dips'
    ],
    'lower_body': [
      'squats', 'lunges', 'deadlifts', 'leg press', 'calf raises', 'glute bridges', 'step-ups',
      'leg curls', 'leg extensions', 'bulgarian split squats'
    ],
    'core': [
      'planks', 'crunches', 'russian twists', 'mountain climbers', 'bicycle crunches', 'leg raises',
      'flutter kicks', 'bird dogs', 'dead bugs'
    ],
    'cardio': [
      'burpees', 'jumping jacks', 'high knees', 'mountain climbers', 'sprints', 'jump rope',
      'cycling', 'running', 'swimming'
    ],
  };

  // Exercise difficulty levels (1-5 scale)
  static const Map<String, int> exerciseDifficulty = {
    // Beginner exercises (1-2)
    'push-ups': 2, 'squats': 1, 'planks': 2, 'crunches': 1, 'walking': 1,
    // Intermediate exercises (3)
    'pull-ups': 3, 'deadlifts': 3, 'lunges': 3, 'burpees': 3, 'bench press': 3,
    // Advanced exercises (4-5)
    'overhead press': 4, 'dips': 4, 'pistol squats': 5, 'muscle-ups': 5,
  };

  /// Generate workout suggestions based on user history and profile
  Future<List<WorkoutSuggestion>> getWorkoutSuggestions({int limit = 3}) async {
    if (currentUserId == null) return [];

    try {
      // Get user profile for goals and fitness level
      final profile = await _profileService.getProfile();

      // Get recent workout history (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentWorkouts = await _analyticsService.getWorkoutsInRange(
        thirtyDaysAgo,
        DateTime.now(),
      );

      // Get last 7 days for immediate suggestions
      final last7DaysWorkouts = await _analyticsService.getLast7DaysWorkouts();

      // Analyze workout patterns
      final suggestions = <WorkoutSuggestion>[];

      // 1. Suggest variety - exercises they haven't done recently
      final varietySuggestions = await _getVarietySuggestions(recentWorkouts, profile);
      suggestions.addAll(varietySuggestions);

      // 2. Suggest progression - increase weight/reps for recent exercises
      final progressionSuggestions = _getProgressionSuggestions(last7DaysWorkouts);
      suggestions.addAll(progressionSuggestions);

      // 3. Suggest based on goals and fitness level
      final goalSuggestions = _getGoalBasedSuggestions(profile, recentWorkouts);
      suggestions.addAll(goalSuggestions);

      // Remove duplicates and limit results
      final uniqueSuggestions = <WorkoutSuggestion>[];
      final seenExercises = <String>{};

      for (final suggestion in suggestions) {
        if (!seenExercises.contains(suggestion.exerciseName.toLowerCase())) {
          uniqueSuggestions.add(suggestion);
          seenExercises.add(suggestion.exerciseName.toLowerCase());
          if (uniqueSuggestions.length >= limit) break;
        }
      }

      return uniqueSuggestions;
    } catch (e) {
      print('Error generating workout suggestions: $e');
      return _getDefaultSuggestions();
    }
  }

  /// Suggest exercises for variety (ones they haven't done recently)
  Future<List<WorkoutSuggestion>> _getVarietySuggestions(
    List<Workout> recentWorkouts,
    Profile? profile,
  ) async {
    final suggestions = <WorkoutSuggestion>[];

    // Get exercises done in the last 30 days
    final recentExercises = recentWorkouts
        .map((w) => w.exerciseName.toLowerCase())
        .toSet();

    // Determine user's fitness level
    final fitnessLevel = profile?.fitnessLevel ?? 'intermediate';
    final userDifficulty = _getFitnessLevelDifficulty(fitnessLevel);

    // Find exercises they haven't done recently
    for (final category in exerciseCategories.keys) {
      final categoryExercises = exerciseCategories[category]!;

      // Find exercises in this category they haven't done
      final untriedExercises = categoryExercises
          .where((exercise) => !recentExercises.contains(exercise.toLowerCase()))
          .toList();

      if (untriedExercises.isNotEmpty) {
        // Pick one exercise from this category at appropriate difficulty
        final suitableExercises = untriedExercises
            .where((exercise) => (exerciseDifficulty[exercise] ?? 3) <= userDifficulty + 1)
            .toList();

        if (suitableExercises.isNotEmpty) {
          final exercise = suitableExercises.first;
          suggestions.add(
            WorkoutSuggestion(
              exerciseName: _capitalizeExerciseName(exercise),
              reason: 'Try something new! You haven\'t done this exercise recently.',
              category: category,
              suggestedSets: 3,
              suggestedReps: _getDefaultRepsForExercise(exercise),
              estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
            ),
          );
        }
      }
    }

    return suggestions;
  }

  /// Suggest progression for recently performed exercises
  List<WorkoutSuggestion> _getProgressionSuggestions(List<Workout> last7DaysWorkouts) {
    final suggestions = <WorkoutSuggestion>[];

    // Group workouts by exercise
    final exerciseGroups = <String, List<Workout>>{};
    for (final workout in last7DaysWorkouts) {
      final exercise = workout.exerciseName.toLowerCase();
      exerciseGroups.putIfAbsent(exercise, () => []).add(workout);
    }

    // For each exercise, suggest progression
    for (final exercise in exerciseGroups.keys) {
      final workouts = exerciseGroups[exercise]!;
      if (workouts.isEmpty) continue;

      // Find the most recent workout for this exercise
      workouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestWorkout = workouts.first;

      // Suggest progression based on recent performance
      if (latestWorkout.weight != null && latestWorkout.weight! > 0) {
        // Weight-based progression
        final suggestedWeight = latestWorkout.weight! * 1.05; // 5% increase
        suggestions.add(
          WorkoutSuggestion(
            exerciseName: _capitalizeExerciseName(exercise),
            reason: 'Great progress! Try increasing the weight from ${latestWorkout.weight}kg to ${suggestedWeight.toStringAsFixed(1)}kg.',
            category: _getExerciseCategory(exercise),
            suggestedSets: latestWorkout.sets,
            suggestedReps: latestWorkout.reps,
            suggestedWeight: suggestedWeight,
            estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
          ),
        );
      } else if (latestWorkout.reps < 15) {
        // Rep-based progression
        final suggestedReps = (latestWorkout.reps * 1.2).round(); // 20% increase
        suggestions.add(
          WorkoutSuggestion(
            exerciseName: _capitalizeExerciseName(exercise),
            reason: 'You\'re getting stronger! Try ${suggestedReps} reps instead of ${latestWorkout.reps}.',
            category: _getExerciseCategory(exercise),
            suggestedSets: latestWorkout.sets,
            suggestedReps: suggestedReps,
            estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
          ),
        );
      }
    }

    return suggestions;
  }

  /// Suggest exercises based on user goals and fitness level
  List<WorkoutSuggestion> _getGoalBasedSuggestions(Profile? profile, List<Workout> recentWorkouts) {
    final suggestions = <WorkoutSuggestion>[];
    final fitnessLevel = profile?.fitnessLevel ?? 'intermediate';

    // Count workouts by category in recent history
    final categoryCounts = <String, int>{};
    for (final workout in recentWorkouts) {
      final category = _getExerciseCategory(workout.exerciseName.toLowerCase());
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    // Find underrepresented categories
    final totalWorkouts = recentWorkouts.length;
    for (final category in exerciseCategories.keys) {
      final count = categoryCounts[category] ?? 0;
      final percentage = totalWorkouts > 0 ? count / totalWorkouts : 0;

      // If this category is underrepresented (< 20% of workouts)
      if (percentage < 0.2) {
        final exercises = exerciseCategories[category]!;
        final suitableExercise = _getSuitableExerciseForLevel(exercises, fitnessLevel);

        if (suitableExercise != null) {
          suggestions.add(
            WorkoutSuggestion(
              exerciseName: _capitalizeExerciseName(suitableExercise),
              reason: 'Balance your routine! Add more ${category.replaceAll('_', ' ')} exercises.',
              category: category,
              suggestedSets: 3,
              suggestedReps: _getDefaultRepsForExercise(suitableExercise),
              estimatedDifficulty: exerciseDifficulty[suitableExercise] ?? 3,
            ),
          );
        }
      }
    }

    return suggestions;
  }

  /// Get default suggestions when analysis fails
  List<WorkoutSuggestion> _getDefaultSuggestions() {
    return [
      WorkoutSuggestion(
        exerciseName: 'Push-ups',
        reason: 'A classic bodyweight exercise for upper body strength.',
        category: 'upper_body',
        suggestedSets: 3,
        suggestedReps: 10,
        estimatedDifficulty: 2,
      ),
      WorkoutSuggestion(
        exerciseName: 'Squats',
        reason: 'Build lower body strength and power.',
        category: 'lower_body',
        suggestedSets: 3,
        suggestedReps: 12,
        estimatedDifficulty: 1,
      ),
      WorkoutSuggestion(
        exerciseName: 'Planks',
        reason: 'Strengthen your core for better stability.',
        category: 'core',
        suggestedSets: 3,
        suggestedReps: 30, // seconds
        estimatedDifficulty: 2,
      ),
    ];
  }

  // Helper methods

  int _getFitnessLevelDifficulty(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advanced':
        return 5;
      default:
        return 3;
    }
  }

  String _getExerciseCategory(String exerciseName) {
    for (final category in exerciseCategories.keys) {
      if (exerciseCategories[category]!.any((ex) => ex.toLowerCase().contains(exerciseName) ||
                                                   exerciseName.contains(ex.toLowerCase()))) {
        return category;
      }
    }
    return 'upper_body'; // default
  }

  String? _getSuitableExerciseForLevel(List<String> exercises, String fitnessLevel) {
    final userDifficulty = _getFitnessLevelDifficulty(fitnessLevel);

    final suitableExercises = exercises
        .where((exercise) => (exerciseDifficulty[exercise] ?? 3) <= userDifficulty)
        .toList();

    return suitableExercises.isNotEmpty ? suitableExercises.first : null;
  }

  int _getDefaultRepsForExercise(String exercise) {
    final category = _getExerciseCategory(exercise);
    switch (category) {
      case 'upper_body':
        return 10;
      case 'lower_body':
        return 12;
      case 'core':
        return 30; // seconds for planks
      case 'cardio':
        return 45; // seconds
      default:
        return 10;
    }
  }

  String _capitalizeExerciseName(String exercise) {
    return exercise.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Workout suggestion data class
class WorkoutSuggestion {
  final String exerciseName;
  final String reason;
  final String category;
  final int suggestedSets;
  final int suggestedReps;
  final double? suggestedWeight;
  final int estimatedDifficulty;

  const WorkoutSuggestion({
    required this.exerciseName,
    required this.reason,
    required this.category,
    required this.suggestedSets,
    required this.suggestedReps,
    this.suggestedWeight,
    required this.estimatedDifficulty,
  });

  String get difficultyLabel {
    switch (estimatedDifficulty) {
      case 1:
      case 2:
        return 'Beginner';
      case 3:
        return 'Intermediate';
      case 4:
      case 5:
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }

  String get categoryLabel {
    return category.replaceAll('_', ' ').toUpperCase();
  }
}