import 'package:cloud_firestore/cloud_firestore.dart';

/// Export all model classes
export 'workout.dart';
export 'checkin.dart';
export 'badge.dart';
export 'streak.dart';
export '../services/fitness_data_service.dart' show FitnessData;
export 'exercise.dart';

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

  // Nutrition preferences
  final int? dailyCalorieGoal; // target daily calories
  final double? proteinGoal; // target protein in grams
  final double? carbGoal; // target carbs in grams
  final double? fatGoal; // target fat in grams
  final List<String> dietaryRestrictions; // ['vegetarian', 'vegan', 'gluten_free', 'dairy_free', etc.]
  final List<String> foodAllergies; // ['nuts', 'dairy', 'eggs', 'soy', etc.]
  final List<String> preferredCuisines; // ['italian', 'mexican', 'asian', etc.]
  final bool trackWaterIntake; // whether to track water consumption
  final int? dailyWaterGoal; // target water intake in ml
  final List<String> mealTimingPreferences; // ['intermittent_fasting', 'grazing', '3_meals', '5_meals']
  final bool enableNutritionReminders; // whether to show nutrition reminders
  final Map<String, int> mealFrequencyGoals; // meal type -> target frequency per week

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
    // Nutrition preferences
    this.dailyCalorieGoal,
    this.proteinGoal,
    this.carbGoal,
    this.fatGoal,
    this.dietaryRestrictions = const [],
    this.foodAllergies = const [],
    this.preferredCuisines = const [],
    this.trackWaterIntake = false,
    this.dailyWaterGoal,
    this.mealTimingPreferences = const [],
    this.enableNutritionReminders = true,
    this.mealFrequencyGoals = const {},
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

  // Nutrition constants
  static const List<String> availableDietaryRestrictions = [
    'vegetarian', 'vegan', 'pescatarian', 'gluten_free', 'dairy_free',
    'nut_free', 'soy_free', 'low_carb', 'keto', 'paleo', 'mediterranean'
  ];

  static const List<String> availableFoodAllergies = [
    'nuts', 'peanuts', 'tree_nuts', 'dairy', 'eggs', 'soy', 'wheat',
    'fish', 'shellfish', 'sesame', 'sulfites'
  ];

  static const List<String> availableCuisines = [
    'american', 'italian', 'mexican', 'chinese', 'japanese', 'indian',
    'thai', 'french', 'greek', 'mediterranean', 'korean', 'vietnamese'
  ];

  static const List<String> availableMealTimings = [
    '3_meals', '5_meals', 'intermittent_fasting', 'grazing', 'carb_backloading'
  ];

  static const Map<String, int> defaultMealFrequencyGoals = {
    'breakfast': 7, // 7 days per week
    'lunch': 7,
    'dinner': 7,
    'snack': 3,
  };

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
      lastUpdated: data['lastUpdated'] is Timestamp
        ? (data['lastUpdated'] as Timestamp).toDate()
        : data['lastUpdated'] is DateTime
          ? data['lastUpdated'] as DateTime
          : data['lastUpdated'] is String
            ? DateTime.tryParse(data['lastUpdated'])
            : null,
      // Nutrition preferences
      dailyCalorieGoal: data['dailyCalorieGoal'] as int?,
      proteinGoal: data['proteinGoal']?.toDouble(),
      carbGoal: data['carbGoal']?.toDouble(),
      fatGoal: data['fatGoal']?.toDouble(),
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      foodAllergies: List<String>.from(data['foodAllergies'] ?? []),
      preferredCuisines: List<String>.from(data['preferredCuisines'] ?? []),
      trackWaterIntake: data['trackWaterIntake'] ?? false,
      dailyWaterGoal: data['dailyWaterGoal'] as int?,
      mealTimingPreferences: List<String>.from(data['mealTimingPreferences'] ?? []),
      enableNutritionReminders: data['enableNutritionReminders'] ?? true,
      mealFrequencyGoals: Map<String, int>.from(data['mealFrequencyGoals'] ?? defaultMealFrequencyGoals),
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
      // Nutrition preferences
      'dailyCalorieGoal': dailyCalorieGoal,
      'proteinGoal': proteinGoal,
      'carbGoal': carbGoal,
      'fatGoal': fatGoal,
      'dietaryRestrictions': dietaryRestrictions,
      'foodAllergies': foodAllergies,
      'preferredCuisines': preferredCuisines,
      'trackWaterIntake': trackWaterIntake,
      'dailyWaterGoal': dailyWaterGoal,
      'mealTimingPreferences': mealTimingPreferences,
      'enableNutritionReminders': enableNutritionReminders,
      'mealFrequencyGoals': mealFrequencyGoals,
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
      // Nutrition preferences
      'dailyCalorieGoal': dailyCalorieGoal,
      'proteinGoal': proteinGoal,
      'carbGoal': carbGoal,
      'fatGoal': fatGoal,
      'dietaryRestrictions': dietaryRestrictions,
      'foodAllergies': foodAllergies,
      'preferredCuisines': preferredCuisines,
      'trackWaterIntake': trackWaterIntake,
      'dailyWaterGoal': dailyWaterGoal,
      'mealTimingPreferences': mealTimingPreferences,
      'enableNutritionReminders': enableNutritionReminders,
      'mealFrequencyGoals': mealFrequencyGoals,
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
    // Nutrition preferences
    int? dailyCalorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    List<String>? dietaryRestrictions,
    List<String>? foodAllergies,
    List<String>? preferredCuisines,
    bool? trackWaterIntake,
    int? dailyWaterGoal,
    List<String>? mealTimingPreferences,
    bool? enableNutritionReminders,
    Map<String, int>? mealFrequencyGoals,
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
      // Nutrition preferences
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      trackWaterIntake: trackWaterIntake ?? this.trackWaterIntake,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      mealTimingPreferences: mealTimingPreferences ?? this.mealTimingPreferences,
      enableNutritionReminders: enableNutritionReminders ?? this.enableNutritionReminders,
      mealFrequencyGoals: mealFrequencyGoals ?? this.mealFrequencyGoals,
    );
  }
}

