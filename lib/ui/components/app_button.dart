import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import 'app_text.dart';

/// AppButton - Reusable button component for FitLife app
/// Supports three variants: Primary (solid dark), Secondary (outlined), Tertiary (text-only)
/// Includes press animation with scale down and spring back, tap glow, and neon pulse effects
enum AppButtonVariant { primary, secondary, tertiary }

class AppButton extends StatefulWidget {
  final String text;
  final AppButtonVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool useCleanStyle;

  const AppButton({
    super.key,
    required this.text,
    this.variant = AppButtonVariant.primary,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.useCleanStyle = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Glow animation for tap effects
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for primary buttons
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation, _pulseAnimation]),
      builder: (context, child) {
        final isPrimary = widget.variant == AppButtonVariant.primary;
        final scale = isPrimary ? _pulseAnimation.value : _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: isPrimary ? FitLifeTheme.accentGreen.withOpacity(_glowAnimation.value * 0.3) :
                           FitLifeTheme.accentBlue.withOpacity(_glowAnimation.value * 0.2),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 5 * _glowAnimation.value,
                  ),
              ],
            ),
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.onPressed,
              child: _buildButton(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton() {
    if (widget.useCleanStyle) {
      // Clean minimal style using theme button styles
      switch (widget.variant) {
        case AppButtonVariant.primary:
          return ElevatedButton(
            onPressed: widget.onPressed,
            style: FitLifeTheme.primaryButtonStyle,
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FitLifeTheme.background,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          );

        case AppButtonVariant.secondary:
          return ElevatedButton(
            onPressed: widget.onPressed,
            style: FitLifeTheme.secondaryButtonStyle,
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FitLifeTheme.background,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          );

        case AppButtonVariant.tertiary:
          return OutlinedButton(
            onPressed: widget.onPressed,
            style: FitLifeTheme.outlinedButtonStyle,
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FitLifeTheme.accentGreen,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          );
      }
    } else {
      // Legacy gradient style
      switch (widget.variant) {
        case AppButtonVariant.primary:
          return Container(
            width: widget.width,
            height: widget.height ?? 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FitLifeTheme.accentGreen, FitLifeTheme.accentBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(FitLifeTheme.legacyButtonBorderRadius),
              boxShadow: [FitLifeTheme.softShadow],
            ),
            child: Center(
              child: widget.isLoading
                  ? CircularProgressIndicator(color: FitLifeTheme.primaryText)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: FitLifeTheme.primaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: FitLifeTheme.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          );

        case AppButtonVariant.secondary:
          return Container(
            width: widget.width,
            height: widget.height ?? 50,
            decoration: BoxDecoration(
              color: FitLifeTheme.surfaceColor,
              border: Border.all(color: FitLifeTheme.accentGreen),
              borderRadius: BorderRadius.circular(FitLifeTheme.legacyButtonBorderRadius),
              boxShadow: [FitLifeTheme.softShadow],
            ),
            child: Center(
              child: widget.isLoading
                  ? CircularProgressIndicator(color: FitLifeTheme.accentGreen)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: FitLifeTheme.accentGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: FitLifeTheme.accentGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          );

        case AppButtonVariant.tertiary:
          return Container(
            width: widget.width,
            height: widget.height ?? 50,
            child: Center(
              child: widget.isLoading
                  ? CircularProgressIndicator(color: FitLifeTheme.accentGreen)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: FitLifeTheme.accentGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: AppText(
                            widget.text,
                            type: AppTextType.body,
                            color: FitLifeTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
            ),
          );
      }
    }
  }
}