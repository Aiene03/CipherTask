import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _rotateController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Setup fade animation for the content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Subtle rotation for the background elements
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController.forward();

    // Start the navigation process
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // We wait for the fade animation to finish (1.5s) plus a small buffer
    // to ensure the loading state is visible and the UX feels intentional.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final auth = Provider.of<AuthViewModel>(context, listen: false);

    setState(() {
      _isNavigating = true;
    });

    // The loading indicator will continue to spin until pushReplacementNamed is called
    if (auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/todos');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A10), // Deep Navy from the image
      body: Stack(
        children: [
          // Background abstract circles inspired by the uploaded image
          Positioned.fill(
            child: RotationTransition(
              turns: _rotateController,
              child: CustomPaint(painter: _AbstractCirclePainter()),
            ),
          ),

          // Gradient Overlay to ensure text readability
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  const Color(0xFF090A10).withOpacity(0.5),
                  const Color(0xFF090A10),
                ],
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon with glow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 85,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    'CIPHERTASK',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'SECURE PRODUCTIVITY',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.cyan.withOpacity(0.7),
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Loading Indicator - persists until navigation triggers
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A CustomPainter that replicates the abstract, overlapping gradient circles
/// seen in the user-provided image.
class _AbstractCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2CC6D7).withOpacity(0.6),
              const Color(0xFF00D2FF).withOpacity(0.2),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.4,
              -size.height * 0.1,
              size.width,
              size.height,
            ),
          );

    final paint2 = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              const Color(0xFF161B3A),
              const Color(0xFF2CC6D7).withOpacity(0.3),
            ],
          ).createShader(
            Rect.fromLTWH(
              -size.width * 0.2,
              size.height * 0.4,
              size.width,
              size.height,
            ),
          );

    // Draw the large top-right arc
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.6,
      paint1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 100,
    );

    // Draw the large bottom-left arc
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.7),
      size.width * 0.5,
      paint2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 80,
    );

    // Add a smaller accent circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.9,
      Paint()
        ..color = Colors.cyan.withOpacity(0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
