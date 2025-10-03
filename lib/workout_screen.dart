import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/components/components.dart';
import 'services/workout_service.dart';
import 'models/workout.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => AddWorkoutDialog(),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('push') || name.contains('press') || name.contains('bench')) {
      return Icons.fitness_center;
    } else if (name.contains('squat') || name.contains('leg')) {
      return Icons.accessibility;
    } else if (name.contains('plank') || name.contains('core')) {
      return Icons.timer;
    } else if (name.contains('pull') || name.contains('row')) {
      return Icons.fitness_center;
    } else if (name.contains('run') || name.contains('cardio')) {
      return Icons.directions_run;
    } else {
      return Icons.fitness_center;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  // Format time for workout display (HH:MM format)
  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Group workouts by date for better organization
  Map<String, List<Workout>> _groupWorkoutsByDate(List<Workout> workouts) {
    final grouped = <String, List<Workout>>{};
    
    for (final workout in workouts) {
      // Ensure timestamp is converted to local time for correct date grouping
      final localDate = workout.createdAt.toLocal();
      final dateKey = DateTime(localDate.year, localDate.month, localDate.day);
      final dateString = _formatDateGroup(dateKey);
      
      if (!grouped.containsKey(dateString)) {
        grouped[dateString] = [];
      }
      grouped[dateString]!.add(workout);
    }
    
    // Sort dates in descending order (most recent first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final dateA = _parseDateFromGroup(a);
      final dateB = _parseDateFromGroup(b);
      return dateB.compareTo(dateA);
    });
    
    final sortedGrouped = <String, List<Workout>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    
    return sortedGrouped;
  }

  // Helper method to format date for grouping
  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today';
    } else if (workoutDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // Helper method to parse date from group string for sorting
  DateTime _parseDateFromGroup(String dateString) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (dateString == 'Today') {
      return today;
    } else if (dateString == 'Yesterday') {
      return today.subtract(const Duration(days: 1));
    } else {
      // Parse MM/DD/YYYY format
      final parts = dateString.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: AppBar(
        title: AppText(
          'Your Workouts',
          type: AppTextType.headingSmall,
          color: FitLifeTheme.primaryText,
          useCleanStyle: true,
        ),
        backgroundColor: FitLifeTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: FitLifeTheme.primaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [],
      ),
      body: StreamBuilder<List<Workout>>(
        stream: _workoutService.getWorkouts(), // Changed from getTodaysWorkouts() to show all workouts including past ones
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerLoading(
              child: SkeletonList(itemCount: 3),
            );
          }

          if (snapshot.hasError) {
            return ErrorState(
              title: 'Failed to Load Workouts',
              message: 'Something went wrong while loading your workouts. Please try again.',
              onRetry: () => setState(() {}),
            );
          }

          final workouts = snapshot.data ?? [];
          
          // Debug print to verify Firestore documents retrieved
          debugPrint('WorkoutScreen: Retrieved ${workouts.length} workouts from Firestore');
          for (var workout in workouts) {
            debugPrint('Workout: ${workout.exerciseName} - Date: ${workout.createdAt.toLocal()}');
          }

          // Group workouts by date for better organization
          final groupedWorkouts = _groupWorkoutsByDate(workouts);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Motivational text moved to top
                      Center(
                        child: FadeInAnimation(
                          child: AppText(
                            'Push your limits. Transform your body.',
                            type: AppTextType.bodySmall,
                            color: FitLifeTheme.primaryText.withOpacity(0.6),
                            useCleanStyle: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: FitLifeTheme.spacingL),

                      // Display grouped workouts by date
                      if (workouts.isEmpty) ...[
                        // Empty state
                        EmptyState(
                          title: 'No Workouts Yet',
                          message: 'Start your fitness journey by adding your first workout! Track your progress and stay motivated.',
                          icon: Icons.fitness_center,
                          actionButton: AnimatedButton(
                            text: 'Add Your First Workout',
                            icon: Icons.add,
                            onPressed: _addExercise,
                          ),
                        ),
                      ] else ...[
                        // Display workouts grouped by date
                        ...groupedWorkouts.entries.map((entry) {
                          final dateLabel = entry.key;
                          final dayWorkouts = entry.value;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              FadeInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: FitLifeTheme.spacingS,
                                    horizontal: FitLifeTheme.spacingM,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FitLifeTheme.surfaceColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
                                  ),
                                  child: AppText(
                                    '$dateLabel (${dayWorkouts.length} exercise${dayWorkouts.length == 1 ? '' : 's'})',
                                    type: AppTextType.bodyLarge,
                                    color: FitLifeTheme.primaryText,
                                    useCleanStyle: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: FitLifeTheme.spacingM),
                              
                              // Workouts for this date
                              ...dayWorkouts.asMap().entries.map((entry) {
                                final index = entry.key;
                                final workout = entry.value;
                                return Column(
                                  children: [
                                    SwipeToDeleteItem(
                                      onDelete: () async {
                                        try {
                                          await _workoutService.deleteWorkout(workout.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${workout.exerciseName} deleted'),
                                                backgroundColor: FitLifeTheme.accentGreen,
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  textColor: FitLifeTheme.primaryText,
                                                  onPressed: () async {
                                                    // Re-add the workout (you might want to implement this)
                                                    // For now, just show a message
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Undo not implemented yet'),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to delete workout: $e'),
                                                backgroundColor: FitLifeTheme.highlightPink,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        // Use Container with explicit BoxDecoration to prevent any theme interference
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A1A), // Explicit dark background
                                          borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(FitLifeTheme.spacingL),
                                          child: Row(
                                            children: [
                                              // Exercise icon
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: FitLifeTheme.accentGreen.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  _getExerciseIcon(workout.exerciseName),
                                                  color: FitLifeTheme.accentGreen,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: FitLifeTheme.spacingM),

                                              // Exercise details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    AppText(
                                                      workout.exerciseName,
                                                      type: AppTextType.bodyLarge,
                                                      color: FitLifeTheme.primaryText,
                                                      useCleanStyle: true,
                                                    ),
                                                    const SizedBox(height: FitLifeTheme.spacingXS),
                                                    AppText(
                                                      '${workout.sets} sets × ${workout.reps} reps',
                                                      type: AppTextType.bodyMedium,
                                                      color: FitLifeTheme.primaryText.withOpacity(0.7),
                                                      useCleanStyle: true,
                                                    ),
                                                    const SizedBox(height: FitLifeTheme.spacingXS),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: FitLifeTheme.primaryText.withOpacity(0.5),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        AppText(
                                                          _formatTime(workout.createdAt),
                                                          type: AppTextType.bodySmall,
                                                          color: FitLifeTheme.primaryText.withOpacity(0.6),
                                                          useCleanStyle: true,
                                                        ),
                                                        if (workout.duration != null) ...[
                                                          const SizedBox(width: FitLifeTheme.spacingM),
                                                          Icon(
                                                            Icons.timer,
                                                            size: 14,
                                                            color: FitLifeTheme.accentBlue,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          AppText(
                                                            _formatDuration(workout.duration!),
                                                            type: AppTextType.bodySmall,
                                                            color: FitLifeTheme.accentBlue,
                                                            useCleanStyle: true,
                                                          ),
                                                        ],
                                                        if (workout.weight != null) ...[
                                                          const SizedBox(width: FitLifeTheme.spacingM),
                                                          Icon(
                                                            Icons.fitness_center,
                                                            size: 14,
                                                            color: FitLifeTheme.highlightPink,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          AppText(
                                                            '${workout.weight}kg',
                                                            type: AppTextType.bodySmall,
                                                            color: FitLifeTheme.highlightPink,
                                                            useCleanStyle: true,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                                                      const SizedBox(height: FitLifeTheme.spacingXS),
                                                      AppText(
                                                        workout.notes!,
                                                        type: AppTextType.bodySmall,
                                                        color: FitLifeTheme.accentBlue,
                                                        useCleanStyle: true,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),

                                              // Completion indicator with accentGreen for completed workouts
                                              Icon(
                                                Icons.check_circle,
                                                color: FitLifeTheme.accentGreen,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Divider between items within the same date group
                                    if (index < dayWorkouts.length - 1) ...[
                                      const SizedBox(height: FitLifeTheme.spacingM),
                                      Divider(
                                        color: FitLifeTheme.dividerColor,
                                        thickness: 1,
                                        height: 1,
                                      ),
                                      const SizedBox(height: FitLifeTheme.spacingM),
                                    ],
                                  ],
                                );
                              }).toList(),
                              
                              // Spacing between date groups
                              const SizedBox(height: FitLifeTheme.spacingXL),
                            ],
                          );
                        }).toList(),
                      ],

                      const SizedBox(height: FitLifeTheme.spacingL),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedFAB(
        onPressed: _addExercise,
        icon: Icons.add,
        tooltip: 'Add Exercise',
      ),
    );
  }
}