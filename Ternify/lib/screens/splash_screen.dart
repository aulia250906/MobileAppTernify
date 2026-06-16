import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color gold = Color(0xFFCFBFA5);

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // Main entrance
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _progressOpacity;

  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.25, curve: Curves.easeOut)),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.55, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.55, curve: Curves.easeOutCubic)),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.45, 0.7, curve: Curves.easeOut)),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.45, 0.7, curve: Curves.easeOutCubic)),
    );
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.65, 0.85, curve: Curves.easeOut)),
    );

    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    _checkAppState();
  }

  Future<void> _checkAppState() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2B45), Color(0xFF243655), Color(0xFF1E3252), Color(0xFF162540)],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._buildDecorativeCircles(),
            SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([_mainController, _pulseController, _shimmerController]),
                builder: (context, child) {
                  return SizedBox(
                    width: double.infinity, // INI PERBAIKAN PRESISI (AGAR CENTER HORIZONTAL)
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        _buildLogo(),
                        const SizedBox(height: 32),
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: _buildTitle(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SlideTransition(
                          position: _taglineSlide,
                          child: FadeTransition(
                            opacity: _taglineOpacity,
                            child: _buildTagline(),
                          ),
                        ),
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _progressOpacity,
                          child: _buildLoadingIndicator(),
                        ),
                        const SizedBox(height: 40),
                        FadeTransition(
                          opacity: _progressOpacity,
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25), letterSpacing: 1.0),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: gold.withOpacity(0.15), width: 1.5),
                  ),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF4A90E2).withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.0)],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment(-1.0 + (_shimmerController.value * 2), -0.5),
                    end: Alignment(0.0 + (_shimmerController.value * 2), 0.5),
                  ).createShader(bounds);
                },
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const Icon(Icons.pets, size: 48, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [Colors.white, Color(0xFFE0D5C3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: const Text(
        'Ternify',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        'Catatan Pintar Peternak',
        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final brightness = (math.sin((_mainController.value * math.pi * 2) + (index * 1.0)) + 1) / 2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(gold.withOpacity(0.3), gold, brightness),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Mempersiapkan aplikasi...',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeCircles() {
    return [
      Positioned(top: -80, right: -60, child: _buildCircle(220, Colors.white.withOpacity(0.04))),
      Positioned(bottom: -100, left: -80, child: _buildCircle(280, const Color(0xFF4A90E2).withOpacity(0.05))),
      Positioned(top: 60, left: 40, child: _buildSolidCircle(12, gold.withOpacity(0.15))),
      Positioned(top: 300, right: 30, child: _buildSolidCircle(8, const Color(0xFF4A90E2).withOpacity(0.2))),
      Positioned(bottom: 120, right: 50, child: _buildSolidCircle(16, Colors.white.withOpacity(0.06))),
    ];
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.01), Colors.transparent]),
      ),
    );
  }

  Widget _buildSolidCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
