import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ui/components/components.dart';
import 'services/analytics_service.dart';
import 'services/checkin_service.dart';
import 'services/gamification_service.dart';
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
                AppText(
                  'Daily Calories Burned',
                  type: AppTextType.headingSmall,
                  color: FitLifeTheme.accentBlue,
                  useCleanStyle: true,
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!.entries.map((entry) {
                            return FlSpot(
                              entry.key.millisecondsSinceEpoch.toDouble(),
                              entry.value,
                            );
                          }).toList(),
                          isCurved: true,
                          color: FitLifeTheme.accentBlue,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
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
                AppText(
                  'Daily Workout Frequency',
                  type: AppTextType.headingSmall,
                  color: FitLifeTheme.accentPurple,
                  useCleanStyle: true,
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: snapshot.data!.entries.map((entry) {
                        final dayIndex = entry.key.weekday - 1;
                        return BarChartGroupData(
                          x: dayIndex,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: FitLifeTheme.accentPurple,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
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
