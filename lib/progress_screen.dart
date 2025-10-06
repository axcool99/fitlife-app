import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ui/components/components.dart';
import 'services/analytics_service.dart';
import 'services/sync_service.dart';
import 'services/network_service.dart';
import 'main.dart';

enum TimeRange { week, month, threeMonths }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final NetworkService _networkService = getIt<NetworkService>();
  final SyncService _syncService = getIt<SyncService>();

  bool _isOnline = true;
  TimeRange _selectedTimeRange = TimeRange.week;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _networkService.connectivityStream.listen((ConnectivityResult result) async {
      await _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final wasOnline = _isOnline;
      final isOnline = await _networkService.isOnline();

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        if (!wasOnline && isOnline) {
          _syncCachedData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  Future<void> _syncCachedData() async {
    try {
      final hasPending = await _syncService.hasPendingSync();
      if (hasPending) {
        await _syncService.syncAllData();
        setState(() {});
      }
    } catch (e) {
      print('Error syncing cached data: $e');
    }
  }

  Widget _buildStatsPlaceholder() {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Center(
          child: AppText(
            'Loading weekly stats...',
            type: AppTextType.bodyMedium,
            color: FitLifeTheme.textSecondary,
            useCleanStyle: true,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStatsState() {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: EmptyState(
          title: 'Start Your Fitness Journey',
          message: 'Complete your first workout to see your progress and statistics here!',
          icon: Icons.rocket_launch,
          animate: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: FitLifeAppBar(
        title: 'Progress & Analytics',
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          if (!_isOnline) ...[
            Container(
              margin: const EdgeInsets.all(FitLifeTheme.spacingM),
              padding: const EdgeInsets.all(FitLifeTheme.spacingS),
              decoration: BoxDecoration(
                color: FitLifeTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                border: Border.all(color: FitLifeTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: FitLifeTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: FitLifeTheme.spacingS),
                  Expanded(
                    child: AppText(
                      'You\'re offline. Changes will be synced when connection is restored.',
                      type: AppTextType.bodySmall,
                      color: FitLifeTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FitLifeTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<WeeklyStats>(
                    future: _analyticsService.getWeeklyStats(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildStatsPlaceholder();
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return _buildStatsPlaceholder();
                      }

                      final stats = snapshot.data!;
                      final hasData = stats.totalWorkouts > 0 || stats.streak > 0;

                      if (!hasData) {
                        return _buildEmptyStatsState();
                      }

                      return _buildWeeklyStatsCard(stats);
                    },
                  ),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  AppText(
                    'This Week\'s Activity',
                    type: AppTextType.headingMedium,
                    color: FitLifeTheme.textPrimary,
                  ),
                  const SizedBox(height: FitLifeTheme.spacingM),
                  _buildTimeRangeSelector(),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  _buildCaloriesChart(),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  _buildWorkoutFrequencyChart(),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  _buildWorkoutTypeDistributionChart(),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  _buildCombinedMetricsChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard(WeeklyStats stats) {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Weekly Summary',
              type: AppTextType.headingSmall,
              color: FitLifeTheme.accentBlue,
              useCleanStyle: true,
            ),
            const SizedBox(height: FitLifeTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Workouts',
                    stats.totalWorkouts.toString(),
                    Icons.fitness_center,
                    FitLifeTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: FitLifeTheme.spacingM),
                Expanded(
                  child: _buildStatItem(
                    'Avg Calories',
                    '${stats.avgCaloriesPerSession.toStringAsFixed(0)}',
                    Icons.local_fire_department,
                    FitLifeTheme.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitLifeTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Streak',
                    '${stats.streak} days',
                    Icons.local_fire_department,
                    FitLifeTheme.accentPurple,
                  ),
                ),
                const SizedBox(width: FitLifeTheme.spacingM),
                Expanded(
                  child: _buildStatItem(
                    'Progress',
                    '${stats.progressPercentage >= 0 ? '+' : ''}${stats.progressPercentage.toStringAsFixed(0)}%',
                    stats.progressPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    stats.progressPercentage >= 0 ? FitLifeTheme.accentGreen : FitLifeTheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(FitLifeTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: FitLifeTheme.spacingXS),
          AppText(
            value,
            type: AppTextType.headingSmall,
            color: color,
            useCleanStyle: true,
          ),
          AppText(
            label,
            type: AppTextType.bodySmall,
            color: FitLifeTheme.textSecondary,
            useCleanStyle: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FitLifeTheme.spacingM, vertical: FitLifeTheme.spacingS),
      decoration: BoxDecoration(
        color: FitLifeTheme.surfaceColor,
        borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
        border: Border.all(color: FitLifeTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeRangeButton('Week', TimeRange.week),
          const SizedBox(width: FitLifeTheme.spacingS),
          _buildTimeRangeButton('Month', TimeRange.month),
          const SizedBox(width: FitLifeTheme.spacingS),
          _buildTimeRangeButton('3 Months', TimeRange.threeMonths),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, TimeRange range) {
    final isSelected = _selectedTimeRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTimeRange = range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: FitLifeTheme.spacingS),
          decoration: BoxDecoration(
            color: isSelected ? FitLifeTheme.accentGreen.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(FitLifeTheme.radiusS),
            border: Border.all(
              color: isSelected ? FitLifeTheme.accentGreen : FitLifeTheme.borderColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: AppText(
              label,
              type: AppTextType.bodySmall,
              color: isSelected ? FitLifeTheme.accentGreen : FitLifeTheme.textSecondary,
              useCleanStyle: true,
            ),
          ),
        ),
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

        final hasData = snapshot.data!.values.any((value) => value > 0);

        if (!hasData) {
          return _buildEmptyChartState(
            'No Calorie Data Yet',
            'Start logging your workouts to see your calorie burn trends!',
            Icons.local_fire_department,
          );
        }

        return AppCard(
          useCleanStyle: true,
          child: Padding(
            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
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
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
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
                            getTitlesWidget: (value, meta) {
                              final dayIndex = value.toInt();
                              if (dayIndex >= 0 && dayIndex < 7) {
                                const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    weekdays[dayIndex],
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
                      barGroups: snapshot.data!.entries.map((entry) {
                        final daysAgo = DateTime.now().difference(entry.key).inDays;
                        final dayIndex = (6 - daysAgo).clamp(0, 6);
                        return BarChartGroupData(
                          x: dayIndex,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: FitLifeTheme.accentBlue,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 0, color: FitLifeTheme.surfaceColor),
                            ),
                          ],
                        );
                      }).toList(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: FitLifeTheme.surfaceColor,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.toInt().toString(),
                              TextStyle(
                                color: FitLifeTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
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
    );
  }

  Widget _buildWorkoutTypeDistributionChart() {
    return FutureBuilder<Map<String, int>>(
      future: _analyticsService.getWorkoutTypeDistribution(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartPlaceholder('Loading workout types...');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildChartPlaceholder('Unable to load workout types');
        }

        final hasData = snapshot.data!.values.any((value) => value > 0);

        if (!hasData) {
          return _buildEmptyChartState(
            'No Workout Data Yet',
            'Complete workouts with different exercises to see your workout type distribution!',
            Icons.pie_chart,
          );
        }

        return AppCard(
          useCleanStyle: true,
          child: Padding(
            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart,
                      color: FitLifeTheme.accentPurple,
                      size: 24,
                    ),
                    const SizedBox(width: FitLifeTheme.spacingS),
                    AppText(
                      'Workout Types',
                      type: AppTextType.bodyLarge,
                      color: FitLifeTheme.primaryText,
                      useCleanStyle: true,
                    ),
                  ],
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(snapshot.data!),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Handle touch events if needed
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                _buildWorkoutTypeLegend(snapshot.data!),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> data) {
    final total = data.values.fold(0, (sum, value) => sum + value);
    final colors = [
      FitLifeTheme.accentGreen,
      FitLifeTheme.accentBlue,
      FitLifeTheme.accentOrange,
      FitLifeTheme.accentPurple,
      FitLifeTheme.highlightPink,
    ];

    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final colorIndex = data.keys.toList().indexOf(entry.key) % colors.length;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[colorIndex],
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: FitLifeTheme.textPrimary,
        ),
      );
    }).toList();
  }

  Widget _buildWorkoutTypeLegend(Map<String, int> data) {
    final colors = [
      FitLifeTheme.accentGreen,
      FitLifeTheme.accentBlue,
      FitLifeTheme.accentOrange,
      FitLifeTheme.accentPurple,
      FitLifeTheme.highlightPink,
    ];

    return Wrap(
      spacing: FitLifeTheme.spacingM,
      runSpacing: FitLifeTheme.spacingS,
      children: data.entries.map((entry) {
        final colorIndex = data.keys.toList().indexOf(entry.key) % colors.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[colorIndex],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: FitLifeTheme.spacingXS),
            AppText(
              '${entry.key}: ${entry.value}',
              type: AppTextType.bodySmall,
              color: FitLifeTheme.textSecondary,
              useCleanStyle: true,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCombinedMetricsChart() {
    return FutureBuilder<List<Map<DateTime, double>>>(
      future: Future.wait([
        _analyticsService.getDailyWorkoutFrequency().then((data) => data.map((key, value) => MapEntry(key, value.toDouble()))),
        _analyticsService.getAverageSessionDuration(),
        _analyticsService.getCalorieBurnEfficiency(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartPlaceholder('Loading combined metrics...');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildChartPlaceholder('Unable to load combined metrics');
        }

        final workoutFrequency = snapshot.data![0];
        final sessionDuration = snapshot.data![1];
        final calorieEfficiency = snapshot.data![2];

        final hasData = workoutFrequency.values.any((v) => v > 0) ||
                       sessionDuration.values.any((v) => v > 0) ||
                       calorieEfficiency.values.any((v) => v > 0);

        if (!hasData) {
          return _buildEmptyChartState(
            'No Metrics Data Yet',
            'Complete more workouts to see your combined performance metrics!',
            Icons.show_chart,
          );
        }

        return AppCard(
          useCleanStyle: true,
          child: Padding(
            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      color: FitLifeTheme.accentOrange,
                      size: 24,
                    ),
                    const SizedBox(width: FitLifeTheme.spacingS),
                    AppText(
                      'Combined Metrics',
                      type: AppTextType.bodyLarge,
                      color: FitLifeTheme.primaryText,
                      useCleanStyle: true,
                    ),
                  ],
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
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
                            getTitlesWidget: (value, meta) {
                              final dayIndex = value.toInt();
                              if (dayIndex >= 0 && dayIndex < 7) {
                                const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    weekdays[dayIndex],
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
                        _buildLineChartBarData(workoutFrequency, FitLifeTheme.accentGreen, 'Workouts'),
                        _buildLineChartBarData(sessionDuration, FitLifeTheme.accentBlue, 'Duration (min)'),
                        _buildLineChartBarData(calorieEfficiency, FitLifeTheme.accentOrange, 'Cal/min'),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: FitLifeTheme.surfaceColor,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final data = spot.bar.spots;
                              final dayIndex = spot.x.toInt();
                              final value = spot.y;

                              String label;
                              if (spot.barIndex == 0) {
                                label = '${value.toInt()} workouts';
                              } else if (spot.barIndex == 1) {
                                label = '${value.toStringAsFixed(1)} min avg';
                              } else {
                                label = '${value.toStringAsFixed(1)} cal/min';
                              }

                              return LineTooltipItem(
                                label,
                                TextStyle(
                                  color: spot.bar.color,
                                  fontSize: 12,
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
                const SizedBox(height: FitLifeTheme.spacingM),
                _buildCombinedMetricsLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  LineChartBarData _buildLineChartBarData(Map<DateTime, double> data, Color color, String label) {
    final spots = data.entries.map((entry) {
      final daysAgo = DateTime.now().difference(entry.key).inDays;
      final dayIndex = (6 - daysAgo).clamp(0, 6);
      return FlSpot(dayIndex.toDouble(), entry.value);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: FitLifeTheme.background,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildCombinedMetricsLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: FitLifeTheme.spacingL,
      runSpacing: FitLifeTheme.spacingS,
      children: [
        _buildLegendItem(FitLifeTheme.accentGreen, 'Workouts'),
        _buildLegendItem(FitLifeTheme.accentBlue, 'Avg Duration'),
        _buildLegendItem(FitLifeTheme.accentOrange, 'Calorie Efficiency'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: FitLifeTheme.spacingXS),
        AppText(
          label,
          type: AppTextType.bodySmall,
          color: FitLifeTheme.textSecondary,
          useCleanStyle: true,
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder(String message) {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                color: FitLifeTheme.textSecondary.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: FitLifeTheme.spacingM),
              AppText(
                message,
                type: AppTextType.bodyMedium,
                color: FitLifeTheme.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutFrequencyChart() {
    return FutureBuilder<Map<DateTime, int>>(
      future: _analyticsService.getDailyWorkoutFrequency(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartPlaceholder('Loading workout frequency...');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildChartPlaceholder('Unable to load workout frequency');
        }

        final hasData = snapshot.data!.values.any((value) => value > 0);

        if (!hasData) {
          return _buildEmptyChartState(
            'No Workout Data Yet',
            'Complete your first workout to start tracking your activity!',
            Icons.fitness_center,
          );
        }

        return AppCard(
          useCleanStyle: true,
          child: Padding(
            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: FitLifeTheme.accentGreen,
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
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
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
                                const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    weekdays[dayIndex],
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
                              if (value == 0) return const Text('');
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
                      barGroups: snapshot.data!.entries.map((entry) {
                        final daysAgo = DateTime.now().difference(entry.key).inDays;
                        final dayIndex = (6 - daysAgo).clamp(0, 6);
                        return BarChartGroupData(
                          x: dayIndex,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: FitLifeTheme.accentGreen,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 0, color: FitLifeTheme.surfaceColor),
                            ),
                          ],
                        );
                      }).toList(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: FitLifeTheme.surfaceColor,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.toInt().toString(),
                              TextStyle(
                                color: FitLifeTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
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
    );
  }

  Widget _buildEmptyChartState(String title, String message, IconData icon) {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: EmptyState(
          title: title,
          message: message,
          icon: icon,
          animate: false,
        ),
      ),
    );
  }
}
