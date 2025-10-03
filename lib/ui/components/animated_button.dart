import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// AnimatedButton - Enhanced button with neon pulse animation for primary actions
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow animation for tap effects
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _glowController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _glowController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _glowController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FitLifeTheme.accentGreen,
                  FitLifeTheme.accentBlue,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: FitLifeTheme.accentGreen.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: FitLifeTheme.accentGreen.withOpacity(_glowAnimation.value * 0.6),
                    blurRadius: 30 * _glowAnimation.value,
                    spreadRadius: 10 * _glowAnimation.value,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onPressed,
                splashColor: FitLifeTheme.accentBlue.withOpacity(0.3),
                highlightColor: Colors.transparent,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(FitLifeTheme.background),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: FitLifeTheme.background,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                fontFamily: FitLifeTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: FitLifeTheme.background,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}