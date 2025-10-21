import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ui/components/components.dart';
import 'services/services.dart';
import 'models/models.dart';
import 'main.dart'; // Import for getIt

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with TickerProviderStateMixin {
  final NutritionService _nutritionService = getIt<NutritionService>();
  final ProfileService _profileService = getIt<ProfileService>();
  final UserPreferencesService _userPreferencesService = getIt<UserPreferencesService>();
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final NetworkService _networkService = getIt<NetworkService>();

  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isOnline = true;

  // Futures for async data
  Future<List<Meal>>? _mealsFuture;
  Future<NutritionData>? _dailyNutritionFuture;
  Future<List<Map<String, dynamic>>>? _nutritionTrendsFuture;
  Future<List<Recipe>>? _userRecipesFuture;

  // Search and food data
  final TextEditingController _foodSearchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkConnectivity();
    _setupConnectivityListener();
    _createDemoData(); // Load demo data instead of real data
  }

  @override
  void dispose() {
    _tabController.dispose();
    _foodSearchController.dispose();
    super.dispose();
  }

  void _setupConnectivityListener() {
    _networkService.connectivityStream.listen((result) async {
      await _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await _networkService.isOnline();
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  void _loadData() {
    _loadMeals();
    _loadDailyNutrition();
    _loadNutritionTrends();
    _loadUserRecipes();
  }

  // Temporary method to create demo data
  void _createDemoData() {
    // Demo meals for today
    final demoMeals = [
      Meal.create(
        userId: 'demo_user',
        name: 'Breakfast Bowl',
        type: 'breakfast',
        dateTime: DateTime.now().subtract(const Duration(hours: 8)),
        foodItems: [
          MealFoodItem(
            id: 'demo_oatmeal_item',
            foodItem: FoodItem(
              id: 'demo_oatmeal',
              name: 'Oatmeal',
              brand: 'Generic',
              servingSize: 40,
              servingUnit: 'g',
              nutritionData: const NutritionData(calories: 150, protein: 5, carbs: 27, fat: 3),
              isCustom: false,
            ),
            portionSize: 40,
            addedAt: DateTime.now(),
          ),
          MealFoodItem(
            id: 'demo_banana_item',
            foodItem: FoodItem(
              id: 'demo_banana',
              name: 'Banana',
              brand: 'Generic',
              servingSize: 118,
              servingUnit: 'g',
              nutritionData: const NutritionData(calories: 105, protein: 1.3, carbs: 27, fat: 0.4),
              isCustom: false,
            ),
            portionSize: 118,
            addedAt: DateTime.now(),
          ),
        ],
      ),
      Meal.create(
        userId: 'demo_user',
        name: 'Grilled Chicken Salad',
        type: 'lunch',
        dateTime: DateTime.now().subtract(const Duration(hours: 4)),
        foodItems: [
          MealFoodItem(
            id: 'demo_chicken_item',
            foodItem: FoodItem(
              id: 'demo_chicken',
              name: 'Grilled Chicken Breast',
              brand: 'Generic',
              servingSize: 100,
              servingUnit: 'g',
              nutritionData: const NutritionData(calories: 165, protein: 31, carbs: 0, fat: 3.6),
              isCustom: false,
            ),
            portionSize: 150,
            addedAt: DateTime.now(),
          ),
          MealFoodItem(
            id: 'demo_salad_item',
            foodItem: FoodItem(
              id: 'demo_salad',
              name: 'Mixed Salad Greens',
              brand: 'Generic',
              servingSize: 100,
              servingUnit: 'g',
              nutritionData: const NutritionData(calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2),
              isCustom: false,
            ),
            portionSize: 200,
            addedAt: DateTime.now(),
          ),
        ],
      ),
      Meal.create(
        userId: 'demo_user',
        name: 'Protein Shake',
        type: 'snack',
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        foodItems: [
          MealFoodItem(
            id: 'demo_protein_item',
            foodItem: FoodItem(
              id: 'demo_protein',
              name: 'Whey Protein Powder',
              brand: 'Generic',
              servingSize: 30,
              servingUnit: 'g',
              nutritionData: const NutritionData(calories: 120, protein: 24, carbs: 3, fat: 1.5),
              isCustom: false,
            ),
            portionSize: 30,
            addedAt: DateTime.now(),
          ),
        ],
      ),
    ];

    // Demo nutrition trends for the past 30 days with realistic random variation
    final demoTrends = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecondsSinceEpoch; // Use timestamp as seed

    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));

      // Create more realistic calorie variation using a seeded approach
      final baseCalories = 2000.0;
      final dayVariation = (random + i * 37) % 400 - 200; // -200 to +200 variation
      final weeklyPattern = (i % 7) * 30 - 90; // Weekend eating pattern
      final calories = (baseCalories + dayVariation + weeklyPattern).clamp(1500.0, 2800.0);

      // Calculate macros with some realistic variation
      final proteinPercent = 0.22 + ((random + i * 17) % 10 - 5) / 100; // 17-27%
      final carbPercent = 0.45 + ((random + i * 23) % 15 - 7.5) / 100; // 37.5-52.5%
      final fatPercent = 1.0 - proteinPercent - carbPercent; // Remainder

      demoTrends.add({
        'date': date,
        'calories': calories,
        'protein': (calories * proteinPercent / 4).roundToDouble(), // grams
        'carbs': (calories * carbPercent / 4).roundToDouble(), // grams
        'fat': (calories * fatPercent / 9).roundToDouble(), // grams
        'meals': 2 + ((random + i * 41) % 3), // 2-4 meals per day
      });
    }

    // Override the futures with demo data
    _mealsFuture = Future.value(demoMeals);
    _dailyNutritionFuture = Future.value(
      demoMeals.fold(
        const NutritionData(),
        (total, meal) => total + meal.totalNutrition,
      ) as NutritionData,
    );
    _nutritionTrendsFuture = Future.value(demoTrends);
    _userRecipesFuture = Future.value([]); // No recipes for demo
  }

  void _loadMeals() {
    setState(() {
      _mealsFuture = _nutritionService.getMealsForDate(_selectedDate);
    });
  }

  void _loadDailyNutrition() {
    setState(() {
      _dailyNutritionFuture = _nutritionService.getDailyNutritionSummary(_selectedDate);
    });
  }

  void _loadNutritionTrends() {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    setState(() {
      _nutritionTrendsFuture = _nutritionService.getNutritionTrends(startDate, endDate);
    });
  }

  void _loadUserRecipes() {
    setState(() {
      _userRecipesFuture = _nutritionService.getUserRecipes();
    });
  }

  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _nutritionService.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  Future<void> _addMeal(String type) async {
    final result = await showDialog<Meal?>(
      context: context,
      builder: (context) => AddMealDialog(
        mealType: type,
        selectedDate: _selectedDate,
        onMealAdded: _loadData,
      ),
    );

    if (result != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: FitLifeTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(color: FitLifeTheme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 24),
                  onPressed: () => _changeDate(-1),
                ),
                Text(
                  DateFormat('EEEE, MMM d').format(_selectedDate),
                  style: FitLifeTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 24),
                  onPressed: _selectedDate.isBefore(DateTime.now().add(const Duration(days: 1)))
                      ? () => _changeDate(1)
                      : null,
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Meals'),
              Tab(text: 'Recipes'),
            ],
            labelColor: FitLifeTheme.accentGreen,
            unselectedLabelColor: FitLifeTheme.textSecondary,
            indicatorColor: FitLifeTheme.accentGreen,
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildMealsTab(),
                _buildRecipesTab(),
              ],
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily nutrition summary
          FutureBuilder<NutritionData>(
            future: _dailyNutritionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ShimmerLoading(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: FitLifeTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }

              final nutrition = snapshot.data ?? const NutritionData();
              return NutritionSummaryCard(
                nutrition: nutrition,
                date: _selectedDate,
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Quick Actions',
            style: FitLifeTheme.headingSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  title: 'Add Meal',
                  icon: Icons.restaurant,
                  color: FitLifeTheme.accentGreen,
                  onTap: () => _showAddMealMenu(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCard(
                  title: 'Search Food',
                  icon: Icons.search,
                  color: FitLifeTheme.accentBlue,
                  onTap: () => _showFoodSearch(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Nutrition trends chart
          Text(
            'Nutrition Trends (30 days)',
            style: FitLifeTheme.headingSmall,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _nutritionTrendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ShimmerLoading(
                  child: SizedBox(
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FitLifeTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              }

              final trends = snapshot.data ?? [];
              return NutritionTrendsChart(trends: trends);
            },
          ),

          const SizedBox(height: 24),

          // Macronutrient breakdown
          FutureBuilder<NutritionData>(
            future: _dailyNutritionFuture,
            builder: (context, snapshot) {
              final nutrition = snapshot.data ?? const NutritionData();
              return MacronutrientBreakdownCard(nutrition: nutrition);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealsTab() {
    return FutureBuilder<List<Meal>>(
      future: _mealsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final meals = snapshot.data ?? [];

        if (meals.isEmpty) {
          return EmptyState(
            icon: Icons.book,
            title: 'No recipes saved',
            message: 'Create your first recipe to get started',
            actionButton: ElevatedButton(
              onPressed: () => _showCreateRecipeDialog(),
              child: const Text('Create Recipe'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            return MealCard(
              meal: meal,
              onTap: () => _editMeal(meal),
              onDelete: () => _deleteMeal(meal),
            );
          },
        );
      },
    );
  }

  Widget _buildRecipesTab() {
    return FutureBuilder<List<Recipe>>(
      future: _userRecipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipes = snapshot.data ?? [];

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppInput(
                controller: _foodSearchController,
                hintText: 'Search recipes...',
                prefixIcon: Icons.search,
                onChanged: (value) {
                  // Implement recipe search
                },
              ),
            ),

            Expanded(
              child: recipes.isEmpty
                  ? EmptyState(
                      icon: Icons.menu_book,
                      title: 'No recipes yet',
                      message: 'Create your first recipe to get started',
                      actionButton: ElevatedButton(
                        onPressed: () => _createRecipe(),
                        child: const Text('Create Recipe'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => _viewRecipe(recipe),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddMealMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Meal',
              style: FitLifeTheme.headingSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MealTypeButton(
                    type: 'breakfast',
                    icon: Icons.wb_sunny,
                    onTap: () => _addMeal('breakfast'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MealTypeButton(
                    type: 'lunch',
                    icon: Icons.wb_sunny,
                    onTap: () => _addMeal('lunch'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: MealTypeButton(
                    type: 'dinner',
                    icon: Icons.nightlight,
                    onTap: () => _addMeal('dinner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MealTypeButton(
                    type: 'snack',
                    icon: Icons.restaurant,
                    onTap: () => _addMeal('snack'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scrollController) => FoodSearchBottomSheet(
          onFoodSelected: (food) => _addFoodToMeal(food),
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _addFoodToMeal(FoodItem food) async {
    // Show portion selector and add to current meal
    // Implementation will depend on meal creation flow
  }

  Future<void> _editMeal(Meal meal) async {
    // Navigate to meal editing screen
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _nutritionService.deleteMeal(meal.id!);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete meal: $e')),
        );
      }
    }
  }

  void _showCreateRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateRecipeDialog(),
    );
  }

  void _createRecipe() {
    // Navigate to recipe creation screen
  }

  void _viewRecipe(Recipe recipe) {
    // Navigate to recipe detail screen
  }
}

// Supporting widgets (will be implemented in components)
class NutritionSummaryCard extends StatelessWidget {
  final NutritionData nutrition;
  final DateTime date;

  const NutritionSummaryCard({
    super.key,
    required this.nutrition,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Summary',
            style: FitLifeTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutritionMetric(
                label: 'Calories',
                value: nutrition.caloriesDisplay,
                color: FitLifeTheme.accentGreen,
              ),
              _NutritionMetric(
                label: 'Protein',
                value: nutrition.proteinDisplay,
                color: FitLifeTheme.accentBlue,
              ),
              _NutritionMetric(
                label: 'Carbs',
                value: nutrition.carbsDisplay,
                color: FitLifeTheme.accentPurple,
              ),
              _NutritionMetric(
                label: 'Fat',
                value: nutrition.fatDisplay,
                color: FitLifeTheme.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: FitLifeTheme.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FitLifeTheme.bodySmall.copyWith(
            color: FitLifeTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: FitLifeTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NutritionTrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;

  const NutritionTrendsChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort trends by date to ensure proper ordering
    final sortedTrends = List<Map<String, dynamic>>.from(trends)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Calculate min and max values for better scaling
    final calories = sortedTrends.map((t) => t['calories'] as double).toList();
    final minCalories = calories.reduce((a, b) => a < b ? a : b);
    final maxCalories = calories.reduce((a, b) => a > b ? a : b);
    final padding = (maxCalories - minCalories) * 0.1;

    return AppCard(
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 200,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: FitLifeTheme.dividerColor.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 200,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: FitLifeTheme.bodySmall.copyWith(
                        color: FitLifeTheme.textSecondary,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 7, // Show every week
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedTrends.length) {
                      final date = sortedTrends[index]['date'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.month}/${date.day}',
                          style: FitLifeTheme.bodySmall.copyWith(
                            color: FitLifeTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: FitLifeTheme.dividerColor, width: 1),
                left: BorderSide(color: FitLifeTheme.dividerColor, width: 1),
              ),
            ),
            minX: 0,
            maxX: (sortedTrends.length - 1).toDouble(),
            minY: minCalories - padding,
            maxY: maxCalories + padding,
            lineBarsData: [
              LineChartBarData(
                spots: sortedTrends.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return FlSpot(index.toDouble(), data['calories'] as double);
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: FitLifeTheme.accentPurple,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: FitLifeTheme.accentPurple,
                      strokeWidth: 2,
                      strokeColor: FitLifeTheme.background,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: FitLifeTheme.accentPurple.withOpacity(0.1),
                  gradient: LinearGradient(
                    colors: [
                      FitLifeTheme.accentPurple.withOpacity(0.2),
                      FitLifeTheme.accentPurple.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.spotIndex;
                    if (index >= 0 && index < sortedTrends.length) {
                      final data = sortedTrends[index];
                      final date = data['date'] as DateTime;
                      final calories = data['calories'] as double;
                      return LineTooltipItem(
                        '${date.month}/${date.day}\n${calories.toInt()} cal',
                        FitLifeTheme.bodySmall.copyWith(
                          color: FitLifeTheme.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return null;
                  }).whereType<LineTooltipItem>().toList();
                },
                tooltipBgColor: FitLifeTheme.surfaceColor,
                tooltipBorder: BorderSide(
                  color: FitLifeTheme.dividerColor,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MacronutrientBreakdownCard extends StatelessWidget {
  final NutritionData nutrition;

  const MacronutrientBreakdownCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final proteinPercent = nutrition.proteinPercentage;
    final carbPercent = nutrition.carbPercentage;
    final fatPercent = nutrition.fatPercentage;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macronutrient Breakdown',
            style: FitLifeTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: (proteinPercent * 100).round(),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: FitLifeTheme.accentBlue,
                    borderRadius: proteinPercent == 1.0
                        ? BorderRadius.circular(12)
                        : const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: (carbPercent * 100).round(),
                child: Container(
                  height: 24,
                  color: FitLifeTheme.accentPurple,
                ),
              ),
              Expanded(
                flex: (fatPercent * 100).round(),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: FitLifeTheme.accentOrange,
                    borderRadius: fatPercent == 1.0
                        ? BorderRadius.circular(12)
                        : const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroLabel(
                label: 'Protein',
                percentage: proteinPercent,
                color: FitLifeTheme.accentBlue,
              ),
              _MacroLabel(
                label: 'Carbs',
                percentage: carbPercent,
                color: FitLifeTheme.accentPurple,
              ),
              _MacroLabel(
                label: 'Fat',
                percentage: fatPercent,
                color: FitLifeTheme.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _MacroLabel({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${(percentage * 100).round()}%',
          style: FitLifeTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: FitLifeTheme.bodySmall.copyWith(
            color: FitLifeTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FitLifeTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMealIcon(meal.type),
              color: FitLifeTheme.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: FitLifeTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${meal.foodItems.length} items • ${meal.totalNutrition.caloriesDisplay}',
                  style: FitLifeTheme.bodySmall.copyWith(
                    color: FitLifeTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            color: FitLifeTheme.error,
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny;
      case 'dinner':
        return Icons.nightlight;
      case 'snack':
        return Icons.restaurant;
      default:
        return Icons.restaurant;
    }
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: FitLifeTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              image: recipe.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(recipe.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: recipe.imageUrl == null
                ? Icon(
                    Icons.menu_book,
                    color: FitLifeTheme.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: FitLifeTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${recipe.servings} servings • ${recipe.totalNutrition.caloriesDisplay}',
                  style: FitLifeTheme.bodySmall.copyWith(
                    color: FitLifeTheme.textSecondary,
                  ),
                ),
                Text(
                  recipe.prepTimeDisplay + recipe.cookTimeDisplay,
                  style: FitLifeTheme.bodySmall.copyWith(
                    color: FitLifeTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MealTypeButton extends StatelessWidget {
  final String type;
  final IconData icon;
  final VoidCallback onTap;

  const MealTypeButton({
    super.key,
    required this.type,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: FitLifeTheme.accentGreen.withOpacity(0.1),
        foregroundColor: FitLifeTheme.accentGreen,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            type.capitalize(),
            style: FitLifeTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class AddMealDialog extends StatefulWidget {
  final String mealType;
  final DateTime selectedDate;
  final VoidCallback onMealAdded;

  const AddMealDialog({
    super.key,
    required this.mealType,
    required this.selectedDate,
    required this.onMealAdded,
  });

  @override
  _AddMealDialogState createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final TextEditingController _nameController = TextEditingController();
  final List<MealFoodItem> _foodItems = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.mealType.capitalize()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInput(
            controller: _nameController,
            hintText: 'Meal name',
          ),
          const SizedBox(height: 16),
          if (_foodItems.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: _foodItems.length,
                itemBuilder: (context, index) {
                  final item = _foodItems[index];
                  return Text(item.foodItem.displayName);
                },
              ),
            ),
          ElevatedButton(
            onPressed: () {
              // Show food search
            },
            child: const Text('Add Food'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveMeal,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveMeal() async {
    if (_nameController.text.isEmpty) return;

    try {
      final meal = await getIt<NutritionService>().createMeal(
        name: _nameController.text,
        type: widget.mealType,
        dateTime: widget.selectedDate,
        foodItems: _foodItems,
      );

      widget.onMealAdded();
      Navigator.of(context).pop(meal);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save meal: $e')),
      );
    }
  }
}

class FoodSearchBottomSheet extends StatefulWidget {
  final Function(FoodItem) onFoodSelected;
  final ScrollController scrollController;

  const FoodSearchBottomSheet({
    super.key,
    required this.onFoodSelected,
    required this.scrollController,
  });

  @override
  _FoodSearchBottomSheetState createState() => _FoodSearchBottomSheetState();
}

class _FoodSearchBottomSheetState extends State<FoodSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Search Food',
            style: FitLifeTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _searchController,
            hintText: 'Search for food...',
            prefixIcon: Icons.search,
            onChanged: _searchFoods,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final food = _searchResults[index];
                      return ListTile(
                        title: Text(food.displayName),
                        subtitle: Text(food.nutritionData.caloriesDisplay),
                        onTap: () => widget.onFoodSelected(food),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await getIt<NutritionService>().searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
}

class CreateRecipeDialog extends StatefulWidget {
  const CreateRecipeDialog({super.key});

  @override
  _CreateRecipeDialogState createState() => _CreateRecipeDialogState();
}

class _CreateRecipeDialogState extends State<CreateRecipeDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<RecipeIngredient> _ingredients = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Recipe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInput(
            controller: _nameController,
            hintText: 'Recipe name',
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _descriptionController,
            hintText: 'Description (optional)',
          ),
          const SizedBox(height: 16),
          if (_ingredients.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return Text('${ingredient.foodItem.displayName} - ${ingredient.amount}g');
                },
              ),
            ),
          ElevatedButton(
            onPressed: () {
              // Show ingredient search
            },
            child: const Text('Add Ingredient'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveRecipe,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.isEmpty) return;

    final userId = getIt<NutritionService>().currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      final totalNutrition = _ingredients.isEmpty 
          ? const NutritionData() 
          : _ingredients.fold(
              const NutritionData(),
              (total, ingredient) => total + ingredient.adjustedNutrition,
            );

      final recipe = Recipe(
        id: DateTime.now().toString(),
        userId: userId,
        name: _nameController.text,
        description: _descriptionController.text,
        ingredients: _ingredients,
        totalNutrition: totalNutrition,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await getIt<NutritionService>().saveRecipe(recipe);
      Navigator.of(context).pop();
      // Note: _loadData() is not accessible here, will be handled by parent widget
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
      );
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}