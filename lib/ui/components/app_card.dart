import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// AppCard - Reusable card component for FitLife app
/// Supports clean minimal style with white background and soft shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool glassmorphism;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool useCleanStyle; // New parameter to switch between styles

  const AppCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(FitLifeTheme.spacingM),
    this.margin,
    this.glassmorphism = false,
    this.backgroundColor,
    this.onTap,
    this.borderRadius = FitLifeTheme.cardBorderRadius,
    this.useCleanStyle = true, // Default to clean style
  });

  @override
  Widget build(BuildContext context) {
    if (useCleanStyle && !glassmorphism) {
      // Clean minimal style - white background with soft shadow
      Widget card = Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? FitLifeTheme.surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [FitLifeTheme.cardShadow],
        ),
        child: child,
      );

      if (onTap != null) {
        card = GestureDetector(
          onTap: onTap,
          child: card,
        );
      }

      return card;
    } else {
      // Legacy style or glassmorphism
      Widget card = Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: glassmorphism
              ? Colors.white.withValues(alpha: 0.2)
              : backgroundColor ?? FitLifeTheme.surfaceColor, // Use dark surface color
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: glassmorphism ? null : [FitLifeTheme.softShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: glassmorphism
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: padding,
                    child: child,
                  ),
                )
              : Container(
                  padding: padding,
                  child: child,
                ),
        ),
      );

      if (onTap != null) {
        card = GestureDetector(
          onTap: onTap,
          child: card,
        );
      }

      return card;
    }
  }
}