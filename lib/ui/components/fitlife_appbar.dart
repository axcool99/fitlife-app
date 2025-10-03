import 'package:flutter/material.dart';
import 'components.dart';

/// FitLifeAppBar - Unified AppBar component with FitLifeTheme styling
/// Provides consistent neon highlight styling across all screens
class FitLifeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text to display in the AppBar
  final String title;

  /// Optional leading widget (usually back button)
  final Widget? leading;

  /// List of action widgets (icons, buttons)
  final List<Widget>? actions;

  /// Whether to center the title
  final bool centerTitle;

  /// Whether to show the leading widget automatically
  final bool automaticallyImplyLeading;

  const FitLifeAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Background and elevation
      backgroundColor: FitLifeTheme.background,
      elevation: 0,
      shadowColor: Colors.transparent,

      // Title styling with neon highlights
      title: AppText(
        title,
        type: AppTextType.headingSmall,
        color: FitLifeTheme.primaryText,
        useCleanStyle: true,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: centerTitle,

      // Icon theme for consistent neon green
      iconTheme: IconThemeData(
        color: FitLifeTheme.accentGreen,
        size: 24.0, // Consistent 24dp size
      ),

      // Leading and actions
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,

      // Ensure proper toolbar height
      toolbarHeight: kToolbarHeight,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Convenience method to create a back button with consistent styling
Widget fitLifeBackButton(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.of(context).pop(),
    tooltip: 'Back',
  );
}

/// Convenience method to create an overflow menu button for profile actions
Widget fitLifeOverflowMenu({
  required BuildContext context,
  required VoidCallback onEditProfile,
  required VoidCallback onSettings,
  required VoidCallback onLogout,
}) {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) {
      switch (value) {
        case 'edit_profile':
          onEditProfile();
          break;
        case 'settings':
          onSettings();
          break;
        case 'logout':
          onLogout();
          break;
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem<String>(
        value: 'edit_profile',
        child: Row(
          children: [
            Icon(Icons.edit, color: FitLifeTheme.accentGreen),
            SizedBox(width: 12),
            AppText('Edit Profile', type: AppTextType.bodyMedium),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'settings',
        child: Row(
          children: [
            Icon(Icons.settings, color: FitLifeTheme.accentGreen),
            SizedBox(width: 12),
            AppText('Settings', type: AppTextType.bodyMedium),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: FitLifeTheme.accentGreen),
            SizedBox(width: 12),
            AppText('Logout', type: AppTextType.bodyMedium),
          ],
        ),
      ),
    ],
  );
}