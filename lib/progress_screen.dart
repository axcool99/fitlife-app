import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ui/components/components.dart';
import 'services/analytics_service.dart';
import 'services/checkin_service.dart';
import 'services/gamification_service.dart';
import 'services/cache_service.dart';
import 'services/sync_service.dart';
import 'models/checkin.dart';
import 'models/badge.dart' as badge_model;
import 'main_scaffold.dart';
import 'main.dart'; // Import for getIt

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final CheckInService _checkInService = getIt<CheckInService>();
  final GamificationService _gamificationService = getIt<GamificationService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isOnline = true; // Track online status

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final wasOnline = _isOnline;
      final isOnline = await getIt<CacheService>().isOnline();

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        // If we just came back online, sync cached data
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
      final hasPending = await getIt<SyncService>().hasPendingSync();
      if (hasPending) {
        await getIt<SyncService>().syncAllData();
        // Refresh the UI after sync
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

                  // Offline indicator
                  if (!_isOnline) ...[
                    const SizedBox(height: FitLifeTheme.spacingM),
                    FadeInAnimation(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FitLifeTheme.spacingM,
                          vertical: FitLifeTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: FitLifeTheme.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
                          border: Border.all(
                            color: FitLifeTheme.accentOrange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: FitLifeTheme.accentOrange,
                              size: 16,
                            ),
                            const SizedBox(width: FitLifeTheme.spacingS),
                            AppText(
                              'Offline Mode - Showing cached data',
                              type: AppTextType.bodySmall,
                              color: FitLifeTheme.accentOrange,
                              useCleanStyle: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Weight Trend Section
                  FadeInAnimation(
                    child: StreamBuilder<List<CheckIn>>(
                      stream: _checkInService.getCheckIns(),
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
                                        minY: _calculateWeightChartYAxis(weightData)['minY'],
                                        maxY: _calculateWeightChartYAxis(weightData)['maxY'],
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
                                              interval: 1,
                                              getTitlesWidget: (value, meta) {
                                                final dayIndex = value.toInt();
                                                if (dayIndex >= 0 && dayIndex < 7) {
                                                  final date = DateTime.now().subtract(Duration(days: 6 - dayIndex));
                                                  final dateLabel = '${date.day}/${date.month}';
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8.0),
                                                    child: Text(
                                                      dateLabel,
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
                                              interval: _calculateWeightChartYAxis(weightData)['interval'],
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
                                  EmptyState(
                                    title: 'No Weight Data',
                                    message: 'Start tracking your weight by adding check-ins.',
                                    icon: Icons.monitor_weight,
                                    actionButton: AnimatedButton(
                                      text: 'Add Check-In',
                                      icon: Icons.add,
                                      onPressed: () => MainScaffold.navigateToTab(2), // Navigate to Check-ins tab
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

                  // Activity Charts
                  FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Check-in History Section
                  FadeInAnimation(
                    child: StreamBuilder<List<CheckIn>>(
                      stream: _checkInService.getCheckIns(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Check-in History',
                                type: AppTextType.headingSmall,
                                color: FitLifeTheme.primaryText,
                                useCleanStyle: true,
                              ),
                              const SizedBox(height: FitLifeTheme.spacingM),
                              const LoadingState(message: 'Loading check-in history...'),
                            ],
                          );
                        }

                        if (snapshot.hasError) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Check-in History',
                                type: AppTextType.headingSmall,
                                color: FitLifeTheme.primaryText,
                                useCleanStyle: true,
                              ),
                              const SizedBox(height: FitLifeTheme.spacingM),
                              ErrorState(
                                title: 'Failed to Load Check-Ins',
                                message: 'Unable to load your check-in history.',
                                onRetry: () => setState(() {}),
                              ),
                            ],
                          );
                        }

                        final checkIns = snapshot.data ?? [];

                        if (checkIns.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Check-in History',
                                type: AppTextType.headingSmall,
                                color: FitLifeTheme.primaryText,
                                useCleanStyle: true,
                              ),
                              const SizedBox(height: FitLifeTheme.spacingM),
                              EmptyState(
                                title: 'No Check-Ins Yet',
                                message: 'Start tracking your daily wellness by adding your first check-in.',
                                icon: Icons.monitor_heart,
                                actionButton: AnimatedButton(
                                  text: 'Add Check-In',
                                  icon: Icons.add,
                                  onPressed: () => MainScaffold.navigateToTab(2), // Navigate to Check-ins tab
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Check-in History',
                              type: AppTextType.headingSmall,
                              color: FitLifeTheme.primaryText,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingM),
                            // List of recent check-ins (limit to 5 most recent)
                            ...checkIns.take(5).map((checkIn) => Padding(
                              padding: const EdgeInsets.only(bottom: FitLifeTheme.spacingS),
                              child: AppCard(
                                useCleanStyle: true,
                                child: Padding(
                                  padding: const EdgeInsets.all(FitLifeTheme.spacingS),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Date and weight
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          AppText(
                                            DateFormat('MMM dd, yyyy • HH:mm').format(checkIn.date.toLocal()),
                                            type: AppTextType.bodyLarge,
                                            color: FitLifeTheme.primaryText,
                                            useCleanStyle: true,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: FitLifeTheme.spacingS,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: FitLifeTheme.accentOrange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: AppText(
                                              '${checkIn.weight}kg',
                                              type: AppTextType.bodyMedium,
                                              color: FitLifeTheme.accentOrange,
                                              useCleanStyle: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: FitLifeTheme.spacingS),

                                      // Mood and energy
                                      Row(
                                        children: [
                                          // Mood indicator
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: FitLifeTheme.spacingS,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getMoodColor(checkIn.mood).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getMoodIcon(checkIn.mood),
                                                  size: 14,
                                                  color: _getMoodColor(checkIn.mood),
                                                ),
                                                const SizedBox(width: 4),
                                                AppText(
                                                  checkIn.mood,
                                                  type: AppTextType.bodySmall,
                                                  color: _getMoodColor(checkIn.mood),
                                                  useCleanStyle: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: FitLifeTheme.spacingM),

                                          // Energy level
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.flash_on,
                                                size: 14,
                                                color: FitLifeTheme.accentBlue,
                                              ),
                                              const SizedBox(width: 4),
                                              AppText(
                                                CheckIn.getEnergyLabel(checkIn.energyLevel),
                                                type: AppTextType.bodySmall,
                                                color: FitLifeTheme.accentBlue,
                                                useCleanStyle: true,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Notes (if present)
                                      if (checkIn.notes != null && checkIn.notes!.isNotEmpty) ...[
                                        const SizedBox(height: FitLifeTheme.spacingXS),
                                        AppText(
                                          checkIn.notes!,
                                          type: AppTextType.bodySmall,
                                          color: FitLifeTheme.primaryText.withOpacity(0.7),
                                          useCleanStyle: true,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            )).toList(),

                            // Show "View All" button if there are more than 5 check-ins
                            if (checkIns.length > 5) ...[
                              const SizedBox(height: FitLifeTheme.spacingM),
                              Center(
                                child: AnimatedButton(
                                  text: 'View All Check-Ins',
                                  icon: Icons.arrow_forward,
                                  onPressed: () => MainScaffold.navigateToTab(2), // Navigate to Check-ins tab
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Achievements & Badges Section
                  FadeInAnimation(
                    child: FutureBuilder<List<badge_model.Badge>>(
                      future: _gamificationService.getEarnedBadges(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return AppCard(
                            useCleanStyle: true,
                            child: Padding(
                              padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    'Achievements',
                                    type: AppTextType.headingSmall,
                                    color: FitLifeTheme.primaryText,
                                    useCleanStyle: true,
                                  ),
                                  const SizedBox(height: FitLifeTheme.spacingL),
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: FitLifeTheme.accentGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return AppCard(
                            useCleanStyle: true,
                            child: Padding(
                              padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    'Achievements',
                                    type: AppTextType.headingSmall,
                                    color: FitLifeTheme.primaryText,
                                    useCleanStyle: true,
                                  ),
                                  const SizedBox(height: FitLifeTheme.spacingM),
                                  AppText(
                                    'Unable to load achievements',
                                    type: AppTextType.bodySmall,
                                    color: FitLifeTheme.textSecondary,
                                    useCleanStyle: true,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final badges = snapshot.data!;
                        if (badges.isEmpty) {
                          return AppCard(
                            useCleanStyle: true,
                            child: Padding(
                              padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    'Achievements',
                                    type: AppTextType.headingSmall,
                                    color: FitLifeTheme.primaryText,
                                    useCleanStyle: true,
                                  ),
                                  const SizedBox(height: FitLifeTheme.spacingM),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.emoji_events_outlined,
                                          size: 48,
                                          color: FitLifeTheme.textSecondary,
                                        ),
                                        const SizedBox(height: FitLifeTheme.spacingM),
                                        AppText(
                                          'No achievements yet',
                                          type: AppTextType.bodyMedium,
                                          color: FitLifeTheme.textSecondary,
                                          useCleanStyle: true,
                                        ),
                                        const SizedBox(height: FitLifeTheme.spacingS),
                                        AppText(
                                          'Complete workouts to earn badges!',
                                          type: AppTextType.bodySmall,
                                          color: FitLifeTheme.textSecondary,
                                          useCleanStyle: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Group badges by category
                        final badgesByCategory = <badge_model.BadgeCategory, List<badge_model.Badge>>{};
                        for (final badge in badges) {
                          badgesByCategory[badge.category] ??= [];
                          badgesByCategory[badge.category]!.add(badge);
                        }

                        return AppCard(
                          useCleanStyle: true,
                          child: Padding(
                            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppText(
                                      'Achievements',
                                      type: AppTextType.headingSmall,
                                      color: FitLifeTheme.primaryText,
                                      useCleanStyle: true,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: FitLifeTheme.spacingS,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: FitLifeTheme.accentGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: AppText(
                                        '${badges.length} earned',
                                        type: AppTextType.bodySmall,
                                        color: FitLifeTheme.accentGreen,
                                        useCleanStyle: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: FitLifeTheme.spacingL),

                                // Badges by category
                                ...badgesByCategory.entries.map((entry) {
                                  final category = entry.key;
                                  final categoryBadges = entry.value;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        _getCategoryDisplayName(category),
                                        type: AppTextType.bodyMedium,
                                        color: FitLifeTheme.primaryText,
                                        useCleanStyle: true,
                                      ),
                                      const SizedBox(height: FitLifeTheme.spacingM),
                                      Wrap(
                                        spacing: FitLifeTheme.spacingM,
                                        runSpacing: FitLifeTheme.spacingM,
                                        children: categoryBadges.map((badge) => _buildBadgeItem(badge)).toList(),
                                      ),
                                      if (category != badgesByCategory.keys.last)
                                        const SizedBox(height: FitLifeTheme.spacingL),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
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
        final spots = data.entries
            .where((entry) => entry.value > 0) // Filter out zero and negative calories
            .map((entry) {
          final daysAgo = DateTime.now().difference(entry.key).inDays;
          return FlSpot((6 - daysAgo).toDouble(), entry.value);
        })
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x)); // Sort by x-axis (date) for proper rendering

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
                        handleBuiltInTouches: false, // Disable built-in touch handling
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
                              if (value == 0) return null; // Don't show zero values
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

  /// Builds the Workout Frequency chart using accentGreen per style guide.
  /// See /lib/theme/fitlife_style_guide.dart for color mapping guidelines.
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
                color: FitLifeTheme.accentGreen,
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
                  FitLifeTheme.accentPurple,
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

  // Helper methods for check-in history
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Good': return FitLifeTheme.accentGreen;
      case 'Okay': return FitLifeTheme.accentBlue;
      case 'Bad': return FitLifeTheme.highlightPink;
      default: return FitLifeTheme.primaryText;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Good': return Icons.sentiment_very_satisfied;
      case 'Okay': return Icons.sentiment_satisfied;
      case 'Bad': return Icons.sentiment_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  List<FlSpot> _generateWeightChartData(List<CheckIn> checkIns) {
    List<FlSpot> spots = [];

    // Filter out invalid check-ins (0kg or negative weights) to prevent chart distortion
    final validCheckIns = checkIns.where((checkIn) => checkIn.weight > 0).toList();

    // Create spots for each day of the last 7 days
    // i=0 represents 6 days ago, i=6 represents today
    for (int i = 0; i < 7; i++) {
      final targetDate = DateTime.now().subtract(Duration(days: 6 - i));

      // Find all valid check-ins for this specific day
      final dayCheckIns = validCheckIns.where((checkIn) {
        return checkIn.date.year == targetDate.year &&
               checkIn.date.month == targetDate.month &&
               checkIn.date.day == targetDate.day;
      }).toList();

      if (dayCheckIns.isNotEmpty) {
        // If multiple check-ins on same day, use the latest one (highest timestamp)
        dayCheckIns.sort((a, b) => b.date.compareTo(a.date)); // Sort descending by time
        final weight = dayCheckIns.first.weight; // Use the most recent valid check-in for the day
        spots.add(FlSpot(i.toDouble(), weight));
      }
      // Skip days with no valid check-ins - this creates gaps that will be connected by lines
    }

    return spots;
  }

  /// Calculate dynamic Y-axis range for weight chart based on user's last weight
  /// Returns minY, maxY, and interval for the chart
  Map<String, double> _calculateWeightChartYAxis(List<CheckIn> checkIns) {
    // Filter out invalid weights (0kg or negative) to prevent chart scaling issues
    final validCheckIns = checkIns.where((checkIn) => checkIn.weight > 0).toList();

    if (validCheckIns.isEmpty) {
      // Default range when no valid data
      return {'minY': 40.0, 'maxY': 100.0, 'interval': 20.0};
    }

    // Get the most recent valid check-in weight
    validCheckIns.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    final lastWeight = validCheckIns.first.weight;

    // Calculate initial range: lastWeight ± 20kg
    double minY = lastWeight - 20.0;
    double maxY = lastWeight + 20.0;

    // Ensure minimum range of 40kg
    final range = maxY - minY;
    if (range < 40.0) {
      final center = (minY + maxY) / 2.0;
      minY = center - 20.0;
      maxY = center + 20.0;
    }

    // Round to nearest 5kg
    minY = (minY / 5.0).round() * 5.0;
    maxY = (maxY / 5.0).round() * 5.0;

    // Calculate appropriate interval based on range
    final actualRange = maxY - minY;
    double interval = 15.0; // Default
    if (actualRange <= 50.0) {
      interval = 10.0; // Interval for tighter ranges
    } else if (actualRange > 100.0) {
      interval = 25.0; // Larger interval for wider ranges
    }

    return {'minY': minY, 'maxY': maxY, 'interval': interval};
  }

  Widget _buildBadgeItem(badge_model.Badge badge) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(FitLifeTheme.spacingS),
      decoration: BoxDecoration(
        color: Color(badge.colorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(badge.colorValue).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getBadgeIcon(badge.icon),
            color: Color(badge.colorValue),
            size: 24,
          ),
          const SizedBox(height: FitLifeTheme.spacingXS),
          AppText(
            badge.title.length > 10
                ? '${badge.title.substring(0, 8)}...'
                : badge.title,
            type: AppTextType.bodySmall,
            color: Color(badge.colorValue),
            useCleanStyle: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          AppText(
            DateFormat('MMM dd').format(badge.earnedAt),
            type: AppTextType.bodySmall,
            color: FitLifeTheme.textSecondary,
            useCleanStyle: true,
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(badge_model.BadgeCategory category) {
    switch (category) {
      case badge_model.BadgeCategory.streak:
        return 'Streak';
      case badge_model.BadgeCategory.workouts:
        return 'Workouts';
      case badge_model.BadgeCategory.strength:
        return 'Strength';
      case badge_model.BadgeCategory.consistency:
        return 'Consistency';
      case badge_model.BadgeCategory.achievement:
        return 'Achievement';
    }
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_handball':
        return Icons.sports_handball;
      case 'military_tech':
        return Icons.military_tech;
      case 'calendar_month':
        return Icons.calendar_month;
      default:
        return Icons.emoji_events;
    }
  }
}