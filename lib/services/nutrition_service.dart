import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'cache_service.dart';
import 'network_service.dart';

/// Service for managing nutrition data, meals, and food items
class NutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService;
  final NetworkService _networkService;

  // Nutritionix API configuration
  static const String _nutritionixBaseUrl = 'https://trackapi.nutritionix.com/v2';
  static const String _nutritionixAppId = 'your_app_id_here'; // Replace with actual app ID
  static const String _nutritionixAppKey = 'your_app_key_here'; // Replace with actual app key

  NutritionService(this._cacheService, this._networkService);

  String? get currentUserId => _auth.currentUser?.uid;

  // Nutritionix API headers
  Map<String, String> get _nutritionixHeaders => {
    'x-app-id': _nutritionixAppId,
    'x-app-key': _nutritionixAppKey,
    'Content-Type': 'application/json',
  };

  /// Search for foods using Nutritionix API
  Future<List<FoodItem>> searchFoods(String query, {int limit = 20}) async {
    if (!await _networkService.isOnline()) {
      throw Exception('No internet connection');
    }

    try {
      final response = await http.post(
        Uri.parse('$_nutritionixBaseUrl/natural/nutrients'),
        headers: _nutritionixHeaders,
        body: jsonEncode({
          'query': query,
          'timezone': 'US/Eastern', // You might want to make this dynamic
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List<dynamic>? ?? [];

        return foods.map((food) => FoodItem.fromNutritionix(food)).toList();
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching foods: $e');
      throw Exception('Failed to search foods');
    }
  }

  /// Get instant search results (autocomplete)
  Future<List<Map<String, dynamic>>> instantSearch(String query) async {
    if (!await _networkService.isOnline()) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_nutritionixBaseUrl/search/instant?query=$query'),
        headers: _nutritionixHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['common'] ?? []);
      } else {
        print('Instant search failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in instant search: $e');
      return [];
    }
  }

  /// Create a custom food item
  Future<FoodItem> createCustomFoodItem({
    required String name,
    String? brand,
    required double servingSize,
    String servingUnit = 'g',
    required NutritionData nutritionData,
    List<String> tags = const [],
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final foodItem = FoodItem.createCustom(
      name: name,
      brand: brand,
      servingSize: servingSize,
      servingUnit: servingUnit,
      nutritionData: nutritionData,
      tags: tags,
    );

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('foodItems')
          .add(foodItem.toFirestore());

      final savedFoodItem = foodItem.copyWith(id: docRef.id);

      // Cache the food item
      await _cacheFoodItem(savedFoodItem);

      return savedFoodItem;
    } catch (e) {
      print('Error creating custom food item: $e');
      throw Exception('Failed to create custom food item');
    }
  }

  /// Get user's custom food items
  Future<List<FoodItem>> getCustomFoodItems() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('foodItems')
          .where('isCustom', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FoodItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting custom food items: $e');
      throw Exception('Failed to get custom food items');
    }
  }

  /// Cache a food item locally
  Future<void> _cacheFoodItem(FoodItem foodItem) async {
    try {
      final cachedFoods = await _cacheService.getCachedFoodItems();
      cachedFoods[foodItem.id!] = foodItem.toFirestore();
      await _cacheService.saveFoodItems(cachedFoods);
    } catch (e) {
      print('Error caching food item: $e');
    }
  }

  /// Get cached food items
  Future<List<FoodItem>> getCachedFoodItems() async {
    try {
      final cached = await _cacheService.getCachedFoodItems();
      return cached.values
          .map((data) => FoodItem.fromFirestore(data, data['id']))
          .toList();
    } catch (e) {
      print('Error getting cached food items: $e');
      return [];
    }
  }

  /// Create a new meal
  Future<Meal> createMeal({
    required String name,
    required String type,
    required DateTime dateTime,
    List<MealFoodItem> foodItems = const [],
    String? notes,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meal = Meal.create(
      userId: currentUserId!,
      name: name,
      type: type,
      dateTime: dateTime,
      foodItems: foodItems,
      notes: notes,
    );

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .add(meal.toFirestore());

      final savedMeal = meal.copyWith(id: docRef.id);

      // Cache the meal
      await _cacheMeal(savedMeal);

      return savedMeal;
    } catch (e) {
      print('Error creating meal: $e');
      throw Exception('Failed to create meal');
    }
  }

  /// Get meals for a specific date
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('dateTime')
          .get();

      return querySnapshot.docs
          .map((doc) => Meal.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting meals for date: $e');
      throw Exception('Failed to get meals for date');
    }
  }

  /// Get meals for a date range
  Future<List<Meal>> getMealsForDateRange(DateTime startDate, DateTime endDate) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('dateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Meal.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting meals for date range: $e');
      throw Exception('Failed to get meals for date range');
    }
  }

  /// Update a meal
  Future<Meal> updateMeal(Meal meal) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (meal.id == null) {
      throw Exception('Meal ID is required for update');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .doc(meal.id)
          .update(meal.toFirestore());

      final updatedMeal = meal.copyWith(updatedAt: DateTime.now());

      // Update cache
      await _cacheMeal(updatedMeal);

      return updatedMeal;
    } catch (e) {
      print('Error updating meal: $e');
      throw Exception('Failed to update meal');
    }
  }

  /// Delete a meal
  Future<void> deleteMeal(String mealId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .doc(mealId)
          .delete();

      // Remove from cache
      await _removeMealFromCache(mealId);
    } catch (e) {
      print('Error deleting meal: $e');
      throw Exception('Failed to delete meal');
    }
  }

  /// Cache a meal locally
  Future<void> _cacheMeal(Meal meal) async {
    try {
      final cachedMeals = await _cacheService.getCachedMeals();
      cachedMeals[meal.id!] = meal.toFirestore();
      await _cacheService.saveMeals(cachedMeals);
    } catch (e) {
      print('Error caching meal: $e');
    }
  }

  /// Remove meal from cache
  Future<void> _removeMealFromCache(String mealId) async {
    try {
      final cachedMeals = await _cacheService.getCachedMeals();
      cachedMeals.remove(mealId);
      await _cacheService.saveMeals(cachedMeals);
    } catch (e) {
      print('Error removing meal from cache: $e');
    }
  }

  /// Get cached meals
  Future<List<Meal>> getCachedMeals() async {
    try {
      final cached = await _cacheService.getCachedMeals();
      return cached.values
          .map((data) => Meal.fromFirestore(data, data['id']))
          .toList();
    } catch (e) {
      print('Error getting cached meals: $e');
      return [];
    }
  }

  /// Calculate daily nutrition summary
  Future<NutritionData> getDailyNutritionSummary(DateTime date) async {
    final meals = await getMealsForDate(date);
    NutritionData total = const NutritionData();
    for (final meal in meals) {
      total = total + meal.totalNutrition;
    }
    return total;
  }

  /// Calculate nutrition summary for date range
  Future<NutritionData> getNutritionSummaryForRange(DateTime startDate, DateTime endDate) async {
    final meals = await getMealsForDateRange(startDate, endDate);
    NutritionData total = const NutritionData();
    for (final meal in meals) {
      total = total + meal.totalNutrition;
    }
    return total;
  }

  /// Get nutrition trends over time
  Future<List<Map<String, dynamic>>> getNutritionTrends(DateTime startDate, DateTime endDate) async {
    final meals = await getMealsForDateRange(startDate, endDate);

    // Group meals by date
    final mealsByDate = <DateTime, List<Meal>>{};
    for (final meal in meals) {
      final date = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
      mealsByDate[date] = (mealsByDate[date] ?? [])..add(meal);
    }

    // Calculate daily totals
    final trends = <Map<String, dynamic>>[];
    mealsByDate.forEach((date, dayMeals) {
      final totalNutrition = dayMeals.fold(
        const NutritionData(),
        (total, meal) => total + meal.totalNutrition,
      );

      trends.add({
        'date': date,
        'calories': totalNutrition.calories ?? 0,
        'protein': totalNutrition.protein ?? 0,
        'carbs': totalNutrition.carbs ?? 0,
        'fat': totalNutrition.fat ?? 0,
        'meals': dayMeals.length,
      });
    });

    // Sort by date
    trends.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return trends;
  }

  /// Create a recipe
  Future<Recipe> createRecipe({
    required String name,
    String? description,
    required List<RecipeIngredient> ingredients,
    required List<String> instructions,
    int servings = 1,
    int prepTimeMinutes = 0,
    int cookTimeMinutes = 0,
    List<String> tags = const [],
    String? imageUrl,
    bool isPublic = false,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final recipe = Recipe.create(
      userId: currentUserId!,
      name: name,
      description: description,
      ingredients: ingredients,
      instructions: instructions,
      servings: servings,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      tags: tags,
      imageUrl: imageUrl,
      isPublic: isPublic,
    );

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recipes')
          .add(recipe.toFirestore());

      return recipe.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating recipe: $e');
      throw Exception('Failed to create recipe');
    }
  }

  /// Save a recipe (create or update)
  Future<Recipe> saveRecipe(Recipe recipe) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (recipe.id == null) {
        // Create new recipe
        final docRef = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('recipes')
            .add(recipe.toFirestore());
        return recipe.copyWith(id: docRef.id);
      } else {
        // Update existing recipe
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('recipes')
            .doc(recipe.id)
            .set(recipe.toFirestore());
        return recipe;
      }
    } catch (e) {
      print('Error saving recipe: $e');
      throw Exception('Failed to save recipe');
    }
  }

  /// Get user's recipes
  Future<List<Recipe>> getUserRecipes() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user recipes: $e');
      throw Exception('Failed to get user recipes');
    }
  }

  /// Get public recipes
  Future<List<Recipe>> getPublicRecipes({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting public recipes: $e');
      throw Exception('Failed to get public recipes');
    }
  }

  /// Search recipes by tags or name
  Future<List<Recipe>> searchRecipes(String query, {bool includePublic = true}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // For Firestore, we'll get all recipes and filter client-side
      // In a production app, you might want to use Algolia or similar for better search
      final userRecipes = await getUserRecipes();
      final publicRecipes = includePublic ? await getPublicRecipes(limit: 100) : [];

      final allRecipes = <Recipe>[...userRecipes, ...publicRecipes];

      final searchTerm = query.toLowerCase();
      final filteredRecipes = allRecipes.where((recipe) {
        return recipe.name.toLowerCase().contains(searchTerm) ||
               recipe.tags.any((tag) => tag.toLowerCase().contains(searchTerm)) ||
               (recipe.description?.toLowerCase().contains(searchTerm) ?? false);
      });
      return filteredRecipes.toList();
    } catch (e) {
      print('Error searching recipes: $e');
      throw Exception('Failed to search recipes');
    }
  }

  /// Calculate recommended calorie intake based on user profile
  int calculateRecommendedCalories(Profile profile, UserPreferences preferences) {
    if (profile.age == null || profile.height == null || profile.weight == null) {
      return 2000; // Default
    }

    // Basic Mifflin-St Jeor equation
    final bmr = profile.age! <= 0 ? 2000 : (10 * profile.weight! + 6.25 * profile.height! - 5 * profile.age! + 5);

    // Activity multiplier based on workout frequency
    final activityMultiplier = preferences.weeklyWorkoutTarget <= 1 ? 1.2 :
                              preferences.weeklyWorkoutTarget <= 3 ? 1.375 :
                              preferences.weeklyWorkoutTarget <= 5 ? 1.55 : 1.725;

    final tdee = bmr * activityMultiplier;

    // Adjust based on fitness goals
    if (preferences.fitnessGoals.contains('weight_loss')) {
      return (tdee * 0.8).round(); // 20% deficit
    } else if (preferences.fitnessGoals.contains('muscle_gain')) {
      return (tdee * 1.1).round(); // 10% surplus
    } else {
      return tdee.round(); // Maintenance
    }
  }

  /// Calculate recommended macronutrients
  Map<String, double> calculateRecommendedMacros(int calories, UserPreferences preferences) {
    // Default macro split: 40% carbs, 30% protein, 30% fat
    double carbPercentage = 0.4;
    double proteinPercentage = 0.3;
    double fatPercentage = 0.3;

    // Adjust based on goals
    if (preferences.fitnessGoals.contains('weight_loss')) {
      carbPercentage = 0.35;
      proteinPercentage = 0.35;
      fatPercentage = 0.3;
    } else if (preferences.fitnessGoals.contains('muscle_gain')) {
      carbPercentage = 0.45;
      proteinPercentage = 0.25;
      fatPercentage = 0.3;
    } else if (preferences.fitnessGoals.contains('endurance')) {
      carbPercentage = 0.5;
      proteinPercentage = 0.2;
      fatPercentage = 0.3;
    }

    return {
      'protein': (calories * proteinPercentage / 4), // 4 calories per gram
      'carbs': (calories * carbPercentage / 4), // 4 calories per gram
      'fat': (calories * fatPercentage / 9), // 9 calories per gram
    };
  }

  /// Sync cached data with Firestore
  Future<void> syncNutritionData() async {
    if (currentUserId == null || !await _networkService.isOnline()) {
      return;
    }

    try {
      // Sync cached meals
      final cachedMeals = await getCachedMeals();
      for (final meal in cachedMeals) {
        if (meal.id != null) {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('meals')
              .doc(meal.id)
              .set(meal.toFirestore(), SetOptions(merge: true));
        }
      }

      // Sync cached food items
      final cachedFoods = await getCachedFoodItems();
      for (final food in cachedFoods) {
        if (food.id != null && food.isCustom) {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('foodItems')
              .doc(food.id)
              .set(food.toFirestore(), SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('Error syncing nutrition data: $e');
    }
  }
}