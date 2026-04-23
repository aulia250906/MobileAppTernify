import 'package:flutter/material.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  // Color palette
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color navyMid = Color(0xFF243655);
  static const Color beige = Color(0xFFF5F0E8);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color cardWhite = Colors.white;
  static const Color borderColor = Color(0xFFDDD8CE);

  // Warna pra-kalkulasi (mengganti withOpacity)
  static const Color _whiteOpacity25 = Color(0x40FFFFFF);
  static const Color _whiteOpacity55 = Color(0x8CFFFFFF);
  static const Color _whiteOpacity40 = Color(0x66FFFFFF);
  static const Color _blackOpacity25 = Color(0x40000000);
  static const Color _blackOpacity06 = Color(0x0F000000);
  static const Color _blackOpacity04 = Color(0x0A000000);
  static const Color _textMutedOpacity80 = Color(0xCC8A9BB0);

  // Form controllers
  final TextEditingController _namaDepanController = TextEditingController();
  final TextEditingController _namaBelakangController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _namaPeternakanController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _namaDepanController.text = 'Ahmad';
    _namaBelakangController.text = 'Fauzi';
    _emailController.text = 'admin@ternakdigital.id';
    _teleponController.text = '081234567890';
    _namaPeternakanController.text = 'Peternakan Fauzi';
  }

  @override
  void dispose() {
    _namaDepanController.dispose();
    _namaBelakangController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _namaPeternakanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header with curved bottom ──
            _buildProfileHeader(),

            // ── Stats Row (overlapping header) ──
            _buildStatsRow(),

            // ── Informasi Akun Form ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildAccountInfoForm(),
            ),

            // ── Logout Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── Profile Header
  // ─────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Navy background with curved bottom
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
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C4A8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _whiteOpacity25,
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: _blackOpacity25,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'AF',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name
              const Text(
                'Ahmad Fauzi',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Email
              const Text(
                'admin@ternakdigital.id',
                style: TextStyle(
                  fontSize: 13,
                  color: _whiteOpacity55,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: _whiteOpacity40,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Garut, Jawa Barat',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _whiteOpacity40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ── Stats Row with individual bordered cards
  // ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {'value': '248', 'label': 'Domba'},
      {'value': '8', 'label': 'Kandang'},
      {'value': '142', 'label': 'Scan'},
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
                        color: _textMutedOpacity80,
                        fontWeight: FontWeight.w400,
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

  // ─────────────────────────────────────────────
  // ── Account Info Form
  // ─────────────────────────────────────────────
  Widget _buildAccountInfoForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9E0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: _blackOpacity04,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with subtle divider
          const Text(
            'Informasi Akun',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFD4C4A8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),

          // Nama Depan + Nama Belakang
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

          // Email
          _buildFormField(
            label: 'EMAIL',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          // No. Telepon
          _buildFormField(
            label: 'NO. TELEPON',
            controller: _teleponController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),

          // Nama Peternakan
          _buildFormField(
            label: 'NAMA PETERNAKAN',
            controller: _namaPeternakanController,
          ),
          const SizedBox(height: 28),

          // Simpan Perubahan button — outlined style with navy border
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _onSaveChanges,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: navyDark, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: navyDark,
              ),
              child: const Text(
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

  // ─────────────────────────────────────────────
  // ── Form field
  // ─────────────────────────────────────────────
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ── Logout Button
  // ─────────────────────────────────────────────
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
          shadowColor: const Color(0x4DC0392B),
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

  // ─────────────────────────────────────────────
  // ── Actions
  // ─────────────────────────────────────────────
  void _onSaveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Perubahan berhasil disimpan'),
          ],
        ),
        backgroundColor: navyDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
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
}
