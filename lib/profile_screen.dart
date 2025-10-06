import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/components/components.dart';
import 'services/services.dart';
import 'models/models.dart';
import 'main.dart'; // Import for getIt

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = getIt<ProfileService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile();
      if (profile == null && mounted) {
        // Initialize profile if it doesn't exist
        final user = _auth.currentUser;
        if (user != null) {
          await _profileService.initializeProfile(
            user.displayName ?? user.email?.split('@')[0] ?? 'User',
            user.email ?? '',
          );
          _profile = await _profileService.getProfile();
        }
      } else {
        _profile = profile;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: FitLifeTheme.highlightPink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: FitLifeAppBar(
        title: 'Profile',
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Profile?>(
              stream: _profileService.getProfileStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: FitLifeTheme.textSecondary,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        AppText(
                          'Failed to load profile',
                          type: AppTextType.body,
                          color: FitLifeTheme.textSecondary,
                        ),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        AppButton(
                          text: 'Retry',
                          onPressed: _loadProfile,
                          variant: AppButtonVariant.secondary,
                        ),
                      ],
                    ),
                  );
                }

                final profile = snapshot.data ?? _profile;
                if (profile == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        _buildProfileHeader(profile),

                        const SizedBox(height: FitLifeTheme.spacingXL),

                        // Personal Information
                        _buildSectionTitle('Personal Information'),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        _buildPersonalInfoSection(profile),

                        const SizedBox(height: FitLifeTheme.spacingXL),

                        // Fitness Goals
                        _buildSectionTitle('Fitness Goals'),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        _buildFitnessGoalsSection(profile),

                        const SizedBox(height: FitLifeTheme.spacingXL),

                        // Account Management
                        _buildSectionTitle('Account'),
                        const SizedBox(height: FitLifeTheme.spacingM),
                        _buildAccountSection(),

                        const SizedBox(height: FitLifeTheme.spacingXXL),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Container(
      padding: const EdgeInsets.all(FitLifeTheme.spacingL),
      decoration: BoxDecoration(
        color: FitLifeTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FitLifeTheme.accentGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: FitLifeTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: FitLifeTheme.accentGreen,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: FitLifeTheme.accentGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: FitLifeTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  profile.displayName,
                  type: AppTextType.headingSmall,
                ),
                const SizedBox(height: 4),
                AppText(
                  profile.email,
                  type: AppTextType.bodySmall,
                  color: FitLifeTheme.textSecondary,
                ),
                if (profile.bmi != null) ...[
                  const SizedBox(height: 4),
                  AppText(
                    'BMI: ${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})',
                    type: AppTextType.bodySmall,
                    color: FitLifeTheme.accentGreen,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return AppText(
      title,
      type: AppTextType.headingSmall,
      color: FitLifeTheme.accentGreen,
    );
  }

  Widget _buildPersonalInfoSection(Profile profile) {
    return Column(
      children: [
        _buildEditableField(
          label: 'Display Name',
          value: profile.displayName,
          onSave: (value) async {
            if (value.trim().isEmpty || value.length < 2) {
              throw 'Display name must be at least 2 characters';
            }
            final success = await _profileService.updateDisplayName(value.trim());
            if (!success) throw 'Failed to update display name';
          },
        ),
        _buildEmailField(profile.email),
        _buildEditableField(
          label: 'Age',
          value: profile.age?.toString() ?? '',
          keyboardType: TextInputType.number,
          onSave: (value) async {
            final age = int.tryParse(value);
            if (age != null && (age < Profile.minAge || age > Profile.maxAge)) {
              throw 'Age must be between ${Profile.minAge} and ${Profile.maxAge}';
            }
            final success = await _profileService.updatePersonalMetrics(age: age);
            if (!success) throw 'Failed to update age';
          },
        ),
        _buildEditableField(
          label: 'Height (cm)',
          value: profile.height?.toStringAsFixed(1) ?? '',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onSave: (value) async {
            final height = double.tryParse(value);
            if (height != null && (height < Profile.minHeight || height > Profile.maxHeight)) {
              throw 'Height must be between ${Profile.minHeight} and ${Profile.maxHeight} cm';
            }
            final success = await _profileService.updatePersonalMetrics(height: height);
            if (!success) throw 'Failed to update height';
          },
        ),
        _buildEditableField(
          label: 'Weight (kg)',
          value: profile.weight?.toStringAsFixed(1) ?? '',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onSave: (value) async {
            final weight = double.tryParse(value);
            if (weight != null && (weight < Profile.minWeight || weight > Profile.maxWeight)) {
              throw 'Weight must be between ${Profile.minWeight} and ${Profile.maxWeight} kg';
            }
            final success = await _profileService.updatePersonalMetrics(weight: weight);
            if (!success) throw 'Failed to update weight';
          },
        ),
        _buildDropdownField(
          label: 'Fitness Level',
          value: profile.fitnessLevel ?? Profile.defaultFitnessLevel,
          items: Profile.fitnessLevels,
          onChanged: (value) async {
            final success = await _profileService.updatePersonalMetrics(fitnessLevel: value);
            if (!success) throw 'Failed to update fitness level';
          },
        ),
      ],
    );
  }

  Widget _buildFitnessGoalsSection(Profile profile) {
    return Column(
      children: [
        _buildEditableField(
          label: 'Daily Calorie Target',
          value: profile.dailyCalorieTarget?.toString() ?? '',
          keyboardType: TextInputType.number,
          onSave: (value) async {
            final calories = int.tryParse(value);
            if (calories != null && (calories < Profile.minCalorieTarget || calories > Profile.maxCalorieTarget)) {
              throw 'Calorie target must be between ${Profile.minCalorieTarget} and ${Profile.maxCalorieTarget}';
            }
            final success = await _profileService.updateFitnessGoals(dailyCalorieTarget: calories);
            if (!success) throw 'Failed to update calorie target';
          },
        ),
        _buildEditableField(
          label: 'Daily Step Goal',
          value: profile.stepGoal?.toString() ?? '',
          keyboardType: TextInputType.number,
          onSave: (value) async {
            final steps = int.tryParse(value);
            if (steps != null && (steps < Profile.minStepGoal || steps > Profile.maxStepGoal)) {
              throw 'Step goal must be between ${Profile.minStepGoal} and ${Profile.maxStepGoal}';
            }
            final success = await _profileService.updateFitnessGoals(stepGoal: steps);
            if (!success) throw 'Failed to update step goal';
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        _buildActionButton(
          'Change Password',
          Icons.lock,
          () => _showChangePasswordDialog(),
        ),
        _buildActionButton(
          'Logout',
          Icons.logout,
          _logout,
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? trailing,
    required Future<void> Function(String) onSave,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingS),
      padding: const EdgeInsets.all(FitLifeTheme.spacingM),
      decoration: BoxDecoration(
        color: FitLifeTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                AppText(
                  label,
                  type: AppTextType.bodySmall,
                  color: FitLifeTheme.textSecondary,
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
          ),
          const SizedBox(height: FitLifeTheme.spacingXS),
          EditableTextField(
            initialValue: value,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onSave: onSave,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingS),
      padding: const EdgeInsets.all(FitLifeTheme.spacingM),
      decoration: BoxDecoration(
        color: FitLifeTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                AppText(
                  'Email',
                  type: AppTextType.bodySmall,
                  color: FitLifeTheme.textSecondary,
                ),
                const Spacer(),
                Tooltip(
                  message: 'Email cannot be changed',
                  child: Icon(
                    Icons.lock,
                    color: FitLifeTheme.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FitLifeTheme.spacingXS),
          AppText(
            email,
            type: AppTextType.body,
            color: FitLifeTheme.textSecondary.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Future<void> Function(String) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingS),
      padding: const EdgeInsets.all(FitLifeTheme.spacingM),
      decoration: BoxDecoration(
        color: FitLifeTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            type: AppTextType.bodySmall,
            color: FitLifeTheme.textSecondary,
          ),
          const SizedBox(height: FitLifeTheme.spacingXS),
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: AppText(item, type: AppTextType.body),
            )).toList(),
            onChanged: (newValue) async {
              if (newValue != null) {
                try {
                  await onChanged(newValue);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitness level updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: FitLifeTheme.highlightPink,
                      ),
                    );
                  }
                }
              }
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            dropdownColor: FitLifeTheme.surfaceColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, {bool isDestructive = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingS),
      child: AppButton(
        text: text,
        onPressed: onPressed,
        variant: isDestructive ? AppButtonVariant.primary : AppButtonVariant.secondary,
        icon: icon,
      ),
    );
  }

  void _showChangePasswordDialog() {
    String currentPassword = '';
    String newPassword = '';
    String confirmPassword = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitLifeTheme.surfaceColor,
        title: const AppText('Change Password', type: AppTextType.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              labelText: 'Current Password',
              obscureText: true,
              onChanged: (value) => currentPassword = value,
            ),
            const SizedBox(height: FitLifeTheme.spacingM),
            AppInput(
              labelText: 'New Password',
              obscureText: true,
              onChanged: (value) => newPassword = value,
            ),
            const SizedBox(height: FitLifeTheme.spacingM),
            AppInput(
              labelText: 'Confirm New Password',
              obscureText: true,
              onChanged: (value) => confirmPassword = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText('Cancel', type: AppTextType.body, color: FitLifeTheme.textSecondary),
          ),
          TextButton(
            onPressed: () async {
              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: FitLifeTheme.highlightPink,
                  ),
                );
                return;
              }

              try {
                final success = await _profileService.updatePassword(currentPassword, newPassword);
                if (success && mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: FitLifeTheme.highlightPink,
                  ),
                );
              }
            },
            child: AppText('Update', type: AppTextType.body),
          ),
        ],
      ),
    );
  }

}