import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text.dart';
import '../routes/app_routes.dart';
import '../screens/language_theme_screen.dart';

/// Premium, Playful, and Warm Splash Screen — Designed for elderly accessibility.
/// Features a warm background, soft glow blobs with a modern glassmorphism blur,
/// an elastic playful entrance, and a comforting heartbeat pulse.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // 1. Playful Entrance Animation (Elastic drop and fade in)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Continuous Comforting Heartbeat Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start entrance, then trigger continuous pulse
    _entranceController.forward().then((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    // Navigate to next screen after a gentle delay
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        AppRoutes.fadeReplace(context, const LanguageThemeScreen());
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPeach,
      body: Stack(
        children: [
          // ─── Premium Glassmorphism Background Blobs ───
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlob(AppColors.primaryLight.withValues(alpha: 0.35), 320),
          ),
          Positioned(
            bottom: -150,
            right: -50,
            child: _buildBlob(AppColors.warmCoral.withValues(alpha: 0.15), 380),
          ),
          Positioned(
            top: 250,
            right: -120,
            child: _buildBlob(AppColors.primaryDark.withValues(alpha: 0.2), 260),
          ),

          // High-end blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0),
            child: Container(color: Colors.transparent),
          ),

          // ─── Main Playful & Warm Content ───
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Heartbeat Animated Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_entranceController, _pulseController]),
                  builder: (context, child) {
                    // Combine the elastic entrance scale with the continuous pulse
                    double pulseScale = 1.0 + (_pulseController.value * 0.06); 
                    double currentScale = _logoScale.value * pulseScale;

                    return Transform.scale(
                      scale: currentScale,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmCoral.withValues(alpha: 0.25),
                              blurRadius: 35,
                              spreadRadius: 8,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        // Playful combined icon: Heart (warmth) + Add (medical)
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 85,
                              color: AppColors.warmCoral,
                            ),
                            const Icon(
                              Icons.add_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Gentle Sliding Text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          AppText.appName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryVariant,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your Health, Our Priority", // Friendly tag line
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warmCoral.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for background blobs
  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
