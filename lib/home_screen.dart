import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/components/components.dart';
import 'services/services.dart';
import 'models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FitnessDataService _fitnessDataService = FitnessDataService();
  final ProfileService _profileService = ProfileService();
  final CheckInService _checkInService = CheckInService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user display name
  String get userName {
    final user = _auth.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
  }


  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: FitLifeAppBar(
        title: 'Welcome, $userName',
        centerTitle: false, // Left align the title
        automaticallyImplyLeading: false, // No back button
      ),
      body: StreamBuilder<FitnessData?>(
        stream: _fitnessDataService.getTodayFitnessData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading your fitness data...');
          }

          if (snapshot.hasError) {
            return ErrorState(
              title: 'Failed to Load Data',
              message: 'Unable to load your fitness data. Please try again.',
              onRetry: () => setState(() {}),
            );
          }

          final fitnessData = snapshot.data;

          // If no data exists, initialize it
          if (fitnessData == null) {
            _fitnessDataService.initializeTodayData();
            return const LoadingState(message: 'Setting up your fitness data...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                FadeInAnimation(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Track your progress and stay consistent.',
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText.withOpacity(0.8),
                        useCleanStyle: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: FitLifeTheme.spacingXL),

                // Monthly Weight Trend Chart
                FadeInAnimation(
                  child: FutureBuilder<List<CheckIn>>(
                    future: _checkInService.getRecentCheckIns(days: 7),
                    builder: (context, weightSnapshot) {
                      if (weightSnapshot.connectionState == ConnectionState.waiting) {
                        return AppCard(
                          useCleanStyle: true,
                          child: Padding(
                            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  'Weight Trend',
                                  type: AppTextType.headingSmall,
                                  color: FitLifeTheme.primaryText,
                                  useCleanStyle: true,
                                ),
                                const SizedBox(height: FitLifeTheme.spacingL),
                                const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: FitLifeTheme.accentGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final weightData = weightSnapshot.data ?? [];
                      final hasRecentCheckIns = weightData.isNotEmpty;

                      return AppCard(
                        useCleanStyle: true,
                        child: Padding(
                          padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppText(
                                      'Weight Trend',
                                      type: AppTextType.headingSmall,
                                      color: FitLifeTheme.primaryText,
                                      useCleanStyle: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FitLifeTheme.spacingL),
                              if (hasRecentCheckIns) ...[
                                SizedBox(
                                  height: 100,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: false), // Transparent background, no grid lines
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false), // Hide Y-axis labels for clean look
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              // Calculate the actual date for this data point
                                              // i=0 is 6 days ago, i=6 is today
                                              final daysAgo = 6 - value.toInt();
                                              final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
                                              final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                                              final dayName = dayNames[targetDate.weekday % 7]; // weekday is 1-7 (Mon-Sun), adjust for array index

                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: AppText(
                                                  dayName,
                                                  type: AppTextType.bodySmall,
                                                  color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                  useCleanStyle: true,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false), // No border around chart
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _generateWeightChartData(weightData), // Data points sorted by date
                                          isCurved: true, // Smooth curved line for better visual appeal
                                          color: FitLifeTheme.accentGreen, // Line color matches theme
                                          barWidth: 3, // Line thickness
                                          dotData: FlDotData(
                                            show: true, // Show dots at each check-in point
                                            getDotPainter: (spot, percent, barData, index) =>
                                                FlDotCirclePainter(
                                                  radius: 4, // Small dot size
                                                  color: FitLifeTheme.accentBlue, // Dot color for check-in points
                                                  strokeWidth: 2,
                                                  strokeColor: FitLifeTheme.surfaceColor, // Subtle border
                                                ),
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true, // Enable gradient fill under the line
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                FitLifeTheme.accentGreen.withOpacity(0.3), // Semi-transparent at top
                                                FitLifeTheme.accentGreen.withOpacity(0.0), // Fully transparent at bottom
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Empty state when no check-ins in last 30 days
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: FitLifeTheme.spacingXL),
                                    child: AppText(
                                      'No check-ins this week',
                                      type: AppTextType.bodyMedium,
                                      color: FitLifeTheme.primaryText.withOpacity(0.6),
                                      useCleanStyle: true,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: FitLifeTheme.spacingXL),

                // Weekly Progress Chart
                FadeInAnimation(
                  child: FutureBuilder<List<FitnessData>>(
                    future: _fitnessDataService.getWeeklyData(),
                    builder: (context, weeklySnapshot) {
                      if (weeklySnapshot.connectionState == ConnectionState.waiting) {
                        return AppCard(
                          useCleanStyle: true,
                          child: Padding(
                            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  'Weekly Activity',
                                  type: AppTextType.headingSmall,
                                  color: FitLifeTheme.primaryText,
                                  useCleanStyle: true,
                                ),
                                const SizedBox(height: FitLifeTheme.spacingL),
                                const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: FitLifeTheme.accentGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final weeklyData = weeklySnapshot.data ?? [];
                      final chartData = _generateChartData(weeklyData);

                      return AppCard(
                        useCleanStyle: true,
                        child: Padding(
                          padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppText(
                                      'Weekly Activity',
                                      type: AppTextType.headingSmall,
                                      color: FitLifeTheme.primaryText,
                                      useCleanStyle: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FitLifeTheme.spacingL),
                              SizedBox(
                                height: 100,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            // Calculate the actual day for this data point
                                            // i=0 is 6 days ago, i=6 is today
                                            final daysAgo = 6 - value.toInt();
                                            final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
                                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                            final dayName = dayNames[targetDate.weekday - 1]; // weekday is 1-7 (Mon-Sun)

                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: AppText(
                                                dayName,
                                                type: AppTextType.bodySmall,
                                                color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                useCleanStyle: true,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: chartData,
                                        isCurved: true,
                                        color: FitLifeTheme.accentGreen,
                                        barWidth: 3,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) =>
                                              FlDotCirclePainter(
                                                radius: 4,
                                                color: FitLifeTheme.accentGreen,
                                                strokeWidth: 2,
                                                strokeColor: FitLifeTheme.surfaceColor,
                                              ),
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: FitLifeTheme.accentGreen.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: FitLifeTheme.spacingXL),

                // Today's Summary Section Heading
                FadeInAnimation(
                  child: AppText(
                    "Today's Summary",
                    type: AppTextType.headingMedium,
                    color: FitLifeTheme.primaryText,
                    useCleanStyle: true,
                  ),
                ),

                const SizedBox(height: FitLifeTheme.spacingL),

                // Summary Cards
                FadeInAnimation(
                  child: StreamBuilder<Profile?>(
                    stream: _profileService.getProfileStream(),
                    builder: (context, profileSnapshot) {
                      final profile = profileSnapshot.data;

                      return Column(
                        children: [
                          // Workouts Completed Card (Full Width)
                          Container(
                            margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingM),
                            child: AppCard(
                              useCleanStyle: true,
                              child: Padding(
                                padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppText(
                                            'Workouts Completed Today',
                                            type: AppTextType.bodySmall,
                                            color: FitLifeTheme.primaryText.withOpacity(0.8),
                                            useCleanStyle: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: FitLifeTheme.spacingXS),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          color: FitLifeTheme.accentGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: FitLifeTheme.spacingXS),
                                        Expanded(
                                          child: AppText(
                                            fitnessData.workoutsCompleted.toString(),
                                            type: AppTextType.headingSmall,
                                            color: FitLifeTheme.primaryText,
                                            useCleanStyle: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Calories Burned Card (Full Width)
                          Container(
                            margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingM),
                            child: AppCard(
                              useCleanStyle: true,
                              child: Padding(
                                padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      'Calories Burned Today',
                                      type: AppTextType.bodySmall,
                                      color: FitLifeTheme.primaryText.withOpacity(0.8),
                                      useCleanStyle: true,
                                    ),
                                    const SizedBox(height: FitLifeTheme.spacingXS),
                                    // Current value display (large text)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          color: FitLifeTheme.accentBlue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: FitLifeTheme.spacingXS),
                                        Expanded(
                                          child: AppText(
                                            '${fitnessData.caloriesBurned} kcal',
                                            type: AppTextType.headingSmall,
                                            color: FitLifeTheme.primaryText,
                                            useCleanStyle: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Progress indicator - consistent styling across all metric cards
                                    // Uses grey divider color for track and green accent for progress fill
                                    const SizedBox(height: FitLifeTheme.spacingXS),
                                    LinearProgressIndicator(
                                      value: profile?.dailyCalorieTarget != null
                                          ? (fitnessData.caloriesBurned / profile!.dailyCalorieTarget!).clamp(0.0, 1.0)
                                          : 0.0, // Show empty progress when no goal is set
                                      backgroundColor: FitLifeTheme.dividerColor,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FitLifeTheme.accentGreen, // Consistent green progress fill across all cards
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Second row: Steps Walked (full width)
                          AppCard(
                            useCleanStyle: true,
                            child: Padding(
                              padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    'Steps Walked Today',
                                    type: AppTextType.bodySmall,
                                    color: FitLifeTheme.primaryText.withOpacity(0.8),
                                    useCleanStyle: true,
                                  ),
                                  const SizedBox(height: FitLifeTheme.spacingXS),
                                  // Current value display (large text)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        color: FitLifeTheme.highlightPink,
                                        size: 20,
                                      ),
                                      const SizedBox(width: FitLifeTheme.spacingXS),
                                      Expanded(
                                        child: AppText(
                                          '${fitnessData.stepsCount} steps',
                                          type: AppTextType.headingSmall,
                                          color: FitLifeTheme.primaryText,
                                          useCleanStyle: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Progress indicator - consistent styling across all metric cards
                                  // Uses grey divider color for track and green accent for progress fill
                                  const SizedBox(height: FitLifeTheme.spacingXS),
                                  LinearProgressIndicator(
                                    value: profile?.stepGoal != null
                                        ? (fitnessData.stepsCount / profile!.stepGoal!).clamp(0.0, 1.0)
                                        : 0.0, // Show empty progress when no goal is set
                                    backgroundColor: FitLifeTheme.dividerColor, // Consistent grey track color
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      FitLifeTheme.highlightPink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: FitLifeTheme.spacingXL),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Generate chart data from weekly weight check-ins
  /// Data is filtered for last 7 days, sorted by date, and mapped to (date → weight)
  /// If multiple check-ins exist for the same day, uses the latest one
  List<FlSpot> _generateWeightChartData(List<CheckIn> checkIns) {
    List<FlSpot> spots = [];

    // Create spots for each day of the last 7 days
    // i=0 represents 6 days ago, i=6 represents today
    for (int i = 0; i < 7; i++) {
      final targetDate = DateTime.now().subtract(Duration(days: 6 - i));

      // Find all check-ins for this specific day
      final dayCheckIns = checkIns.where((checkIn) {
        return checkIn.date.year == targetDate.year &&
               checkIn.date.month == targetDate.month &&
               checkIn.date.day == targetDate.day;
      }).toList();

      double value = 0.0;
      if (dayCheckIns.isNotEmpty) {
        // If multiple check-ins on same day, use the latest one (highest timestamp)
        dayCheckIns.sort((a, b) => b.date.compareTo(a.date)); // Sort descending by time
        value = dayCheckIns.first.weight; // Use the most recent check-in for the day
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  /// Generate chart data from weekly fitness data
  List<FlSpot> _generateChartData(List<FitnessData> weeklyData) {
    List<FlSpot> spots = [];

    // Create spots for each day of the week
    for (int i = 0; i < 7; i++) {
      final targetDate = DateTime.now().subtract(Duration(days: 6 - i));
      final dayData = weeklyData.where((data) {
        return data.date.year == targetDate.year &&
               data.date.month == targetDate.month &&
               data.date.day == targetDate.day;
      }).toList();

      double value = 0.0;
      if (dayData.isNotEmpty) {
        // Use workouts completed as the chart metric
        value = dayData.first.workoutsCompleted.toDouble();
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  /// Get mood color for UI
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Good': return FitLifeTheme.accentGreen;
      case 'Okay': return FitLifeTheme.accentBlue;
      case 'Bad': return FitLifeTheme.highlightPink;
      default: return FitLifeTheme.primaryText;
    }
  }

  /// Get mood icon for UI
  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Good': return Icons.sentiment_very_satisfied;
      case 'Okay': return Icons.sentiment_satisfied;
      case 'Bad': return Icons.sentiment_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  /// Format check-in date for display
  String _formatCheckInDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkInDate = DateTime(date.year, date.month, date.day);

    if (checkInDate == today) {
      return 'Today';
    } else if (checkInDate == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(checkInDate).inDays;
      if (difference <= 7) {
        return '$difference days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    }
  }
}