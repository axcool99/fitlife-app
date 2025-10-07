import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'analytics_service.dart';
import 'profile_service.dart';
import 'user_preferences_service.dart';

/// AI Service for generating workout suggestions based on user history and goals
class AIService {
  final AnalyticsService _analyticsService;
  final ProfileService _profileService;
  final UserPreferencesService _preferencesService;

  AIService(this._analyticsService, this._profileService, this._preferencesService);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Track recently added workouts to avoid repetition
  final List<String> _recentlyAddedExercises = [];
  DateTime? _lastSuggestionRefresh;

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
      // Get all user data concurrently
      final results = await Future.wait([
        _profileService.getProfile(),
        _preferencesService.getUserPreferences(),
        _analyticsService.getWorkoutsInRange(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
        _analyticsService.getLast7DaysWorkouts(),
        _analyticsService.getDailyCaloriesBurned(),
        _analyticsService.getAverageSessionDuration(),
        _analyticsService.getCalorieBurnEfficiency(),
      ]);

      final profile = results[0] as Profile?;
      final preferences = results[1] as UserPreferences;
      final recentWorkouts = results[2] as List<Workout>;
      final last7DaysWorkouts = results[3] as List<Workout>;
      final dailyCalories = results[4] as Map<DateTime, double>;
      final sessionDuration = results[5] as Map<DateTime, double>;
      final calorieEfficiency = results[6] as Map<DateTime, double>;

      final analyticsData = {
        'dailyCalories': dailyCalories,
        'sessionDuration': sessionDuration,
        'calorieEfficiency': calorieEfficiency,
        'last7DaysWorkouts': last7DaysWorkouts,
      };

      final suggestions = <WorkoutSuggestion>[];

      // 1. Goal-based suggestions (highest priority)
      final goalSuggestions = await _getGoalBasedSuggestions(
        profile, preferences, recentWorkouts, dailyCalories, sessionDuration, calorieEfficiency
      );
      suggestions.addAll(goalSuggestions);

      // 2. Progressive overload suggestions
      final progressionSuggestions = await _getProgressiveOverloadSuggestions(
        preferences, last7DaysWorkouts, analyticsData
      );
      suggestions.addAll(progressionSuggestions);

      // 3. Recovery-based adjustments
      final recoverySuggestions = await _getRecoveryBasedSuggestions(
        preferences, recentWorkouts, analyticsData
      );
      suggestions.addAll(recoverySuggestions);

      // 4. Variety suggestions (fill remaining slots)
      final varietySuggestions = await _getEnhancedVarietySuggestions(
        preferences, recentWorkouts, analyticsData
      );
      suggestions.addAll(varietySuggestions);

      // Filter and rank suggestions
      final filteredSuggestions = _filterAndRankSuggestions(suggestions, preferences);

      // Limit results and enhance with metadata
      final finalSuggestions = _enhanceSuggestionsWithMetadata(
        filteredSuggestions.take(limit).toList(),
        preferences,
        recentWorkouts
      );

      return finalSuggestions;
    } catch (e) {
      print('Error generating workout suggestions: $e');
      return _getDefaultSuggestions();
    }
  }

  /// Track a recently added workout to avoid repetition in future suggestions
  void trackRecentlyAddedWorkout(String exerciseName) {
    final normalizedExercise = _normalizeExerciseName(exerciseName);
    _recentlyAddedExercises.add(normalizedExercise);

    // Keep only the last 10 exercises to avoid memory issues and allow some repetition over time
    if (_recentlyAddedExercises.length > 10) {
      _recentlyAddedExercises.removeAt(0);
    }

    _lastSuggestionRefresh = DateTime.now();
  }

  /// Check if an exercise was recently added
  bool wasRecentlyAdded(String exerciseName) {
    final normalizedExercise = _normalizeExerciseName(exerciseName);
    return _recentlyAddedExercises.contains(normalizedExercise);
  }

  /// Get fresh workout suggestions, avoiding recently added exercises
  Future<List<WorkoutSuggestion>> getFreshWorkoutSuggestions({int limit = 3}) async {
    // Force refresh by clearing any cached data considerations
    _lastSuggestionRefresh = DateTime.now();
    return getWorkoutSuggestions(limit: limit);
  }

  /// Normalize exercise names for better matching
  String _normalizeExerciseName(String exerciseName) {
    return exerciseName.toLowerCase().trim();
  }

  /// Enhanced goal-based suggestions with detailed analysis
  Future<List<WorkoutSuggestion>> _getGoalBasedSuggestions(
    Profile? profile,
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    Map<DateTime, double> dailyCalories,
    Map<DateTime, double> sessionDuration,
    Map<DateTime, double> calorieEfficiency,
  ) async {
    final suggestions = <WorkoutSuggestion>[];
    final fitnessGoals = preferences.fitnessGoals;

    // Analyze current performance metrics
    final avgCaloriesPerSession = dailyCalories.values.isNotEmpty
        ? dailyCalories.values.reduce((a, b) => a + b) / dailyCalories.length
        : 0.0;

    final avgSessionDuration = sessionDuration.values.isNotEmpty
        ? sessionDuration.values.reduce((a, b) => a + b) / sessionDuration.length
        : 0.0;

    // Goal-specific suggestions
    for (final goal in fitnessGoals) {
      switch (goal) {
        case 'weight_loss':
          suggestions.addAll(_getWeightLossSuggestions(
            preferences, recentWorkouts, avgCaloriesPerSession, avgSessionDuration
          ));
          break;

        case 'muscle_gain':
          suggestions.addAll(_getMuscleGainSuggestions(
            preferences, recentWorkouts, profile
          ));
          break;

        case 'endurance':
          suggestions.addAll(_getEnduranceSuggestions(
            preferences, recentWorkouts, avgSessionDuration
          ));
          break;

        case 'strength':
          suggestions.addAll(_getStrengthSuggestions(
            preferences, recentWorkouts, profile
          ));
          break;

        case 'flexibility':
          suggestions.addAll(_getFlexibilitySuggestions(
            preferences, recentWorkouts
          ));
          break;
      }
    }

    // If no specific goals, provide general fitness suggestions
    if (fitnessGoals.isEmpty || fitnessGoals.contains('general_fitness')) {
      suggestions.addAll(_getGeneralFitnessSuggestions(preferences, recentWorkouts));
    }

    return suggestions;
  }

  /// Weight loss focused suggestions
  List<WorkoutSuggestion> _getWeightLossSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    double avgCalories,
    double avgDuration,
  ) {
    final suggestions = <WorkoutSuggestion>[];

    // Focus on cardio and compound movements for calorie burn
    final cardioExercises = ['burpees', 'mountain climbers', 'jumping jacks', 'high knees'];
    final compoundExercises = ['squats', 'lunges', 'push-ups', 'pull-ups'];

    // Suggest higher rep ranges for cardio
    if (avgDuration < 30) { // Less than 30 minutes average
      final exercise = _selectExerciseFromList(cardioExercises, preferences, recentWorkouts);
      if (exercise != null) {
        suggestions.add(WorkoutSuggestion(
          exerciseName: _capitalizeExerciseName(exercise),
          reason: 'Boost calorie burn with high-intensity cardio to support weight loss goals',
          category: 'cardio',
          suggestedSets: 3,
          suggestedReps: 20,
          estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
          expectedBenefits: ['Increased calorie burn', 'Improved cardiovascular fitness', 'Enhanced metabolism'],
          progressionType: 'time',
          confidenceScore: 0.8,
          recoveryConsideration: 'Keep rest periods short (30-45 seconds) for maximum fat burn',
          requiresEquipment: false,
        ));
      }
    }

    // Suggest compound movements for efficiency
    final compoundExercise = _selectExerciseFromList(compoundExercises, preferences, recentWorkouts);
    if (compoundExercise != null) {
      suggestions.add(WorkoutSuggestion(
        exerciseName: _capitalizeExerciseName(compoundExercise),
        reason: 'Compound exercises burn more calories and build functional strength',
        category: _getExerciseCategory(compoundExercise),
        suggestedSets: 4,
        suggestedReps: 12,
        estimatedDifficulty: exerciseDifficulty[compoundExercise] ?? 3,
        expectedBenefits: ['Higher calorie expenditure', 'Full-body engagement', 'Improved muscle tone'],
        progressionType: 'reps',
        confidenceScore: 0.9,
        progressionData: {'target_increase': 2, 'frequency': 'weekly'},
        recoveryConsideration: 'Focus on controlled movements to prevent injury',
      ));
    }

    return suggestions;
  }

  /// Muscle gain focused suggestions
  List<WorkoutSuggestion> _getMuscleGainSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    Profile? profile,
  ) {
    final suggestions = <WorkoutSuggestion>[];
    final progressionStyle = preferences.progressionStyle;

    // Heavy compound lifts with progressive overload
    final compoundLifts = ['bench press', 'squats', 'deadlifts', 'overhead press'];

    // Calculate appropriate weight progression
    final progressionMultiplier = progressionStyle == 'conservative' ? 1.05 :
                                 progressionStyle == 'moderate' ? 1.1 : 1.15;

    final exercise = _selectExerciseFromList(compoundLifts, preferences, recentWorkouts);
    if (exercise != null) {
      final suggestedWeight = _calculateSuggestedWeight(exercise, recentWorkouts, progressionMultiplier);

      suggestions.add(WorkoutSuggestion(
        exerciseName: _capitalizeExerciseName(exercise),
        reason: 'Heavy compound lifts are essential for muscle growth and strength development',
        category: _getExerciseCategory(exercise),
        suggestedSets: 4,
        suggestedReps: 6,
        suggestedWeight: suggestedWeight,
        estimatedDifficulty: exerciseDifficulty[exercise] ?? 4,
        expectedBenefits: ['Muscle hypertrophy', 'Increased strength', 'Better body composition'],
        progressionType: 'weight',
        confidenceScore: 0.9,
        progressionData: {
          'progression_rate': progressionMultiplier,
          'deload_frequency': 'every_4_weeks',
          'rep_range': '6-8'
        },
        recoveryConsideration: 'Allow 2-3 minutes rest between heavy sets for optimal recovery',
        requiresEquipment: true,
        prerequisites: ['Master proper form', 'Build base strength'],
      ));
    }

    return suggestions;
  }

  /// Endurance focused suggestions
  List<WorkoutSuggestion> _getEnduranceSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    double avgDuration,
  ) {
    final suggestions = <WorkoutSuggestion>[];

    // Circuit training and high reps
    final enduranceExercises = ['push-ups', 'squats', 'lunges', 'planks', 'burpees'];

    if (avgDuration < 45) { // Suggest longer sessions
      final exercise = _selectExerciseFromList(enduranceExercises, preferences, recentWorkouts);
      if (exercise != null) {
        suggestions.add(WorkoutSuggestion(
          exerciseName: _capitalizeExerciseName(exercise),
          reason: 'Higher volume training builds muscular endurance and stamina',
          category: _getExerciseCategory(exercise),
          suggestedSets: 4,
          suggestedReps: 15,
          estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
          expectedBenefits: ['Improved muscular endurance', 'Better stamina', 'Enhanced work capacity'],
          progressionType: 'reps',
          confidenceScore: 0.8,
          progressionData: {'target_increase': 3, 'circuit_style': true},
          recoveryConsideration: 'Keep rest periods to 60 seconds for endurance benefits',
          alternativeExercises: ['bodyweight squats', 'wall push-ups', 'step-ups'],
        ));
      }
    }

    return suggestions;
  }

  /// Strength focused suggestions
  List<WorkoutSuggestion> _getStrengthSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    Profile? profile,
  ) {
    final suggestions = <WorkoutSuggestion>[];

    // Low rep, heavy weight training
    final strengthExercises = ['deadlifts', 'bench press', 'squats', 'overhead press'];

    final exercise = _selectExerciseFromList(strengthExercises, preferences, recentWorkouts);
    if (exercise != null) {
      suggestions.add(WorkoutSuggestion(
        exerciseName: _capitalizeExerciseName(exercise),
        reason: 'Heavy, low-rep training maximizes strength gains and neural adaptations',
        category: _getExerciseCategory(exercise),
        suggestedSets: 5,
        suggestedReps: 5,
        estimatedDifficulty: exerciseDifficulty[exercise] ?? 4,
        expectedBenefits: ['Maximum strength development', 'Neural efficiency', 'Power output'],
        progressionType: 'weight',
        confidenceScore: 0.9,
        progressionData: {
          'rep_range': '3-5',
          'rest_periods': '3-5_minutes',
          'progression_rate': 1.05
        },
        recoveryConsideration: 'Longer rest periods (3-5 minutes) allow full recovery between heavy sets',
        requiresEquipment: true,
        prerequisites: ['Proper form mastery', 'Base strength foundation'],
      ));
    }

    return suggestions;
  }

  /// Flexibility and mobility suggestions
  List<WorkoutSuggestion> _getFlexibilitySuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
  ) {
    final suggestions = <WorkoutSuggestion>[];

    // Mobility and stretching exercises
    final flexibilityExercises = ['planks', 'downward dog', 'cobra stretch', 'hip openers'];

    final exercise = _selectExerciseFromList(flexibilityExercises, preferences, recentWorkouts);
    if (exercise != null) {
      suggestions.add(WorkoutSuggestion(
        exerciseName: _capitalizeExerciseName(exercise),
        reason: 'Flexibility work improves mobility, reduces injury risk, and enhances recovery',
        category: 'flexibility',
        suggestedSets: 3,
        suggestedReps: 30, // seconds
        estimatedDifficulty: exerciseDifficulty[exercise] ?? 2,
        expectedBenefits: ['Improved flexibility', 'Better mobility', 'Injury prevention', 'Enhanced recovery'],
        progressionType: 'time',
        confidenceScore: 0.7,
        recoveryConsideration: 'Hold stretches comfortably without pain',
        requiresEquipment: false,
      ));
    }

    return suggestions;
  }

  /// General fitness suggestions for balanced approach
  List<WorkoutSuggestion> _getGeneralFitnessSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
  ) {
    final suggestions = <WorkoutSuggestion>[];

    // Balanced selection across categories
    final categories = ['upper_body', 'lower_body', 'core', 'cardio'];
    for (final category in categories) {
      if (preferences.hasCategory(category)) {
        final exercises = exerciseCategories[category] ?? [];
        final exercise = _selectExerciseFromList(exercises, preferences, recentWorkouts);
        if (exercise != null) {
          suggestions.add(WorkoutSuggestion(
            exerciseName: _capitalizeExerciseName(exercise),
            reason: 'Maintain balanced fitness across all muscle groups',
            category: category,
            suggestedSets: 3,
            suggestedReps: 12,
            estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
            expectedBenefits: ['Overall fitness improvement', 'Balanced development', 'Injury prevention'],
            progressionType: 'reps',
            confidenceScore: 0.6,
          ));
        }
      }
    }

    return suggestions.take(2).toList(); // Limit to 2 general suggestions
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

  String _getExerciseCategory(String exerciseName) {
    for (final category in exerciseCategories.keys) {
      if (exerciseCategories[category]!.any((ex) => ex.toLowerCase().contains(exerciseName) ||
                                                   exerciseName.contains(ex.toLowerCase()))) {
        return category;
      }
    }
    return 'upper_body'; // default
  }

  String _capitalizeExerciseName(String exercise) {
    return exercise.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Select an exercise from a list based on user preferences and recent workout history
  String? _selectExerciseFromList(
    List<String> exercises,
    UserPreferences preferences,
    List<Workout> recentWorkouts,
  ) {
    if (exercises.isEmpty) return null;

    // Filter by equipment availability
    final availableExercises = exercises.where((exercise) {
      final requiresEquipment = _exerciseRequiresEquipment(exercise);
      return !requiresEquipment || _userHasEquipmentForExercise(preferences, exercise);
    }).toList();

    if (availableExercises.isEmpty) return null;

    // Filter by preferred categories
    final preferredExercises = availableExercises.where((exercise) {
      final category = _getExerciseCategory(exercise);
      return preferences.hasCategory(category);
    }).toList();

    final candidates = preferredExercises.isNotEmpty ? preferredExercises : availableExercises;

    // Avoid recently performed exercises
    final recentExerciseNames = recentWorkouts
        .take(10) // Last 10 workouts
        .map((w) => w.exerciseName.toLowerCase())
        .toSet();

    final freshExercises = candidates.where((exercise) =>
        !recentExerciseNames.contains(exercise.toLowerCase())).toList();

    // If all exercises are recent, use the full list
    final finalCandidates = freshExercises.isNotEmpty ? freshExercises : candidates;

    // Random selection with preference for variety
    finalCandidates.shuffle();
    return finalCandidates.first;
  }

  /// Calculate suggested weight based on recent workouts and progression multiplier
  double _calculateSuggestedWeight(
    String exercise,
    List<Workout> recentWorkouts,
    double progressionMultiplier,
  ) {
    // Find recent workouts for this exercise
    final exerciseWorkouts = recentWorkouts
        .where((w) => w.exerciseName.toLowerCase() == exercise.toLowerCase())
        .toList();

    if (exerciseWorkouts.isEmpty) {
      // Base weight based on exercise difficulty
      final difficulty = exerciseDifficulty[exercise] ?? 3;
      return difficulty <= 2 ? 10.0 : difficulty <= 3 ? 20.0 : 30.0;
    }

    // Get the maximum weight used recently
    final maxWeight = exerciseWorkouts
        .map((w) => w.weight ?? 0.0)
        .reduce((a, b) => a > b ? a : b);

    // Apply progression
    return maxWeight * progressionMultiplier;
  }

  /// Check if an exercise requires equipment
  bool _exerciseRequiresEquipment(String exercise) {
    // Bodyweight exercises
    const bodyweightExercises = [
      'push-ups', 'squats', 'planks', 'crunches', 'lunges', 'burpees',
      'mountain climbers', 'jumping jacks', 'high knees', 'pull-ups',
      'dips', 'planks', 'russian twists', 'bicycle crunches'
    ];

    return !bodyweightExercises.contains(exercise.toLowerCase());
  }

  /// Check if user has equipment for a specific exercise
  bool _userHasEquipmentForExercise(UserPreferences preferences, String exercise) {
    final exerciseLower = exercise.toLowerCase();

    // Equipment mapping for exercises
    final equipmentMap = {
      'bench press': ['barbell', 'dumbbells', 'bench'],
      'deadlifts': ['barbell'],
      'squats': ['barbell', 'dumbbells'],
      'overhead press': ['barbell', 'dumbbells'],
      'rows': ['barbell', 'dumbbells', 'resistance_bands'],
      'bicep curls': ['dumbbells', 'barbell', 'resistance_bands'],
      'tricep extensions': ['dumbbells', 'cable_machine'],
      'chest press': ['dumbbells', 'cable_machine'],
      'lat pulldowns': ['cable_machine', 'resistance_bands'],
      'chest flyes': ['dumbbells', 'cable_machine'],
      'leg press': ['cable_machine'],
      'calf raises': ['dumbbells'],
      'glute bridges': ['bodyweight'],
      'step-ups': ['bench', 'box'],
      'leg curls': ['cable_machine'],
      'leg extensions': ['cable_machine'],
      'bulgarian split squats': ['bench', 'dumbbells'],
    };

    final requiredEquipment = equipmentMap[exerciseLower];
    if (requiredEquipment == null) return true; // Unknown exercise, assume available

    // Check if user has any of the required equipment
    return requiredEquipment.any((equipment) => preferences.hasEquipment(equipment));
  }

  /// Progressive overload suggestions based on user's progression history
  Future<List<WorkoutSuggestion>> _getProgressiveOverloadSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    Map<String, dynamic> analyticsData,
  ) async {
    final suggestions = <WorkoutSuggestion>[];

    // Analyze progression patterns
    final progressionAnalysis = _analyzeProgressionPatterns(recentWorkouts);

    for (final pattern in progressionAnalysis) {
      final exercise = pattern['exercise'] as String;
      final currentWeight = pattern['currentWeight'] as double?;
      final progressionRate = pattern['progressionRate'] as double;

      if (currentWeight != null && progressionRate > 0) {
        final suggestedWeight = currentWeight * (1 + progressionRate);
        final category = _getExerciseCategory(exercise);

        suggestions.add(WorkoutSuggestion(
          exerciseName: _capitalizeExerciseName(exercise),
          reason: 'Progressive overload: Increase weight to continue building strength',
          category: category,
          suggestedSets: 4,
          suggestedReps: 8,
          suggestedWeight: suggestedWeight,
          estimatedDifficulty: exerciseDifficulty[exercise] ?? 4,
          expectedBenefits: ['Continued strength gains', 'Muscle adaptation', 'Progressive improvement'],
          progressionType: 'weight',
          confidenceScore: 0.85,
          progressionData: {
            'current_weight': currentWeight,
            'suggested_increase': progressionRate,
            'next_milestone': suggestedWeight * 1.1
          },
          recoveryConsideration: 'Ensure proper form with heavier weights',
          requiresEquipment: true,
        ));
      }
    }

    return suggestions.take(2).toList(); // Limit to 2 suggestions
  }

  /// Recovery-based suggestions considering recent workout intensity and user fatigue
  Future<List<WorkoutSuggestion>> _getRecoveryBasedSuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    Map<String, dynamic> analyticsData,
  ) async {
    final suggestions = <WorkoutSuggestion>[];

    // Analyze recovery needs
    final recoveryAnalysis = _analyzeRecoveryNeeds(recentWorkouts, analyticsData);

    if (recoveryAnalysis['needsRecovery'] == true) {
      // Suggest lighter recovery workouts
      final recoveryExercises = ['walking', 'light yoga', 'stretching', 'foam rolling'];

      for (final exercise in recoveryExercises.take(2)) {
        suggestions.add(WorkoutSuggestion(
          exerciseName: _capitalizeExerciseName(exercise),
          reason: 'Active recovery to promote healing and prevent overtraining',
          category: 'recovery',
          suggestedSets: 1,
          suggestedReps: 20,
          estimatedDifficulty: 1,
          expectedBenefits: ['Improved recovery', 'Reduced soreness', 'Better performance'],
          progressionType: 'time',
          confidenceScore: 0.75,
          recoveryConsideration: 'Keep intensity low and focus on relaxation',
          requiresEquipment: false,
        ));
      }
    }

    return suggestions;
  }

  /// Enhanced variety suggestions with smart exercise rotation
  Future<List<WorkoutSuggestion>> _getEnhancedVarietySuggestions(
    UserPreferences preferences,
    List<Workout> recentWorkouts,
    Map<String, dynamic> analyticsData,
  ) async {
    final suggestions = <WorkoutSuggestion>[];

    // Find underrepresented muscle groups
    final muscleGroupBalance = _analyzeMuscleGroupBalance(recentWorkouts);

    for (final group in muscleGroupBalance.entries) {
      if (group.value < 0.15) { // Less than 15% of workouts
        final exercises = _getExercisesForMuscleGroup(group.key);
        final exercise = _selectExerciseFromList(exercises, preferences, recentWorkouts);

        if (exercise != null) {
          suggestions.add(WorkoutSuggestion(
            exerciseName: _capitalizeExerciseName(exercise),
            reason: 'Add variety by targeting the ${group.key.replaceAll('_', ' ')} muscle group',
            category: _getExerciseCategory(exercise),
            suggestedSets: 3,
            suggestedReps: 12,
            estimatedDifficulty: exerciseDifficulty[exercise] ?? 3,
            expectedBenefits: ['Balanced development', 'Injury prevention', 'Overall fitness'],
            progressionType: 'reps',
            confidenceScore: 0.7,
            alternativeExercises: exercises.where((e) => e != exercise).take(2).toList(),
          ));
        }
      }
    }

    return suggestions.take(2).toList();
  }

  /// Filter and rank suggestions based on user preferences and constraints
  List<WorkoutSuggestion> _filterAndRankSuggestions(
    List<WorkoutSuggestion> suggestions,
    UserPreferences preferences,
  ) {
    // Filter out disliked exercises and recently added exercises
    final filtered = suggestions.where((suggestion) {
      return !preferences.dislikesExercise(suggestion.exerciseName) &&
             !wasRecentlyAdded(suggestion.exerciseName);
    }).toList();

    // Rank by preference score
    filtered.sort((a, b) {
      final scoreA = _calculateSuggestionScore(a, preferences);
      final scoreB = _calculateSuggestionScore(b, preferences);
      return scoreB.compareTo(scoreA); // Higher scores first
    });

    return filtered.take(5).toList(); // Return top 5
  }

  /// Enhance suggestions with additional metadata
  List<WorkoutSuggestion> _enhanceSuggestionsWithMetadata(
    List<WorkoutSuggestion> suggestions,
    UserPreferences preferences,
    List<Workout> recentWorkouts,
  ) {
    return suggestions.map((suggestion) {
      // Add completion rate data
      final completionRate = preferences.getCompletionRate(suggestion.exerciseName);

      // Calculate last performed date
      final lastPerformed = _findLastPerformedDate(suggestion.exerciseName, recentWorkouts);

      // Calculate times performed
      final timesPerformed = recentWorkouts
          .where((w) => w.exerciseName.toLowerCase() == suggestion.exerciseName.toLowerCase())
          .length;

      // Enhance the reason based on recent activity and context
      final enhancedReason = _enhanceSuggestionReason(
        suggestion.reason,
        suggestion.exerciseName,
        lastPerformed,
        timesPerformed,
        recentWorkouts,
        preferences
      );

      return suggestion.copyWith(
        reason: enhancedReason,
        confidenceScore: (suggestion.confidenceScore * completionRate).clamp(0.0, 1.0),
        lastPerformed: lastPerformed,
        timesPerformed: timesPerformed,
      );
    }).toList();
  }

  /// Enhance suggestion reasons based on context and recent activity
  String _enhanceSuggestionReason(
    String baseReason,
    String exerciseName,
    DateTime? lastPerformed,
    int timesPerformed,
    List<Workout> recentWorkouts,
    UserPreferences preferences,
  ) {
    final now = DateTime.now();
    final daysSinceLastPerformed = lastPerformed != null
        ? now.difference(lastPerformed).inDays
        : null;

    // Check if this exercise was recently added (avoid immediate repetition)
    final wasRecentlyAdded = this.wasRecentlyAdded(exerciseName);

    // Analyze recent workout patterns
    final recentCategories = recentWorkouts
        .take(5) // Last 5 workouts
        .map((w) => _getExerciseCategory(w.exerciseName))
        .toSet();

    final currentCategory = _getExerciseCategory(exerciseName);
    final categoryBalance = recentCategories.contains(currentCategory) ? 'continuing' : 'balancing';

    // Build enhanced reason
    final reasons = <String>[baseReason];

    // Add context based on recent activity
    if (wasRecentlyAdded) {
      reasons.add("Great job completing this recently! Let's build on that momentum.");
    } else if (daysSinceLastPerformed != null) {
      if (daysSinceLastPerformed > 7) {
        reasons.add("It's been ${daysSinceLastPerformed} days since you last did this - perfect time to get back to it!");
      } else if (daysSinceLastPerformed <= 1) {
        reasons.add("You've been consistent with this exercise - let's maintain that streak!");
      }
    }

    // Add variety consideration
    if (categoryBalance == 'balancing') {
      reasons.add("This will help balance your recent focus on ${recentCategories.join(' and ')} exercises.");
    }

    // Add progression insight
    if (timesPerformed > 10) {
      reasons.add("You've mastered the basics - time to focus on proper form and progression.");
    } else if (timesPerformed > 5) {
      reasons.add("You're getting comfortable with this movement - consider increasing intensity.");
    }

    // Add preference-based context
    if (preferences.likesExercise(exerciseName)) {
      reasons.add("Based on your preferences, this is one of your favorite exercises!");
    }

    return reasons.join(' ');
  }

  /// Helper methods for advanced analysis
  List<Map<String, dynamic>> _analyzeProgressionPatterns(List<Workout> workouts) {
    final patterns = <Map<String, dynamic>>[];

    // Group workouts by exercise
    final exerciseGroups = <String, List<Workout>>{};
    for (final workout in workouts) {
      final exercise = workout.exerciseName.toLowerCase();
      exerciseGroups.putIfAbsent(exercise, () => []).add(workout);
    }

    for (final entry in exerciseGroups.entries) {
      if (entry.value.length >= 3) { // Need at least 3 workouts for pattern analysis
        final progressionRate = _calculateProgressionRate(entry.value);
        final currentWeight = entry.value.last.weight;

        patterns.add({
          'exercise': entry.key,
          'currentWeight': currentWeight,
          'progressionRate': progressionRate,
        });
      }
    }

    return patterns;
  }

  Map<String, dynamic> _analyzeRecoveryNeeds(List<Workout> workouts, Map<String, dynamic> analyticsData) {
    // Simple recovery analysis based on recent workout frequency and intensity
    final recentWorkouts = workouts.where((w) =>
        w.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).toList();

    final avgIntensity = recentWorkouts.isNotEmpty
        ? recentWorkouts.map((w) => w.weight ?? 0).reduce((a, b) => a + b) / recentWorkouts.length
        : 0.0;

    final needsRecovery = recentWorkouts.length >= 5 || avgIntensity > 50;

    return {
      'needsRecovery': needsRecovery,
      'recentWorkoutCount': recentWorkouts.length,
      'avgIntensity': avgIntensity,
    };
  }

  Map<String, double> _analyzeMuscleGroupBalance(List<Workout> workouts) {
    final muscleGroups = <String, int>{};
    final totalWorkouts = workouts.length;

    for (final workout in workouts) {
      final category = _getExerciseCategory(workout.exerciseName);
      muscleGroups[category] = (muscleGroups[category] ?? 0) + 1;
    }

    // Convert to percentages
    return muscleGroups.map((key, value) =>
        MapEntry(key, totalWorkouts > 0 ? value / totalWorkouts : 0.0)
    );
  }

  List<String> _getExercisesForMuscleGroup(String muscleGroup) {
    return exerciseCategories[muscleGroup] ?? [];
  }

  double _calculateProgressionRate(List<Workout> workouts) {
    if (workouts.length < 2) return 0.0;

    // Simple linear progression rate
    final sortedWorkouts = workouts..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final firstWeight = sortedWorkouts.first.weight ?? 0.0;
    final lastWeight = sortedWorkouts.last.weight ?? 0.0;

    if (firstWeight == 0.0) return 0.0;

    return (lastWeight - firstWeight) / firstWeight;
  }

  double _calculateSuggestionScore(WorkoutSuggestion suggestion, UserPreferences preferences) {
    double score = suggestion.confidenceScore;

    // Boost score for preferred categories
    if (preferences.hasCategory(suggestion.category)) {
      score += 0.2;
    }

    // Boost score for favorite exercises
    if (preferences.likesExercise(suggestion.exerciseName)) {
      score += 0.3;
    }

    // Penalize for disliked exercises (already filtered out, but just in case)
    if (preferences.dislikesExercise(suggestion.exerciseName)) {
      score -= 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  DateTime? _findLastPerformedDate(String exerciseName, List<Workout> workouts) {
    final exerciseWorkouts = workouts
        .where((w) => w.exerciseName.toLowerCase() == exerciseName.toLowerCase())
        .toList();

    if (exerciseWorkouts.isEmpty) return null;

    exerciseWorkouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return exerciseWorkouts.first.createdAt;
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

  // Enhanced metadata
  final List<String> expectedBenefits;
  final String progressionType; // 'weight', 'reps', 'time', 'complexity'
  final double confidenceScore; // 0.0 to 1.0 - how confident AI is in this suggestion
  final Map<String, dynamic> progressionData; // additional progression info
  final List<String> prerequisites; // exercises user should master first
  final bool requiresEquipment;
  final List<String> alternativeExercises; // alternatives if this doesn't work
  final String recoveryConsideration; // rest needed, soreness expected, etc.
  final DateTime? lastPerformed; // when user last did this exercise
  final int timesPerformed; // how many times user has done this

  const WorkoutSuggestion({
    required this.exerciseName,
    required this.reason,
    required this.category,
    required this.suggestedSets,
    required this.suggestedReps,
    this.suggestedWeight,
    required this.estimatedDifficulty,
    this.expectedBenefits = const [],
    this.progressionType = 'reps',
    this.confidenceScore = 0.5,
    this.progressionData = const {},
    this.prerequisites = const [],
    this.requiresEquipment = false,
    this.alternativeExercises = const [],
    this.recoveryConsideration = '',
    this.lastPerformed,
    this.timesPerformed = 0,
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

  // Get detailed explanation for the suggestion
  String get detailedExplanation {
    final buffer = StringBuffer();
    buffer.writeln('**Why this exercise:** $reason');
    buffer.writeln('**Expected benefits:** ${expectedBenefits.join(", ")}');
    buffer.writeln('**Suggested progression:** $progressionType-based (${suggestedSets} sets × ${suggestedReps} reps)');
    if (suggestedWeight != null) {
      buffer.writeln('**Suggested weight:** ${suggestedWeight}kg');
    }
    if (recoveryConsideration.isNotEmpty) {
      buffer.writeln('**Recovery note:** $recoveryConsideration');
    }
    if (prerequisites.isNotEmpty) {
      buffer.writeln('**Prerequisites:** ${prerequisites.join(", ")}');
    }
    if (alternativeExercises.isNotEmpty) {
      buffer.writeln('**Alternatives:** ${alternativeExercises.take(2).join(", ")}');
    }
    return buffer.toString();
  }

  // Calculate if this is a good suggestion based on user's recent performance
  bool isGoodSuggestion(UserPreferences preferences, List<Workout> recentWorkouts) {
    // Don't suggest exercises user dislikes
    if (preferences.dislikesExercise(exerciseName)) return false;

    // Prioritize exercises user likes
    if (preferences.likesExercise(exerciseName)) return true;

    // Consider completion rate
    final completionRate = preferences.getCompletionRate(exerciseName);
    if (completionRate < 0.3) return false; // Don't suggest exercises user rarely completes

    // Check if recently performed (avoid same exercise too frequently)
    final recentlyPerformed = recentWorkouts.any((w) =>
        w.exerciseName.toLowerCase() == exerciseName.toLowerCase());
    if (recentlyPerformed && timesPerformed > 5) return false;

    return true;
  }

  // Create a copy with updated metadata
  WorkoutSuggestion copyWith({
    String? exerciseName,
    String? reason,
    String? category,
    int? suggestedSets,
    int? suggestedReps,
    double? suggestedWeight,
    int? estimatedDifficulty,
    List<String>? expectedBenefits,
    String? progressionType,
    double? confidenceScore,
    Map<String, dynamic>? progressionData,
    List<String>? prerequisites,
    bool? requiresEquipment,
    List<String>? alternativeExercises,
    String? recoveryConsideration,
    DateTime? lastPerformed,
    int? timesPerformed,
  }) {
    return WorkoutSuggestion(
      exerciseName: exerciseName ?? this.exerciseName,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      suggestedSets: suggestedSets ?? this.suggestedSets,
      suggestedReps: suggestedReps ?? this.suggestedReps,
      suggestedWeight: suggestedWeight ?? this.suggestedWeight,
      estimatedDifficulty: estimatedDifficulty ?? this.estimatedDifficulty,
      expectedBenefits: expectedBenefits ?? this.expectedBenefits,
      progressionType: progressionType ?? this.progressionType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      progressionData: progressionData ?? this.progressionData,
      prerequisites: prerequisites ?? this.prerequisites,
      requiresEquipment: requiresEquipment ?? this.requiresEquipment,
      alternativeExercises: alternativeExercises ?? this.alternativeExercises,
      recoveryConsideration: recoveryConsideration ?? this.recoveryConsideration,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      timesPerformed: timesPerformed ?? this.timesPerformed,
    );
  }
}