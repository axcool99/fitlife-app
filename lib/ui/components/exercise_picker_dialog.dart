import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../ui/theme/theme.dart';
import '../../main.dart' as main;
import 'components.dart';
import 'shimmer_loading.dart';
import 'micro_interactions.dart';

/// Dialog for picking exercises from ExerciseDB API
class ExercisePickerDialog extends StatefulWidget {
  const ExercisePickerDialog({super.key});

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();

  /// Show the exercise picker dialog
  static Future<Exercise?> show(BuildContext context) {
    return showDialog<Exercise>(
      context: context,
      builder: (context) => const ExercisePickerDialog(),
    );
  }
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  final ExerciseService _exerciseService = main.getIt<ExerciseService>();
  final TextEditingController _searchController = TextEditingController();

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedBodyPart;
  String? _selectedEquipment;

  List<String> _availableBodyParts = [];
  List<String> _availableEquipment = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exercises = await _exerciseService.getExercises();
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _filteredExercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              'Failed to load exercises. Please try again.',
              type: AppTextType.bodySmall,
              color: FitLifeTheme.background,
            ),
            backgroundColor: FitLifeTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadFilters() async {
    try {
      final bodyParts = await _exerciseService.getAvailableBodyParts();
      final equipment = await _exerciseService.getAvailableEquipment();

      if (mounted) {
        setState(() {
          _availableBodyParts = bodyParts;
          _availableEquipment = equipment;
        });
      }
    } catch (e) {
      // Silently fail for filters
      print('Error loading filters: $e');
    }
  }

  Future<void> _searchExercises(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    try {
      List<Exercise> results;
      if (query.trim().isEmpty) {
        results = await _exerciseService.getExercises();
      } else {
        results = await _exerciseService.searchExercises(query);
      }

      if (mounted) {
        setState(() {
          _exercises = results;
          _applyFilters();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              'Search failed. Please try again.',
              type: AppTextType.bodySmall,
              color: FitLifeTheme.background,
            ),
            backgroundColor: FitLifeTheme.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = _exercises.where((exercise) {
        return exercise.matchesFilters(
          bodyPartFilter: _selectedBodyPart,
          equipmentFilter: _selectedEquipment,
        );
      }).toList();
    });
  }

  void _onExerciseSelected(Exercise exercise) {
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FitLifeTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(FitLifeTheme.spacingM),
              decoration: BoxDecoration(
                color: FitLifeTheme.primaryText.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(FitLifeTheme.radiusM),
                  topRight: Radius.circular(FitLifeTheme.radiusM),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: FitLifeTheme.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: FitLifeTheme.spacingS),
                  Expanded(
                    child: AppText(
                      'Select Exercise',
                      type: AppTextType.headingSmall,
                      color: FitLifeTheme.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: FitLifeTheme.primaryText.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Search and Filters
            Padding(
              padding: const EdgeInsets.all(FitLifeTheme.spacingM),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: FitLifeTheme.primaryText.withOpacity(0.6),
                      ),
                      suffixIcon: _isSearching
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FitLifeTheme.accentGreen,
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchExercises('');
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: FitLifeTheme.primaryText.withOpacity(0.6),
                                  ),
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                        borderSide: BorderSide(
                          color: FitLifeTheme.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                        borderSide: BorderSide(
                          color: FitLifeTheme.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                        borderSide: BorderSide(
                          color: FitLifeTheme.accentGreen,
                        ),
                      ),
                      filled: true,
                      fillColor: FitLifeTheme.background,
                    ),
                    onSubmitted: _searchExercises,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _searchExercises('');
                      }
                    },
                  ),

                  const SizedBox(height: FitLifeTheme.spacingM),

                  // Filters Row
                  Row(
                    children: [
                      // Body Part Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedBodyPart,
                          decoration: InputDecoration(
                            labelText: 'Body Part',
                            labelStyle: TextStyle(
                              color: FitLifeTheme.primaryText.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: FitLifeTheme.spacingS,
                              vertical: FitLifeTheme.spacingXS,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: AppText('All Body Parts', type: AppTextType.bodySmall),
                            ),
                            ..._availableBodyParts.map((bodyPart) {
                              return DropdownMenuItem(
                                value: bodyPart,
                                child: AppText(
                                  bodyPart.replaceAll('_', ' ').toUpperCase(),
                                  type: AppTextType.bodySmall,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBodyPart = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),

                      const SizedBox(width: FitLifeTheme.spacingM),

                      // Equipment Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedEquipment,
                          decoration: InputDecoration(
                            labelText: 'Equipment',
                            labelStyle: TextStyle(
                              color: FitLifeTheme.primaryText.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: FitLifeTheme.spacingS,
                              vertical: FitLifeTheme.spacingXS,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: AppText('All Equipment', type: AppTextType.bodySmall),
                            ),
                            ..._availableEquipment.map((equipment) {
                              return DropdownMenuItem(
                                value: equipment,
                                child: AppText(
                                  equipment.replaceAll('_', ' ').toUpperCase(),
                                  type: AppTextType.bodySmall,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEquipment = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Exercise List
            Expanded(
              child: CustomRefreshIndicator(
                onRefresh: _loadExercises,
                child: _isLoading
                    ? ShimmerLoading(
                        child: SkeletonList(itemCount: 5, itemHeight: 80),
                      )
                    : _filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: FitLifeTheme.primaryText.withOpacity(0.3),
                              ),
                              const SizedBox(height: FitLifeTheme.spacingM),
                              AppText(
                                'No exercises found',
                                type: AppTextType.bodyMedium,
                                color: FitLifeTheme.primaryText.withOpacity(0.6),
                              ),
                              const SizedBox(height: FitLifeTheme.spacingS),
                              AppText(
                                'Try adjusting your search or filters',
                                type: AppTextType.bodySmall,
                                color: FitLifeTheme.primaryText.withOpacity(0.4),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: FitLifeTheme.spacingM),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            return FadeInAnimation(
                              child: _ExerciseListItem(
                                exercise: exercise,
                                onTap: () => _onExerciseSelected(exercise),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual exercise list item
class _ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseListItem({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FitLifeTheme.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.all(FitLifeTheme.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: FitLifeTheme.dividerColor,
              ),
              borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
            ),
            child: Row(
              children: [
                // GIF Preview
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FitLifeTheme.radiusS),
                    color: FitLifeTheme.surfaceColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FitLifeTheme.radiusS),
                    child: CachedNetworkImage(
                      imageUrl: exercise.gifUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: FitLifeTheme.dividerColor,
                        child: Icon(
                          Icons.fitness_center,
                          color: FitLifeTheme.primaryText.withOpacity(0.3),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: FitLifeTheme.dividerColor,
                        child: Icon(
                          Icons.fitness_center,
                          color: FitLifeTheme.primaryText.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: FitLifeTheme.spacingM),

                // Exercise Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Name
                      AppText(
                        exercise.displayName,
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: FitLifeTheme.spacingXS),

                      // Body Part and Target
                      Row(
                        children: [
                          _buildInfoChip(
                            exercise.bodyPartDisplay,
                            FitLifeTheme.accentBlue,
                          ),
                          const SizedBox(width: FitLifeTheme.spacingXS),
                          _buildInfoChip(
                            exercise.targetDisplay,
                            FitLifeTheme.accentGreen,
                          ),
                        ],
                      ),

                      const SizedBox(height: FitLifeTheme.spacingXS),

                      // Equipment
                      _buildInfoChip(
                        exercise.equipmentDisplay,
                        FitLifeTheme.accentOrange,
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: FitLifeTheme.primaryText.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitLifeTheme.spacingXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FitLifeTheme.radiusS),
      ),
      child: AppText(
        label,
        type: AppTextType.bodySmall,
        color: color,
      ),
    );
  }
}