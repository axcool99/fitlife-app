import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ui/components/components.dart';
import 'services/analytics_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: FitLifeAppBar(
        title: 'Progress & Analytics',
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<WeeklyStats>(
        future: _analyticsService.getWeeklyStats(),
        builder: (context, statsSnapshot) {
          if (statsSnapshot.connectionState == ConnectionState.waiting) {
            return ShimmerLoading(
              child: Column(
                children: [
                  SkeletonChart(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: SkeletonCard(height: 100)),
                      const SizedBox(width: 16),
                      Expanded(child: SkeletonCard(height: 100)),
                    ],
                  ),
                ],
              ),
            );
          }

          if (statsSnapshot.hasError) {
            return ErrorState(
              title: 'Failed to Load Analytics',
              message: 'Unable to load your progress data. Please check your connection and try again.',
              onRetry: () => setState(() {}),
            );
          }

          final stats = statsSnapshot.data!;

          return CustomRefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FitLifeTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  FadeInAnimation(
                    child: AppText(
                      'Track your fitness journey and see your improvements over time.',
                      type: AppTextType.bodyMedium,
                      color: FitLifeTheme.primaryText.withOpacity(0.8),
                      useCleanStyle: true,
                    ),
                  ),

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Weekly Progress Section
                  FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Weekly Progress',
                          type: AppTextType.headingSmall,
                          color: FitLifeTheme.primaryText,
                          useCleanStyle: true,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        _buildCaloriesChart(),
                        const SizedBox(height: FitLifeTheme.spacingL),
                        _buildWorkoutFrequencyChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Activity Stats Section
                  FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Activity Stats',
                          type: AppTextType.headingSmall,
                          color: FitLifeTheme.primaryText,
                          useCleanStyle: true,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        _buildStatsCards(stats),
                      ],
                    ),
                  ),

                  const SizedBox(height: FitLifeTheme.spacingXXL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaloriesChart() {
    return FutureBuilder<Map<DateTime, double>>(
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
                      color: FitLifeTheme.accentGreen,
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
                          color: FitLifeTheme.accentGreen,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: FitLifeTheme.accentGreen,
                                strokeWidth: 2,
                                strokeColor: FitLifeTheme.background,
                              );
                            },
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
    );
  }

  Widget _buildWorkoutFrequencyChart() {
    return FutureBuilder<Map<DateTime, int>>(
      future: _analyticsService.getDailyWorkoutFrequency(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartPlaceholder('Loading workout data...');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildChartPlaceholder('Unable to load workout data');
        }

        final data = snapshot.data!;
        final barGroups = data.entries.map((entry) {
          final daysAgo = DateTime.now().difference(entry.key).inDays;
          return BarChartGroupData(
            x: 6 - daysAgo,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: FitLifeTheme.accentBlue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList();

        if (barGroups.every((group) => group.barRods.first.toY == 0)) {
          return _buildChartPlaceholder('Start working out to see your activity!');
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
                      Icons.fitness_center,
                      color: FitLifeTheme.accentBlue,
                      size: 24,
                    ),
                    const SizedBox(width: FitLifeTheme.spacingS),
                    AppText(
                      'Workout Frequency',
                      type: AppTextType.bodyLarge,
                      color: FitLifeTheme.primaryText,
                      useCleanStyle: true,
                    ),
                  ],
                ),
                const SizedBox(height: FitLifeTheme.spacingL),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) + 1,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: FitLifeTheme.surfaceColor,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()} workout${rod.toY.toInt() == 1 ? '' : 's'}',
                              TextStyle(
                                color: FitLifeTheme.primaryText,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
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
                            interval: 1,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == value.toInt().toDouble()) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: FitLifeTheme.primaryText.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: FitLifeTheme.dividerColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildStatsCards(WeeklyStats stats) {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'This Week',
              type: AppTextType.headingSmall,
              color: FitLifeTheme.primaryText,
              useCleanStyle: true,
            ),
            const SizedBox(height: FitLifeTheme.spacingL),
            Row(
              children: [
                _buildStatItem(
                  'Workouts',
                  stats.totalWorkouts.toString(),
                  Icons.fitness_center,
                  FitLifeTheme.accentGreen,
                ),
                _buildStatItem(
                  'Avg Calories',
                  stats.avgCaloriesPerSession.toStringAsFixed(0),
                  Icons.local_fire_department,
                  FitLifeTheme.accentBlue,
                ),
                _buildStatItem(
                  'Day(s) Streak',
                  '${stats.streak}',
                  Icons.calendar_today,
                  FitLifeTheme.highlightPink,
                ),
              ],
            ),
            const SizedBox(height: FitLifeTheme.spacingL),
            // Progress indicator
            if (stats.totalWorkouts > 0) ...[
              const SizedBox(height: FitLifeTheme.spacingM),
              Row(
                children: [
                  Icon(
                    stats.progressPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: stats.progressPercentage >= 0 ? FitLifeTheme.accentGreen : FitLifeTheme.highlightPink,
                    size: 20,
                  ),
                  const SizedBox(width: FitLifeTheme.spacingS),
                  Expanded(
                    child: AppText(
                      '${stats.progressPercentage >= 0 ? '+' : ''}${stats.progressPercentage.toStringAsFixed(1)}% vs last week',
                      type: AppTextType.bodyMedium,
                      color: stats.progressPercentage >= 0 ? FitLifeTheme.accentGreen : FitLifeTheme.highlightPink,
                      useCleanStyle: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: FitLifeTheme.spacingS),
          AppText(
            value,
            type: AppTextType.headingSmall,
            color: FitLifeTheme.primaryText,
            useCleanStyle: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FitLifeTheme.spacingXS),
          AppText(
            label,
            type: AppTextType.bodySmall,
            color: FitLifeTheme.primaryText.withOpacity(0.6),
            useCleanStyle: true,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}