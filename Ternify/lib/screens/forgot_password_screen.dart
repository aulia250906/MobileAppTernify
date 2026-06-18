import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/app_popup.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ─── Step: 0 = Email, 1 = OTP, 2 = New Password ───
  int _currentStep = 0;

  // Controllers
  final TextEditingController _emailController       = TextEditingController();
  final TextEditingController _otpController         = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State
  bool _isLoading           = false;
  bool _obscureNew          = true;
  bool _obscureConfirm      = true;
  final Map<String, String?> _fieldErrors = {};

  // OTP Timer
  int  _otpSecondsLeft = 60;
  Timer? _otpTimer;
  bool _canResend = false;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Color palette (matches login_screen)
  static const Color navyDark    = Color(0xFF1A2B45);
  static const Color navyMid     = Color(0xFF243655);
  static const Color beige       = Color(0xFFF5F0E8);
  static const Color beigeLight  = Color(0xFFFAF7F2);
  static const Color textMuted   = Color(0xFF8A9BB0);
  static const Color accent      = Color(0xFF2D5A8E);
  static const Color errorRed    = Color(0xFFC0392B);
  static const Color successGreen = Color(0xFF27AE60);

  static const Color _whiteOpacity03 = Color(0x08FFFFFF);
  static const Color _whiteOpacity04 = Color(0x0AFFFFFF);
  static const Color _whiteOpacity60 = Color(0x99FFFFFF);
  static const Color _navyOpacity60  = Color(0x991A2B45);
  static const Color _blackOpacity03 = Color(0x08000000);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // OTP TIMER
  // ─────────────────────────────────────────────

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _otpSecondsLeft = 60;
      _canResend = false;
    });
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_otpSecondsLeft > 0) {
          _otpSecondsLeft--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ─────────────────────────────────────────────
  // STEP TRANSITION
  // ─────────────────────────────────────────────

  void _goToStep(int step) {
  FocusManager.instance.primaryFocus?.unfocus();

  _animController.reset();
  setState(() {
    _currentStep = step;
    _fieldErrors.clear();
  });
  _animController.forward();
}

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();

    setState(() {
      _fieldErrors.clear();
      if (email.isEmpty) _fieldErrors['email'] = 'Email wajib diisi';
      if (email.isNotEmpty && !_isValidEmail(email)) {
        _fieldErrors['email'] = 'Format email tidak valid';
      }
    });
    if (_fieldErrors.isNotEmpty) return;

    setState(() => _isLoading = true);

    final result = await ApiService.forgotPasswordSendOtp(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      AppPopup.show(context, message: result['message'] ?? 'Kode OTP telah dikirim ke email Anda');
      _startOtpTimer();
      _goToStep(1);
    } else {
      AppPopup.show(context, message: result['message'] ?? 'Gagal mengirim OTP', isError: true);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();

    setState(() {
      _fieldErrors.clear();
      if (otp.isEmpty) _fieldErrors['otp'] = 'Kode OTP wajib diisi';
      if (otp.isNotEmpty && otp.length < 6) _fieldErrors['otp'] = 'Kode OTP harus 6 digit';
    });
    if (_fieldErrors.isNotEmpty) return;

    setState(() => _isLoading = true);

    final result = await ApiService.forgotPasswordVerifyOtp(
      email: _emailController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      AppPopup.show(context, message: 'Kode OTP terverifikasi');
      _goToStep(2);
    } else {
      AppPopup.show(context, message: result['message'] ?? 'Kode OTP tidak valid', isError: true);
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _fieldErrors.clear();
      if (newPass.isEmpty) _fieldErrors['new_password'] = 'Kata sandi baru wajib diisi';
      if (confirm.isEmpty) _fieldErrors['confirm_password'] = 'Konfirmasi kata sandi wajib diisi';
    });
    if (_fieldErrors.isNotEmpty) return;

    if (newPass.length < 8) {
      setState(() => _fieldErrors['new_password'] = 'Kata sandi minimal 8 karakter');
      return;
    }

    if (newPass != confirm) {
      setState(() => _fieldErrors['confirm_password'] = 'Konfirmasi kata sandi tidak cocok');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.forgotPasswordReset(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      password: newPass,
      passwordConfirmation: confirm,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      AppPopup.show(context, message: 'Kata sandi berhasil direset!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      AppPopup.show(context, message: result['message'] ?? 'Gagal mereset kata sandi', isError: true);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    final result = await ApiService.forgotPasswordSendOtp(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      AppPopup.show(context, message: 'Kode OTP baru telah dikirim');
      _startOtpTimer();
    } else {
      AppPopup.show(context, message: result['message'] ?? 'Gagal mengirim ulang OTP', isError: true);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
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
          // ── Header ──
          Expanded(
            flex: 3,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Back button
                          GestureDetector(
                            onTap: () {
                              if (_currentStep == 0) {
                                Navigator.pop(context);
                              } else {
                                _goToStep(_currentStep - 1);
                              }
                            },
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _whiteOpacity04,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Header content
                          Center(
                            child: Column(
                              children: [
                                _buildHeaderIcon(),
                                const SizedBox(height: 16),
                                Text(
                                  _getHeaderTitle(),
                                  style: const TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getHeaderSubtitle(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: _whiteOpacity60,
                                    height: 1.55,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
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
            flex: 5,
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
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Indicator
                        _buildStepIndicator(),
                        const SizedBox(height: 28),

                        // Forms
                        if (_currentStep == 0) _buildEmailStep(),
                        if (_currentStep == 1) _buildOtpStep(),
                        if (_currentStep == 2) _buildResetStep(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER HELPERS
  // ─────────────────────────────────────────────

  Widget _buildHeaderIcon() {
    final icons = [
      Icons.email_outlined,
      Icons.pin_outlined,
      Icons.lock_reset_rounded,
    ];
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _whiteOpacity04,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _whiteOpacity03, width: 1.5),
      ),
      child: Icon(
        icons[_currentStep],
        color: Colors.white,
        size: 30,
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentStep) {
      case 0: return 'Lupa Kata Sandi?';
      case 1: return 'Verifikasi OTP';
      case 2: return 'Buat Kata Sandi Baru';
      default: return '';
    }
  }

  String _getHeaderSubtitle() {
    switch (_currentStep) {
      case 0: return 'Masukkan email yang terdaftar untuk\nmenerima kode verifikasi';
      case 1: return 'Masukkan kode 6 digit yang telah\ndikirim ke email Anda';
      case 2: return 'Buat kata sandi baru yang kuat\nuntuk mengamankan akun Anda';
      default: return '';
    }
  }

  // ─────────────────────────────────────────────
  // STEP INDICATOR
  // ─────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive   = index == _currentStep;
        final isComplete = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? successGreen
                        : isActive
                            ? accent
                            : const Color(0xFFDDD8CE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 0: EMAIL
  // ─────────────────────────────────────────────

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('EMAIL'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'Masukkan email yang terdaftar',
          keyboardType: TextInputType.emailAddress,
          errorText: _fieldErrors['email'],
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 12),

        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDE5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0D9CC)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kami akan mengirimkan kode OTP 6 digit ke email Anda untuk verifikasi identitas.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textMuted.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Kirim Kode OTP',
          isLoading: _isLoading,
          onPressed: _handleSendOtp,
          icon: Icons.send_rounded,
        ),
        const SizedBox(height: 20),

        // Back to login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
              text: const TextSpan(
                text: 'Ingat kata sandi? ',
                style: TextStyle(fontSize: 13, color: textMuted),
                children: [
                  TextSpan(
                    text: 'Masuk',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: OTP
  // ─────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8DE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 16, color: textMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _emailController.text.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: navyDark,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _goToStep(0),
                child: const Icon(Icons.edit_outlined, size: 14, color: accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildLabel('KODE OTP'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _otpController,
          hint: 'Masukkan 6 digit kode OTP',
          keyboardType: TextInputType.number,
          errorText: _fieldErrors['otp'],
          prefixIcon: Icons.pin_outlined,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        // Timer & Resend
        Center(
          child: _canResend
              ? GestureDetector(
                  onTap: _handleResendOtp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDD8CE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          'Kirim Ulang Kode',
                          style: TextStyle(
                            fontSize: 13,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Kirim ulang dalam $_otpSecondsLeft detik',
                      style: const TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Verifikasi',
          isLoading: _isLoading,
          onPressed: _handleVerifyOtp,
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2: RESET PASSWORD
  // ─────────────────────────────────────────────

  Widget _buildResetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: successGreen),
              const SizedBox(width: 8),
              const Text(
                'Email terverifikasi',
                style: TextStyle(
                  fontSize: 13,
                  color: successGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildLabel('KATA SANDI BARU'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _newPasswordController,
          hint: 'Buat kata sandi baru (min. 8 karakter)',
          obscure: _obscureNew,
          keyboardType: TextInputType.visiblePassword,
          errorText: _fieldErrors['new_password'],
          prefixIcon: Icons.lock_outline_rounded,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureNew = !_obscureNew),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Password strength indicator
        _buildPasswordStrength(),
        const SizedBox(height: 20),

        _buildLabel('KONFIRMASI KATA SANDI'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: 'Ulangi kata sandi baru',
          obscure: _obscureConfirm,
          keyboardType: TextInputType.visiblePassword,
          errorText: _fieldErrors['confirm_password'],
          prefixIcon: Icons.lock_outline_rounded,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        _buildPrimaryButton(
          label: 'Reset Kata Sandi',
          isLoading: _isLoading,
          onPressed: _handleResetPassword,
          icon: Icons.lock_reset_rounded,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PASSWORD STRENGTH
  // ─────────────────────────────────────────────

  Widget _buildPasswordStrength() {
    final password = _newPasswordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;

    final labels = ['', 'Lemah', 'Cukup', 'Kuat', 'Sangat Kuat'];
    final colors = [
      const Color(0xFFDDD8CE),
      errorRed,
      const Color(0xFFE67E22),
      const Color(0xFF2ECC71),
      successGreen,
    ];

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: index < strength ? colors[strength] : const Color(0xFFDDD8CE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          labels[strength],
          style: TextStyle(
            fontSize: 11.5,
            color: colors[strength],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
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
          disabledBackgroundColor: _navyOpacity60,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

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
    String? errorText,
    IconData? prefixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
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
              color: hasError ? errorRed : const Color(0xFFDDD8CE),
              width: hasError ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(color: _blackOpacity03, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: (_) {
              // Rebuild for password strength
              if (_currentStep == 2) setState(() {});
            },
            style: const TextStyle(fontSize: 14, color: navyDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: InputBorder.none,
              counterText: '',
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Icon(prefixIcon, size: 20, color: textMuted),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
              style: const TextStyle(fontSize: 12, color: errorRed),
            ),
          ),
      ],
    );
  }
}
