import 'package:flutter/material.dart';

class RiwayatScanScreen extends StatefulWidget {
  const RiwayatScanScreen({super.key});

  @override
  State<RiwayatScanScreen> createState() => _RiwayatScanScreenState();
}

class _RiwayatScanScreenState extends State<RiwayatScanScreen> {
  String _activeFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);

  final List<Map<String, dynamic>> _allItems = [
    {
      'icon': Icons.description_outlined,
      'name': 'Catatan_Maret_01',
      'sub': 'rekam_berat.jpg',
      'date': '10 Mar 2026',
      'confidence': 92,
    },
    {
      'icon': Icons.camera_alt_outlined,
      'name': 'vaksinasi_feb.jpg',
      'sub': 'Vaksinasi',
      'date': '28 Feb 2026',
      'confidence': 68,
    },
    {
      'icon': Icons.description_outlined,
      'name': 'berat_bulanan_jan.jpg',
      'sub': 'Rekap Berat',
      'date': '31 Jan 2026',
      'confidence': 95,
    },
    {
      'icon': Icons.camera_alt_outlined,
      'name': 'kesehatan_jan.jpg',
      'sub': 'Pemeriksaan',
      'date': '15 Jan 2026',
      'confidence': 88,
    },
    {
      'icon': Icons.description_outlined,
      'name': 'catatan_berat_des.jpg',
      'sub': 'Rekap Berat',
      'date': '28 Des 2025',
      'confidence': 42,
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.toLowerCase();
    return _allItems.where((item) {
      final matchSearch = item['name'].toString().toLowerCase().contains(query) ||
          item['sub'].toString().toLowerCase().contains(query);
      final c = item['confidence'] as int;
      final matchFilter = _activeFilter == 'Semua' ||
          (_activeFilter == 'Tinggi (>85%)' && c > 85) ||
          (_activeFilter == 'Sedang' && c >= 60 && c <= 85) ||
          (_activeFilter == 'Rendah' && c < 60);
      return matchSearch && matchFilter;
    }).toList();
  }

  Color _confidenceColor(int c) {
    if (c > 85) return const Color(0xFF4CAF50);
    if (c >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: _buildSearchBar(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildFilterChips(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: [
                      ..._filteredItems.map((item) => _buildScanCard(item)),
                      const SizedBox(height: 12),
                      _buildLoadMore(),
                    ],
                  ),
                ),
              ],
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
                      'Riwayat Scan',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '142 total scan',
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD8CE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, color: navyDark),
        decoration: InputDecoration(
          hintText: 'Cari catatan scan...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Semua', 'color': navyDark},
      {'label': 'Tinggi (>85%)', 'color': const Color(0xFF4CAF50)},
      {'label': 'Sedang', 'color': const Color(0xFFFF9800)},
      {'label': 'Rendah', 'color': const Color(0xFFE53935)},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = _activeFilter == f['label'];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? navyDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? navyDark : const Color(0xFFDDD8CE),
                ),
                boxShadow: isActive ? [
                  BoxShadow(color: navyDark.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f['icon'] != null) ...[
                    Text(f['icon'] as String, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> item) {
    final confidence = item['confidence'] as int;
    final color = _confidenceColor(confidence);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDE6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item['icon'] as IconData, size: 18, color: textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: navyDark),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['sub']} · ${item['date']}',
                  style: const TextStyle(fontSize: 11.5, color: textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$confidence%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE4D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Muat Lebih Banyak',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: navyDark,
          ),
        ),
      ),
    );
  }
}