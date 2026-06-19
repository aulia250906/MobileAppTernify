import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ScanLogDetailScreen extends StatefulWidget {
  final String idScan;
  final Map<String, dynamic>? initialData;

  const ScanLogDetailScreen({
    super.key,
    required this.idScan,
    this.initialData,
  });

  @override
  State<ScanLogDetailScreen> createState() => _ScanLogDetailScreenState();
}

class _ScanLogDetailScreenState extends State<ScanLogDetailScreen> {
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color _blackOpacity04 = Color(0x0A000000);

  bool _isLoading = true;
  bool _showRawText = false;

  Map<String, dynamic>? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.fetchScanLogDetail(widget.idScan);

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _data = Map<String, dynamic>.from(response['data'] ?? {});
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = response['message']?.toString();
      });
    }
  }

  int _confidenceValue() {
    final raw = _data?['akurasi_score'] ?? _data?['confidence'] ?? 0;
    return int.tryParse(raw.toString()) ?? 0;
  }

  Color _confidenceColor(int value) {
    if (value > 85) return const Color(0xFF4CAF50);
    if (value >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  String _confidenceLabel(int value) {
    if (value > 85) return 'Akurasi Tinggi';
    if (value >= 60) return 'Akurasi Sedang';
    return 'Akurasi Rendah';
  }

  Map<String, dynamic> _detailData() {
    final raw = _data?['detail_data'];

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  String _fieldLabel(String key) {
    final labels = {
      'ear_tag': 'Nomor Ear Tag',
      'gejala': 'Gejala',
      'diagnosa': 'Diagnosa',
      'tindakan': 'Tindakan',
      'dosis_obat': 'Dosis Obat',
      'status_kondisi': 'Status Kondisi',
      'catatan': 'Catatan Tambahan',
      'nama_domba': 'Nama Domba',
      'berat': 'Berat Badan',
      'umur': 'Umur',
      'jenis_kelamin': 'Jenis Kelamin',
      'ras': 'Ras / Jenis',
      'id_kandang': 'ID Kandang',
    };

    return labels[key] ??
        key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) {
              if (word.isEmpty) return word;
              return '${word[0].toUpperCase()}${word.substring(1)}';
            })
            .join(' ');
  }

  IconData _fieldIcon(String key) {
    final icons = {
      'ear_tag': Icons.label_outlined,
      'gejala': Icons.thermostat_outlined,
      'diagnosa': Icons.medical_services_outlined,
      'tindakan': Icons.healing_outlined,
      'dosis_obat': Icons.medication_outlined,
      'status_kondisi': Icons.monitor_heart_outlined,
      'catatan': Icons.note_alt_outlined,
      'nama_domba': Icons.pets_outlined,
      'berat': Icons.scale_outlined,
      'umur': Icons.cake_outlined,
      'jenis_kelamin': Icons.wc_outlined,
      'ras': Icons.category_outlined,
      'id_kandang': Icons.house_outlined,
    };

    return icons[key] ?? Icons.text_fields_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final confidence = _confidenceValue();
    final confColor = _confidenceColor(confidence);

    final namaFile =
        data?['nama_file']?.toString().isNotEmpty == true
            ? data!['nama_file'].toString()
            : data?['name']?.toString() ?? 'Detail Scan';

    final jenisDokumen =
        data?['jenis_dokumen']?.toString() ??
        data?['sub']?.toString() ??
        '-';

    final tanggal =
        data?['tanggal_scan_display']?.toString() ??
        data?['date']?.toString() ??
        data?['tanggal_scan']?.toString() ??
        '-';

    return Scaffold(
      backgroundColor: beigeLight,
      body: Column(
        children: [
          _buildAppBar(namaFile),
          Expanded(
            child: _isLoading && data == null
                ? const Center(
                    child: CircularProgressIndicator(color: navyDark),
                  )
                : _errorMessage != null && data == null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _loadDetail,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCard(
                                namaFile: namaFile,
                                jenisDokumen: jenisDokumen,
                                tanggal: tanggal,
                                confidence: confidence,
                                confColor: confColor,
                              ),
                              const SizedBox(height: 14),
                              _buildAccuracyInfo(confidence, confColor),
                              const SizedBox(height: 14),
                              _buildDetectedDataCard(),
                              const SizedBox(height: 14),
                              _buildRawTextCard(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String title) {
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
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Scan',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0x8CFFFFFF),
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

  Widget _buildSummaryCard({
    required String namaFile,
    required String jenisDokumen,
    required String tanggal,
    required int confidence,
    required Color confColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Scan',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navyDark,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow(
            icon: Icons.insert_drive_file_outlined,
            label: 'Nama File',
            value: namaFile,
          ),
          const Divider(height: 22, color: Color(0xFFEEE9DF)),
          _summaryRow(
            icon: Icons.description_outlined,
            label: 'Jenis Dokumen',
            value: jenisDokumen,
          ),
          const Divider(height: 22, color: Color(0xFFEEE9DF)),
          _summaryRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Scan',
            value: tanggal,
          ),
          const Divider(height: 22, color: Color(0xFFEEE9DF)),
          Row(
            children: [
              _smallIcon(Icons.speed_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Akurasi OCR',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: confColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$confidence%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: confColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyInfo(int confidence, Color confColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: confColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: confColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: confColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _confidenceLabel(confidence),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: confColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedDataCard() {
    final details = _detailData();
    final entries = details.entries.toList();

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              'Data yang Terdeteksi',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navyDark,
              ),
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'Tidak ada detail data yang tersimpan.',
                style: TextStyle(fontSize: 12.5, color: textMuted),
              ),
            )
          else
            ...entries.asMap().entries.map((indexed) {
              final index = indexed.key;
              final entry = indexed.value;
              final isLast = index == entries.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _smallIcon(_fieldIcon(entry.key)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fieldLabel(entry.key),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                entry.value?.toString().isNotEmpty == true
                                    ? entry.value.toString()
                                    : '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: navyDark,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: Color(0xFFEEE9DF)),
                    ),
                ],
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRawTextCard() {
    final rawText = _data?['hasil_ocr']?.toString() ?? '';

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showRawText = !_showRawText;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _smallIcon(Icons.text_snippet_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _showRawText
                          ? 'Sembunyikan teks asli OCR'
                          : 'Lihat teks asli OCR',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: navyDark,
                      ),
                    ),
                  ),
                  Icon(
                    _showRawText
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: navyDark,
                  ),
                ],
              ),
            ),
          ),
          if (_showRawText)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8E3DA)),
              ),
              child: SelectableText(
                rawText.isNotEmpty ? rawText : 'Tidak ada teks OCR tersimpan.',
                style: const TextStyle(
                  color: navyDark,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _smallIcon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: textMuted),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: navyDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: navyDark),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: _blackOpacity04,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal mengambil detail scan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navyDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: navyDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}