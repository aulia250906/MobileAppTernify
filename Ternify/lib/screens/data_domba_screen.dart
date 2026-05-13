import 'package:flutter/material.dart';
import '../models/domba_model.dart';
import '../repositories/domba_repository.dart';
import '../widgets/app_popup.dart';

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

  // ── navigasi ke form (pop-up modal) ─────────────────────────────────────────
  void _openForm({Domba? domba}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DombaFormModal(domba: domba),
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
          AppPopup.show(
            context,
            message: 'Domba "${d.earTag}" berhasil dihapus.',
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

// ─── Form Tambah / Edit (Pop-up Modal) ────────────────────────────────────────

class _DombaFormModal extends StatefulWidget {
  final Domba? domba;

  const _DombaFormModal({this.domba});

  @override
  State<_DombaFormModal> createState() => _DombaFormModalState();
}

class _DombaFormModalState extends State<_DombaFormModal>
    with SingleTickerProviderStateMixin {
  static const Color navyDark   = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted  = Color(0xFF8A9BB0);
  static const Color cardBg     = Color(0xFFF5EFE4);
  static const Color borderClr  = Color(0xFFEAE4D8);
  static const Color accentGold = Color(0xFFC9A96E);

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

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  bool get isEdit => widget.domba != null;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();

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
    if (d.tanggalLahir != null) {
      _tanggalLahir = DateTime.tryParse(d.tanggalLahir!);
    }
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: navyDark,
              onPrimary: Colors.white,
              surface: beigeLight,
              onSurface: navyDark,
            ),
          ),
          child: child!,
        );
      },
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
        AppPopup.show(
          context,
          message: isEdit ? 'Data berhasil diperbarui.' : 'Domba berhasil ditambahkan.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppPopup.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _earTagCtrl.dispose();
    _bangsaCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: beigeLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 24),
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 8),
                    // ── Identitas Domba Card ──
                    _sectionLabel('IDENTITAS DOMBA'),
                    const SizedBox(height: 8),
                    _styledField(
                      controller: _earTagCtrl,
                      label: 'Ear Tag',
                      hint: 'Contoh: DOM-001',
                      icon: Icons.tag,
                      isRequired: true,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    _styledField(
                      controller: _bangsaCtrl,
                      label: 'Jenis / Bangsa',
                      hint: 'Contoh: Domba Etawa',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ── Jenis Kelamin (Toggle Cards) ──
                    _sectionLabel('JENIS KELAMIN *'),
                    const SizedBox(height: 8),
                    _buildGenderToggle(),
                    if (_jenisKelamin == null)
                      const SizedBox.shrink(),
                    const SizedBox(height: 16),

                    // ── Tanggal Lahir ──
                    _sectionLabel('TANGGAL LAHIR'),
                    const SizedBox(height: 8),
                    _buildDatePickerField(),
                    const SizedBox(height: 16),

                    // ── Garis Keturunan ──
                    _sectionLabel('GARIS KETURUNAN'),
                    const SizedBox(height: 8),
                    if (_isLoadingDropdown)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: navyDark,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _styledDropdown<String>(
                        label: 'Induk (Betina)',
                        icon: Icons.female,
                        value: _idInduk,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('— Tidak ada —')),
                          ..._listBetina
                              .where((d) =>
                                  !isEdit || d.idDomba != widget.domba!.idDomba)
                              .map((d) => DropdownMenuItem(
                                  value: d.idDomba, child: Text(d.earTag))),
                        ],
                        onChanged: (v) => setState(() => _idInduk = v),
                      ),
                      const SizedBox(height: 12),
                      _styledDropdown<String>(
                        label: 'Pejantan (Jantan)',
                        icon: Icons.male,
                        value: _idPejantan,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('— Tidak ada —')),
                          ..._listJantan
                              .where((d) =>
                                  !isEdit || d.idDomba != widget.domba!.idDomba)
                              .map((d) => DropdownMenuItem(
                                  value: d.idDomba, child: Text(d.earTag))),
                        ],
                        onChanged: (v) => setState(() => _idPejantan = v),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Action Buttons ──
                    _buildActionButtons(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Handle ──
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2B45), Color(0xFF2A3F5F)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Domba' : 'Tambah Domba',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEdit
                      ? 'Perbarui informasi domba'
                      : 'Isi data domba baru',
                  style: const TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 16, color: navyDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textMuted,
      ),
    );
  }

  // ── Styled Text Field ──
  Widget _styledField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: navyDark,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, size: 18, color: accentGold),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42, minHeight: 42,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // ── Gender Toggle Cards ──
  Widget _buildGenderToggle() {
    return Row(
      children: [
        Expanded(
          child: _genderCard(
            label: 'Jantan',
            icon: Icons.male,
            value: 'jantan',
            color: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _genderCard(
            label: 'Betina',
            icon: Icons.female,
            value: 'betina',
            color: const Color(0xFFE91E63),
            bgColor: const Color(0xFFFCE4EC),
          ),
        ),
      ],
    );
  }

  Widget _genderCard({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    final isSelected = _jenisKelamin == value;
    return GestureDetector(
      onTap: () => setState(() {
        _jenisKelamin = value;
        _idInduk = null;
        _idPejantan = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : borderClr,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? color : textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : textMuted,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 18, height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Date Picker Field ──
  Widget _buildDatePickerField() {
    final hasDate = _tanggalLahir != null;
    return GestureDetector(
      onTap: _pickTanggal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: hasDate ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 16,
                color: hasDate ? const Color(0xFF4CAF50) : textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Lahir',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasDate
                        ? '${_tanggalLahir!.day.toString().padLeft(2, '0')}/${_tanggalLahir!.month.toString().padLeft(2, '0')}/${_tanggalLahir!.year}'
                        : 'Pilih tanggal...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                      color: hasDate ? navyDark : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Styled Dropdown ──
  Widget _styledDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: navyDark,
        ),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 20),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, size: 18, color: accentGold),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42, minHeight: 42,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14,
          ),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ── Action Buttons ──
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: navyDark,
              side: const BorderSide(color: Color(0xFFBFB8A8), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDark,
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor: navyDark.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEdit ? Icons.save_outlined : Icons.add,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEdit ? 'Simpan' : 'Tambah Domba',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}