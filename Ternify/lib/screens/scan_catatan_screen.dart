import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_api_service.dart';
import '../services/api_service.dart';
import '../widgets/app_popup.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ScanCatatanScreen extends StatefulWidget {
  const ScanCatatanScreen({super.key});

  /// Global key to access the state and trigger the source picker popup
  static final GlobalKey<ScanCatatanScreenState> globalKey =
      GlobalKey<ScanCatatanScreenState>();

  @override
  State<ScanCatatanScreen> createState() => ScanCatatanScreenState();
}

class ScanCatatanScreenState extends State<ScanCatatanScreen> {
  bool _hasImage = false;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isSaved = false;
  XFile? _pickedImage;
  bool _sheetShown = false; // prevent showing multiple sheets

  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beige = Color(0xFFF5F0E8);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color cardWhite = Colors.white;

  // Pre-computed opacity colors
  static const Color _whiteOpacity55 = Color(0x8CFFFFFF);
  static const Color _whiteOpacity10 = Color(0x1AFFFFFF);
  static const Color _whiteOpacity12 = Color(0x1FFFFFFF);
  static const Color _whiteOpacity60 = Color(0x99FFFFFF);
  static const Color _blackOpacity05 = Color(0x0D000000);
  static const Color _greenOpacity30 = Color(0x4D4CAF50);

  final ImagePicker _picker = ImagePicker();

final OCRApiService _ocrApiService = OCRApiService();

Map<String, dynamic>? _ocrResult;
String? _errorMessage;
final Map<String, TextEditingController> _editControllers = {};
  // ──────────────────────────── Source Picker Bottom Sheet ────────────────────

  /// Public method — called from MainShell when scan tab becomes active
  void showSourcePickerSheet() {
    if (_sheetShown) return; // don't stack multiple sheets
    _sheetShown = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => _SourcePickerSheet(
        onCameraTap: () {
          Navigator.of(ctx).pop();
          _pickFromCamera();
        },
        onGalleryTap: () {
          Navigator.of(ctx).pop();
          _pickFromGallery();
        },
      ),
    ).whenComplete(() {
      _sheetShown = false;
    });
  }

Future<void> _pickFromCamera() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
  );

  if (image != null) {
    await _processOCR(image);
  }
}

Future<void> _pickFromGallery() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (image != null) {
    await _processOCR(image);
  }
}
Future<void> _processOCR(XFile image) async {
  setState(() {
  _pickedImage = image;
  _isProcessing = true;
  _hasImage = false;
  _errorMessage = null;
  _ocrResult = null;
  _isSaved = false;
  _disposeControllers();
});

  final result = await _ocrApiService.scanDocument(image);

  if (!mounted) return;

  if (result['success'] == true) {
    setState(() {
      _ocrResult = result['data'];
      _hasImage = true;
      _isProcessing = false;
      _initEditControllers();
    });
  } else {
    setState(() {
      _errorMessage = result['details']?.toString() ?? result['error']?.toString();
      _hasImage = false;
      _isProcessing = false;
    });

    AppPopup.show(
      context,
      message: _errorMessage ?? 'Gagal memproses OCR',
      isError: true,
      duration: const Duration(seconds: 4),
    );
  }
}
void _initEditControllers() {
  _disposeControllers();
  final details = _ocrResult?['details'];
  if (details is Map) {
    for (final entry in details.entries) {
      _editControllers[entry.key.toString()] = TextEditingController(
        text: entry.value?.toString() ?? '',
      );
    }
  }
}

void _disposeControllers() {
  for (final c in _editControllers.values) {
    c.dispose();
  }
  _editControllers.clear();
}

/// Get the edited details (from controllers, not raw OCR)
Map<String, dynamic> _getEditedDetails() {
  return _editControllers.map((key, ctrl) => MapEntry(key, ctrl.text.trim()));
}

@override
void dispose() {
  _disposeControllers();
  super.dispose();
}

String _todayForApi() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

String _getPickedFileName() {
  final name = _pickedImage?.name;

  if (name != null && name.trim().isNotEmpty) {
    return name.trim();
  }

  return 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
}

