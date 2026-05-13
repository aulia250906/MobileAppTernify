import 'package:flutter/material.dart';
import '../models/kandang_model.dart';
import '../repositories/kandang_repository.dart';
import '../widgets/app_popup.dart';
import 'data_domba_screen.dart';

class KandangScreen extends StatefulWidget {
  const KandangScreen({super.key});

  @override
  State<KandangScreen> createState() => _KandangScreenState();
}

class _KandangScreenState extends State<KandangScreen> {
  static const Color navyDark   = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted  = Color(0xFF8A9BB0);
  static const Color cardWhite  = Colors.white;
  static const Color redAccent  = Color(0xFFD94F4F);

  final KandangRepository _repo = KandangRepository();

  List<Kandang> _kandangList    = [];
  Map<String, int> _stats       = {'total_kandang': 0, 'total_domba': 0};
  bool _isLoading               = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final results = await Future.wait([
        _repo.fetchKandang(),
        _repo.fetchStatistik(),
      ]);
      setState(() {
        _kandangList = results[0] as List<Kandang>;
        _stats       = results[1] as Map<String, int>;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError()
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCards(),
                              const SizedBox(height: 18),
                              ..._kandangList.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildKandangCard(e.value, e.key),
                              )),
                              _buildTambahKandang(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadAll, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final total = _stats['total_kandang'] ?? 0;
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
                    const Text('Kandang',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 2),
                    Text('$total kandang aktif',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.55))),
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
              decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final statsDisplay = [
      {'label': 'Total Kandang', 'value': '${_stats['total_kandang'] ?? 0}'},
      {'label': 'Aktif',         'value': '${_stats['total_kandang'] ?? 0}'},
      {'label': 'Total Domba',   'value': '${_stats['total_domba'] ?? 0}'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statsDisplay.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final isFirst = i == 0;
          return Container(
            width: 118,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: isFirst
                  ? const Border(bottom: BorderSide(color: navyDark, width: 3))
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statsDisplay[i]['value']!,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: navyDark,
                    )),
                const Spacer(),
                Text(statsDisplay[i]['label']!,
                    style: const TextStyle(fontSize: 11.5, color: textMuted)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Kandang Card ───────────────────────────────────────────────────────────
  Widget _buildKandangCard(Kandang k, int index) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
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
                Text(k.namaKandang,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                const SizedBox(height: 3),
                Text(
                  '${k.idKandang} · ${k.tipeKandang ?? '-'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _statBox('${k.jumlahDomba}', 'Domba'),
                const SizedBox(width: 8),
                _statBox('${k.kapasitas}', 'Kapasitas'),
                const SizedBox(width: 8),
                _statBox('${k.persentaseIsiDisplay}%', 'Isi'),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: k.persentaseIsi,
                minHeight: 6,
                backgroundColor: const Color(0xFFEEE9DF),
                valueColor: const AlwaysStoppedAnimation<Color>(navyDark),
              ),
            ),
          ),

          // Tipe kandang info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              k.tipeKandang ?? '-',
              style: const TextStyle(fontSize: 12, color: textMuted),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                _actionButton('Edit', Colors.white, navyDark, const Color(0xFFBFB8A8),
                    onTap: () => _showFormSheet(kandang: k)),
                const SizedBox(width: 8),
                _actionButton('Domba', const Color(0xFFEAE4D8), navyDark, Colors.transparent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DataDombaScreen(filterKandang: k.namaKandang),
                      ),
                    )),
                const SizedBox(width: 8),
                _actionButton('Hapus', redAccent, Colors.white, redAccent,
                    onTap: () => _showDeleteDialog(k)),
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
            Text(value,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navyDark,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 11, color: textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color fg, Color border,
      {VoidCallback? onTap}) {
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
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              )),
        ),
      ),
    );
  }

  // ── Tambah Kandang Button ──────────────────────────────────────────────────
  Widget _buildTambahKandang() {
    return GestureDetector(
      onTap: () => _showFormSheet(),
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
            const Text('Tambah Kandang Baru',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: navyDark,
                )),
          ],
        ),
      ),
    );
  }

  // ── Form Sheet (Tambah & Edit) ─────────────────────────────────────────────
  void _showFormSheet({Kandang? kandang}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KandangFormSheet(
        kandang: kandang,
        onSave: (payload) async {
          try {
            if (kandang == null) {
              await _repo.createKandang(payload);
            } else {
              await _repo.updateKandang(kandang.idKandang, payload);
            }
            if (mounted) {
              Navigator.pop(context);
              AppPopup.show(
                context,
                message: kandang == null
                    ? 'Kandang berhasil ditambahkan.'
                    : 'Kandang berhasil diperbarui.',
              );
              _loadAll();
            }
          } catch (e) {
            if (mounted) {
              AppPopup.show(
                context,
                message: e.toString(),
                isError: true,
              );
            }
          }
        },
      ),
    );
  }

  // ── Delete Dialog ──────────────────────────────────────────────────────────
  void _showDeleteDialog(Kandang k) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus ${k.namaKandang}?',
            style: const TextStyle(
                fontFamily: 'Georgia', fontSize: 17, color: navyDark)),
        content: Text(
          k.jumlahDomba > 0
              ? 'Kandang ini masih berisi ${k.jumlahDomba} domba. Pindahkan domba terlebih dahulu sebelum menghapus.'
              : 'Data kandang ini akan dihapus secara permanen.',
          style: const TextStyle(fontSize: 13.5, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: textMuted)),
          ),
          if (k.jumlahDomba == 0)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _repo.deleteKandang(k.idKandang);
                  if (mounted) {
                    AppPopup.show(context, message: 'Kandang berhasil dihapus.');
                    _loadAll();
                  }
                } catch (e) {
                  if (mounted) {
                    AppPopup.show(
                      context,
                      message: e.toString(),
                      isError: true,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Hapus'),
            ),
        ],
      ),
    );
  }
}

