import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'scan_log_detail_screen.dart';

class RiwayatScanScreen extends StatefulWidget {
  const RiwayatScanScreen({super.key});

  @override
  State<RiwayatScanScreen> createState() => _RiwayatScanScreenState();
}

class _RiwayatScanScreenState extends State<RiwayatScanScreen> {
  String _activeFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);

  // Pre-computed opacity colors
  static const Color _whiteOpacity55 = Color(0x8CFFFFFF);
  static const Color _whiteOpacity10 = Color(0x1AFFFFFF);
  static const Color _blackOpacity04 = Color(0x0A000000);
  static const Color _navyOpacity20 = Color(0x331A2B45);

List<Map<String, dynamic>> _items = [];

bool _isLoading = true;
bool _isLoadingMore = false;

int _totalScan = 0;
int _page = 1;
bool _hasMore = false;

Timer? _debounce;
@override
void initState() {
  super.initState();
  _loadScanLogs(reset: true);
}

@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}

String get _filterParam {
  if (_activeFilter == 'Tinggi (>85%)') return 'tinggi';
  if (_activeFilter == 'Sedang') return 'sedang';
  if (_activeFilter == 'Rendah') return 'rendah';
  return 'semua';
}

IconData _iconByJenisDokumen(String value) {
  final lower = value.toLowerCase();

  if (lower.contains('vaksin') ||
      lower.contains('medis') ||
      lower.contains('kesehatan') ||
      lower.contains('pemeriksaan')) {
    return Icons.camera_alt_outlined;
  }

  return Icons.description_outlined;
}

