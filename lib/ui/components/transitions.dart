import 'package:flutter/material.dart';

/// Custom page route transitions for FitLife app
class FitLifeTransitions {
  /// Slide transition from right to left
  static PageRouteBuilder slideRightToLeft(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Slide transition from bottom to top
  static PageRouteBuilder slideBottomToTop(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Fade transition with scale
  static PageRouteBuilder fadeScale(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        var scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Hero-style zoom transition
  static PageRouteBuilder zoomHero(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;

        var scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  /// Custom transition for auth screens (slide up with fade)
  static PageRouteBuilder authTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve)).animate(animation);

        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        var scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: curve)).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}