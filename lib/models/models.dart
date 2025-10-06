import 'package:cloud_firestore/cloud_firestore.dart';

/// Export all model classes
export 'workout.dart';
export 'checkin.dart';
export 'badge.dart';
export 'streak.dart';
export '../services/fitness_data_service.dart' show FitnessData;

/// Profile - User profile data model
class Profile {
  final String? id;
  final String displayName;
  final String email;
  final int? dailyCalorieTarget;
  final int? stepGoal;
  final double? height; // in cm
  final double? weight; // in kg
  final int? age;
  final String? fitnessLevel; // beginner, intermediate, advanced
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    this.id,
    required this.displayName,
    required this.email,
    this.dailyCalorieTarget,
    this.stepGoal,
    this.height,
    this.weight,
    this.age,
    this.fitnessLevel,
    this.createdAt,
    this.updatedAt,
  });

  // Default values for new profiles
  static const int defaultDailyCalorieTarget = 2000;
  static const int defaultStepGoal = 10000;
  static const String defaultFitnessLevel = 'intermediate';

  // Fitness level options
  static const List<String> fitnessLevels = [
    'beginner',
    'intermediate',
    'advanced'
  ];

  // Validation ranges
  static const int minAge = 13;
  static const int maxAge = 120;
  static const double minHeight = 100.0; // cm
  static const double maxHeight = 250.0; // cm
  static const double minWeight = 30.0; // kg
  static const double maxWeight = 300.0; // kg
  static const int minCalorieTarget = 800;
  static const int maxCalorieTarget = 5000;
  static const int minStepGoal = 1000;
  static const int maxStepGoal = 50000;

  // Copy with method for updates
  Profile copyWith({
    String? id,
    String? displayName,
    String? email,
    int? dailyCalorieTarget,
    int? stepGoal,
    double? height,
    double? weight,
    int? age,
    String? fitnessLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      stepGoal: stepGoal ?? this.stepGoal,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'dailyCalorieTarget': dailyCalorieTarget ?? defaultDailyCalorieTarget,
      'stepGoal': stepGoal ?? defaultStepGoal,
      'height': height,
      'weight': weight,
      'age': age,
      'fitnessLevel': fitnessLevel ?? defaultFitnessLevel,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // Create from Firestore document
  factory Profile.fromFirestore(Map<String, dynamic> data, String id) {
    return Profile(
      id: id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      dailyCalorieTarget: data['dailyCalorieTarget']?.toInt(),
      stepGoal: data['stepGoal']?.toInt(),
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      age: data['age']?.toInt(),
      fitnessLevel: data['fitnessLevel'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create default profile for new users
  factory Profile.createDefault(String displayName, String email) {
    return Profile(
      displayName: displayName,
      email: email,
      dailyCalorieTarget: defaultDailyCalorieTarget,
      stepGoal: defaultStepGoal,
      fitnessLevel: defaultFitnessLevel,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Validation methods
  bool get isValidDisplayName => displayName.trim().isNotEmpty && displayName.length >= 2;
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool get isValidAge => age == null || (age! >= minAge && age! <= maxAge);
  bool get isValidHeight => height == null || (height! >= minHeight && height! <= maxHeight);
  bool get isValidWeight => weight == null || (weight! >= minWeight && weight! <= maxWeight);
  bool get isValidCalorieTarget => dailyCalorieTarget == null ||
      (dailyCalorieTarget! >= minCalorieTarget && dailyCalorieTarget! <= maxCalorieTarget);
  bool get isValidStepGoal => stepGoal == null ||
      (stepGoal! >= minStepGoal && stepGoal! <= maxStepGoal);
  bool get isValidFitnessLevel => fitnessLevel == null || fitnessLevels.contains(fitnessLevel);

  bool get isValid => isValidDisplayName && isValidEmail && isValidAge &&
      isValidHeight && isValidWeight && isValidCalorieTarget &&
      isValidStepGoal && isValidFitnessLevel;

  // Calculate BMI if height and weight are available
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  String? get bmiCategory {
    if (bmi == null) return null;
    if (bmi! < 18.5) return 'Underweight';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Overweight';
    return 'Obese';
  }

  // Calculate recommended calorie target based on profile
  int get recommendedCalorieTarget {
    if (weight == null || height == null || age == null) {
      return defaultDailyCalorieTarget;
    }

    // Basic BMR calculation using Mifflin-St Jeor Equation
    final bmr = fitnessLevel == 'advanced' ? 10 * weight! + 6.25 * height! - 5 * age! + 5 :
               fitnessLevel == 'beginner' ? 10 * weight! + 6.25 * height! - 5 * age! - 161 :
               10 * weight! + 6.25 * height! - 5 * age! - 5; // intermediate default

    // Activity multiplier based on fitness level
    final activityMultiplier = fitnessLevel == 'advanced' ? 1.725 :
                              fitnessLevel == 'beginner' ? 1.2 : 1.55;

    return (bmr * activityMultiplier).round();
  }
}

/// User preferences for personalized workout recommendations
class UserPreferences {
  final String? id;
  final String userId;

  // Exercise preferences
  final List<String> favoriteExercises;
  final List<String> dislikedExercises;
  final List<String> preferredCategories; // ['upper_body', 'cardio', 'core', etc.]

  // Workout preferences
  final int? preferredWorkoutDuration; // in minutes
  final List<String> preferredWorkoutTimes; // ['morning', 'afternoon', 'evening']
  final int weeklyWorkoutTarget; // target workouts per week

  // Fitness goals
  final List<String> fitnessGoals; // ['weight_loss', 'muscle_gain', 'endurance', 'strength', 'flexibility']

  // Equipment and location
  final List<String> availableEquipment; // ['dumbbells', 'barbell', 'resistance_bands', etc.]
  final String workoutLocation; // 'home', 'gym', 'both'
  final bool hasHomeEquipment;

  // Advanced preferences
  final String progressionStyle; // 'conservative', 'moderate', 'aggressive'
  final bool prefersCompoundMovements;
  final bool avoidsHighImpact;
  final List<String> medicalConditions; // conditions to consider for safety

  // Learning data (updated by AI)
  final Map<String, double> exerciseCompletionRates; // exercise -> completion %
  final Map<String, int> exerciseFrequency; // how often they do each exercise
  final DateTime? lastUpdated;

  const UserPreferences({
    this.id,
    required this.userId,
    this.favoriteExercises = const [],
    this.dislikedExercises = const [],
    this.preferredCategories = const [],
    this.preferredWorkoutDuration,
    this.preferredWorkoutTimes = const [],
    this.weeklyWorkoutTarget = 3,
    this.fitnessGoals = const [],
    this.availableEquipment = const [],
    this.workoutLocation = 'both',
    this.hasHomeEquipment = false,
    this.progressionStyle = 'moderate',
    this.prefersCompoundMovements = true,
    this.avoidsHighImpact = false,
    this.medicalConditions = const [],
    this.exerciseCompletionRates = const {},
    this.exerciseFrequency = const {},
    this.lastUpdated,
  });

  // Default preferences for new users
  static const List<String> defaultCategories = ['upper_body', 'lower_body', 'core'];
  static const List<String> defaultGoals = ['strength', 'endurance'];
  static const List<String> defaultEquipment = ['bodyweight'];

  // Available options
  static const List<String> availableCategories = [
    'upper_body', 'lower_body', 'core', 'cardio', 'flexibility', 'sports'
  ];

  static const List<String> availableGoals = [
    'weight_loss', 'muscle_gain', 'endurance', 'strength', 'flexibility', 'general_fitness'
  ];

  static const List<String> availableEquipmentOptions = [
    'bodyweight', 'dumbbells', 'barbell', 'kettlebell', 'resistance_bands',
    'pull_up_bar', 'bench', 'cable_machine', 'treadmill', 'bike', 'rower'
  ];

  static const List<String> workoutLocations = ['home', 'gym', 'both'];
  static const List<String> progressionStyles = ['conservative', 'moderate', 'aggressive'];
  static const List<String> workoutTimeOptions = ['morning', 'afternoon', 'evening'];

  // Create from Firestore document
  factory UserPreferences.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserPreferences(
      id: docId,
      userId: data['userId'] ?? '',
      favoriteExercises: List<String>.from(data['favoriteExercises'] ?? []),
      dislikedExercises: List<String>.from(data['dislikedExercises'] ?? []),
      preferredCategories: List<String>.from(data['preferredCategories'] ?? defaultCategories),
      preferredWorkoutDuration: data['preferredWorkoutDuration'] as int?,
      preferredWorkoutTimes: List<String>.from(data['preferredWorkoutTimes'] ?? []),
      weeklyWorkoutTarget: data['weeklyWorkoutTarget'] ?? 3,
      fitnessGoals: List<String>.from(data['fitnessGoals'] ?? defaultGoals),
      availableEquipment: List<String>.from(data['availableEquipment'] ?? defaultEquipment),
      workoutLocation: data['workoutLocation'] ?? 'both',
      hasHomeEquipment: data['hasHomeEquipment'] ?? false,
      progressionStyle: data['progressionStyle'] ?? 'moderate',
      prefersCompoundMovements: data['prefersCompoundMovements'] ?? true,
      avoidsHighImpact: data['avoidsHighImpact'] ?? false,
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      exerciseCompletionRates: Map<String, double>.from(data['exerciseCompletionRates'] ?? {}),
      exerciseFrequency: Map<String, int>.from(data['exerciseFrequency'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'favoriteExercises': favoriteExercises,
      'dislikedExercises': dislikedExercises,
      'preferredCategories': preferredCategories,
      'preferredWorkoutDuration': preferredWorkoutDuration,
      'preferredWorkoutTimes': preferredWorkoutTimes,
      'weeklyWorkoutTarget': weeklyWorkoutTarget,
      'fitnessGoals': fitnessGoals,
      'availableEquipment': availableEquipment,
      'workoutLocation': workoutLocation,
      'hasHomeEquipment': hasHomeEquipment,
      'progressionStyle': progressionStyle,
      'prefersCompoundMovements': prefersCompoundMovements,
      'avoidsHighImpact': avoidsHighImpact,
      'medicalConditions': medicalConditions,
      'exerciseCompletionRates': exerciseCompletionRates,
      'exerciseFrequency': exerciseFrequency,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Convert to cache-friendly map (without FieldValue)
  Map<String, dynamic> toCache() {
    return {
      'userId': userId,
      'favoriteExercises': favoriteExercises,
      'dislikedExercises': dislikedExercises,
      'preferredCategories': preferredCategories,
      'preferredWorkoutDuration': preferredWorkoutDuration,
      'preferredWorkoutTimes': preferredWorkoutTimes,
      'weeklyWorkoutTarget': weeklyWorkoutTarget,
      'fitnessGoals': fitnessGoals,
      'availableEquipment': availableEquipment,
      'workoutLocation': workoutLocation,
      'hasHomeEquipment': hasHomeEquipment,
      'progressionStyle': progressionStyle,
      'prefersCompoundMovements': prefersCompoundMovements,
      'avoidsHighImpact': avoidsHighImpact,
      'medicalConditions': medicalConditions,
      'exerciseCompletionRates': exerciseCompletionRates,
      'exerciseFrequency': exerciseFrequency,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // Create default preferences for new users
  factory UserPreferences.createDefault(String userId) {
    return UserPreferences(
      userId: userId,
      preferredCategories: defaultCategories,
      fitnessGoals: defaultGoals,
      availableEquipment: defaultEquipment,
      weeklyWorkoutTarget: 3,
    );
  }

  // Helper methods
  bool hasGoal(String goal) => fitnessGoals.contains(goal);
  bool hasCategory(String category) => preferredCategories.contains(category);
  bool hasEquipment(String equipment) => availableEquipment.contains(equipment);
  bool likesExercise(String exercise) => favoriteExercises.contains(exercise.toLowerCase());
  bool dislikesExercise(String exercise) => dislikedExercises.contains(exercise.toLowerCase());

  // Get completion rate for an exercise (default 0.5 if unknown)
  double getCompletionRate(String exercise) => exerciseCompletionRates[exercise.toLowerCase()] ?? 0.5;

  // Update completion rate (moving average)
  UserPreferences updateCompletionRate(String exercise, bool completed) {
    final currentRate = getCompletionRate(exercise);
    final newRate = (currentRate * 0.8) + (completed ? 0.2 : 0.0); // 80% weight to history, 20% to current

    final updatedRates = Map<String, double>.from(exerciseCompletionRates);
    updatedRates[exercise.toLowerCase()] = newRate;

    return copyWith(exerciseCompletionRates: updatedRates);
  }

  // Copy with method for immutability
  UserPreferences copyWith({
    String? id,
    String? userId,
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
    Map<String, double>? exerciseCompletionRates,
    Map<String, int>? exerciseFrequency,
    DateTime? lastUpdated,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      favoriteExercises: favoriteExercises ?? this.favoriteExercises,
      dislikedExercises: dislikedExercises ?? this.dislikedExercises,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      preferredWorkoutDuration: preferredWorkoutDuration ?? this.preferredWorkoutDuration,
      preferredWorkoutTimes: preferredWorkoutTimes ?? this.preferredWorkoutTimes,
      weeklyWorkoutTarget: weeklyWorkoutTarget ?? this.weeklyWorkoutTarget,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      hasHomeEquipment: hasHomeEquipment ?? this.hasHomeEquipment,
      progressionStyle: progressionStyle ?? this.progressionStyle,
      prefersCompoundMovements: prefersCompoundMovements ?? this.prefersCompoundMovements,
      avoidsHighImpact: avoidsHighImpact ?? this.avoidsHighImpact,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      exerciseCompletionRates: exerciseCompletionRates ?? this.exerciseCompletionRates,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}