import 'package:flutter/material.dart';
import '../components/components.dart';

/// Dialog that allows users to choose between Quick Add (manual entry) or Browse Exercises (from database)
class ExerciseChoiceDialog extends StatelessWidget {
  const ExerciseChoiceDialog({super.key});

  /// Shows the exercise choice dialog and returns the selected option
  static Future<ExerciseChoice?> show(BuildContext context) {
    return showDialog<ExerciseChoice>(
      context: context,
      builder: (context) => const ExerciseChoiceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FitLifeTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    Icons.add,
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

            AppText(
              'How would you like to add your workout?',
              type: AppTextType.bodyMedium,
              color: FitLifeTheme.primaryText.withOpacity(0.8),
              useCleanStyle: true,
            ),

            const SizedBox(height: FitLifeTheme.spacingXL),

            // Quick Add Option
            _buildChoiceButton(
              context: context,
              icon: Icons.edit,
              title: 'Quick Add',
              description: 'Manually enter exercise details',
              color: FitLifeTheme.accentBlue,
              onPressed: () => Navigator.of(context).pop(ExerciseChoice.quickAdd),
            ),

            const SizedBox(height: FitLifeTheme.spacingM),

            // Browse Exercises Option
            _buildChoiceButton(
              context: context,
              icon: Icons.search,
              title: 'Browse Exercises',
              description: 'Choose from exercise database',
              color: FitLifeTheme.accentGreen,
              onPressed: () => Navigator.of(context).pop(ExerciseChoice.browseExercises),
            ),

            const SizedBox(height: FitLifeTheme.spacingL),

            // Cancel button
            AppButton(
              text: 'Cancel',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
              useCleanStyle: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(FitLifeTheme.spacingM),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(FitLifeTheme.cardBorderRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: FitLifeTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      type: AppTextType.bodyLarge,
                      color: FitLifeTheme.primaryText,
                      useCleanStyle: true,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      description,
                      type: AppTextType.bodySmall,
                      color: FitLifeTheme.primaryText.withOpacity(0.6),
                      useCleanStyle: true,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enum representing the user's choice for adding exercises
enum ExerciseChoice {
  quickAdd,
  browseExercises,
}