/// NutritionData - Nutritional information for food items
class NutritionData {
  final double? calories; // kcal
  final double? protein; // grams
  final double? carbs; // grams
  final double? fat; // grams
  final double? fiber; // grams
  final double? sugar; // grams
  final double? sodium; // mg
  final double? potassium; // mg
  final double? calcium; // mg
  final double? iron; // mg
  final double? vitaminC; // mg
  final double? vitaminA; // IU
  final double? cholesterol; // mg
  final double? saturatedFat; // grams
  final double? transFat; // grams

  const NutritionData({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.potassium,
    this.calcium,
    this.iron,
    this.vitaminC,
    this.vitaminA,
    this.cholesterol,
    this.saturatedFat,
    this.transFat,
  });

  // Create from Nutritionix API response
  factory NutritionData.fromNutritionix(Map<String, dynamic> data) {
    return NutritionData(
      calories: data['nf_calories']?.toDouble(),
      protein: data['nf_protein']?.toDouble(),
      carbs: data['nf_total_carbohydrate']?.toDouble(),
      fat: data['nf_total_fat']?.toDouble(),
      fiber: data['nf_dietary_fiber']?.toDouble(),
      sugar: data['nf_sugars']?.toDouble(),
      sodium: data['nf_sodium']?.toDouble(),
      potassium: data['nf_potassium']?.toDouble(),
      calcium: data['nf_calcium']?.toDouble(),
      iron: data['nf_iron']?.toDouble(),
      vitaminC: data['nf_vitamin_c']?.toDouble(),
      vitaminA: data['nf_vitamin_a']?.toDouble(),
      cholesterol: data['nf_cholesterol']?.toDouble(),
      saturatedFat: data['nf_saturated_fat']?.toDouble(),
      transFat: data['nf_trans_fatty_acid']?.toDouble(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'potassium': potassium,
      'calcium': calcium,
      'iron': iron,
      'vitaminC': vitaminC,
      'vitaminA': vitaminA,
      'cholesterol': cholesterol,
      'saturatedFat': saturatedFat,
      'transFat': transFat,
    };
  }

  // Create from Firestore document
  factory NutritionData.fromFirestore(Map<String, dynamic> data) {
    return NutritionData(
      calories: data['calories']?.toDouble(),
      protein: data['protein']?.toDouble(),
      carbs: data['carbs']?.toDouble(),
      fat: data['fat']?.toDouble(),
      fiber: data['fiber']?.toDouble(),
      sugar: data['sugar']?.toDouble(),
      sodium: data['sodium']?.toDouble(),
      potassium: data['potassium']?.toDouble(),
      calcium: data['calcium']?.toDouble(),
      iron: data['iron']?.toDouble(),
      vitaminC: data['vitaminC']?.toDouble(),
      vitaminA: data['vitaminA']?.toDouble(),
      cholesterol: data['cholesterol']?.toDouble(),
      saturatedFat: data['saturatedFat']?.toDouble(),
      transFat: data['transFat']?.toDouble(),
    );
  }

  // Add two nutrition data objects together
  NutritionData operator +(NutritionData other) {
    return NutritionData(
      calories: (calories ?? 0) + (other.calories ?? 0),
      protein: (protein ?? 0) + (other.protein ?? 0),
      carbs: (carbs ?? 0) + (other.carbs ?? 0),
      fat: (fat ?? 0) + (other.fat ?? 0),
      fiber: (fiber ?? 0) + (other.fiber ?? 0),
      sugar: (sugar ?? 0) + (other.sugar ?? 0),
      sodium: (sodium ?? 0) + (other.sodium ?? 0),
      potassium: (potassium ?? 0) + (other.potassium ?? 0),
      calcium: (calcium ?? 0) + (other.calcium ?? 0),
      iron: (iron ?? 0) + (other.iron ?? 0),
      vitaminC: (vitaminC ?? 0) + (other.vitaminC ?? 0),
      vitaminA: (vitaminA ?? 0) + (other.vitaminA ?? 0),
      cholesterol: (cholesterol ?? 0) + (other.cholesterol ?? 0),
      saturatedFat: (saturatedFat ?? 0) + (other.saturatedFat ?? 0),
      transFat: (transFat ?? 0) + (other.transFat ?? 0),
    );
  }

  // Multiply nutrition data by a scalar (for portion adjustments)
  NutritionData operator *(double multiplier) {
    return NutritionData(
      calories: calories != null ? calories! * multiplier : null,
      protein: protein != null ? protein! * multiplier : null,
      carbs: carbs != null ? carbs! * multiplier : null,
      fat: fat != null ? fat! * multiplier : null,
      fiber: fiber != null ? fiber! * multiplier : null,
      sugar: sugar != null ? sugar! * multiplier : null,
      sodium: sodium != null ? sodium! * multiplier : null,
      potassium: potassium != null ? potassium! * multiplier : null,
      calcium: calcium != null ? calcium! * multiplier : null,
      iron: iron != null ? iron! * multiplier : null,
      vitaminC: vitaminC != null ? vitaminC! * multiplier : null,
      vitaminA: vitaminA != null ? vitaminA! * multiplier : null,
      cholesterol: cholesterol != null ? cholesterol! * multiplier : null,
      saturatedFat: saturatedFat != null ? saturatedFat! * multiplier : null,
      transFat: transFat != null ? transFat! * multiplier : null,
    );
  }

  // Get macronutrient percentages (based on calories)
  double get proteinPercentage => protein != null && calories != null && calories! > 0
      ? (protein! * 4 / calories!) * 100 : 0;
  double get carbPercentage => carbs != null && calories != null && calories! > 0
      ? (carbs! * 4 / calories!) * 100 : 0;
  double get fatPercentage => fat != null && calories != null && calories! > 0
      ? (fat! * 9 / calories!) * 100 : 0;

  // Check if nutrition data is empty (all null values)
  bool get isEmpty => calories == null && protein == null && carbs == null && fat == null;

  // Get formatted display values
  String get caloriesDisplay => calories != null ? '${calories!.round()} kcal' : '0 kcal';
  String get proteinDisplay => protein != null ? '${protein!.toStringAsFixed(1)}g' : '0g';
  String get carbsDisplay => carbs != null ? '${carbs!.toStringAsFixed(1)}g' : '0g';
  String get fatDisplay => fat != null ? '${fat!.toStringAsFixed(1)}g' : '0g';
}

/// FoodItem - Individual food item with nutritional data
class FoodItem {
  final String? id;
  final String name;
  final String? brand;
  final double servingSize; // grams
  final String servingUnit; // 'g', 'ml', 'cup', etc.
  final NutritionData nutritionData;
  final String? foodId; // Nutritionix food ID
  final String? imageUrl;
  final List<String> tags; // ['vegetarian', 'gluten_free', etc.]
  final bool isCustom; // true if manually created, false if from API
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodItem({
    this.id,
    required this.name,
    this.brand,
    required this.servingSize,
    this.servingUnit = 'g',
    required this.nutritionData,
    this.foodId,
    this.imageUrl,
    this.tags = const [],
    this.isCustom = false,
    this.createdAt,
    this.updatedAt,
  });

