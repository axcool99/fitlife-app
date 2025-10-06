import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../../services/workout_service.dart';
import '../../services/ai_service.dart';

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
  final _durationController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestion != null) {
      _exerciseController.text = widget.suggestion!.exerciseName;
      _setsController.text = widget.suggestion!.suggestedSets.toString();
      _repsController.text = widget.suggestion!.suggestedReps.toString();
      if (widget.suggestion!.suggestedWeight != null) {
        _weightController.text = widget.suggestion!.suggestedWeight!.toStringAsFixed(1);
      }
      _notesController.text = 'AI Suggested.';
    }
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await WorkoutService().addWorkout(
        exerciseName: _exerciseController.text.trim(),
        sets: int.parse(_setsController.text),
        reps: int.parse(_repsController.text),
        duration: _durationController.text.isNotEmpty ? int.parse(_durationController.text) : null,
        weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout added successfully!')),
        );
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

              const SizedBox(height: FitLifeTheme.spacingM),

              // Duration and Weight Row
              Row(
                children: [
                  // Duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Duration (sec)',
                          type: AppTextType.bodyMedium,
                          color: FitLifeTheme.primaryText,
                          useCleanStyle: true,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingXS),
                        AppInput(
                          controller: _durationController,
                          hintText: 'Optional',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final duration = int.tryParse(value);
                              if (duration == null || duration < 1 || duration > 3600) {
                                return '1-3600';
                              }
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: FitLifeTheme.spacingM),

                  // Weight
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Weight (kg)',
                          type: AppTextType.bodyMedium,
                          color: FitLifeTheme.primaryText,
                          useCleanStyle: true,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingXS),
                        AppInput(
                          controller: _weightController,
                          hintText: 'Optional',
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final weight = double.tryParse(value);
                              if (weight == null || weight < 0.1 || weight > 500) {
                                return '0.1-500';
                              }
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

              const SizedBox(height: FitLifeTheme.spacingM),

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
}