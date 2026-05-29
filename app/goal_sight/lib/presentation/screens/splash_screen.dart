import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../features/auth/auth_state.dart';
import '../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;

  bool _restored = false;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.38, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).restoreSession(),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;
    final isLoading =
        status == AuthStatus.loading || status == AuthStatus.initial;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background gradient orbs ─────────────────────────────────────
          Positioned(
            top: -160,
            left: -120,
            child: _GradientOrb(
              size: 420,
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _GradientOrb(
              size: 360,
              color: AppColors.accentCyan.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            left: MediaQuery.of(context).size.width * 0.6,
            child: _GradientOrb(
              size: 200,
              color: AppColors.accentGreen.withValues(alpha: 0.04),
            ),
          ),

          // ── Animated rings ───────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ringCtrl, _pulseCtrl]),
              builder: (context, _) {
                return CustomPaint(
                  size: Size(
                    context.rs(300, min: 240, max: 360),
                    context.rs(300, min: 240, max: 360),
                  ),
                  painter: _SplashRingPainter(
                    progress: _ringCtrl.value,
                    pulse: _pulseCtrl.value,
                  ),
                );
              },
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon (appears first — scale + fade)
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: _SplashLogoIcon(
                        size: context.rs(80, min: 64, max: 98),
                      ),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 18, max: 32)),

                  // Brand name (appears second — fade + slide)
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: ShaderMask(
                        shaderCallback: (b) =>
                            AppGradients.brand.createShader(b),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'GOALSIGHT',
                          style: TextStyle(
                            fontSize: context.sp(30, min: 24, max: 40),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 5.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: context.rs(8, min: 5, max: 12)),

                  // Tagline (appears third — fade)
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'AI Football Intelligence',
                      style: AppTextStyles.caption(
                        color: AppColors.textMuted,
                      ).copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w500,
                        fontSize: context.sp(12, min: 10, max: 15),
                      ),
                    ),
                  ),

                  SizedBox(height: context.rs(56, min: 40, max: 72)),

                  // Loading indicator
                  if (isLoading)
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: const _SplashDotLoader(),
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

// ─── Splash logo icon (icon only, no text) ────────────────────────────────────

class _SplashLogoIcon extends StatelessWidget {
  final double size;
  const _SplashLogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: AppGradients.brand,
        boxShadow: AppShadows.cardGlow,
      ),
      child: Icon(
        Icons.sports_soccer_rounded,
        color: Colors.white,
        size: size * 0.46,
      ),
    );
  }
}

// ─── Background orb ───────────────────────────────────────────────────────────

class _GradientOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GradientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────

class _SplashRingPainter extends CustomPainter {
  final double progress;
  final double pulse;
  _SplashRingPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Outer static ring
    canvas.drawCircle(
      c,
      maxR * (0.92 + 0.04 * pulse),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = AppColors.primaryPurple.withValues(alpha: 0.18),
    );

    // Outer rotating arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: maxR * 0.92),
      progress * 2 * math.pi,
      math.pi * 0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primaryPurple.withValues(alpha: 0.65),
    );

    // Mid ring
    canvas.drawCircle(
      c,
      maxR * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.accentCyan.withValues(alpha: 0.15),
    );

    // Mid counter-rotating arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: maxR * 0.68),
      -progress * 2 * math.pi * 1.4 + math.pi,
      math.pi * 0.38,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentCyan.withValues(alpha: 0.5),
    );

    // Inner pulsing ring
    canvas.drawCircle(
      c,
      maxR * (0.42 + 0.03 * pulse),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = AppColors.outlineSubtle.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_SplashRingPainter old) =>
      old.progress != progress || old.pulse != pulse;
}

// ─── Dot loader ───────────────────────────────────────────────────────────────

class _SplashDotLoader extends StatefulWidget {
  const _SplashDotLoader();

  @override
  State<_SplashDotLoader> createState() => _SplashDotLoaderState();
}

class _SplashDotLoaderState extends State<_SplashDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final raw = (_ctrl.value * 3) - i;
            final phase = (raw % 3.0).clamp(0.0, 1.0);
            final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple.withValues(
                  alpha: 0.25 + opacity * 0.75,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
