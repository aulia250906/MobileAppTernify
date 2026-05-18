import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_popup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController              = TextEditingController();
  final TextEditingController _passwordController           = TextEditingController();
  final TextEditingController _namaController               = TextEditingController();
  final TextEditingController _emailDaftarController        = TextEditingController();
  final TextEditingController _passwordDaftarController     = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();

  bool _obscurePassword       = true;
  bool _obscurePasswordDaftar = true;
  bool _obscureKonfirmasi     = true;
  bool _isLoading             = false;
  int  _selectedTab           = 0; // 0 = Masuk, 1 = Daftar

  // Per-field validation errors
  final Map<String, String?> _fieldErrors = {};

  // Color palette
  static const Color navyDark  = Color(0xFF1A2B45);
  static const Color navyMid   = Color(0xFF243655);
  static const Color beige     = Color(0xFFF5F0E8);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color accent    = Color(0xFF2D4A6E);

  static const Color _whiteOpacity03 = Color(0x08FFFFFF);
  static const Color _whiteOpacity04 = Color(0x0AFFFFFF);
  static const Color _whiteOpacity60 = Color(0x99FFFFFF);

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

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    // Inline field validation
    setState(() {
      _fieldErrors.clear();
      if (email.isEmpty)    _fieldErrors['login_email']    = 'Email wajib diisi';
      if (password.isEmpty) _fieldErrors['login_password'] = 'Kata sandi wajib diisi';
    });
    if (_fieldErrors.isNotEmpty) return;

    setState(() => _isLoading = true);

    final result = await ApiService.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      _showSnackbar(result['message'] ?? 'Login gagal', isError: true);
    }
  }

  Future<void> _handleRegister() async {
    final nama     = _namaController.text.trim();
    final email    = _emailDaftarController.text.trim();
    final password = _passwordDaftarController.text;
    final konfirm  = _konfirmasiPasswordController.text;

    // Inline field validation
    setState(() {
      _fieldErrors.clear();
      if (nama.isEmpty)     _fieldErrors['reg_nama']     = 'Nama lengkap wajib diisi';
      if (email.isEmpty)    _fieldErrors['reg_email']    = 'Email wajib diisi';
      if (password.isEmpty) _fieldErrors['reg_password'] = 'Kata sandi wajib diisi';
      if (konfirm.isEmpty)  _fieldErrors['reg_konfirm']  = 'Konfirmasi kata sandi wajib diisi';
    });
    if (_fieldErrors.isNotEmpty) return;

    if (password != konfirm) {
      setState(() => _fieldErrors['reg_konfirm'] = 'Konfirmasi kata sandi tidak cocok');
      return;
    }

    if (password.length < 8) {
      setState(() => _fieldErrors['reg_password'] = 'Kata sandi minimal 8 karakter');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.register(
      namaLengkap:           nama,
      email:                 email,
      password:              password,
      passwordConfirmation:  konfirm,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Tangani error validasi dari Laravel
      final errors = result['errors'];
      if (errors != null && errors is Map) {
        final firstError = (errors.values.first as List).first.toString();
        _showSnackbar(firstError, isError: true);
      } else {
        _showSnackbar(result['message'] ?? 'Registrasi gagal', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    AppPopup.show(context, message: message, isError: isError);
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

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
                  colors: [Color(0xFF1A2B45), Color(0xFF243655), Color(0xFF1E3252)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 160, height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _whiteOpacity03,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: -30,
                    child: Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _whiteOpacity04,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      style: const TextStyle(fontSize: 13.5, color: textMuted),
                    ),
                    const SizedBox(height: 24),
                    _buildSegmentedControl(),
                    const SizedBox(height: 28),
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

  // ── Segmented Control ──
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
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedTab == 0 ? 0 : halfWidth + 4,
                top: 0, bottom: 0,
                width: halfWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _buildTab('Masuk', 0)),
                  Expanded(child: _buildTab('Daftar', 1)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() { _selectedTab = index; _fieldErrors.clear(); }),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? navyDark : textMuted,
          ),
        ),
      ),
    );
  }

  // ── Masuk Form ──
  Widget _buildMasukForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('EMAIL'),
        const SizedBox(height: 8),
        _buildTextField(controller: _emailController, hint: 'Masukkan email anda', keyboardType: TextInputType.emailAddress, errorText: _fieldErrors['login_email']),
        const SizedBox(height: 20),

        _buildLabel('KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: 'Masukkan kata sandi',
          obscure: _obscurePassword,
          errorText: _fieldErrors['login_password'],
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Masuk',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: RichText(
              text: const TextSpan(
                text: 'Belum punya akun? ',
                style: TextStyle(fontSize: 13, color: textMuted),
                children: [
                  TextSpan(
                    text: 'Daftar',
                    style: TextStyle(color: Color(0xFF2D5A8E), fontWeight: FontWeight.w600),
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

  // ── Daftar Form ──
  Widget _buildDaftarForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('NAMA LENGKAP'),
        const SizedBox(height: 8),
        _buildTextField(controller: _namaController, hint: 'Masukkan nama lengkap', errorText: _fieldErrors['reg_nama']),
        const SizedBox(height: 20),

        _buildLabel('EMAIL'),
        const SizedBox(height: 8),
        _buildTextField(controller: _emailDaftarController, hint: 'Masukkan email anda', keyboardType: TextInputType.emailAddress, errorText: _fieldErrors['reg_email']),
        const SizedBox(height: 20),

        _buildLabel('KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordDaftarController,
          hint: 'Buat kata sandi (min. 8 karakter)',
          obscure: _obscurePasswordDaftar,
          errorText: _fieldErrors['reg_password'],
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePasswordDaftar = !_obscurePasswordDaftar),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscurePasswordDaftar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildLabel('KONFIRMASI KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _konfirmasiPasswordController,
          hint: 'Ulangi kata sandi',
          obscure: _obscureKonfirmasi,
          errorText: _fieldErrors['reg_konfirm'],
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscureKonfirmasi ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Daftar',
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),
        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: RichText(
              text: const TextSpan(
                text: 'Sudah punya akun? ',
                style: TextStyle(fontSize: 13, color: textMuted),
                children: [
                  TextSpan(
                    text: 'Masuk',
                    style: TextStyle(color: Color(0xFF2D5A8E), fontWeight: FontWeight.w600),
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

  // ── Helpers ──
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: navyDark,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: navyDark.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        letterSpacing: 1.2, color: Color(0xFF6B7A8D),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFC0392B) : const Color(0xFFDDD8CE),
              width: hasError ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B45)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: InputBorder.none,
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC0392B)),
            ),
          ),
      ],
    );
  }
}