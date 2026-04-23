import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Daftar fields
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailDaftarController = TextEditingController();
  final TextEditingController _passwordDaftarController =
      TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordDaftar = true;
  bool _obscureKonfirmasi = true;
  int _selectedTab = 0; // 0 = Masuk, 1 = Daftar

  // Color palette
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color navyMid = Color(0xFF243655);
  static const Color beige = Color(0xFFF5F0E8);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color accent = Color(0xFF2D4A6E);

  // Warna pra-kalkulasi
  static const Color _whiteOpacity03 = Color(0x08FFFFFF);
  static const Color _whiteOpacity04 = Color(0x0AFFFFFF);
  static const Color _whiteOpacity08 = Color(0x14FFFFFF);
  static const Color _whiteOpacity10 = Color(0x1AFFFFFF);
  static const Color _whiteOpacity15 = Color(0x26FFFFFF);
  static const Color _whiteOpacity20 = Color(0x33FFFFFF);
  static const Color _whiteOpacity60 = Color(0x99FFFFFF);
  static const Color _blackOpacity03 = Color(0x08000000);
  static const Color _blackOpacity06 = Color(0x0F000000);
  static const Color _blackOpacity02 = Color(0x05000000);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _emailDaftarController.dispose();
    _passwordDaftarController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyDark,
      body: Column(
        children: [
          Expanded(
            flex: _selectedTab == 0 ? 4 : 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A2B45),
                    Color(0xFF243655),
                    Color(0xFF1E3252),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circle top-right
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _whiteOpacity03,
                      ),
                    ),
                  ),
                  // Decorative circle bottom-left
                  Positioned(
                    bottom: 20,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _whiteOpacity04,
                      ),
                    ),
                  ),
                  // Logo & tagline
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Container(
                          //   width: 52,
                          //   height: 52,
                          //   margin: const EdgeInsets.only(bottom: 16),
                          //   decoration: BoxDecoration(
                          //     borderRadius: BorderRadius.circular(14),
                          //     color: Colors.white.withOpacity(0.08),
                          //     border: Border.all(
                          //       color: Colors.white.withOpacity(0.15),
                          //       width: 1,
                          //     ),
                          //   ),
                          //   // child: const Icon(
                          //   //   Icons.pets,
                          //   //   color: Colors.white70,
                          //   //   size: 28,
                          //   // ),
                          // ),
                          const Text(
                            'Ternify',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Platform digitalisasi catatan peternakan\nberbasis teknologi OCR cerdas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _whiteOpacity60,
                              height: 1.55,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form Panel ──
          Expanded(
            flex: _selectedTab == 0 ? 6 : 8,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: beigeLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      _selectedTab == 0 ? 'Selamat Datang' : 'Buat Akun Baru',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTab == 0
                          ? 'Masuk ke akun Anda untuk melanjutkan'
                          : 'Daftar untuk mulai mengelola peternakan',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Segmented Tab Control ──
                    _buildSegmentedControl(),
                    const SizedBox(height: 28),

                    // ── Form Content ──
                    if (_selectedTab == 0) _buildMasukForm(),
                    if (_selectedTab == 1) _buildDaftarForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  SEGMENTED CONTROL
  // ══════════════════════════════════════════════
  Widget _buildSegmentedControl() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E2D6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              // Animated slider background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedTab == 0 ? 0 : halfWidth + 4,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: _blackOpacity06,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: _blackOpacity02,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedTab == 0 ? navyDark : textMuted,
                            letterSpacing: 0.2,
                          ),
                          child: const Text('Masuk'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedTab == 1 ? navyDark : textMuted,
                            letterSpacing: 0.2,
                          ),
                          child: const Text('Daftar'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  MASUK FORM
  // ══════════════════════════════════════════════
  Widget _buildMasukForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Field
        _buildLabel('EMAIL'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'Masukkan email anda',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Password Field
        _buildLabel('KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: 'Masukkan kata sandi',
          obscure: _obscurePassword,
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: textMuted,
              ),
            ),
          ),
        ),

        // Lupa kata sandi
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
            child: const Text(
              'Lupa kata sandi?',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2D5A8E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Masuk Button
        _buildPrimaryButton(
          label: 'Masuk',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),

        const SizedBox(height: 20),

        // Belum punya akun?
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: RichText(
              text: const TextSpan(
                text: 'Belum punya akun? ',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
                children: [
                  TextSpan(
                    text: 'Daftar',
                    style: TextStyle(
                      color: Color(0xFF2D5A8E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ══════════════════════════════════════════════
  //  DAFTAR FORM
  // ══════════════════════════════════════════════
  Widget _buildDaftarForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama Lengkap
        _buildLabel('NAMA LENGKAP'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _namaController,
          hint: 'Masukkan nama lengkap',
        ),
        const SizedBox(height: 20),

        // Email
        _buildLabel('EMAIL'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailDaftarController,
          hint: 'Masukkan email anda',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Kata Sandi
        _buildLabel('KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordDaftarController,
          hint: 'Buat kata sandi',
          obscure: _obscurePasswordDaftar,
          suffix: GestureDetector(
            onTap: () => setState(
                () => _obscurePasswordDaftar = !_obscurePasswordDaftar),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscurePasswordDaftar
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Konfirmasi Kata Sandi
        _buildLabel('KONFIRMASI KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _konfirmasiPasswordController,
          hint: 'Ulangi kata sandi',
          obscure: _obscureKonfirmasi,
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscureKonfirmasi
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: textMuted,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Daftar Button
        _buildPrimaryButton(
          label: 'Daftar',
          onPressed: () {
            // TODO: Handle registration
          },
        ),

        const SizedBox(height: 20),

        // Sudah punya akun?
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: RichText(
              text: const TextSpan(
                text: 'Sudah punya akun? ',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
                children: [
                  TextSpan(
                    text: 'Masuk',
                    style: TextStyle(
                      color: Color(0xFF2D5A8E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ══════════════════════════════════════════════
  //  PRIMARY BUTTON
  // ══════════════════════════════════════════════
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: navyDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Color(0xFF6B7A8D),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD8CE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A2B45),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13.5,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
      ),
    );
  }
}