// ─── Form Sheet Widget ────────────────────────────────────────────────────────

class _KandangFormSheet extends StatefulWidget {
  final Kandang? kandang;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _KandangFormSheet({this.kandang, required this.onSave});

  @override
  State<_KandangFormSheet> createState() => _KandangFormSheetState();
}

class _KandangFormSheetState extends State<_KandangFormSheet> {
  static const Color navyDark  = Color(0xFF1A2B45);
  static const Color textMuted = Color(0xFF8A9BB0);

  final _namaCtrl      = TextEditingController();
  final _tipeCtrl      = TextEditingController();
  final _kapasitasCtrl = TextEditingController();
  bool _isSaving       = false;

  bool get isEdit => widget.kandang != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _namaCtrl.text      = widget.kandang!.namaKandang;
      _tipeCtrl.text      = widget.kandang!.tipeKandang ?? '';
      _kapasitasCtrl.text = widget.kandang!.kapasitas.toString();
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tipeCtrl.dispose();
    _kapasitasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_namaCtrl.text.trim().isEmpty) {
      AppPopup.show(context, message: 'Nama kandang wajib diisi.', isError: true
      );
      return;
    }
    if (_kapasitasCtrl.text.trim().isEmpty) {
      AppPopup.show(context, message: 'Kapasitas wajib diisi.', isError: true
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'nama_kandang': _namaCtrl.text.trim(),
      'tipe_kandang': _tipeCtrl.text.trim().isEmpty ? null : _tipeCtrl.text.trim(),
      'kapasitas':    int.tryParse(_kapasitasCtrl.text.trim()) ?? 0,
    };

    await widget.onSave(payload);
    if (mounted) setState(() => _isSaving = false);
  }

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
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit ${widget.kandang!.namaKandang}' : 'Tambah Kandang Baru',
                style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyDark)),
            const SizedBox(height: 16),
            _field('Nama Kandang *', _namaCtrl),
            _field('Tipe / Blok', _tipeCtrl),
            _field('Kapasitas *', _kapasitasCtrl, type: TextInputType.number),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7A8D))),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}