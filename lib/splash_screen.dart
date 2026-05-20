// ═══════════════════════════════════════════════════════════════
//  splash_screen.dart  —  Animated brand splash
//  Animations: particle steam, logo scale+fade, text slide-up,
//              radial reveal wipe transition to HomeScreen
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _steamCtrl;
  late final AnimationController _circleCtrl;

  // ── Logo animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  // ── Tagline animations
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineOpacity;

  // ── Steam
  late final Animation<double> _steamAnim;

  // ── Circle reveal (exit)
  late final Animation<double> _circleReveal;

  final List<SteamParticle> _particles =
      List.generate(8, (_) => SteamParticle());

  @override
  void initState() {
    super.initState();

    // Logo: scale from 0.4→1 + fade in
    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // Tagline: slides up 400ms after logo
    _textCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.6), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );

    // Steam (looping)
    _steamCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
    _steamAnim = Tween<double>(begin: 0, end: 1).animate(_steamCtrl);

    // Exit circle reveal
    _circleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _circleReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleCtrl, curve: Curves.easeInCubic),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    await _circleCtrl.forward();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _steamCtrl.dispose();
    _circleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoCtrl, _textCtrl, _steamCtrl, _circleCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── Radial exit wipe ─────────────────────────
              if (_circleReveal.value > 0)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _CircleRevealPainter(
                    progress: _circleReveal.value,
                    color: AppTheme.bg,
                  ),
                ),

              // ── Background warm glow ──────────────────────
              Center(
                child: Container(
                  width: 320, height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Steam particles ───────────────────────────
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.42,
                left: 0, right: 0,
                child: SizedBox(
                  height: 80,
                  child: CustomPaint(
                    painter: _SteamPainter(
                      progress: _steamAnim.value,
                      particles: _particles,
                    ),
                  ),
                ),
              ),

              // ── Logo + Cup ────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: _CoffeeCupIcon(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Brand name
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineOpacity,
                        child: Column(
                          children: [
                            Text(
                              'BREWED',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Premium Coffee Delivery',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.accentLight.withOpacity(0.8),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom tagline ────────────────────────────
              Positioned(
                bottom: 48,
                left: 0, right: 0,
                child: FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'Every cup tells a story',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Coffee cup SVG-style widget ─────────────────────────────────
class _CoffeeCupIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppTheme.primary, AppTheme.bgDark],
          center: Alignment.topLeft,
          radius: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.4),
            blurRadius: 40, spreadRadius: 8,
          ),
        ],
      ),
      child: Icon(
        Icons.coffee_rounded,
        size: 58, color: AppTheme.accentLight,
      ),
    );
  }
}

// ─── Steam painter ───────────────────────────────────────────────
class SteamParticle {
  final double x;
  final double speed;
  final double size;
  SteamParticle()
      : x = (math.Random().nextDouble() * 120) - 60,
        speed = 0.6 + math.Random().nextDouble() * 0.4,
        size = 3 + math.Random().nextDouble() * 5;
}

class _SteamPainter extends CustomPainter {
  final double progress;
  final List<SteamParticle> particles;
  _SteamPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final t = (progress * p.speed) % 1.0;
      final cx = size.width / 2 + p.x + math.sin(t * math.pi * 2) * 8;
      final cy = size.height * (1 - t);
      final opacity = t < 0.3
          ? t / 0.3
          : t > 0.7
              ? (1 - t) / 0.3
              : 1.0;
      paint.color = AppTheme.accentLight.withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(cx, cy), p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_SteamPainter old) => old.progress != progress;
}

// ─── Circle reveal painter ───────────────────────────────────────
class _CircleRevealPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CircleRevealPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final paint = Paint()..color = color;
    canvas.drawCircle(center, maxR * progress, paint);
  }

  @override
  bool shouldRepaint(_CircleRevealPainter old) => old.progress != progress;
}
