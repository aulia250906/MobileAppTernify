import 'package:flutter/material.dart';
import 'data_domba_screen.dart';

class KandangScreen extends StatefulWidget {
  const KandangScreen({super.key});

  @override
  State<KandangScreen> createState() => _KandangScreenState();
}

List<Map<String, dynamic>> kandangListPortable = [
  {
    'nama': 'Kandang A',
    'kode': '#KDG-001',
    'blok': 'Blok Utara',
    'domba': 42,
    'kapasitas': 60,
    'jenis': 'Domba Etawa',
    'pakan': 'Rumput + Konsentrat',
  },
  {
    'nama': 'Kandang B',
    'kode': '#KDG-002',
    'blok': 'Blok Selatan',
    'domba': 38,
    'kapasitas': 50,
    'jenis': 'Domba Garut',
    'pakan': 'Hijauan',
  },
];

class _KandangScreenState extends State<KandangScreen> {
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color beige = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color cardWhite = Colors.white;
  static const Color redAccent = Color(0xFFD94F4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 18),
                  ...kandangListPortable.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildKandangCard(entry.value, entry.key),
                  )),
                  _buildTambahKandang(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2B45), Color(0xFF243655)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kandang',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${kandangListPortable.length} kandang aktif',
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
              _notifButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notifButton() {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
          Positioned(
            top: 7, right: 7,
            child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalDomba = kandangListPortable.fold<int>(0, (sum, k) => sum + (k['domba'] as int));
    final stats = [
      {'label': 'Total Kandang', 'value': '${kandangListPortable.length}'},
      {'label': 'Aktif', 'value': '${kandangListPortable.length}'},
      {'label': 'Total Domba', 'value': '$totalDomba'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final isFirst = i == 0;
          return Container(
            width: 118,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: isFirst ? const Border(bottom: BorderSide(color: navyDark, width: 3)) : null,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats[i]['value']!,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                  ),
                ),
                const Spacer(),
                Text(
                  stats[i]['label']!,
                  style: const TextStyle(fontSize: 11.5, color: textMuted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKandangCard(Map<String, dynamic> kandang, int index) {
    final domba = kandang['domba'] as int;
    final kapasitas = kandang['kapasitas'] as int;
    final isiPct = (domba / kapasitas);
    final isiPctDisplay = (isiPct * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: navyDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kandang['nama'],
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${kandang['kode']} · ${kandang['blok']}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _statBox('$domba', 'Domba'),
                const SizedBox(width: 8),
                _statBox('$kapasitas', 'Kapasitas'),
                const SizedBox(width: 8),
                _statBox('$isiPctDisplay%', 'Isi'),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: isiPct,
                minHeight: 6,
                backgroundColor: const Color(0xFFEEE9DF),
                valueColor: const AlwaysStoppedAnimation<Color>(navyDark),
              ),
            ),
          ),

          // Jenis & pakan
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              '${kandang['jenis']} · Pakan: ${kandang['pakan']}',
              style: const TextStyle(fontSize: 12, color: textMuted),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                _actionButton('Edit', Colors.white, navyDark, const Color(0xFFBFB8A8),
                  onTap: () => _showEditDialog(index),
                ),
                const SizedBox(width: 8),
                _actionButton('Domba', const Color(0xFFEAE4D8), navyDark, Colors.transparent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DataDombaScreen(
                        filterKandang: kandang['nama'] as String,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _actionButton('Hapus', redAccent, Colors.white, redAccent,
                  onTap: () => _showDeleteDialog(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: navyDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, color: textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color bg,
    Color fg,
    Color border, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1.3),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTambahKandang() {
    return GestureDetector(
      onTap: _showTambahDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECE4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFB8A8), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: navyDark, size: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tambah Kandang Baru',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: navyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

// data portable sementara
  void _showTambahDialog() {
    final namaCtrl = TextEditingController();
    final blokCtrl = TextEditingController();
    final kapasitasCtrl = TextEditingController();
    final jenisCtrl = TextEditingController();
    final pakanCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KandangFormSheet(
        title: 'Tambah Kandang Baru',
        namaCtrl: namaCtrl,
        blokCtrl: blokCtrl,
        kapasitasCtrl: kapasitasCtrl,
        jenisCtrl: jenisCtrl,
        pakanCtrl: pakanCtrl,
        onSave: () {
          if (namaCtrl.text.isEmpty) return;
          setState(() {
            kandangListPortable.add({
              'nama': namaCtrl.text,
              'kode': '#KDG-00${kandangListPortable.length + 1}',
              'blok': blokCtrl.text.isEmpty ? 'Blok Baru' : blokCtrl.text,
              'domba': 0,
              'kapasitas': int.tryParse(kapasitasCtrl.text) ?? 50,
              'jenis': jenisCtrl.text.isEmpty ? '-' : jenisCtrl.text,
              'pakan': pakanCtrl.text.isEmpty ? '-' : pakanCtrl.text,
            });
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog(int index) {
    final k = kandangListPortable[index];
    final namaCtrl = TextEditingController(text: k['nama']);
    final blokCtrl = TextEditingController(text: k['blok']);
    final kapasitasCtrl = TextEditingController(text: '${k['kapasitas']}');
    final jenisCtrl = TextEditingController(text: k['jenis']);
    final pakanCtrl = TextEditingController(text: k['pakan']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KandangFormSheet(
        title: 'Edit ${k['nama']}',
        namaCtrl: namaCtrl,
        blokCtrl: blokCtrl,
        kapasitasCtrl: kapasitasCtrl,
        jenisCtrl: jenisCtrl,
        pakanCtrl: pakanCtrl,
        onSave: () {
          setState(() {
            kandangListPortable[index] = {
              ...kandangListPortable[index],
              'nama': namaCtrl.text,
              'blok': blokCtrl.text,
              'kapasitas': int.tryParse(kapasitasCtrl.text) ?? k['kapasitas'],
              'jenis': jenisCtrl.text,
              'pakan': pakanCtrl.text,
            };
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus ${kandangListPortable[index]['nama']}?',
          style: const TextStyle(fontFamily: 'Georgia', fontSize: 17, color: navyDark)),
        content: const Text('Data kandang ini akan dihapus secara permanen.',
          style: TextStyle(fontSize: 13.5, color: textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => kandangListPortable.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}


class _KandangFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController namaCtrl, blokCtrl, kapasitasCtrl, jenisCtrl, pakanCtrl;
  final VoidCallback onSave;

  const _KandangFormSheet({
    required this.title,
    required this.namaCtrl,
    required this.blokCtrl,
    required this.kapasitasCtrl,
    required this.jenisCtrl,
    required this.pakanCtrl,
    required this.onSave,
  });

  static const Color navyDark = Color(0xFF1A2B45);
  static const Color textMuted = Color(0xFF8A9BB0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 18,
                  fontWeight: FontWeight.bold, color: navyDark)),
            const SizedBox(height: 16),
            _field('Nama Kandang', namaCtrl),
            _field('Blok', blokCtrl),
            _field('Kapasitas', kapasitasCtrl, type: TextInputType.number),
            _field('Jenis Domba', jenisCtrl),
            _field('Pakan', pakanCtrl),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, letterSpacing: 1.1,
                fontWeight: FontWeight.w700, color: Color(0xFF6B7A8D))),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD8CE)),
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              style: const TextStyle(fontSize: 14, color: navyDark),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}