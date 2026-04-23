import 'package:flutter/material.dart';
import '../models/domba_model.dart';
import '../repositories/domba_repository.dart';

// ─── Screen utama ─────────────────────────────────────────────────────────────

class DataDombaScreen extends StatefulWidget {
  final String? filterKandang;

  const DataDombaScreen({super.key, this.filterKandang});

  @override
  State<DataDombaScreen> createState() => _DataDombaScreenState();
}

class _DataDombaScreenState extends State<DataDombaScreen> {
  static const Color navyDark   = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted  = Color(0xFF8A9BB0);

  final DombaRepository _repo     = DombaRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Domba> _dombas      = [];
  bool _isLoading          = false;
  String? _errorMessage;
  String _activeFilter     = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      String? jenisKelamin;
      if (_activeFilter == 'Jantan') jenisKelamin = 'jantan';
      if (_activeFilter == 'Betina') jenisKelamin = 'betina';

      final results = await _repo.fetchDomba(
        search: _searchCtrl.text,
        jenisKelamin: jenisKelamin,
      );

      setState(() {
        _dombas = results;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── computed ────────────────────────────────────────────────────────────────
  int get _total   => _dombas.length;
  int get _jantan  => _dombas.where((d) => d.jenisKelamin == 'jantan').length;
  int get _betina  => _dombas.where((d) => d.jenisKelamin == 'betina').length;

  List<Domba> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    var list = _dombas;

    // Filter lokal berdasarkan pencarian
    if (q.isNotEmpty) {
      list = list.where((d) =>
        d.earTag.toLowerCase().contains(q) ||
        (d.idBangsa?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    return list;
  }

  // ── color helpers ───────────────────────────────────────────────────────────
  Color _genderColor(String jk) {
    return jk == 'jantan'
        ? const Color(0xFF2196F3)
        : const Color(0xFFE91E63);
  }

  Color _genderBg(String jk) {
    return jk == 'jantan'
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFFCE4EC);
  }

  // ── navigasi ke form ────────────────────────────────────────────────────────
  void _openForm({Domba? domba}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DombaFormScreen(domba: domba)),
    );
    if (result == true) _loadAll();
  }

  // ── delete ──────────────────────────────────────────────────────────────────
  Future<void> _deleteDomba(Domba d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Domba'),
        content: Text('Yakin ingin menghapus domba "${d.earTag}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.deleteDomba(d.idDomba);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Domba "${d.earTag}" berhasil dihapus.')),
          );
          _loadAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      'Semua ($_total)',
      'Jantan ($_jantan)',
      'Betina ($_betina)',
    ];

    final activeLabel = _activeFilter == 'Semua'
        ? 'Semua ($_total)'
        : filters.firstWhere((f) => f.startsWith(_activeFilter),
            orElse: () => _activeFilter);

    final items = _filtered;

    return Scaffold(
      backgroundColor: beigeLight,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: Column(
          children: [
            _buildAppBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildSummaryCards(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildFilterChips(filters, activeLabel),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          children: [
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text('Tidak ada data domba.',
                                      style: TextStyle(color: textMuted)),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: items.asMap().entries.map((e) {
                                    return _buildDombaItem(e.value,
                                        isLast: e.key == items.length - 1);
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Menampilkan ${items.length} domba',
                                style: const TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTambahButton(),
                          ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_errorMessage!, textAlign: TextAlign.center,
                style: const TextStyle(color: textMuted)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadAll, child: const Text('Coba Lagi')),
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
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 16),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Domba',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 2),
                    Text('$_total ekor terdaftar',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.55))),
                  ],
                ),
              ),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Colors.white70, size: 20),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD8CE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (_) => _loadAll(),
        style: const TextStyle(fontSize: 14, color: navyDark),
        decoration: InputDecoration(
          hintText: 'Cari ear tag domba...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadAll();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      {'label': 'Total',   'value': '$_total',   'icon': Icons.pets, 'color': const Color(0xFF1A2B45), 'active': _activeFilter == 'Semua'},
      {'label': 'Jantan',  'value': '$_jantan',  'icon': Icons.male, 'color': const Color(0xFF2196F3), 'active': _activeFilter == 'Jantan'},
      {'label': 'Betina',  'value': '$_betina',  'icon': Icons.female, 'color': const Color(0xFFE91E63), 'active': _activeFilter == 'Betina'},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = cards[i];
          final isActive = c['active'] as bool;
          return GestureDetector(
            onTap: () => setState(() {
              _activeFilter = i == 0 ? 'Semua' : c['label'] as String;
              _loadAll();
            }),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? Border(bottom: BorderSide(color: c['color'] as Color, width: 3))
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
                  Row(
                    children: [
                      Text(c['value'] as String,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: navyDark,
                          )),
                      const Spacer(),
                      Icon(c['icon'] as IconData, size: 16, color: c['color'] as Color),
                    ],
                  ),
                  const Spacer(),
                  Text(c['label'] as String,
                      style: const TextStyle(fontSize: 11.5, color: textMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(List<String> filters, String activeLabel) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label   = filters[i];
          final isActive = label == activeLabel || (i == 0 && _activeFilter == 'Semua');
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = i == 0 ? 'Semua' : label.split(' ').first;
              });
              _loadAll();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? navyDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive ? navyDark : const Color(0xFFDDD8CE)),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? Colors.white : textMuted,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDombaItem(Domba d, {required bool isLast}) {
    return GestureDetector(
      onTap: () => _showDetailModal(d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF0EDE6), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _genderBg(d.jenisKelamin),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                d.jenisKelamin == 'jantan' ? Icons.male : Icons.female,
                size: 20, color: _genderColor(d.jenisKelamin),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.earTag,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: navyDark,
                      )),
                  const SizedBox(height: 3),
                  Text(
                    '${d.idBangsa ?? '-'} · ${d.jenisKelaminLabel} · ${d.umur}',
                    style: const TextStyle(fontSize: 11.5, color: textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _genderBg(d.jenisKelamin),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(d.jenisKelaminLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _genderColor(d.jenisKelamin),
                  )),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildTambahButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah Domba',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: navyDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showDetailModal(Domba d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailDombaModal(
        domba: d,
        onEdit: () {
          Navigator.pop(context);
          _openForm(domba: d);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteDomba(d);
        },
        genderColor: _genderColor,
        genderBg: _genderBg,
      ),
    );
  }
}

