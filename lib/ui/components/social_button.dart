import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// SocialButton - Reusable social login button component for FitLife app
/// Features white background, rounded corners, light gray border, and press shadow
class SocialButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool useCleanStyle; // New parameter to switch between styles

  const SocialButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 56.0,
    this.useCleanStyle = true, // Default to clean style
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useCleanStyle) {
      // Clean minimal style
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: FitLifeTheme.surfaceColor, // Dark surface for monochromatic theme
            border: Border.all(color: FitLifeTheme.borderColor), // Gray border
            borderRadius: BorderRadius.circular(FitLifeTheme.buttonBorderRadius),
            boxShadow: _isPressed
                ? [FitLifeTheme.buttonShadow]
                : null,
          ),
          child: Icon(
            widget.icon,
            color: FitLifeTheme.textPrimary, // Light gray for icons
            size: widget.size * 0.5, // Icon size relative to button size
          ),
        ),
      );
    } else {
      // Legacy style
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: FitLifeTheme.surfaceColor, // Dark surface for monochromatic theme
            border: Border.all(color: FitLifeTheme.borderColor), // Gray border
            borderRadius: BorderRadius.circular(FitLifeTheme.legacyButtonBorderRadius),
            boxShadow: _isPressed
                ? [FitLifeTheme.softShadow]
                : null,
          ),
          child: Icon(
            widget.icon,
            color: FitLifeTheme.textPrimary, // Light gray for icons
            size: widget.size * 0.5, // Icon size relative to button size
          ),
        ),
      );
    }
  }
}