import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../../services/workout_service.dart';
import '../../services/gamification_service.dart';
import '../../models/badge.dart' as badge_model;
import '../../services/ai_service.dart';
import '../../main.dart'; // Import for getIt
import '../../home_screen.dart';
import '../../progress_screen.dart';

class AddWorkoutDialog extends StatefulWidget {
  final WorkoutSuggestion? suggestion;

  const AddWorkoutDialog({super.key, this.suggestion});

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestion != null) {
      _exerciseController.text = widget.suggestion!.exerciseName;
      _setsController.text = widget.suggestion!.suggestedSets.toString();
      _repsController.text = widget.suggestion!.suggestedReps.toString();
      _notesController.text = 'AI Suggested.';
    }
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await getIt<WorkoutService>().addWorkout(
        exerciseName: _exerciseController.text.trim(),
        sets: int.parse(_setsController.text),
        reps: int.parse(_repsController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Track this workout in AI service to avoid repetition
      final aiService = getIt<AIService>();
      aiService.trackRecentlyAddedWorkout(_exerciseController.text.trim());

      // Check for new badges after workout is added
      final gamificationService = getIt<GamificationService>();
      final newBadges = await gamificationService.checkAndAwardBadges();

      if (mounted) {
        if (newBadges.isNotEmpty) {
          // Show badge notification dialog
          _showBadgeNotification(newBadges);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout added successfully!')),
          );
        }
        
        // Refresh home screen and progress screen data
        HomeScreen.refreshData();
        ProgressScreen.refreshData();
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding workout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FitLifeTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FitLifeTheme.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: FitLifeTheme.accentGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: FitLifeTheme.spacingM),
                  Expanded(
                    child: AppText(
                      'Add Workout',
                      type: AppTextType.headingMedium,
                      color: FitLifeTheme.primaryText,
                      useCleanStyle: true,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: FitLifeTheme.primaryText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: FitLifeTheme.spacingL),

              // Exercise Name
              AppText(
                'Exercise Name',
                type: AppTextType.bodyMedium,
                color: FitLifeTheme.primaryText,
                useCleanStyle: true,
              ),
              const SizedBox(height: FitLifeTheme.spacingXS),
              AppInput(
                controller: _exerciseController,
                hintText: 'e.g., Push-ups, Squats, Bench Press',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Exercise name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Exercise name must be at least 2 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: FitLifeTheme.spacingM),

              // Sets and Reps Row
              Row(
                children: [
                  // Sets
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Sets',
                          type: AppTextType.bodyMedium,
                          color: FitLifeTheme.primaryText,
                          useCleanStyle: true,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingXS),
                        AppInput(
                          controller: _setsController,
                          hintText: '3',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final sets = int.tryParse(value);
                            if (sets == null || sets < 1 || sets > 20) {
                              return '1-20';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: FitLifeTheme.spacingM),

                  // Reps
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Reps',
                          type: AppTextType.bodyMedium,
                          color: FitLifeTheme.primaryText,
                          useCleanStyle: true,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingXS),
                        AppInput(
                          controller: _repsController,
                          hintText: '10',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final reps = int.tryParse(value);
                            if (reps == null || reps < 1 || reps > 999) {
                              return '1-999';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),


              // Notes (Optional)
              AppText(
                'Notes (Optional)',
                type: AppTextType.bodyMedium,
                color: FitLifeTheme.primaryText,
                useCleanStyle: true,
              ),
              const SizedBox(height: FitLifeTheme.spacingXS),
              AppInput(
                controller: _notesController,
                hintText: 'e.g., Focus on form, use light weights',
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitWorkout(),
              ),

              const SizedBox(height: FitLifeTheme.spacingXL),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                      useCleanStyle: true,
                    ),
                  ),
                  const SizedBox(width: FitLifeTheme.spacingM),
                  Expanded(
                    child: AppButton(
                      text: 'Add Workout',
                      variant: AppButtonVariant.primary,
                      onPressed: _isLoading ? null : _submitWorkout,
                      useCleanStyle: true,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeNotification(List<badge_model.Badge> newBadges) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitLifeTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: FitLifeTheme.accentGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Achievement Unlocked!',
              style: FitLifeTheme.headingSmall.copyWith(
                color: FitLifeTheme.accentGreen,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations! You\'ve earned ${newBadges.length} new badge${newBadges.length > 1 ? 's' : ''}:',
              style: FitLifeTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...newBadges.map((badge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _getBadgeIcon(badge.category),
                    color: _getBadgeColor(badge.category),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          style: FitLifeTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          badge.description,
                          style: FitLifeTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Awesome!',
              style: TextStyle(color: FitLifeTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBadgeIcon(badge_model.BadgeCategory category) {
    switch (category) {
      case badge_model.BadgeCategory.streak:
        return Icons.local_fire_department;
      case badge_model.BadgeCategory.workouts:
        return Icons.fitness_center;
      case badge_model.BadgeCategory.strength:
        return Icons.monitor_weight;
      case badge_model.BadgeCategory.consistency:
        return Icons.calendar_today;
      case badge_model.BadgeCategory.achievement:
        return Icons.emoji_events;
    }
  }

  Color _getBadgeColor(badge_model.BadgeCategory category) {
    switch (category) {
      case badge_model.BadgeCategory.streak:
        return FitLifeTheme.accentOrange;
      case badge_model.BadgeCategory.workouts:
        return FitLifeTheme.accentGreen;
      case badge_model.BadgeCategory.strength:
        return FitLifeTheme.accentBlue;
      case badge_model.BadgeCategory.consistency:
        return FitLifeTheme.accentPurple;
      case badge_model.BadgeCategory.achievement:
        return FitLifeTheme.textPrimary;
    }
  }
}