Future<void> _saveScanResult() async {
  final result = _ocrResult;

  if (result == null) {
    AppPopup.show(
      context,
      message: 'Tidak ada hasil OCR untuk disimpan',
      isError: true,
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  // Use edited values from controllers instead of raw OCR data
  final details = _editControllers.isNotEmpty
      ? _getEditedDetails()
      : (result['details'] is Map
          ? Map<String, dynamic>.from(result['details'])
          : <String, dynamic>{});

  final rawConfidence =
      double.tryParse(result['confidence']?.toString() ?? '0') ?? 0;

  final confidenceValue =
      rawConfidence > 1 ? rawConfidence : rawConfidence * 100;

  final formType = result['form_type']?.toString() ?? 'Catatan';
  final extractedText = result['extracted_text']?.toString() ?? '';

  final payload = {
    'nama_file': _getPickedFileName(),
    'jenis_dokumen': _getFormTypeLabel(formType),
    'tanggal_scan': _todayForApi(),
    'akurasi_score': confidenceValue.round(),
    'hasil_ocr': extractedText,
    'detail_data': details,
  };

  // ── Detect type: Rekam Medis or Data Domba ──

  final isRekamMedis = _isRekamMedisForm(formType, details);
  final isDataDomba = !isRekamMedis &&
      (details.containsKey('ear_tag') || formType.toLowerCase().contains('domba'));

  try {
    // Handle Rekam Medis scan
    if (isRekamMedis) {
      final earTag = details['ear_tag']?.toString().trim();

      if (earTag == null || earTag.isEmpty) {
        setState(() => _isSaving = false);
        AppPopup.show(
          context,
          message: 'Ear tag tidak ditemukan pada data rekam medis. Pastikan ear tag domba tertera pada catatan.',
          isError: true,
        );
        return;
      }

      final medisPayload = _buildRekamMedisPayloadFromScan(details);
      await ApiService.createRekamMedis(medisPayload);
    }

    // Handle Data Domba scan
    if (isDataDomba) {
      final dombaPayload = _buildDombaPayloadFromScan(details);

      if (dombaPayload['ear_tag'] == null ||
          dombaPayload['ear_tag'].toString().isEmpty ||
          dombaPayload['jenis_kelamin'] == null) {
        setState(() => _isSaving = false);

        AppPopup.show(
          context,
          message: 'Data domba belum lengkap. Ear tag dan jenis kelamin wajib ada.',
          isError: true,
        );
        return;
      }

      await ApiService.createDombaFromScan(dombaPayload);
    }

    // Always save to scan log
    final response = await ApiService.createScanLog(payload: payload);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (response['success'] == true) {
      setState(() => _isSaved = true);

      final successMsg = isRekamMedis
          ? 'Rekam medis berhasil disimpan untuk domba ${details['ear_tag']}'
          : 'Hasil scan berhasil disimpan ke riwayat';

      AppPopup.show(context, message: successMsg);
    } else {
      AppPopup.show(
        context,
        message: response['message']?.toString() ?? 'Gagal menyimpan hasil scan',
        isError: true,
      );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    AppPopup.show(
      context,
      message: e.toString(),
      isError: true,
    );
  }
}

/// Detect if scan result is a rekam medis form
bool _isRekamMedisForm(String formType, Map<String, dynamic> details) {
  final lc = formType.toLowerCase();
  if (lc.contains('rekam_medis') || lc.contains('medis') || lc.contains('medical')) {
    return true;
  }

  // Also detect by content: if it has medical-specific fields
  const medicalKeys = ['gejala', 'diagnosa', 'tindakan', 'dosis_obat', 'suhu_tubuh', 'status_kondisi', 'obat'];
  final matchCount = medicalKeys.where((k) => details.containsKey(k)).length;
  return matchCount >= 2; // at least 2 medical fields present
}

/// Build rekam medis payload from OCR scan details
Map<String, dynamic> _buildRekamMedisPayloadFromScan(Map<String, dynamic> details) {
  double? parseNumeric(dynamic value) {
    if (value == null) return null;
    final cleaned = value
        .toString()
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned);
  }

  return {
    'ear_tag': details['ear_tag']?.toString().trim(),
    'tanggal_pemeriksaan': details['tanggal_pemeriksaan'] ??
        details['tanggal'] ??
        _todayForApi(),
    'berat': parseNumeric(details['berat']),
    'suhu_tubuh': parseNumeric(details['suhu_tubuh'] ?? details['suhu']),
    'status_kesehatan': details['status_kondisi'] ??
        details['status_kesehatan'] ??
        details['status'] ??
        details['kondisi'],
    'vaksinasi': details['vaksinasi'],
    'obat': details['dosis_obat'] ?? details['obat'] ?? details['tindakan'],
    'catatan': details['catatan'] ??
        details['diagnosa'] ??
        details['gejala'],
  };
}

Map<String, dynamic> _buildDombaPayloadFromScan(Map<String, dynamic> details) {
  String? normalizeGender(dynamic value) {
    final raw = value?.toString().trim().toLowerCase();

    if (raw == null || raw.isEmpty) return null;

    if (raw.contains('jantan') || raw == 'male') {
      return 'jantan';
    }

    if (raw.contains('betina') || raw == 'female') {
      return 'betina';
    }

    return raw;
  }

  double? parseBerat(dynamic value) {
    if (value == null) return null;

    final cleaned = value
        .toString()
        .replaceAll('kg', '')
        .replaceAll('KG', '')
        .replaceAll(',', '.')
        .trim();

    return double.tryParse(cleaned);
  }

  return {
    'ear_tag': details['ear_tag']?.toString().trim(),
    'id_bangsa': details['id_bangsa'] ??
        details['ras'] ??
        details['jenis_domba'],
    'jenis_kelamin': normalizeGender(details['jenis_kelamin']),
    'tanggal_lahir': details['tanggal_lahir'],
    'berat': parseBerat(details['berat']),
    'status': details['status'] ?? 'Sehat',
    'vaksinasi': details['vaksinasi'],
  };
}




  // ──────────────────────────── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _isProcessing
                ? _buildProcessingView()
                : _hasImage
                ? _buildResultView()
                : _buildEmptyView(),
          ),
        ],
      ),
    );
  }

  // ─── Empty state (before image is chosen) ─────────────────────────────────

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E3DA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 42,
                color: navyDark,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Belum ada gambar',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih sumber gambar untuk mulai scan catatan peternakan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: showSourcePickerSheet,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Pilih Sumber Gambar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Processing state ─────────────────────────────────────────────────────

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(navyDark),
              backgroundColor: beige,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Memproses gambar…',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menjalankan OCR pada catatan',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Result view (after image processed) ──────────────────────────────────

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePreviewCard(),
          const SizedBox(height: 16),
          _buildOcrResult(),
          const SizedBox(height: 14),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

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
                      'Scan Catatan',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload foto catatan',
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

  // ─── Image Preview Card (compact, with rescan options) ────────────────────

  Widget _buildImagePreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image thumbnail
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E3DA)),
            ),
