import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// AppText - Wrapper for consistent typography in FitLife app
/// Supports both clean minimal and legacy typography styles
enum AppTextType {
  // Clean minimal styles
  headingLarge,
  headingMedium,
  headingSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  link,

  // Legacy styles
  h1,
  h2,
  h3,
  body,
  secondary,
  caption
}

class AppText extends StatelessWidget {
  final String text;
  final AppTextType type;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool useCleanStyle; // New parameter to switch between styles

  const AppText(
    this.text, {
    super.key,
    required this.type,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.useCleanStyle = true, // Default to clean style
  });

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle;

    if (useCleanStyle) {
      // Clean minimal typography
      switch (type) {
        case AppTextType.headingLarge:
          baseStyle = FitLifeTheme.headingLarge;
          break;
        case AppTextType.headingMedium:
          baseStyle = FitLifeTheme.headingMedium;
          break;
        case AppTextType.headingSmall:
          baseStyle = FitLifeTheme.headingSmall;
          break;
        case AppTextType.bodyLarge:
          baseStyle = FitLifeTheme.bodyLarge;
          break;
        case AppTextType.bodyMedium:
          baseStyle = FitLifeTheme.bodyMedium;
          break;
        case AppTextType.bodySmall:
          baseStyle = FitLifeTheme.bodySmall;
          break;
        case AppTextType.link:
          baseStyle = FitLifeTheme.link;
          break;
        // Legacy fallbacks
        case AppTextType.h1:
          baseStyle = FitLifeTheme.headingLarge;
          break;
        case AppTextType.h2:
          baseStyle = FitLifeTheme.headingMedium;
          break;
        case AppTextType.h3:
          baseStyle = FitLifeTheme.headingSmall;
          break;
        case AppTextType.body:
          baseStyle = FitLifeTheme.bodyLarge;
          break;
        case AppTextType.secondary:
          baseStyle = FitLifeTheme.bodyMedium;
          break;
        case AppTextType.caption:
          baseStyle = FitLifeTheme.bodySmall;
          break;
      }
    } else {
      // Legacy typography - updated to use monochromatic colors
      switch (type) {
        case AppTextType.h1:
          baseStyle = FitLifeTheme.headingLarge.copyWith(color: FitLifeTheme.textPrimary);
          break;
        case AppTextType.h2:
          baseStyle = FitLifeTheme.headingMedium.copyWith(color: FitLifeTheme.textPrimary);
          break;
        case AppTextType.h3:
          baseStyle = FitLifeTheme.headingSmall.copyWith(color: FitLifeTheme.textPrimary);
          break;
        case AppTextType.body:
          baseStyle = FitLifeTheme.bodyLarge.copyWith(color: FitLifeTheme.textSecondary);
          break;
        case AppTextType.secondary:
          baseStyle = FitLifeTheme.bodyMedium.copyWith(color: FitLifeTheme.textSecondary);
          break;
        case AppTextType.caption:
          baseStyle = FitLifeTheme.bodySmall.copyWith(color: FitLifeTheme.textSecondary);
          break;
        // Clean style fallbacks
        default:
          baseStyle = FitLifeTheme.bodyLarge.copyWith(color: FitLifeTheme.textSecondary);
          break;
      }
    }

    return Text(
      text,
      style: color != null ? baseStyle.copyWith(color: color) : baseStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}