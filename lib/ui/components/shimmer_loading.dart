import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// ShimmerLoading - Skeleton loading effect for FitLife app
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFF1A1A1A),
    this.highlightColor = const Color(0xFF2A2A2A),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
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
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _animation.value.abs(),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// SkeletonCard - Pre-built skeleton for workout cards
class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 80,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width - 32; // Fallback to screen width minus padding

        return ShimmerLoading(
          child: Container(
            width: width.isFinite ? width : availableWidth,
            height: height,
            decoration: BoxDecoration(
              color: FitLifeTheme.surfaceColor,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: height.isFinite
                ? null // For fixed height, just show the container background
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title skeleton
                      Container(
                        width: availableWidth * 0.6,
                        height: 16,
                        color: FitLifeTheme.surfaceColor,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXS),
                      // Subtitle skeleton
                      Container(
                        width: availableWidth * 0.4,
                        height: 12,
                        color: FitLifeTheme.surfaceColor,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingM),
                      // Content skeleton
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            color: FitLifeTheme.surfaceColor,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: availableWidth * 0.3,
                            height: 14,
                            color: FitLifeTheme.surfaceColor,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// SkeletonChart - Skeleton for progress charts
class SkeletonChart extends StatelessWidget {
  final double height;

  const SkeletonChart({
    super.key,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: FitLifeTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart area skeleton
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: FitLifeTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: _SkeletonChartPainter(),
                ),
              ),
            ),
            const SizedBox(height: FitLifeTheme.spacingL),
            // Legend skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => Container(
                  width: 60,
                  height: 12,
                  color: FitLifeTheme.surfaceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FitLifeTheme.surfaceColor
      ..style = PaintingStyle.fill;

    // Draw random bars for chart skeleton
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    for (int i = 0; i < 7; i++) {
      final height = size.height * (0.3 + (random + i * 13) % 70 / 100);
      final left = i * size.width / 7;
      final width = size.width / 8;

      canvas.drawRect(
        Rect.fromLTWH(left, size.height - height, width, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SkeletonList - Skeleton for workout lists
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonCard(height: itemHeight),
        );
      },
    );
  }
}