child: _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: kIsWeb
                        // Gunakan Image.network jika berjalan di Web (Chrome)
                        ? Image.network(
                            _pickedImage!.path,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.image_outlined,
                              size: 28,
                              color: Color(0xFF8A9BB0),
                            ),
                          )
                        // Gunakan Image.file jika berjalan di Android fisik
                        : Image.file(
                            File(_pickedImage!.path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.image_outlined,
                              size: 28,
                              color: Color(0xFF8A9BB0),
                            ),
                          ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: Color(0xFF8A9BB0),
                  ),          ),
          const SizedBox(width: 12),
          // Info + buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto Catatan',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ganti foto untuk scan ulang',
                  style: TextStyle(fontSize: 11.5, color: textMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMiniButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri',
                      onTap: _pickFromGallery,
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Kamera',
                      onTap: _pickFromCamera,
                      filled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return Expanded(
      child: Material(
        color: filled ? navyDark : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: filled
                  ? null
                  : Border.all(color: const Color(0xFFD5CFBF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: filled ? Colors.white : navyDark,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : navyDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── OCR Result ───────────────────────────────────────────────────────────

  bool _showRawText = false;

  // Maps field keys to human-readable labels, icons, and descriptions
  static const Map<String, Map<String, dynamic>> _fieldMeta = {
    'ear_tag': {'label': 'Nomor Ear Tag', 'icon': Icons.label_outlined, 'hint': 'Nomor identitas domba'},
    'gejala': {'label': 'Gejala', 'icon': Icons.thermostat_outlined, 'hint': 'Gejala yang ditemukan'},
    'diagnosa': {'label': 'Diagnosa', 'icon': Icons.medical_services_outlined, 'hint': 'Hasil diagnosa'},
    'tindakan': {'label': 'Tindakan', 'icon': Icons.healing_outlined, 'hint': 'Tindakan yang dilakukan'},
    'dosis_obat': {'label': 'Dosis Obat', 'icon': Icons.medication_outlined, 'hint': 'Dosis dan jenis obat'},
    'status_kondisi': {'label': 'Status Kondisi', 'icon': Icons.monitor_heart_outlined, 'hint': 'Kondisi ternak saat ini'},
    'catatan': {'label': 'Catatan Tambahan', 'icon': Icons.note_alt_outlined, 'hint': 'Catatan lainnya'},
    'nama_domba': {'label': 'Nama Domba', 'icon': Icons.pets_outlined, 'hint': 'Nama panggilan domba'},
    'berat': {'label': 'Berat Badan', 'icon': Icons.scale_outlined, 'hint': 'Berat dalam kg'},
    'umur': {'label': 'Umur', 'icon': Icons.cake_outlined, 'hint': 'Umur ternak'},
    'jenis_kelamin': {'label': 'Jenis Kelamin', 'icon': Icons.wc_outlined, 'hint': 'Jantan atau betina'},
    'ras': {'label': 'Ras / Jenis', 'icon': Icons.category_outlined, 'hint': 'Jenis ras domba'},
    'id_kandang': {'label': 'ID Kandang', 'icon': Icons.house_outlined, 'hint': 'Lokasi kandang'},
  };

  String _getFieldLabel(String key) {
    return _fieldMeta[key]?['label'] as String? ??
        key.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
        ).join(' ');
  }

  IconData _getFieldIcon(String key) {
    return _fieldMeta[key]?['icon'] as IconData? ?? Icons.text_fields_outlined;
  }

  String _getFieldHint(String key) {
    return _fieldMeta[key]?['hint'] as String? ?? '';
  }

  Color _getConfidenceColor(double value) {
    if (value >= 80) return const Color(0xFF4CAF50);
    if (value >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFFF6B6B);
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required List<String> options,
    required Map<String, String> labels,
  }) {
    final currentValue = options.contains(controller.text.toLowerCase())
        ? controller.text.toLowerCase()
        : null;
    return DropdownButtonFormField<String>(
      value: currentValue,
      isDense: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE8E3DA), width: 1),
        ),
      ),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navyDark),
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFBFB8A8)),
      items: options.map((opt) {
        return DropdownMenuItem(value: opt, child: Text(labels[opt] ?? opt));
      }).toList(),
      onChanged: (val) {
        if (val != null) controller.text = val;
      },
    );
  }

  String _getConfidenceLabel(double value) {
    if (value >= 80) return 'Akurasi Tinggi';
    if (value >= 60) return 'Akurasi Sedang';
    return 'Akurasi Rendah';
  }

  String _getConfidenceDesc(double value) {
    if (value >= 80) return 'Data yang terdeteksi kemungkinan besar sudah benar.';
    if (value >= 60) return 'Sebagian data mungkin perlu diperiksa ulang.';
    return 'Mohon periksa semua data dengan teliti sebelum menyimpan.';
  }

  String _getFormTypeLabel(String formType) {
    final lc = formType.toLowerCase();
    if (lc.contains('rekam_medis') || lc.contains('medis')) return 'Rekam Medis';
    if (lc.contains('domba') || lc.contains('ternak')) return 'Data Ternak';
    if (lc.contains('kandang')) return 'Data Kandang';
    return formType.replaceAll('_', ' ');
  }

  Widget _buildOcrResult() {
    final result = _ocrResult ?? {};
    final details = result['details'] is Map
        ? Map<String, dynamic>.from(result['details'])
        : <String, dynamic>{};

    final rawConfidence = double.tryParse(result['confidence']?.toString() ?? '0') ?? 0;
    final confidenceValue = rawConfidence > 1 ? rawConfidence : rawConfidence * 100;
    final formType = result['form_type']?.toString() ?? '-';
    final extractedText = result['extracted_text']?.toString() ?? '-';

    final confColor = _getConfidenceColor(confidenceValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Status Banner ──
        _buildStatusBanner(confidenceValue, confColor),
        const SizedBox(height: 16),

        // ── 2. Ringkasan Scan ──
        _buildScanSummaryCard(formType, details.length, confidenceValue, confColor),
        const SizedBox(height: 16),

        // ── 3. Data Fields ──
        if (details.isNotEmpty)
          _buildDataFieldsCard(details),

        // ── 4. Raw OCR Text (Collapsible) ──
        const SizedBox(height: 12),
        _buildRawTextSection(extractedText),
      ],
    );
  }

  // ── Status Banner ──────────────────────────────────────────────────────────

  Widget _buildStatusBanner(double confidence, Color confColor) {
    final isGood = confidence >= 70;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGood
            ? const Color(0xFFE8F5E9) // light green
            : const Color(0xFFFFF3E0), // light orange
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood
              ? const Color(0xFFA5D6A7) // green border
              : const Color(0xFFFFCC80), // orange border
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGood ? Icons.check_circle_rounded : Icons.info_rounded,
              color: isGood ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGood ? 'Scan Berhasil!' : 'Scan Selesai — Perlu Review',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGood
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getConfidenceDesc(confidence),
                  style: TextStyle(
                    fontSize: 12,
                    color: isGood
                        ? const Color(0xFF558B2F)
                        : const Color(0xFFBF360C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scan Summary Card ─────────────────────────────────────────────────────

  Widget _buildScanSummaryCard(
    String formType,
    int fieldCount,
    double confidence,
    Color confColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
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

          // Row 1: Jenis Form
          _buildSummaryRow(
            icon: Icons.description_outlined,
            label: 'Jenis Catatan',
            value: _getFormTypeLabel(formType),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFEEE9DF), height: 1),
          ),

          // Row 2: Jumlah Data
          _buildSummaryRow(
            icon: Icons.format_list_numbered_outlined,
            label: 'Data Terdeteksi',
            value: '$fieldCount informasi',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFEEE9DF), height: 1),
          ),

          // Row 3: Confidence with bar
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed_outlined, size: 16, color: navyDark),
              ),
              const SizedBox(width: 10),
              const Expanded(
                flex: 2,
                child: Text(
                  'Akurasi',
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _getConfidenceLabel(confidence),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: confColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${confidence.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: confColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (confidence / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEEE9DF),
                        valueColor: AlwaysStoppedAnimation<Color>(confColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: navyDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: navyDark,
          ),
        ),
      ],
    );
  }

  // ── Data Fields — Unified Card ─────────────────────────────────────────────

  Widget _buildDataFieldsCard(Map<String, dynamic> details) {
    final entries = details.entries.toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: navyDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_outlined, size: 15, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Data yang Terdeteksi',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: navyDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entries.length} data',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Periksa dan edit data sebelum menyimpan ke database',
              style: TextStyle(fontSize: 11.5, color: textMuted),
            ),
          ),
          const SizedBox(height: 12),

          // Data rows — editable
          ...entries.asMap().entries.map((indexed) {
            final index = indexed.key;
            final entry = indexed.value;
            final isLast = index == entries.length - 1;
            final fieldIcon = _getFieldIcon(entry.key);
            final fieldLabel = _getFieldLabel(entry.key);
            final controller = _editControllers[entry.key];
            final isDropdown = entry.key == 'jenis_kelamin';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(fieldIcon, size: 16, color: navyDark),
                      ),
                      const SizedBox(width: 12),
                      // Label + Editable Field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fieldLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isDropdown)
                              _buildDropdownField(
                                controller: controller!,
                                options: const ['jantan', 'betina'],
                                labels: const {'jantan': 'Jantan', 'betina': 'Betina'},
                              )
                            else
                              TextField(
                                controller: controller,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: navyDark,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                  border: InputBorder.none,
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFE8E3DA), width: 1),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF1A2B45), width: 1.5),
                                  ),
                                  hintText: _getFieldHint(entry.key),
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBFB8A8)),
                                  suffixIcon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFFBFB8A8)),
                                  suffixIconConstraints: const BoxConstraints(maxHeight: 20, maxWidth: 20),
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
                    child: Divider(color: Color(0xFFEEE9DF), height: 1),
                  ),
              ],
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── Raw OCR Text (Collapsible) ─────────────────────────────────────────────

  Widget _buildRawTextSection(String extractedText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (tap to toggle)
          InkWell(
            onTap: () => setState(() => _showRawText = !_showRawText),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.text_snippet_outlined,
                      size: 16,
                      color: navyDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Teks Asli dari Foto',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: navyDark,
                          ),
                        ),
                        Text(
                          _showRawText ? 'Ketuk untuk menyembunyikan' : 'Ketuk untuk melihat',
                          style: const TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showRawText ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: navyDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8E3DA)),
              ),
              child: SelectableText(
                extractedText,
                style: const TextStyle(
                  color: navyDark,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ),
            crossFadeState: _showRawText
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // Widget _ocrInfoRow(String label, String value, {bool highlight = false}) {
  //   return Row(
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  //         decoration: highlight
  //             ? BoxDecoration(
  //                 color: _whiteOpacity12,
  //                 borderRadius: BorderRadius.circular(5),
  //               )
  //             : null,
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontSize: 12.5, color: Colors.white70),
  //         ),
  //       ),
  //       const SizedBox(width: 6),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  //         decoration: BoxDecoration(
  //           color: _whiteOpacity12,
  //           borderRadius: BorderRadius.circular(5),
  //         ),
  //         child: Text(
  //           value,
  //           style: const TextStyle(fontSize: 12.5, color: Colors.white),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // // ─── Confidence Detail Card ───────────────────────────────────────────────

  // Widget _buildConfidenceDetail() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: cardWhite,
  //       borderRadius: BorderRadius.circular(14),
  //       boxShadow: const [
  //         BoxShadow(
  //           color: _blackOpacity05,
  //           blurRadius: 8,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Detail Confidence',
  //           style: TextStyle(
  //             fontFamily: 'Georgia',
  //             fontSize: 15,
  //             fontWeight: FontWeight.bold,
  //             color: navyDark,
  //           ),
  //         ),
  //         const SizedBox(height: 14),
  //         ..._confidenceItems.map(
  //           (item) => Padding(
  //             padding: const EdgeInsets.only(bottom: 12),
  //             child: Row(
  //               children: [
  //                 SizedBox(
  //                   width: 110,
  //                   child: Text(
  //                     item['label'],
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       color: textMuted,
  //                       height: 1.3,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Expanded(
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(4),
  //                     child: LinearProgressIndicator(
  //                       value: item['value'],
  //                       minHeight: 7,
  //                       backgroundColor: const Color(0xFFEEE9DF),
  //                       valueColor: AlwaysStoppedAnimation<Color>(
  //                         item['color'],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 SizedBox(
  //                   width: 34,
  //                   child: Text(
  //                     item['pct'],
  //                     textAlign: TextAlign.right,
  //                     style: TextStyle(
  //                       fontSize: 12.5,
  //                       fontWeight: FontWeight.w700,
  //                       color: item['color'],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ─── Bottom Actions ───────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Row(
      children: [
Expanded(
  child: ElevatedButton(
    onPressed: (_isSaving || _isSaved) ? null : _saveScanResult,
    style: ElevatedButton.styleFrom(
      backgroundColor: navyDark,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFB8B8B8),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: _isSaving
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            _isSaved ? 'Sudah Disimpan' : 'Simpan Hasil',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
  ),
),      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Bottom-sheet widget for choosing Camera / Gallery
// ═══════════════════════════════════════════════════════════════════════════════

class _SourcePickerSheet extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const _SourcePickerSheet({
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  static const Color navyDark = Color(0xFF1A2B45);
  static const Color textMuted = Color(0xFF8A9BB0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD8CF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),

          // Title row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EDE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, size: 18, color: navyDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ambil dari kamera atau pilih gambar dari galeri ponsel Anda.',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),

          // Option tiles
          Row(
            children: [
              Expanded(
                child: _buildOptionTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  subtitle: 'Ambil foto langsung',
                  color: const Color(0xFF3A7BF7),
                  onTap: onCameraTap,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildOptionTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  subtitle: 'Pilih dari galeri',
                  color: const Color(0xFF4CAF50),
                  onTap: onGalleryTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Color.fromARGB(20, color.red, color.green, color.blue),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color.fromARGB(64, color.red, color.green, color.blue), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Color.fromARGB(38, color.red, color.green, color.blue),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: navyDark,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
