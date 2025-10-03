import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// EmptyState - Animated empty state illustrations
class EmptyState extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? actionButton;
  final bool animate;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionButton,
    this.animate = true,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon with glow effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          FitLifeTheme.accentGreen.withOpacity(0.2),
                          FitLifeTheme.accentBlue.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FitLifeTheme.accentGreen.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 60,
                      color: FitLifeTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(height: FitLifeTheme.spacingL),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: FitLifeTheme.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: FitLifeTheme.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FitLifeTheme.spacingM),
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontFamily: FitLifeTheme.fontFamily,
                      fontSize: 16,
                      color: FitLifeTheme.primaryText.withOpacity(0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.actionButton != null) ...[
                    const SizedBox(height: FitLifeTheme.spacingXXL),
                    widget.actionButton!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ErrorState - Animated error state with retry functionality
class ErrorState extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryText;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  @override
  State<ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<ErrorState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));

    // Auto-play shake animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * 10 * (1 - _shakeAnimation.value), 0),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon with red glow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FitLifeTheme.highlightPink.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: FitLifeTheme.highlightPink.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 50,
                    color: FitLifeTheme.highlightPink,
                  ),
                ),
                const SizedBox(height: FitLifeTheme.spacingL),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: FitLifeTheme.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: FitLifeTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FitLifeTheme.spacingM),
                Text(
                  widget.message,
                  style: TextStyle(
                    fontFamily: FitLifeTheme.fontFamily,
                    fontSize: 16,
                    color: FitLifeTheme.primaryText.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: FitLifeTheme.spacingXXL),
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(widget.retryText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitLifeTheme.accentBlue,
                      foregroundColor: FitLifeTheme.primaryText,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// OfflineState - Offline state with retry animation
class OfflineState extends StatefulWidget {
  final VoidCallback? onRetry;
  final String retryText;

  const OfflineState({
    super.key,
    this.onRetry,
    this.retryText = 'Retry Connection',
  });

  @override
  State<OfflineState> createState() => _OfflineStateState();
}

class _OfflineStateState extends State<OfflineState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated wifi off icon
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FitLifeTheme.accentBlue.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: FitLifeTheme.accentBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    size: 50,
                    color: FitLifeTheme.accentBlue,
                  ),
                ),
              ),
              const SizedBox(height: FitLifeTheme.spacingL),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontFamily: FitLifeTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: FitLifeTheme.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FitLifeTheme.spacingM),
              Text(
                'Please check your connection and try again.',
                style: TextStyle(
                  fontFamily: FitLifeTheme.fontFamily,
                  fontSize: 16,
                  color: FitLifeTheme.primaryText.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: FitLifeTheme.spacingXXL),
                ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(widget.retryText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitLifeTheme.accentGreen,
                    foregroundColor: FitLifeTheme.primaryText,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// LoadingState - Custom loading indicator with FitLife branding
class LoadingState extends StatefulWidget {
  final String? message;
  final Color? color;

  const LoadingState({
    super.key,
    this.message,
    this.color,
  });

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.color ?? FitLifeTheme.accentGreen,
                          widget.color ?? FitLifeTheme.accentBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? FitLifeTheme.accentGreen).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: FitLifeTheme.primaryText,
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: FitLifeTheme.spacingL),
            Text(
              widget.message!,
              style: TextStyle(
                fontFamily: FitLifeTheme.fontFamily,
                fontSize: 16,
                color: FitLifeTheme.primaryText.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}