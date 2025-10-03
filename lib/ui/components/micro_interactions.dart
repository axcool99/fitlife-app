import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// AnimatedFAB - Floating Action Button with scale animation
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
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

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            tooltip: widget.tooltip,
            backgroundColor: widget.backgroundColor ?? FitLifeTheme.accentGreen,
            foregroundColor: widget.foregroundColor ?? FitLifeTheme.background,
            elevation: 8,
            highlightElevation: 12,
            child: Icon(widget.icon),
          ),
        );
      },
    );
  }
}

/// SwipeToDeleteItem - Workout item with swipe-to-delete functionality
class SwipeToDeleteItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String deleteLabel;
  final Duration animationDuration;

  const SwipeToDeleteItem({
    super.key,
    required this.child,
    required this.onDelete,
    this.deleteLabel = 'Delete',
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SwipeToDeleteItem> createState() => _SwipeToDeleteItemState();
}

class _SwipeToDeleteItemState extends State<SwipeToDeleteItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  double _dragExtent = 0.0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDeleting) return;

    setState(() {
      _dragExtent += details.delta.dx;
      // Limit the drag to prevent over-swiping
      _dragExtent = _dragExtent.clamp(-100.0, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDeleting) return;

    if (_dragExtent < -50.0) {
      // Swipe threshold reached, show delete confirmation
      _showDeleteConfirmation();
    } else {
      // Reset position
      setState(() {
        _dragExtent = 0.0;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitLifeTheme.surfaceColor,
        title: Text(
          'Delete Workout',
          style: TextStyle(color: FitLifeTheme.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete this workout?',
          style: TextStyle(color: FitLifeTheme.primaryText.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _dragExtent = 0.0;
              });
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: FitLifeTheme.accentBlue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: FitLifeTheme.highlightPink),
            ),
          ),
        ],
      ),
    );
  }

  void _performDelete() {
    setState(() {
      _isDeleting = true;
    });

    _controller.forward().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Delete background
        Positioned.fill(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: FitLifeTheme.highlightPink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete,
              color: FitLifeTheme.primaryText,
            ),
          ),
        ),
        // Main content
        GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([_slideAnimation, _opacityAnimation]),
            builder: (context, child) {
              return Opacity(
                opacity: _isDeleting ? _opacityAnimation.value : 1.0,
                child: Transform.translate(
                  offset: Offset(_isDeleting ? _slideAnimation.value : _dragExtent, 0),
                  child: widget.child,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// CustomRefreshIndicator - Pull-to-refresh with FitLife branding
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final String refreshText;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshText = 'Pull to refresh',
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: FitLifeTheme.accentGreen,
      backgroundColor: FitLifeTheme.surfaceColor,
      displacement: 40,
      strokeWidth: 3,
      child: child,
    );
  }
}

/// PulseAnimation - Reusable pulse animation widget
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double begin;
  final double end;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.begin = 1.0,
    this.end = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
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
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// BounceAnimation - Bounce effect for interactive elements
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.9,
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

  void _onTap() {
    if (widget.onPressed != null) {
      _controller.forward().then((_) {
        _controller.reverse();
        widget.onPressed!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}