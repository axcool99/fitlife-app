/// FitLife Style Guide - Unified Theme Reference
///
/// This file serves as the authoritative reference for FitLife's design system
/// and color mapping. All UI components must follow these guidelines.
///
/// ## Color Mapping by Category
///
/// ### Primary Categories & Colors
/// - **Workouts** = FitLifeTheme.accentGreen (#00FF85)
///   - Workout cards, workout-related icons, workout progress indicators
///   - Example: Workout completion badges, exercise timers, workout history
///
/// - **Calories** = FitLifeTheme.accentBlue (#1E90FF)
///   - Calorie tracking, nutrition data, calorie burn charts
///   - Example: Daily calorie counters, calorie progress bars, nutrition cards
///
/// - **Steps** = FitLifeTheme.accentPurple (#9B59B6)
///   - Step counting, activity tracking, step goals
///   - Example: Step counters, activity rings, step progress indicators
///
/// - **Weight Trend & Check-ins** = FitLifeTheme.accentOrange (#FFA500)
///   - Weight charts, check-in forms, weight history
///   - Example: Weight trend graphs, check-in cards, weight milestone badges
///
/// - **Profile/General** = FitLifeTheme.textPrimary / neutral grey (#FFFFFF / #B3B3B3)
///   - User profiles, settings, general UI elements
///   - Example: Profile cards, settings screens, neutral backgrounds
///
/// ## Implementation Rules
///
/// ### 1. Color Usage
/// - NEVER use hardcoded colors (e.g., `Color(0xFF00FF85)`)
/// - ALWAYS use `FitLifeTheme` constants (e.g., `FitLifeTheme.accentGreen`)
/// - Each UI component must consistently use its category's assigned color
///
/// ### 2. Component Structure
/// Every card/chart component should apply colors to:
/// - Header icon
/// - Chart lines/bars/areas
/// - Progress indicators
/// - Touch interactions (hover states, selection indicators)
///
/// ### 3. Examples
///
/// #### Workout Card
/// ```dart
/// // ✅ CORRECT
/// Icon(Icons.fitness_center, color: FitLifeTheme.accentGreen)
/// LinearProgressIndicator(valueColor: AlwaysStoppedAnimation(FitLifeTheme.accentGreen))
///
/// // ❌ WRONG - Never do this
/// Icon(Icons.fitness_center, color: Color(0xFF00FF85))
/// LinearProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.green))
/// ```
///
/// #### Calorie Chart
/// ```dart
/// // ✅ CORRECT
/// LineChartBarData(
///   color: FitLifeTheme.accentBlue,
///   dotData: FlDotData(getDotPainter: (spot, percent, barData, index) =>
///     FlDotCirclePainter(color: FitLifeTheme.accentBlue)),
/// )
/// ```
///
/// ## Screen-Specific Guidelines
///
/// ### HomeScreen
/// - Workouts Completed → accentGreen
/// - Calories Burned Today → accentBlue
/// - Steps Walked Today → accentPurple
/// - Weight Trend card → accentOrange
///
/// ### ProgressScreen
/// - Daily Calories Burned → accentBlue
/// - This Week Stats:
///   - Avg Calories → accentBlue
///   - Steps → accentPurple
///   - Workouts → accentGreen
/// - Weight Trend → accentOrange
///
/// ### Check-in History
/// - Weight displays → accentOrange
/// - Charts and icons → accentOrange
///
/// ## Maintenance
///
/// When adding new features:
/// 1. Check this guide first
/// 2. Assign appropriate category color
/// 3. Update this guide if new categories are needed
/// 4. Ensure consistency across all screens
///
/// ## Version History
/// - v1.0: Initial unified color mapping (Workouts=Green, Calories=Blue, Steps=Purple, Weight=Orange)
///   - Added accentOrange and accentPurple to FitLifeTheme
///   - Refactored all screens to use category-based colors</content>
<parameter name="filePath">/Users/axcool/Desktop/ff/lib/theme/fitlife_style_guide.dart