import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text.dart';
import '../providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../screens/admin_screen.dart';
import '../screens/language_theme_screen.dart';
import '../screens/scan_screen.dart';
import '../utils/responsive_helper.dart';

/// Premium, Playful, and Warm Splash Screen — Designed for elderly accessibility.
/// Features a warm background, soft glow blobs with a modern glassmorphism blur,
/// an elastic playful entrance, and a comforting heartbeat pulse.
/// Triple-tap anywhere to reveal the hidden admin password panel.
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

  // ─── Triple-tap detection ───
  int _tapCount = 0;
  DateTime? _lastTapTime;

  // ─── Password state ───
  bool _showPasswordOverlay = false;
  final String _correctPassword = '1234';
  String _enteredPassword = '';
  _PasswordState _passwordState = _PasswordState.idle;

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
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted || _showPasswordOverlay) return;
      final settings = context.read<SettingsProvider>();
      if (settings.hasCompletedSetup) {
        // Returning user — skip straight to Scan Product
        AppRoutes.fadeReplace(context, const ScanScreen());
      } else {
        // First launch — start the full setup flow
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

  // ─── Triple-tap handler ───
  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(milliseconds: 600)) {
      // Reset if too slow
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount >= 3) {
      _tapCount = 0;
      _lastTapTime = null;
      setState(() {
        _showPasswordOverlay = true;
        _enteredPassword = '';
        _passwordState = _PasswordState.idle;
      });
    }
  }

  // ─── Password input handler ───
  void _onPasswordChanged(String value) {
    // Only allow digits, max 4
    if (value.length > 4) return;
    setState(() {
      _enteredPassword = value;
      _passwordState = _PasswordState.idle;
    });

    if (value.length == 4) {
      _checkPassword(value);
    }
  }

  void _checkPassword(String value) {
    if (value == _correctPassword) {
      setState(() => _passwordState = _PasswordState.correct);
      // Redirect to admin after short delay
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() => _showPasswordOverlay = false);
        AppRoutes.fadeReplace(context, const AdminScreen());
      });
    } else {
      setState(() => _passwordState = _PasswordState.wrong);
      // Shake then clear after delay
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _enteredPassword = '';
          _passwordState = _PasswordState.idle;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        backgroundColor: AppColors.softPeach,
        body: Stack(
          children: [
            // ─── Premium Glassmorphism Background Blobs ───
            Positioned(
              top: -100.rh,
              left: -100.rw,
              child: _buildBlob(
                AppColors.primaryLight.withValues(alpha: 0.35),
                320.r,
              ),
            ),
            Positioned(
              bottom: -150.rh,
              right: -50.rw,
              child: _buildBlob(
                AppColors.warmCoral.withValues(alpha: 0.15),
                380.r,
              ),
            ),
            Positioned(
              top: 250.rh,
              right: -120.rw,
              child: _buildBlob(
                AppColors.primaryDark.withValues(alpha: 0.2),
                260.r,
              ),
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
                    animation: Listenable.merge([
                      _entranceController,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      double pulseScale = 1.0 + (_pulseController.value * 0.06);
                      double currentScale = _logoScale.value * pulseScale;

                      return Transform.scale(
                        scale: currentScale,
                        child: Container(
                          padding: EdgeInsets.all(28.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmCoral.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 35,
                                spreadRadius: 8,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 85.sp,
                                color: AppColors.warmCoral,
                              ),
                              Icon(
                                Icons.add_rounded,
                                size: 40.sp,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 48.rh),

                  // Gentle Sliding Text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          Text(
                            AppText.appName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryVariant,
                              letterSpacing: 2.0,
                            ),
                          ),
                          SizedBox(height: 8.rh),
                          Text(
                            "Your Health, Our Priority",
                            style: TextStyle(
                              fontSize: 18.sp,
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

            // ─── Password Overlay ───
            if (_showPasswordOverlay)
              _PasswordOverlay(
                enteredPassword: _enteredPassword,
                passwordState: _passwordState,
                onPasswordChanged: _onPasswordChanged,
                onDismiss: () {
                  setState(() {
                    _showPasswordOverlay = false;
                    _enteredPassword = '';
                    _passwordState = _PasswordState.idle;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // Helper for background blobs
  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}


// ─── Password State Enum ───
enum _PasswordState { idle, correct, wrong }

// ─── Password Overlay Widget ───
class _PasswordOverlay extends StatefulWidget {
  final String enteredPassword;
  final _PasswordState passwordState;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onDismiss;

  const _PasswordOverlay({
    required this.enteredPassword,
    required this.passwordState,
    required this.onPasswordChanged,
    required this.onDismiss,
  });

  @override
  State<_PasswordOverlay> createState() => _PasswordOverlayState();
}

class _PasswordOverlayState extends State<_PasswordOverlay>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    // Auto-focus to bring up keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(_PasswordOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passwordState == _PasswordState.wrong &&
        oldWidget.passwordState != _PasswordState.wrong) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color get _boxColor {
    switch (widget.passwordState) {
      case _PasswordState.correct:
        return const Color(0xFF22C55E); // green-500
      case _PasswordState.wrong:
        return const Color(0xFFEF4444); // red-500
      case _PasswordState.idle:
        return AppColors.primaryVariant;
    }
  }

  Color get _boxBorderColor {
    switch (widget.passwordState) {
      case _PasswordState.correct:
        return const Color(0xFF16A34A);
      case _PasswordState.wrong:
        return const Color(0xFFDC2626);
      case _PasswordState.idle:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping the card
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 40.rw),
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.rw,
                    vertical: 36.rh,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock icon
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.softPeach,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 36.sp,
                          color: AppColors.primaryVariant,
                        ),
                      ),
                      SizedBox(height: 20.rh),

                      // Title
                      Text(
                        'Admin Access',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6.rh),
                      Text(
                        'Masukkan PIN untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 28.rh),

                      // ─── PIN Dot Indicators ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < widget.enteredPassword.length;
                          Color dotColor;
                          switch (widget.passwordState) {
                            case _PasswordState.correct:
                              dotColor = const Color(0xFF22C55E);
                              break;
                            case _PasswordState.wrong:
                              dotColor = const Color(0xFFEF4444);
                              break;
                            case _PasswordState.idle:
                              dotColor = AppColors.primaryVariant;
                          }
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(horizontal: 8.rw),
                            width: 18.r,
                            height: 18.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? dotColor : Colors.grey.shade200,
                              border: Border.all(
                                color: filled ? dotColor : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 24.rh),

                      // ─── Hidden numeric-only TextField ───
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _boxColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _boxBorderColor,
                            width: 2.0,
                          ),
                        ),
                        child: TextField(
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          obscureText: true,
                          obscuringCharacter: '●',
                          textAlign: TextAlign.center,
                          maxLength: 4,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: _boxColor,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.rw,
                              vertical: 14.rh,
                            ),
                            hintText: '• • • •',
                            hintStyle: TextStyle(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 24.sp,
                              letterSpacing: 8,
                            ),
                          ),
                          onChanged: widget.onPasswordChanged,
                          controller:
                              TextEditingController(
                                  text: widget.enteredPassword,
                                )
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: widget.enteredPassword.length,
                                  ),
                                ),
                          enabled:
                              widget.passwordState != _PasswordState.correct,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Feedback label
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: widget.passwordState == _PasswordState.wrong
                            ? Row(
                                key: const ValueKey('wrong'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'PIN salah, coba lagi',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : widget.passwordState == _PasswordState.correct
                            ? Row(
                                key: const ValueKey('correct'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Color(0xFF22C55E),
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Access Granted! Loading.....',
                                    style: TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(key: ValueKey('idle'), height: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
