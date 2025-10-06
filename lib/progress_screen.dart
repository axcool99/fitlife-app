import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ui/components/components.dart';
import 'services/analytics_service.dart';
import 'services/sync_service.dart';
import 'services/network_service.dart';
import 'main.dart';

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
                  _buildCaloriesChart(),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  _buildWorkoutFrequencyChart(),
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
                  child: LineChart(
                    LineChartData(
                      minY: 0, // Ensure Y-axis starts at 0 to prevent below-graph drawing
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
                      clipData: FlClipData.all(), // Prevent line from drawing below chart area
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!.entries.map((entry) {
                            final daysAgo = DateTime.now().difference(entry.key).inDays;
                            return FlSpot((6 - daysAgo).toDouble(), entry.value);
                          }).toList()..sort((a, b) => a.x.compareTo(b.x)),
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
                      'Daily Workout Frequency',
                      type: AppTextType.bodyLarge,
                      color: FitLifeTheme.primaryText,
                      useCleanStyle: true,
                    ),
                  ],
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
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
                            interval: 1,
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
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!.entries.map((entry) {
                            final daysAgo = DateTime.now().difference(entry.key).inDays;
                            return FlSpot((6 - daysAgo).toDouble(), entry.value.toDouble());
                          }).toList()..sort((a, b) => a.x.compareTo(b.x)),
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
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: false,
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            return TouchedSpotIndicatorData(
                              FlLine(color: FitLifeTheme.accentGreen, strokeWidth: 2),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                      radius: 6,
                                      color: FitLifeTheme.accentGreen,
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
    );
  }

  Widget _buildChartPlaceholder(String message) {
    return AppCard(
      useCleanStyle: true,
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Center(
          child: AppText(
            message,
            type: AppTextType.bodyMedium,
            color: FitLifeTheme.textSecondary,
            useCleanStyle: true,
          ),
        ),
      ),
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
}
