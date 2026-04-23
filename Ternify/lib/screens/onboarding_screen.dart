import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // ── Warna statis pra-kalkulasi ──
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color accent = Color(0xFF4A90E2);
  static const Color gold = Color(0xFFCFBFA5);

  static const Color _whiteOpacity50 = Color(0x80FFFFFF);
  static const Color _whiteOpacity20 = Color(0x33FFFFFF);
  static const Color _whiteOpacity15 = Color(0x26FFFFFF);
  static const Color _whiteOpacity10 = Color(0x1AFFFFFF);
  static const Color _whiteOpacity08 = Color(0x14FFFFFF);
  static const Color _whiteOpacity06 = Color(0x0FFFFFFF);
  static const Color _whiteOpacity04 = Color(0x0AFFFFFF);
  static const Color _accentOpacity15 = Color(0x264A90E2);
  static const Color _accentOpacity25 = Color(0x404A90E2);
  static const Color _accentOpacity08 = Color(0x144A90E2);
  static const Color _accentOpacity02 = Color(0x054A90E2);
  static const Color _accentOpacity06 = Color(0x0F4A90E2);
  static const Color _accentOpacity01 = Color(0x034A90E2);
  static const Color _accentOpacity90 = Color(0xE64A90E2);
  static const Color _accentOpacity40 = Color(0x664A90E2);
  static const Color _accentOpacity20 = Color(0x334A90E2);
  static const Color _goldOpacity15 = Color(0x26CFBFA5);
  static const Color _goldOpacity25 = Color(0x40CFBFA5);
  static const Color _goldOpacity90 = Color(0xE6CFBFA5);
  static const Color _goldOpacity08 = Color(0x14CFBFA5);
  static const Color _goldOpacity02 = Color(0x05CFBFA5);
  static const Color _goldOpacity05 = Color(0x0DCFBFA5);
  static const Color _goldOpacity01 = Color(0x03CFBFA5);
  static const Color _goldOpacity40 = Color(0x66CFBFA5);
  static const Color _goldOpacity30 = Color(0x4DCFBFA5);
  static const Color _goldOpacity12 = Color(0x1FCFBFA5);
  static const Color _goldOpacity80 = Color(0xCCCFBFA5);
  static const Color _greenOpacity30 = Color(0x4D66BB6A);
  static const Color _blackOpacity15 = Color(0x26000000);
  static const Color _whiteOpacity30 = Color(0x4DFFFFFF);

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Hanya 1 AnimationController untuk entrance
  late AnimationController _entranceController;
  late Animation<double> _entranceOpacity;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    // Entrance animation saja — floating dihapus karena terlalu berat
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onPageChanged(int index) {
    setState(() => _currentPageIndex = index);
    _entranceController.reset();
    _entranceController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2B45),
              Color(0xFF243655),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Background decorations (statis) ──
            ..._buildBackgroundDecorations(),

            // ── Main Content ──
            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: _currentPageIndex == 0
                          ? TextButton(
                              onPressed: () {
                                _pageController.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text(
                                'Lewati',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _whiteOpacity50,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            )
                          : const SizedBox(height: 48),
                    ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [
                        _buildPage1(),
                        _buildPage2(),
                      ],
                    ),
                  ),

                  // ── Bottom area: indicator + button ──
                  _buildBottomArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  PAGE 1 — Transform your notes
  // ══════════════════════════════════════════════
  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Illustration (statis — tanpa floating animation)
          _buildIllustration1(),

          const Spacer(flex: 1),

          // Text content dengan entrance animation
          SlideTransition(
            position: _entranceSlide,
            child: FadeTransition(
              opacity: _entranceOpacity,
              child: Column(
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _accentOpacity15,
                      border: Border.all(color: _accentOpacity25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: _accentOpacity90,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'OCR Cerdas',
                          style: TextStyle(
                            fontSize: 12,
                            color: _accentOpacity90,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Ubah catatan lama mu\nmenjadi catatan yang lebih\nterstruktur dan menarik!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  const Text(
                    'Foto catatan tulisan tangan dan biarkan\nteknologi kami mengubahnya menjadi data digital.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _whiteOpacity50,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  PAGE 2 — Start tracking
  // ══════════════════════════════════════════════
  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Illustration (statis)
          _buildIllustration2(),

          const Spacer(flex: 1),

          // Text content
          SlideTransition(
            position: _entranceSlide,
            child: FadeTransition(
              opacity: _entranceOpacity,
              child: Column(
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _goldOpacity15,
                      border: Border.all(color: _goldOpacity25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color: _goldOpacity90,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Kelola Peternakan',
                          style: TextStyle(
                            fontSize: 12,
                            color: _goldOpacity90,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Ayo mulai\nmencatat ternakmu!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  const Text(
                    'Pantau kesehatan, berat badan, dan\nperkembangan ternak dalam satu aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _whiteOpacity50,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  ILLUSTRATION 1 — Scan / Document visual
  // ══════════════════════════════════════════════
  Widget _buildIllustration1() {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accentOpacity08,
                  _accentOpacity02,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _whiteOpacity06, width: 1),
            ),
          ),

          // Inner ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _whiteOpacity04, width: 1),
            ),
          ),

          // Center icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accentOpacity20, _accentOpacity08],
              ),
              border: Border.all(color: _accentOpacity40, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: _accentOpacity15,
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 44,
              color: Colors.white,
            ),
          ),

          // Floating mini-cards
          Positioned(
            top: 15,
            right: 20,
            child: _buildFloatingChip(
              Icons.description_outlined,
              _accentOpacity90,
            ),
          ),
          Positioned(
            bottom: 25,
            left: 10,
            child: _buildFloatingChip(
              Icons.edit_note_rounded,
              _goldOpacity80,
            ),
          ),
          Positioned(
            top: 40,
            left: 15,
            child: _buildSmallDot(_accentOpacity40),
          ),
          Positioned(
            bottom: 15,
            right: 35,
            child: _buildSmallDot(_goldOpacity30),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  ILLUSTRATION 2 — Livestock / Farm visual
  // ══════════════════════════════════════════════
  Widget _buildIllustration2() {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _goldOpacity08,
                  _goldOpacity02,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _whiteOpacity06, width: 1),
            ),
          ),

          // Inner ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _whiteOpacity04, width: 1),
            ),
          ),

          // Center icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_goldOpacity15, _goldOpacity08],
              ),
              border: Border.all(color: _goldOpacity30, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: _goldOpacity15,
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.pets,
              size: 44,
              color: Colors.white,
            ),
          ),

          // Floating mini-cards
          Positioned(
            top: 10,
            left: 25,
            child: _buildFloatingChip(
              Icons.monitor_heart_outlined,
              const Color(0xFF66BB6A),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 15,
            child: _buildFloatingChip(
              Icons.bar_chart_rounded,
              _accentOpacity90,
            ),
          ),
          Positioned(
            top: 35,
            right: 15,
            child: _buildSmallDot(_goldOpacity40),
          ),
          Positioned(
            bottom: 40,
            left: 25,
            child: _buildSmallDot(_greenOpacity30),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingChip(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _whiteOpacity08,
        border: Border.all(color: _whiteOpacity10),
        boxShadow: const [
          BoxShadow(
            color: _blackOpacity15,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildSmallDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  BOTTOM AREA — indicators + button
  // ══════════════════════════════════════════════
  Widget _buildBottomArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final isActive = _currentPageIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? Colors.white : _whiteOpacity20,
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: _whiteOpacity30,
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentPageIndex == 1
                ? _buildPrimaryButton()
                : _buildSecondaryButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      key: const ValueKey('PrimaryButton'),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _completeOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: navyDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Mulai Sekarang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0x1A1A2B45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      key: const ValueKey('SecondaryButton'),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _whiteOpacity10,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: _whiteOpacity15,
              width: 1,
            ),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selanjutnya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Color(0xB3FFFFFF),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  BACKGROUND DECORATIONS (statis)
  // ══════════════════════════════════════════════
  List<Widget> _buildBackgroundDecorations() {
    return [
      // Top-right gradient circle
      Positioned(
        top: -100,
        right: -80,
        child: Container(
          width: 260,
          height: 260,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _accentOpacity06,
                _accentOpacity01,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Bottom-left gradient circle
      Positioned(
        bottom: -60,
        left: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _goldOpacity05,
                _goldOpacity01,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Tiny accent dots
      Positioned(
        top: 140,
        left: 20,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _accentOpacity20,
          ),
        ),
      ),
      Positioned(
        bottom: 200,
        right: 25,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _goldOpacity12,
          ),
        ),
      ),
    ];
  }
}