// ─── Detail Modal ─────────────────────────────────────────────────────────────

class _DetailDombaModal extends StatelessWidget {
  final Domba domba;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color Function(String) genderColor;
  final Color Function(String) genderBg;

  static const Color navyDark  = Color(0xFF1A2B45);
  static const Color textMuted = Color(0xFF8A9BB0);

  const _DetailDombaModal({
    required this.domba,
    required this.onEdit,
    required this.onDelete,
    required this.genderColor,
    required this.genderBg,
  });

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
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Detail Domba',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navyDark,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEAE4D8),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close, size: 16, color: navyDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Identity card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5EFE4),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: genderBg(domba.jenisKelamin),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                        domba.jenisKelamin == 'jantan' ? Icons.male : Icons.female,
                        size: 28, color: genderColor(domba.jenisKelamin),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(domba.earTag,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: navyDark,
                              )),
                          const SizedBox(height: 2),
                          Text('${domba.idBangsa ?? '-'} · ${domba.jenisKelaminLabel}',
                              style: const TextStyle(
                                  fontSize: 12.5, color: textMuted)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                                color: genderBg(domba.jenisKelamin),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(domba.jenisKelaminLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: genderColor(domba.jenisKelamin),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Info grid 2x2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _infoBox('UMUR', domba.umur)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoBox('TANGGAL LAHIR', domba.tanggalLahir ?? '-')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _infoBox('INDUK', domba.namaInduk)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoBox('PEJANTAN', domba.namaPejantan)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Delete button
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: navyDark,
                        side: const BorderSide(
                            color: Color(0xFFBFB8A8), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Tutup',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Edit',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE4D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFF8A9BB0),
              )),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: navyDark,
              )),
        ],
      ),
    );
  }
}

// ─── Form Tambah / Edit ───────────────────────────────────────────────────────

class DombaFormScreen extends StatefulWidget {
  final Domba? domba;

  const DombaFormScreen({super.key, this.domba});

  @override
  State<DombaFormScreen> createState() => _DombaFormScreenState();
}

class _DombaFormScreenState extends State<DombaFormScreen> {
  static const Color navyDark = Color(0xFF1A2B45);

