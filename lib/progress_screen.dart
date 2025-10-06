import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ui/components/components.dart';
import 'services/analytics_service.dart';
import 'services/checkin_service.dart';
import 'services/gamification_service.dart';
import 'services/cache_service.dart';
import 'services/sync_service.dart';
import 'services/network_service.dart';
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
  final NetworkService _networkService = getIt<NetworkService>();
  final SyncService _syncService = getIt<SyncService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isOnline = true; // Track online status

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _networkService.connectivityStream.listen((ConnectivityResult result) async {
      // When connectivity changes, check actual online status
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
      final hasPending = await _syncService.hasPendingSync();
      if (hasPending) {
        await _syncService.syncAllData();
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
      body: Column(
        children: [
          // Offline indicator
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

          // Main content
          Expanded(
            child: Center(
              child: AppText(
                'Progress & Analytics\n(Coming Soon)',
                type: AppTextType.headingMedium,
                color: FitLifeTheme.textPrimary,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
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

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'streak':
        return 'Streak';
      case 'workouts':
        return 'Workouts';
      case 'strength':
        return 'Strength';
      case 'consistency':
        return 'Consistency';
      case 'achievement':
        return 'Achievement';
      default:
        return category;
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