Future<void> _loadScanLogs({bool reset = false}) async {
  if (reset) {
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasMore = false;
    });
  } else {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });
  }

  final targetPage = reset ? 1 : _page + 1;

  final response = await ApiService.fetchScanLogs(
    search: _searchController.text,
    filter: _filterParam,
    page: targetPage,
    perPage: 10,
    dateFrom: _dateFrom != null
        ? DateFormat('yyyy-MM-dd').format(_dateFrom!)
        : null,
    dateTo: _dateTo != null
        ? DateFormat('yyyy-MM-dd').format(_dateTo!)
        : null,
  );

  if (!mounted) return;

  if (response['success'] == true) {
    final rawData = response['data'];

    final newItems = rawData is List
        ? rawData.map((e) {
            final item = Map<String, dynamic>.from(e as Map);

            final jenisDokumen =
                item['jenis_dokumen']?.toString() ??
                item['sub']?.toString() ??
                '-';

            final confidence =
                int.tryParse(item['akurasi_score']?.toString() ??
                        item['confidence']?.toString() ??
                        '0') ??
                    0;

            return {
              'id_scan': item['id_scan'],
              'icon': _iconByJenisDokumen(jenisDokumen),
              'name': item['nama_file']?.toString().isNotEmpty == true
                  ? item['nama_file']
                  : item['name'] ?? 'Scan Catatan',
              'sub': jenisDokumen,
              'date': item['tanggal_scan_display'] ??
                  item['date'] ??
                  item['tanggal_scan'] ??
                  '-',
              'confidence': confidence,
              'hasil_ocr': item['hasil_ocr'],
              'detail_data': item['detail_data'],
            };
          }).toList()
        : <Map<String, dynamic>>[];

    final pagination = response['pagination'] is Map
        ? Map<String, dynamic>.from(response['pagination'])
        : <String, dynamic>{};

    setState(() {
      _totalScan = int.tryParse(response['total']?.toString() ?? '0') ?? 0;

      if (reset) {
        _items = newItems;
      } else {
        _items.addAll(newItems);
      }

      _page = targetPage;
      _hasMore = pagination['has_more'] == true;
      _isLoading = false;
      _isLoadingMore = false;
    });
  } else {
    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']?.toString() ?? 'Gagal mengambil riwayat scan'),
      ),
    );
  }
}

  List<Map<String, dynamic>> get _filteredItems {
    return _items;
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _buildSearchBar(),
                ),
                if (_dateFrom != null || _dateTo != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildDateRangeChip(),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
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
                      '$_totalScan total scan',
                      style: TextStyle(fontSize: 12.5, color: _whiteOpacity55),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _whiteOpacity10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white70,
            size: 20,
          ),
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CalendarPopup(
        initialFrom: _dateFrom,
        initialTo: _dateTo,
      ),
    );

    if (result != null) {
      setState(() {
        _dateFrom = result.start;
        _dateTo = result.end;
      });
      _loadScanLogs(reset: true);
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    _loadScanLogs(reset: true);
  }

  Widget _buildDateRangeChip() {
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    final label = _dateFrom != null && _dateTo != null
        ? '${fmt.format(_dateFrom!)} – ${fmt.format(_dateTo!)}'
        : _dateFrom != null
            ? 'Dari ${fmt.format(_dateFrom!)}'
            : 'Sampai ${fmt.format(_dateTo!)}';  

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB8CCE8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range, size: 14, color: navyDark),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: navyDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearDateRange,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: navyDark.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final bool hasDateFilter = _dateFrom != null || _dateTo != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD8CE)),
        boxShadow: const [
          BoxShadow(
            color: _blackOpacity04,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _loadScanLogs(reset: true);
                });
              },
              style: const TextStyle(fontSize: 14, color: navyDark),
              decoration: InputDecoration(
                hintText: 'Cari catatan scan...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFDDD8CE),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickDateRange,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 22,
                  color: hasDateFilter ? navyDark : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = _activeFilter == f['label'];
          return GestureDetector(
            onTap: () {
              final newFilter = f['label'] as String;
              if (_activeFilter != newFilter) {
                setState(() => _activeFilter = newFilter);
                _loadScanLogs(reset: true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? navyDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? navyDark : const Color(0xFFDDD8CE),
                ),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: _navyOpacity20,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f['icon'] != null) ...[
                    Text(
                      f['icon'] as String,
                      style: const TextStyle(fontSize: 11),
                    ),
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

  return GestureDetector(
    onTap: () async {
      final idScan = item['id_scan']?.toString();

      if (idScan == null || idScan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID scan tidak ditemukan'),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanLogDetailScreen(
            idScan: idScan,
            initialData: item,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: _blackOpacity04,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDE6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item['icon'] as IconData,
              size: 18,
              color: textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: navyDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['sub']} · ${item['date']}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: textMuted,
                  ),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    ),
  );
}
  Widget _buildLoadMore() {
    if (!_hasMore) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _isLoadingMore ? null : () => _loadScanLogs(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE4D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isLoadingMore
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : const Text(
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

// ─────────────────────────────────────────────
// CUSTOM CALENDAR POP-UP
// ─────────────────────────────────────────────

class _CalendarPopup extends StatefulWidget {
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const _CalendarPopup({this.initialFrom, this.initialTo});

  @override
  State<_CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<_CalendarPopup>
    with SingleTickerProviderStateMixin {
  static const Color _navy = Color(0xFF1A2B45);
  static const Color _beige = Color(0xFFFAF7F2);
  static const Color _muted = Color(0xFF8A9BB0);

  late DateTime _displayMonth;
  DateTime? _from;
  DateTime? _to;

  /// true = picking "dari", false = picking "sampai"
  bool _pickingFrom = true;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  final List<String> _dayLabels = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
    _displayMonth = DateTime(
      (_from ?? DateTime.now()).year,
      (_from ?? DateTime.now()).month,
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() => _displayMonth = next);
    }
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_pickingFrom) {
        _from = day;
        // Auto-advance to "sampai" picker
        _pickingFrom = false;
        // If "to" is before "from", reset "to"
        if (_to != null && _to!.isBefore(day)) {
          _to = null;
        }
      } else {
        if (_from != null && day.isBefore(_from!)) {
          // If user picks a date before "from", swap
          _to = _from;
          _from = day;
        } else {
          _to = day;
        }
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime day) {
    if (_from == null || _to == null) return false;
    return day.isAfter(_from!.subtract(const Duration(days: 1))) &&
        day.isBefore(_to!.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildDateInputs(),
              _buildMonthNav(),
              _buildDayHeaders(),
              _buildCalendarGrid(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2B45), Color(0xFF243655)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pilih Rentang Tanggal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Georgia',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Filter riwayat scan berdasarkan tanggal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInputs() {
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _dateField(
              label: 'Dari Tanggal',
              value: _from != null ? fmt.format(_from!) : '-- --- ----',
              isActive: _pickingFrom,
              onTap: () => setState(() => _pickingFrom = true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, size: 18, color: _muted),
          ),
          Expanded(
            child: _dateField(
              label: 'Sampai Tanggal',
              value: _to != null ? fmt.format(_to!) : '-- --- ----',
              isActive: !_pickingFrom,
              onTap: () => setState(() => _pickingFrom = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF3FA) : _beige,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _navy : const Color(0xFFDDD8CE),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? _navy : _muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? _navy : const Color(0xFF5A6A7D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navArrow(Icons.chevron_left_rounded, _prevMonth),
          Text(
            '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          _navArrow(Icons.chevron_right_rounded, _nextMonth),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _beige,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: _navy),
        ),
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _dayLabels
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final firstOfMonth =
        DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

    // Monday = 1
    int startWeekday = firstOfMonth.weekday; // 1=Mon … 7=Sun

    final cells = <Widget>[];

    // Leading empty cells
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_displayMonth.year, _displayMonth.month, d);
      final isToday = _isSameDay(day, now);
      final isFuture = day.isAfter(now);
      final isFrom = _from != null && _isSameDay(day, _from!);
      final isTo = _to != null && _isSameDay(day, _to!);
      final isEndpoint = isFrom || isTo;
      final isInRange = _isInRange(day) && !isEndpoint;

      cells.add(
        GestureDetector(
          onTap: isFuture ? null : () => _onDayTap(day),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isEndpoint
                  ? _navy
                  : isInRange
                      ? _navy.withOpacity(0.10)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isEndpoint
                  ? Border.all(color: _navy, width: 1.2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$d',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isEndpoint || isToday ? FontWeight.w700 : FontWeight.w400,
                color: isFuture
                    ? _muted.withOpacity(0.4)
                    : isEndpoint
                        ? Colors.white
                        : isInRange
                            ? _navy
                            : const Color(0xFF3A4A5C),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: cells,
      ),
    );
  }

  Widget _buildActions() {
    final canApply = _from != null && _to != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(color: Color(0xFFDDD8CE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: canApply
                  ? () {
                      Navigator.of(context).pop(
                        DateTimeRange(start: _from!, end: _to!),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                disabledBackgroundColor: _navy.withOpacity(0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'Terapkan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
