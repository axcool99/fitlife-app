import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'cache_service.dart';
import 'ai_service.dart';

/// Service for managing user preferences with Firestore integration and caching
class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService;

  UserPreferencesService(this._cacheService);

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user preferences, creating default ones if they don't exist
  Future<UserPreferences> getUserPreferences() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Try to get from cache first
      final cached = await _cacheService.loadUserPreferences();
      if (cached != null) {
        return cached;
      }

      // Get from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('preferences')
          .doc('user_preferences')
          .get();

      if (doc.exists) {
        final preferences = UserPreferences.fromFirestore(doc.data()!, doc.id);
        // Cache the result
        await _cacheService.saveUserPreferences(preferences);
        return preferences;
      } else {
        // Create default preferences
        final defaultPreferences = UserPreferences.createDefault(currentUserId!);
        await saveUserPreferences(defaultPreferences);
        return defaultPreferences;
      }
    } catch (e) {
      print('Error getting user preferences: $e');
      // Return default preferences on error
      return UserPreferences.createDefault(currentUserId!);
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('preferences')
          .doc('user_preferences')
          .set(preferences.toFirestore());

      // Update cache
      await _cacheService.saveUserPreferences(preferences);
    } catch (e) {
      print('Error saving user preferences: $e');
      throw Exception('Failed to save user preferences');
    }
  }

  /// Update specific preferences (partial update)
  Future<void> updatePreferences({
    List<String>? favoriteExercises,
    List<String>? dislikedExercises,
    List<String>? preferredCategories,
    int? preferredWorkoutDuration,
    List<String>? preferredWorkoutTimes,
    int? weeklyWorkoutTarget,
    List<String>? fitnessGoals,
    List<String>? availableEquipment,
    String? workoutLocation,
    bool? hasHomeEquipment,
    String? progressionStyle,
    bool? prefersCompoundMovements,
    bool? avoidsHighImpact,
    List<String>? medicalConditions,
  }) async {
    final currentPrefs = await getUserPreferences();

    final updatedPrefs = currentPrefs.copyWith(
      favoriteExercises: favoriteExercises,
      dislikedExercises: dislikedExercises,
      preferredCategories: preferredCategories,
      preferredWorkoutDuration: preferredWorkoutDuration,
      preferredWorkoutTimes: preferredWorkoutTimes,
      weeklyWorkoutTarget: weeklyWorkoutTarget,
      fitnessGoals: fitnessGoals,
      availableEquipment: availableEquipment,
      workoutLocation: workoutLocation,
      hasHomeEquipment: hasHomeEquipment,
      progressionStyle: progressionStyle,
      prefersCompoundMovements: prefersCompoundMovements,
      avoidsHighImpact: avoidsHighImpact,
      medicalConditions: medicalConditions,
    );

    await saveUserPreferences(updatedPrefs);
  }

  /// Update exercise completion tracking
  Future<void> updateExerciseCompletion(String exerciseName, bool completed) async {
    final currentPrefs = await getUserPreferences();
    final updatedPrefs = currentPrefs.updateCompletionRate(exerciseName, completed);

    // Also update exercise frequency
    final updatedFrequency = Map<String, int>.from(updatedPrefs.exerciseFrequency);
    updatedFrequency[exerciseName.toLowerCase()] = (updatedFrequency[exerciseName.toLowerCase()] ?? 0) + 1;

    final finalPrefs = updatedPrefs.copyWith(
      exerciseFrequency: updatedFrequency,
      lastUpdated: DateTime.now(),
    );

    await saveUserPreferences(finalPrefs);
  }

  /// Get exercise recommendations based on preferences
  Future<List<String>> getRecommendedExercises({
    required List<String> availableExercises,
    int limit = 10,
  }) async {
    final preferences = await getUserPreferences();

    // Filter by preferred categories
    var filtered = availableExercises.where((exercise) {
      final category = _getExerciseCategory(exercise);
      return preferences.hasCategory(category);
    }).toList();

    // Prioritize favorite exercises
    final favorites = filtered.where((exercise) => preferences.likesExercise(exercise)).toList();
    final others = filtered.where((exercise) => !preferences.likesExercise(exercise)).toList();

    // Sort by completion rate (higher completion rate = more recommended)
    others.sort((a, b) {
      final rateA = preferences.getCompletionRate(a);
      final rateB = preferences.getCompletionRate(b);
      return rateB.compareTo(rateA); // Higher completion rate first
    });

    // Exclude disliked exercises
    final recommended = [...favorites, ...others]
        .where((exercise) => !preferences.dislikesExercise(exercise))
        .take(limit)
        .toList();

    return recommended;
  }

  /// Check if exercise is suitable based on equipment and preferences
  bool isExerciseSuitable(String exercise, UserPreferences preferences) {
    // Check if user has required equipment
    final requiredEquipment = _getRequiredEquipment(exercise);
    final hasEquipment = requiredEquipment.every((equip) => preferences.hasEquipment(equip));

    if (!hasEquipment) return false;

    // Check workout location preference
    if (preferences.workoutLocation == 'home' && !_isHomeFriendly(exercise)) {
      return false;
    }

    if (preferences.workoutLocation == 'gym' && !_isGymFriendly(exercise)) {
      return false;
    }

    // Check medical conditions
    if (preferences.avoidsHighImpact && _isHighImpact(exercise)) {
      return false;
    }

    return true;
  }

  /// Helper method to get exercise category
  String _getExerciseCategory(String exercise) {
    final exerciseLower = exercise.toLowerCase();

    for (final category in UserPreferences.availableCategories) {
      if (AIService.exerciseCategories[category]?.any((e) => exerciseLower.contains(e)) ?? false) {
        return category;
      }
    }

    return 'upper_body'; // default
  }

  /// Helper method to get required equipment for an exercise
  List<String> _getRequiredEquipment(String exercise) {
    final exerciseLower = exercise.toLowerCase();

    if (exerciseLower.contains('dumbbell') || exerciseLower.contains('curl') || exerciseLower.contains('press')) {
      return ['dumbbells'];
    }

    if (exerciseLower.contains('barbell') || exerciseLower.contains('deadlift') || exerciseLower.contains('squat')) {
      return ['barbell'];
    }

    if (exerciseLower.contains('pull-up') || exerciseLower.contains('chin-up')) {
      return ['pull_up_bar'];
    }

    if (exerciseLower.contains('bench press') || exerciseLower.contains('chest press')) {
      return ['barbell', 'bench'];
    }

    // Bodyweight exercises
    return ['bodyweight'];
  }

  /// Check if exercise is home-friendly
  bool _isHomeFriendly(String exercise) {
    final homeUnfriendly = ['treadmill', 'bike', 'cable_machine', 'leg_press'];
    return !homeUnfriendly.any((term) => exercise.toLowerCase().contains(term));
  }

  /// Check if exercise is gym-friendly
  bool _isGymFriendly(String exercise) {
    // Most exercises work in gym
    return true;
  }

  /// Check if exercise is high impact
  bool _isHighImpact(String exercise) {
    final highImpact = ['burpee', 'jump', 'box jump', 'sprint', 'high knee'];
    return highImpact.any((term) => exercise.toLowerCase().contains(term));
  }
}