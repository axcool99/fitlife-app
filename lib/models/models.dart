import 'package:cloud_firestore/cloud_firestore.dart';

/// Export all model classes
export 'workout.dart';
export 'checkin.dart';
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