  // Create from Nutritionix API response
  factory FoodItem.fromNutritionix(Map<String, dynamic> data) {
    final foodData = data['food'] ?? data;
    final servingData = foodData['serving_weight_grams'] != null
        ? {'weight': foodData['serving_weight_grams'], 'unit': 'g'}
        : foodData['serving_qty'] != null && foodData['serving_unit'] != null
            ? {'weight': foodData['serving_qty'], 'unit': foodData['serving_unit']}
            : {'weight': 100.0, 'unit': 'g'};

    return FoodItem(
      name: foodData['food_name'] ?? 'Unknown Food',
      brand: foodData['brand_name'],
      servingSize: servingData['weight']?.toDouble() ?? 100.0,
      servingUnit: servingData['unit'] ?? 'g',
      nutritionData: NutritionData.fromNutritionix(foodData),
      foodId: foodData['food_id']?.toString(),
      imageUrl: foodData['photo']?['thumb'],
      tags: List<String>.from(foodData['tags'] ?? []),
      isCustom: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'nutritionData': nutritionData.toFirestore(),
      'foodId': foodId,
      'imageUrl': imageUrl,
      'tags': tags,
      'isCustom': isCustom,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // Create from Firestore document
  factory FoodItem.fromFirestore(Map<String, dynamic> data, String id) {
    return FoodItem(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'],
      servingSize: data['servingSize']?.toDouble() ?? 100.0,
      servingUnit: data['servingUnit'] ?? 'g',
      nutritionData: NutritionData.fromFirestore(data['nutritionData'] ?? {}),
      foodId: data['foodId'],
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      isCustom: data['isCustom'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create custom food item
  factory FoodItem.createCustom({
    required String name,
    String? brand,
    required double servingSize,
    String servingUnit = 'g',
    required NutritionData nutritionData,
    List<String> tags = const [],
  }) {
    return FoodItem(
      name: name,
      brand: brand,
      servingSize: servingSize,
      servingUnit: servingUnit,
      nutritionData: nutritionData,
      tags: tags,
      isCustom: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method
  FoodItem copyWith({
    String? id,
    String? name,
    String? brand,
    double? servingSize,
    String? servingUnit,
    NutritionData? nutritionData,
    String? foodId,
    String? imageUrl,
    List<String>? tags,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      nutritionData: nutritionData ?? this.nutritionData,
      foodId: foodId ?? this.foodId,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get adjusted nutrition data for a specific portion
  NutritionData getNutritionForPortion(double portionSize) {
    final multiplier = portionSize / servingSize;
    return nutritionData * multiplier;
  }

  // Display helpers
  String get displayName => brand != null ? '$brand $name' : name;
  String get servingDisplay => '${servingSize.toStringAsFixed(0)}$servingUnit';
}

/// Meal - Collection of food items consumed at a specific time
class Meal {
  final String? id;
  final String userId;
  final String name;
  final String type; // 'breakfast', 'lunch', 'dinner', 'snack'
  final DateTime dateTime;
  final List<MealFoodItem> foodItems;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Meal({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.dateTime,
    this.foodItems = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Meal types
  static const List<String> mealTypes = [
    'breakfast', 'lunch', 'dinner', 'snack'
  ];

  // Calculate total nutrition for the meal
  NutritionData get totalNutrition {
    return foodItems.fold(
      const NutritionData(),
      (total, item) => total + item.adjustedNutrition,
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'dateTime': dateTime,
      'foodItems': foodItems.map((item) => item.toFirestore()).toList(),
      'notes': notes,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // Create from Firestore document
  factory Meal.fromFirestore(Map<String, dynamic> data, String id) {
    return Meal(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? 'snack',
      dateTime: data['dateTime'] != null
          ? (data['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      foodItems: (data['foodItems'] as List<dynamic>?)
          ?.map((item) => MealFoodItem.fromFirestore(item))
          .toList() ?? [],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create new meal
  factory Meal.create({
    required String userId,
    required String name,
    required String type,
    required DateTime dateTime,
    List<MealFoodItem> foodItems = const [],
    String? notes,
  }) {
    return Meal(
      userId: userId,
      name: name,
      type: type,
      dateTime: dateTime,
      foodItems: foodItems,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method
  Meal copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    DateTime? dateTime,
    List<MealFoodItem>? foodItems,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      foodItems: foodItems ?? this.foodItems,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Add food item to meal
  Meal addFoodItem(MealFoodItem foodItem) {
    return copyWith(foodItems: [...foodItems, foodItem]);
  }

  // Remove food item from meal
  Meal removeFoodItem(String foodItemId) {
    return copyWith(
      foodItems: foodItems.where((item) => item.id != foodItemId).toList(),
    );
  }

  // Update food item in meal
  Meal updateFoodItem(MealFoodItem updatedItem) {
    return copyWith(
      foodItems: foodItems.map((item) =>
        item.id == updatedItem.id ? updatedItem : item
      ).toList(),
    );
  }
}

/// MealFoodItem - Food item within a meal with specific portion
class MealFoodItem {
  final String id;
  final FoodItem foodItem;
  final double portionSize; // in grams or serving units
  final DateTime addedAt;

  const MealFoodItem({
    required this.id,
    required this.foodItem,
    required this.portionSize,
    required this.addedAt,
  });

  // Get adjusted nutrition data for this portion
  NutritionData get adjustedNutrition => foodItem.getNutritionForPortion(portionSize);

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'foodItem': foodItem.toFirestore(),
      'portionSize': portionSize,
      'addedAt': addedAt,
    };
  }

  // Create from Firestore document
  factory MealFoodItem.fromFirestore(Map<String, dynamic> data) {
    return MealFoodItem(
      id: data['id'] ?? '',
      foodItem: FoodItem.fromFirestore(data['foodItem'] ?? {}, data['foodItem']['id'] ?? ''),
      portionSize: data['portionSize']?.toDouble() ?? 100.0,
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create new meal food item
  factory MealFoodItem.create({
    required FoodItem foodItem,
    required double portionSize,
  }) {
    return MealFoodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItem: foodItem,
      portionSize: portionSize,
      addedAt: DateTime.now(),
    );
  }

  // Copy with method
  MealFoodItem copyWith({
    String? id,
    FoodItem? foodItem,
    double? portionSize,
    DateTime? addedAt,
  }) {
    return MealFoodItem(
      id: id ?? this.id,
      foodItem: foodItem ?? this.foodItem,
      portionSize: portionSize ?? this.portionSize,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Recipe - Collection of ingredients with instructions
class Recipe {
  final String? id;
  final String userId;
  final String name;
  final String? description;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<String> tags; // ['vegetarian', 'gluten_free', 'high_protein', etc.]
  final String? imageUrl;
  final NutritionData totalNutrition; // per serving
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Recipe({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.ingredients = const [],
    this.instructions = const [],
    this.servings = 1,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.tags = const [],
    this.imageUrl,
    required this.totalNutrition,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  // Calculate total nutrition from ingredients
  static NutritionData calculateTotalNutrition(List<RecipeIngredient> ingredients, int servings) {
    final total = ingredients.fold(
      const NutritionData(),
      (sum, ingredient) => sum + ingredient.adjustedNutrition,
    );
    // Divide by servings to get per-serving nutrition
    return total * (1.0 / servings);
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'ingredients': ingredients.map((item) => item.toFirestore()).toList(),
      'instructions': instructions,
      'servings': servings,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'tags': tags,
      'imageUrl': imageUrl,
      'totalNutrition': totalNutrition.toFirestore(),
      'isPublic': isPublic,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // Create from Firestore document
  factory Recipe.fromFirestore(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      ingredients: (data['ingredients'] as List<dynamic>?)
          ?.map((item) => RecipeIngredient.fromFirestore(item))
          .toList() ?? [],
      instructions: List<String>.from(data['instructions'] ?? []),
      servings: data['servings'] ?? 1,
      prepTimeMinutes: data['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: data['cookTimeMinutes'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      totalNutrition: NutritionData.fromFirestore(data['totalNutrition'] ?? {}),
      isPublic: data['isPublic'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create new recipe
  factory Recipe.create({
    required String userId,
    required String name,
    String? description,
    List<RecipeIngredient> ingredients = const [],
    List<String> instructions = const [],
    int servings = 1,
    int prepTimeMinutes = 0,
    int cookTimeMinutes = 0,
    List<String> tags = const [],
    String? imageUrl,
    bool isPublic = false,
  }) {
    final totalNutrition = calculateTotalNutrition(ingredients, servings);
    return Recipe(
      userId: userId,
      name: name,
      description: description,
      ingredients: ingredients,
      instructions: instructions,
      servings: servings,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      tags: tags,
      imageUrl: imageUrl,
      totalNutrition: totalNutrition,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method
  Recipe copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<String>? tags,
    String? imageUrl,
    NutritionData? totalNutrition,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      totalNutrition: totalNutrition ?? this.totalNutrition,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get total time in minutes
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  // Get formatted time strings
  String get prepTimeDisplay => prepTimeMinutes > 0 ? '${prepTimeMinutes}min prep' : '';
  String get cookTimeDisplay => cookTimeMinutes > 0 ? '${cookTimeMinutes}min cook' : '';
  String get totalTimeDisplay {
    final total = totalTimeMinutes;
    if (total == 0) return '';
    if (total < 60) return '${total}min';
    final hours = total ~/ 60;
    final minutes = total % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }
}

/// RecipeIngredient - Ingredient within a recipe
class RecipeIngredient {
  final String id;
  final FoodItem foodItem;
  final double amount; // in grams or serving units
  final String? notes; // e.g., "chopped", "diced"
  final DateTime addedAt;

  const RecipeIngredient({
    required this.id,
    required this.foodItem,
    required this.amount,
    this.notes,
    required this.addedAt,
  });

  // Get adjusted nutrition data for this ingredient amount
  NutritionData get adjustedNutrition => foodItem.getNutritionForPortion(amount);

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'foodItem': foodItem.toFirestore(),
      'amount': amount,
      'notes': notes,
      'addedAt': addedAt,
    };
  }

  // Create from Firestore document
  factory RecipeIngredient.fromFirestore(Map<String, dynamic> data) {
    return RecipeIngredient(
      id: data['id'] ?? '',
      foodItem: FoodItem.fromFirestore(data['foodItem'] ?? {}, data['foodItem']['id'] ?? ''),
      amount: data['amount']?.toDouble() ?? 0.0,
      notes: data['notes'],
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create new recipe ingredient
  factory RecipeIngredient.create({
    required FoodItem foodItem,
    required double amount,
    String? notes,
  }) {
    return RecipeIngredient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItem: foodItem,
      amount: amount,
      notes: notes,
      addedAt: DateTime.now(),
    );
  }

  // Copy with method
  RecipeIngredient copyWith({
    String? id,
    FoodItem? foodItem,
    double? amount,
    String? notes,
    DateTime? addedAt,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      foodItem: foodItem ?? this.foodItem,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Health Data Models for Wearable Integration

/// HeartRatePoint - Individual heart rate measurement
class HeartRatePoint {
  final DateTime timestamp;
  final double heartRate; // BPM
  final String? zone; // 'fat-burn', 'cardio', 'peak', etc.

  const HeartRatePoint({
    required this.timestamp,
    required this.heartRate,
    this.zone,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': timestamp,
      'heartRate': heartRate,
      'zone': zone,
    };
  }

  // Create from Firestore document
  factory HeartRatePoint.fromFirestore(Map<String, dynamic> data) {
    return HeartRatePoint(
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      heartRate: data['heartRate']?.toDouble() ?? 0.0,
      zone: data['zone'],
    );
  }

  // Get heart rate zone based on age and resting HR
  String getHeartRateZone(int? age, double? restingHeartRate) {
    if (age == null || restingHeartRate == null) return 'unknown';

    final maxHR = 220 - age;
    final reserve = maxHR - restingHeartRate;

    final percentage = ((heartRate - restingHeartRate) / reserve) * 100;

    if (percentage < 50) return 'warm-up';
    if (percentage < 60) return 'fat-burn';
    if (percentage < 70) return 'aerobic';
    if (percentage < 80) return 'anaerobic';
    if (percentage < 90) return 'maximum';
    return 'peak';
  }
}

/// HeartRateZone - Summary of time spent in each heart rate zone
class HeartRateZone {
  final String zone;
  final Duration duration;
  final double percentage; // Percentage of total workout time

  const HeartRateZone({
    required this.zone,
    required this.duration,
    required this.percentage,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'zone': zone,
      'durationMinutes': duration.inMinutes,
      'percentage': percentage,
    };
  }

  // Create from Firestore document
  factory HeartRateZone.fromFirestore(Map<String, dynamic> data) {
    return HeartRateZone(
      zone: data['zone'] ?? 'unknown',
      duration: Duration(minutes: data['durationMinutes'] ?? 0),
      percentage: data['percentage']?.toDouble() ?? 0.0,
    );
  }
}

/// SleepData - Sleep quality and duration information
class SleepData {
  final DateTime date;
  final Duration totalSleep; // Total sleep duration
  final Duration deepSleep; // Deep sleep duration
  final Duration remSleep; // REM sleep duration
  final Duration lightSleep; // Light sleep duration
  final Duration awakeTime; // Time awake during sleep period
  final int sleepEfficiency; // Percentage (0-100)
  final DateTime? bedTime; // When user went to bed
  final DateTime? wakeTime; // When user woke up

  const SleepData({
    required this.date,
    required this.totalSleep,
    required this.deepSleep,
    required this.remSleep,
    required this.lightSleep,
    required this.awakeTime,
    required this.sleepEfficiency,
    this.bedTime,
    this.wakeTime,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'totalSleepMinutes': totalSleep.inMinutes,
      'deepSleepMinutes': deepSleep.inMinutes,
      'remSleepMinutes': remSleep.inMinutes,
      'lightSleepMinutes': lightSleep.inMinutes,
      'awakeTimeMinutes': awakeTime.inMinutes,
      'sleepEfficiency': sleepEfficiency,
      'bedTime': bedTime,
      'wakeTime': wakeTime,
    };
  }

  // Create from Firestore document
  factory SleepData.fromFirestore(Map<String, dynamic> data) {
    return SleepData(
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date']),
      totalSleep: Duration(minutes: data['totalSleepMinutes'] ?? 0),
      deepSleep: Duration(minutes: data['deepSleepMinutes'] ?? 0),
      remSleep: Duration(minutes: data['remSleepMinutes'] ?? 0),
      lightSleep: Duration(minutes: data['lightSleepMinutes'] ?? 0),
      awakeTime: Duration(minutes: data['awakeTimeMinutes'] ?? 0),
      sleepEfficiency: data['sleepEfficiency'] ?? 0,
      bedTime: data['bedTime'] is Timestamp
          ? (data['bedTime'] as Timestamp).toDate()
          : data['bedTime'] != null ? DateTime.parse(data['bedTime']) : null,
      wakeTime: data['wakeTime'] is Timestamp
          ? (data['wakeTime'] as Timestamp).toDate()
          : data['wakeTime'] != null ? DateTime.parse(data['wakeTime']) : null,
    );
  }

  // Get sleep quality rating (1-5 scale)
  int get sleepQualityRating {
    if (sleepEfficiency >= 85 && deepSleep.inMinutes >= 90) return 5;
    if (sleepEfficiency >= 75 && deepSleep.inMinutes >= 60) return 4;
    if (sleepEfficiency >= 65 && deepSleep.inMinutes >= 30) return 3;
    if (sleepEfficiency >= 55) return 2;
    return 1;
  }

  // Get formatted sleep duration
  String get totalSleepDisplay {
    final hours = totalSleep.inHours;
    final minutes = totalSleep.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

/// GPSRoute - GPS coordinates for outdoor activities
class GPSRoute {
  final List<GPSPoint> points;
  final double totalDistance; // in meters
  final Duration totalTime;
  final double averageSpeed; // m/s
  final double maxSpeed; // m/s
  final double elevationGain; // in meters
  final double elevationLoss; // in meters

  const GPSRoute({
    required this.points,
    required this.totalDistance,
    required this.totalTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.elevationGain,
    required this.elevationLoss,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'points': points.map((point) => point.toFirestore()).toList(),
      'totalDistance': totalDistance,
      'totalTimeMinutes': totalTime.inMinutes,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'elevationGain': elevationGain,
      'elevationLoss': elevationLoss,
    };
  }

  // Create from Firestore document
  factory GPSRoute.fromFirestore(Map<String, dynamic> data) {
    return GPSRoute(
      points: (data['points'] as List<dynamic>?)
          ?.map((point) => GPSPoint.fromFirestore(point))
          .toList() ?? [],
      totalDistance: data['totalDistance']?.toDouble() ?? 0.0,
      totalTime: Duration(minutes: data['totalTimeMinutes'] ?? 0),
      averageSpeed: data['averageSpeed']?.toDouble() ?? 0.0,
      maxSpeed: data['maxSpeed']?.toDouble() ?? 0.0,
      elevationGain: data['elevationGain']?.toDouble() ?? 0.0,
      elevationLoss: data['elevationLoss']?.toDouble() ?? 0.0,
    );
  }
}

/// GPSPoint - Individual GPS coordinate with timestamp
class GPSPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? altitude; // in meters
  final double? speed; // m/s

  const GPSPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
    };
  }

  // Create from Firestore document
  factory GPSPoint.fromFirestore(Map<String, dynamic> data) {
    return GPSPoint(
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      altitude: data['altitude']?.toDouble(),
      speed: data['speed']?.toDouble(),
    );
  }
}

/// HealthData - Unified health data from wearables
class HealthData {
  final DateTime date;
  final int steps;
  final double caloriesBurned; // Active calories
  final double restingHeartRate; // BPM
  final List<HeartRatePoint> heartRatePoints;
  final SleepData? sleepData;
  final double? activeEnergy; // Total active energy in kcal
  final double? basalEnergy; // Basal metabolic rate in kcal
  final double? distance; // Distance traveled in meters
  final String source; // 'healthkit', 'google_fit', 'fitbit', etc.

  const HealthData({
    required this.date,
    required this.steps,
    required this.caloriesBurned,
    required this.restingHeartRate,
    this.heartRatePoints = const [],
    this.sleepData,
    this.activeEnergy,
    this.basalEnergy,
    this.distance,
    this.source = 'unknown',
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'restingHeartRate': restingHeartRate,
      'heartRatePoints': heartRatePoints.map((point) => point.toFirestore()).toList(),
      'sleepData': sleepData?.toFirestore(),
      'activeEnergy': activeEnergy,
      'basalEnergy': basalEnergy,
      'distance': distance,
      'source': source,
    };
  }

  // Create from Firestore document
  factory HealthData.fromFirestore(Map<String, dynamic> data) {
    DateTime date;
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is DateTime) {
      date = data['date'] as DateTime;
    } else if (data['date'] is String) {
      date = DateTime.parse(data['date']);
    } else {
      date = DateTime.now(); // fallback
    }

    return HealthData(
      date: date,
      steps: data['steps'] ?? 0,
      caloriesBurned: data['caloriesBurned']?.toDouble() ?? 0.0,
      restingHeartRate: data['restingHeartRate']?.toDouble() ?? 0.0,
      heartRatePoints: (data['heartRatePoints'] as List<dynamic>?)
          ?.map((point) => HeartRatePoint.fromFirestore(point))
          .toList() ?? [],
      sleepData: data['sleepData'] != null
          ? SleepData.fromFirestore(data['sleepData'])
          : null,
      activeEnergy: data['activeEnergy']?.toDouble(),
      basalEnergy: data['basalEnergy']?.toDouble(),
      distance: data['distance']?.toDouble(),
      source: data['source'] ?? 'unknown',
    );
  }

  // Calculate average heart rate during a time period
  double getAverageHeartRate(DateTime start, DateTime end) {
    final pointsInRange = heartRatePoints.where((point) =>
        point.timestamp.isAfter(start) && point.timestamp.isBefore(end)).toList();

    if (pointsInRange.isEmpty) return 0.0;

    final sum = pointsInRange.fold<double>(0.0, (sum, point) => sum + point.heartRate);
    return sum / pointsInRange.length;
  }

  // Get heart rate zones for a workout period
  List<HeartRateZone> getHeartRateZones(DateTime workoutStart, DateTime workoutEnd, int? age) {
    final workoutPoints = heartRatePoints.where((point) =>
        point.timestamp.isAfter(workoutStart) && point.timestamp.isBefore(workoutEnd)).toList();

    if (workoutPoints.isEmpty) return [];

    final totalDuration = workoutEnd.difference(workoutStart);
    final zoneCounts = <String, int>{};

    for (final point in workoutPoints) {
      final zone = point.getHeartRateZone(age, restingHeartRate);
      zoneCounts[zone] = (zoneCounts[zone] ?? 0) + 1;
    }

    return zoneCounts.entries.map((entry) {
      final duration = Duration(seconds: (entry.value * 10)); // Assuming 10-second intervals
      final percentage = (duration.inSeconds / totalDuration.inSeconds) * 100;
      return HeartRateZone(
        zone: entry.key,
        duration: duration,
        percentage: percentage,
      );
    }).toList();
  }
}