import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/components/components.dart';
import 'services/checkin_service.dart';
import 'models/checkin.dart';
import 'main_scaffold.dart';
import 'main.dart'; // Import for getIt

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final CheckInService _checkInService = getIt<CheckInService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  // Form state
  String _selectedMood = CheckIn.moodOptions[1]; // Default to "Okay"
  double _energyLevel = 3.0; // Default to 3
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Submit the check-in form
  Future<void> _submitCheckIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final weight = double.parse(_weightController.text.trim());

      await _checkInService.addCheckIn(
        weight: weight,
        mood: _selectedMood,
        energyLevel: _energyLevel.toInt(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in saved!'),
            backgroundColor: FitLifeTheme.accentGreen,
          ),
        );
        // Navigate to HomeScreen (tab index 0)
        MainScaffold.navigateToTab(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save check-in: $e'),
            backgroundColor: FitLifeTheme.highlightPink,
          ),
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
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FitLifeTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInAnimation(
                child: AppText(
                  'How are you feeling today?',
                  type: AppTextType.headingSmall,
                  color: FitLifeTheme.primaryText,
                  useCleanStyle: true,
                ),
              ),
              const SizedBox(height: FitLifeTheme.spacingM),

              // Weight Input
              AppCard(
                useCleanStyle: true,
                child: Padding(
                  padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Weight (kg)',
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText.withOpacity(0.8),
                        useCleanStyle: true,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXS),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: FitLifeTheme.primaryText),
                        decoration: InputDecoration(
                          hintText: 'Enter your weight',
                          hintStyle: TextStyle(color: FitLifeTheme.primaryText.withOpacity(0.5)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FitLifeTheme.borderColor),
                            borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FitLifeTheme.accentGreen),
                            borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
                          ),
                          filled: true,
                          fillColor: FitLifeTheme.inputFillColor,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value.trim());
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FitLifeTheme.spacingM),

              // Mood Selector
              AppCard(
                useCleanStyle: true,
                child: Padding(
                  padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Mood',
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText.withOpacity(0.8),
                        useCleanStyle: true,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXS),
                      DropdownButtonFormField<String>(
                        value: _selectedMood,
                        items: CheckIn.moodOptions.map((mood) {
                          return DropdownMenuItem<String>(
                            value: mood,
                            child: AppText(
                              mood,
                              type: AppTextType.bodyMedium,
                              color: FitLifeTheme.primaryText,
                              useCleanStyle: true,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMood = value);
                          }
                        },
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FitLifeTheme.borderColor),
                            borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FitLifeTheme.accentGreen),
                            borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
                          ),
                          filled: true,
                          fillColor: FitLifeTheme.inputFillColor,
                        ),
                        dropdownColor: FitLifeTheme.surfaceColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FitLifeTheme.spacingM),

              // Energy Level Slider
              AppCard(
                useCleanStyle: true,
                child: Padding(
                  padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Energy Level',
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText.withOpacity(0.8),
                        useCleanStyle: true,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXS),
                      // Energy level labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Low',
                            type: AppTextType.bodySmall,
                            color: FitLifeTheme.primaryText.withOpacity(0.6),
                            useCleanStyle: true,
                          ),
                          AppText(
                            CheckIn.getEnergyLabel(_energyLevel.toInt()),
                            type: AppTextType.bodyMedium,
                            color: FitLifeTheme.accentGreen,
                            useCleanStyle: true,
                          ),
                          AppText(
                            'High',
                            type: AppTextType.bodySmall,
                            color: FitLifeTheme.primaryText.withOpacity(0.6),
                            useCleanStyle: true,
                          ),
                        ],
                      ),
                      Slider(
                        value: _energyLevel,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: FitLifeTheme.accentGreen,
                        inactiveColor: FitLifeTheme.dividerColor,
                        onChanged: (value) {
                          setState(() => _energyLevel = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FitLifeTheme.spacingM),

              // Notes Input
              AppCard(
                useCleanStyle: true,
                child: Padding(
                  padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Notes (Optional)',
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText.withOpacity(0.8),
                        useCleanStyle: true,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXS),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: TextStyle(color: FitLifeTheme.primaryText),
                        decoration: InputDecoration(
                          hintText: 'How did your workout go? Any observations?',
                          hintStyle: TextStyle(color: FitLifeTheme.primaryText.withOpacity(0.5)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FitLifeTheme.borderColor),
                            borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FitLifeTheme.accentGreen),
                            borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
                          ),
                          filled: true,
                          fillColor: FitLifeTheme.inputFillColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FitLifeTheme.spacingXL),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  text: 'Submit Check-In',
                  icon: Icons.check,
                  onPressed: _isLoading ? null : _submitCheckIn,
                  isLoading: _isLoading,
                  height: 44, // Smaller height
                  textSize: 14, // Smaller text
                  iconPadding: 8, // Less padding between icon and text
                ),
              ),

              const SizedBox(height: FitLifeTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}