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
  final AnalyticsService _analyticsService = AnalyticsService();
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
                                  Icon(
                                    Icons.monitor_weight,
                                    color: FitLifeTheme.accentOrange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: FitLifeTheme.spacingS),
                                  AppText(
                                    'Weight Trend',
                                    type: AppTextType.bodyLarge,
                                    color: FitLifeTheme.primaryText,
                                    useCleanStyle: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: FitLifeTheme.spacingL),
                              if (hasRecentCheckIns) ...[
                                SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: 5,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: FitLifeTheme.dividerColor,
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              final dayIndex = value.toInt();
                                              if (dayIndex >= 0 && dayIndex < 7) {
                                                final date = DateTime.now().subtract(Duration(days: 6 - dayIndex));
                                                final weekday = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(
                                                    weekday,
                                                    style: TextStyle(
                                                      color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 20,
                                            reservedSize: 50,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                '${value.toInt()}kg',
                                                style: TextStyle(
                                                  color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _generateWeightChartData(weightData),
                                          isCurved: true,
                                          color: FitLifeTheme.accentOrange,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: FitLifeTheme.accentOrange,
                                                strokeWidth: 2,
                                                strokeColor: FitLifeTheme.background,
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: FitLifeTheme.accentOrange.withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        handleBuiltInTouches: false,
                                        getTouchedSpotIndicator: (barData, spotIndexes) {
                                          return spotIndexes.map((spotIndex) {
                                            return TouchedSpotIndicatorData(
                                              FlLine(color: FitLifeTheme.accentOrange, strokeWidth: 2),
                                              FlDotData(
                                                getDotPainter: (spot, percent, barData, index) =>
                                                    FlDotCirclePainter(
                                                      radius: 6,
                                                      color: FitLifeTheme.accentOrange,
                                                      strokeWidth: 2,
                                                      strokeColor: FitLifeTheme.surfaceColor,
                                                    ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                        touchTooltipData: LineTouchTooltipData(
                                          tooltipBgColor: Colors.transparent,
                                          tooltipPadding: EdgeInsets.zero,
                                          tooltipMargin: 8,
                                          tooltipRoundedRadius: 0,
                                          getTooltipItems: (touchedSpots) {
                                            return touchedSpots.map((touchedSpot) {
                                              final value = touchedSpot.y;
                                              if (value == 0) return null;
                                              return LineTooltipItem(
                                                '${value.toStringAsFixed(1)}kg',
                                                TextStyle(
                                                  color: FitLifeTheme.textSecondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
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

                // Daily Calories Burned Chart
                FadeInAnimation(
                  child: FutureBuilder<Map<DateTime, double>>(
                    future: _analyticsService.getDailyCaloriesBurned(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildChartPlaceholder('Loading calories data...');
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return _buildChartPlaceholder('Unable to load calories data');
                      }

                      final data = snapshot.data!;
                      final spots = data.entries.map((entry) {
                        final daysAgo = DateTime.now().difference(entry.key).inDays;
                        return FlSpot((6 - daysAgo).toDouble(), entry.value);
                      }).toList();

                      if (spots.every((spot) => spot.y == 0)) {
                        return _buildChartPlaceholder('Start working out to see your calorie burn!');
                      }

                      return AppCard(
                        useCleanStyle: true,
                        child: Padding(
                          padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: FitLifeTheme.accentBlue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: FitLifeTheme.spacingS),
                                  AppText(
                                    'Daily Calories Burned',
                                    type: AppTextType.bodyLarge,
                                    color: FitLifeTheme.primaryText,
                                    useCleanStyle: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: FitLifeTheme.spacingL),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 50,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: FitLifeTheme.dividerColor,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            final dayIndex = value.toInt();
                                            if (dayIndex >= 0 && dayIndex < 7) {
                                              final date = DateTime.now().subtract(Duration(days: 6 - dayIndex));
                                              final weekday = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  weekday,
                                                  style: TextStyle(
                                                    color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 100,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        color: FitLifeTheme.accentBlue,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: FitLifeTheme.accentBlue,
                                              strokeWidth: 2,
                                              strokeColor: FitLifeTheme.background,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: FitLifeTheme.accentBlue.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      handleBuiltInTouches: false,
                                      getTouchedSpotIndicator: (barData, spotIndexes) {
                                        return spotIndexes.map((spotIndex) {
                                          return TouchedSpotIndicatorData(
                                            FlLine(color: FitLifeTheme.accentBlue, strokeWidth: 2),
                                            FlDotData(
                                              getDotPainter: (spot, percent, barData, index) =>
                                                  FlDotCirclePainter(
                                                    radius: 6,
                                                    color: FitLifeTheme.accentBlue,
                                                    strokeWidth: 2,
                                                    strokeColor: FitLifeTheme.surfaceColor,
                                                  ),
                                            ),
                                          );
                                        }).toList();
                                      },
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor: Colors.transparent,
                                        tooltipPadding: EdgeInsets.zero,
                                        tooltipMargin: 8,
                                        tooltipRoundedRadius: 0,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((touchedSpot) {
                                            final value = touchedSpot.y;
                                            if (value == 0) return null;
                                            return LineTooltipItem(
                                              value.toStringAsFixed(0),
                                              TextStyle(
                                                color: FitLifeTheme.textSecondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
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
                                        FitLifeTheme.accentBlue, // Consistent blue progress fill for calories
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
                                        color: FitLifeTheme.accentPurple,
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
                                      FitLifeTheme.accentPurple,
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

  Widget _buildChartPlaceholder(String message) {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: FitLifeTheme.primaryText.withOpacity(0.3),
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                AppText(
                  message,
                  type: AppTextType.bodyMedium,
                  color: FitLifeTheme.primaryText.withOpacity(0.6),
                  textAlign: TextAlign.center,
                  useCleanStyle: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}