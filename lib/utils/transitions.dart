import 'package:flutter/material.dart';

/// Custom page transition with slide and fade effect
class SlidePageTransition extends PageRouteBuilder {
  final Widget child;

  SlidePageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Curve for smooth easing
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          // Slide from right to left
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = curvedAnimation.drive(tween);

          // Fade animation
          final fadeAnimation = curvedAnimation;

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 350),
      );
}

/// Custom page transition with fade effect only
class FadePageTransition extends PageRouteBuilder {
  final Widget child;

  FadePageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          // Subtle scale effect for professional feel
          final scaleAnimation = curvedAnimation.drive(
            Tween(begin: 0.98, end: 1.0),
          );

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(opacity: curvedAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 500),
      );
}

/// Custom page transition with scale effect (zoom)
class ScalePageTransition extends PageRouteBuilder {
  final Widget child;

  ScalePageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final tween = Tween(begin: 0.85, end: 1.0);
          final scaleAnimation = curvedAnimation.drive(tween);
          final fadeAnimation = curvedAnimation;

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 350),
      );
}

/// Premium smooth transition combining slide, scale, and fade
class SmoothPageTransition extends PageRouteBuilder {
  final Widget child;

  SmoothPageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          // Slide from right
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final slideAnimation = curvedAnimation.drive(
            Tween(begin: begin, end: end),
          );

          // Scale effect
          final scaleAnimation = curvedAnimation.drive(
            Tween(begin: 0.9, end: 1.0),
          );

          // Fade effect
          final fadeAnimation = curvedAnimation;

          return SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: fadeAnimation, child: child),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}
