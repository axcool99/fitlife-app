import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ui/components/components.dart';
import 'services/checkin_service.dart';
import 'models/checkin.dart';
import 'main_scaffold.dart';

class CheckInHistoryScreen extends StatefulWidget {
  const CheckInHistoryScreen({super.key});

  @override
  _CheckInHistoryScreenState createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  final CheckInService _checkInService = CheckInService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: FitLifeAppBar(
        title: 'Check-In History',
        leading: fitLifeBackButton(context),
      ),
      body: StreamBuilder<List<CheckIn>>(
        stream: _checkInService.getCheckIns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading your check-ins...');
          }

          if (snapshot.hasError) {
            return ErrorState(
              title: 'Failed to Load Check-Ins',
              message: 'Unable to load your check-in history. Please try again.',
              onRetry: () => setState(() {}),
            );
          }

          final checkIns = snapshot.data ?? [];

          // Debug: Print all fetched check-ins
          debugPrint('CheckInHistoryScreen: Fetched ${checkIns.length} check-ins');
          for (final checkIn in checkIns) {
            debugPrint('CheckInHistoryScreen: Date: ${checkIn.date}, Weight: ${checkIn.weight}kg');
          }

          if (checkIns.isEmpty) {
            return EmptyState(
              title: 'No Check-Ins Yet',
              message: 'Start tracking your daily wellness by adding your first check-in.',
              icon: Icons.monitor_heart,
              actionButton: AnimatedButton(
                text: 'Add First Check-In',
                icon: Icons.add,
                onPressed: () => MainScaffold.navigateToTab(2), // Navigate to Check-ins tab
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(FitLifeTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Check-In History List
                FadeInAnimation(
                  child: AppText(
                    'Recent Check-Ins',
                    type: AppTextType.headingSmall,
                    color: FitLifeTheme.primaryText,
                    useCleanStyle: true,
                  ),
                ),
                const SizedBox(height: FitLifeTheme.spacingM),

                // List of check-ins
                ...checkIns.map((checkIn) => Padding(
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
                                DateFormat('MMM d, yyyy').format(checkIn.date),
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
                                  color: FitLifeTheme.accentGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AppText(
                                  '${checkIn.weight}kg',
                                  type: AppTextType.bodyMedium,
                                  color: FitLifeTheme.accentGreen,
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

                const SizedBox(height: FitLifeTheme.spacingL),
              ],
            ),
          );
        },
      ),
      floatingActionButton: AnimatedFAB(
        onPressed: () => MainScaffold.navigateToTab(2), // Navigate to Check-ins tab
        icon: Icons.add,
        tooltip: 'Add Check-In',
      ),
    );
  }


  // Get mood color for UI
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Good': return FitLifeTheme.accentGreen;
      case 'Okay': return FitLifeTheme.accentBlue;
      case 'Bad': return FitLifeTheme.highlightPink;
      default: return FitLifeTheme.primaryText;
    }
  }

  // Get mood icon for UI
  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Good': return Icons.sentiment_very_satisfied;
      case 'Okay': return Icons.sentiment_satisfied;
      case 'Bad': return Icons.sentiment_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }
}