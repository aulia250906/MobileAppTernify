import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_popup.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  // Color palette
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color cardWhite = Colors.white;

  static const Color _whiteOpacity25 = Color(0x40FFFFFF);
  static const Color _whiteOpacity55 = Color(0x8CFFFFFF);
  static const Color _whiteOpacity40 = Color(0x66FFFFFF);
  static const Color _blackOpacity25 = Color(0x40000000);
  static const Color _blackOpacity06 = Color(0x0F000000);

  // Form controllers
  final TextEditingController _namaDepanController = TextEditingController();
  final TextEditingController _namaBelakangController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _namaPeternakanController =
      TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaDepanController.dispose();
    _namaBelakangController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _namaPeternakanController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────

  /// Muat data lokal dulu (cepat), lalu sync dari API
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    // 1. Tampilkan data dari cache lokal dulu
    final saved = await ApiService.getSavedUser();
    if (saved != null) {
      _populateFields(saved);
      setState(() {
        _userData = saved;
        _isLoading = false;
      });
    }

    // 2. Fetch terbaru dari server di background
    final result = await ApiService.getProfile();
    if (!mounted) return;

    if (result['success'] == true) {
      _populateFields(result['user']);
      setState(() {
        _userData = result['user'];
        _isLoading = false;
      });
    } else if (saved == null) {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(Map<String, dynamic> user) {
    final namaLengkap = (user['nama_lengkap'] ?? '') as String;
    final parts = namaLengkap.split(' ');
    _namaDepanController.text = parts.isNotEmpty ? parts.first : '';
    _namaBelakangController.text = parts.length > 1
        ? parts.sublist(1).join(' ')
        : '';
    _emailController.text = user['email'] ?? '';
    _teleponController.text = user['no_telepon'] ?? '';
    _namaPeternakanController.text = user['nama_peternakan'] ?? '';
    _lokasiController.text = user['lokasi'] ?? '';
  }

  // ─────────────────────────────────────────────
  // SAVE CHANGES
  // ─────────────────────────────────────────────

  Future<void> _onSaveChanges() async {
    final namaDepan = _namaDepanController.text.trim();
    final namaBelakang = _namaBelakangController.text.trim();
    final namaLengkap = namaBelakang.isEmpty
        ? namaDepan
        : '$namaDepan $namaBelakang';

    if (namaDepan.isEmpty) {
      _showSnackbar('Nama depan tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final result = await ApiService.updateProfile(
      namaLengkap: namaLengkap,
      email: _emailController.text.trim(),
      noTelepon: _teleponController.text.trim(),
      namaPeternakan: _namaPeternakanController.text.trim(),
      lokasi: _lokasiController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      setState(() => _userData = result['user']);
      _showSnackbar('Perubahan berhasil disimpan');
    } else {
      _showSnackbar(result['message'] ?? 'Gagal menyimpan', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x1AC0392B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFC0392B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Keluar dari Akun',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: navyDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7A8D), height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: textMuted,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ApiService.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    AppPopup.show(context, message: message, isError: isError);
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userData == null) {
      return const Scaffold(
        backgroundColor: beigeLight,
        body: Center(child: CircularProgressIndicator(color: navyDark)),
      );
    }

    return Scaffold(
      backgroundColor: beigeLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsRow(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildAccountInfoForm(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Header ──
  Widget _buildProfileHeader() {
    final namaLengkap = _userData?['nama_lengkap'] ?? '';
    final email = _userData?['email'] ?? '';
    final lokasi = _userData?['lokasi'] ?? '';

    // Buat inisial dari nama lengkap
    final parts = namaLengkap.trim().split(' ');
    final inisial = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : namaLengkap.isNotEmpty
        ? namaLengkap[0].toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 50,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A2B45), Color(0xFF243655)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              // Avatar inisial
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C4A8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _whiteOpacity25, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: _blackOpacity25,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    inisial,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                namaLengkap.isEmpty ? 'Pengguna' : namaLengkap,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                email,
                style: const TextStyle(
                  fontSize: 13,
                  color: _whiteOpacity55,
                  letterSpacing: 0.2,
                ),
              ),

              if (lokasi.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: _whiteOpacity40,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lokasi,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _whiteOpacity40,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow() {
    final stats = [
      {'value': '—', 'label': 'Domba'},
      {'value': '—', 'label': 'Kandang'},
      {'value': '—', 'label': 'Scan'},
    ];

    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: List.generate(stats.length, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == stats.length - 1 ? 0 : 6,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8E2D8),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: _blackOpacity06,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      stats[i]['value']!,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: navyDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i]['label']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Account Info Form ──
  Widget _buildAccountInfoForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E2D8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: _blackOpacity06,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMASI AKUN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: Color(0xFF8A9BB0),
            ),
          ),
          const SizedBox(height: 18),

          // Nama Depan & Belakang (2 kolom)
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'NAMA DEPAN',
                  controller: _namaDepanController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'NAMA BELAKANG',
                  controller: _namaBelakangController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildFormField(
            label: 'EMAIL',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          _buildFormField(
            label: 'NO. TELEPON',
            controller: _teleponController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),

          _buildFormField(
            label: 'NAMA PETERNAKAN',
            controller: _namaPeternakanController,
          ),
          const SizedBox(height: 18),

          _buildFormField(label: 'LOKASI', controller: _lokasiController),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _onSaveChanges,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: navyDark, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: navyDark,
                disabledForegroundColor: navyDark.withOpacity(0.4),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: navyDark,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Color(0xFF7A8A9D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD8D2C8), width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              color: navyDark,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC0392B),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18),
            SizedBox(width: 8),
            Text(
              'Keluar dari Akun',
              style: TextStyle(
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
}