  final _formKey       = GlobalKey<FormState>();
  final _repo          = DombaRepository();
  final _earTagCtrl    = TextEditingController();
  final _bangsaCtrl    = TextEditingController();

  String? _jenisKelamin;
  DateTime? _tanggalLahir;
  String? _idInduk;
  String? _idPejantan;

  List<Domba> _listBetina  = [];
  List<Domba> _listJantan  = [];
  bool _isSaving           = false;
  bool _isLoadingDropdown  = false;

  bool get isEdit => widget.domba != null;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    if (isEdit) _prefill();
  }

  void _prefill() {
    final d = widget.domba!;
    _earTagCtrl.text    = d.earTag;
    _bangsaCtrl.text    = d.idBangsa ?? '';
    _jenisKelamin       = d.jenisKelamin;
    _idInduk            = d.idInduk;
    _idPejantan         = d.idPejantan;
    if (d.tanggalLahir != null) _tanggalLahir = DateTime.tryParse(d.tanggalLahir!);
  }

  Future<void> _loadDropdowns() async {
    setState(() => _isLoadingDropdown = true);
    try {
      final results = await Future.wait([
        _repo.fetchBetina(),
        _repo.fetchJantan(),
      ]);
      setState(() {
        _listBetina = results[0];
        _listJantan = results[1];
      });
    } catch (_) {}
    finally { setState(() => _isLoadingDropdown = false); }
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'ear_tag':       _earTagCtrl.text.trim(),
      'id_bangsa':     _bangsaCtrl.text.trim().isEmpty ? null : _bangsaCtrl.text.trim(),
      'jenis_kelamin': _jenisKelamin,
      'tanggal_lahir': _tanggalLahir != null
          ? '${_tanggalLahir!.year}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.day.toString().padLeft(2, '0')}'
          : null,
      'id_induk':      _idInduk,
      'id_pejantan':   _idPejantan,
    };

    try {
      if (isEdit) {
        await _repo.updateDomba(widget.domba!.idDomba, payload);
      } else {
        await _repo.createDomba(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Data berhasil diperbarui.' : 'Domba berhasil ditambahkan.'),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _earTagCtrl.dispose();
    _bangsaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyDark,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Domba' : 'Tambah Domba'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_earTagCtrl, 'Ear Tag *', Icons.tag,
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
            _field(_bangsaCtrl, 'Jenis / Bangsa', Icons.category_outlined),
            const SizedBox(height: 4),
            // Jenis kelamin
            _dropdown<String>(
              label: 'Jenis Kelamin *',
              icon: Icons.wc,
              value: _jenisKelamin,
              items: const [
                DropdownMenuItem(value: 'jantan', child: Text('Jantan')),
                DropdownMenuItem(value: 'betina', child: Text('Betina')),
              ],
              onChanged: (v) => setState(() {
                _jenisKelamin = v;
                _idInduk = null;
                _idPejantan = null;
              }),
              validator: (v) => v == null ? 'Wajib dipilih' : null,
            ),
            // Tanggal lahir
            const SizedBox(height: 4),
            InkWell(
              onTap: _pickTanggal,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _tanggalLahir != null
                      ? '${_tanggalLahir!.day}/${_tanggalLahir!.month}/${_tanggalLahir!.year}'
                      : 'Pilih tanggal...',
                  style: TextStyle(color: _tanggalLahir != null ? null : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_isLoadingDropdown)
              const LinearProgressIndicator()
            else ...[
              _dropdown<String>(
                label: 'Induk (betina)',
                icon: Icons.female,
                value: _idInduk,
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Tidak ada —')),
                  ..._listBetina
                      .where((d) => !isEdit || d.idDomba != widget.domba!.idDomba)
                      .map((d) => DropdownMenuItem(value: d.idDomba, child: Text(d.earTag))),
                ],
                onChanged: (v) => setState(() => _idInduk = v),
              ),
              _dropdown<String>(
                label: 'Pejantan (jantan)',
                icon: Icons.male,
                value: _idPejantan,
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Tidak ada —')),
                  ..._listJantan
                      .where((d) => !isEdit || d.idDomba != widget.domba!.idDomba)
                      .map((d) => DropdownMenuItem(value: d.idDomba, child: Text(d.earTag))),
                ],
                onChanged: (v) => setState(() => _idPejantan = v),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Domba',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}