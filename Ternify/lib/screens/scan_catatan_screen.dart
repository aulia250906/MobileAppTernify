import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  final List<Map<String, dynamic>> _ocrItems = [
    {
      'id': 'DOM-001',
      'berat': '34.5 kg',
      'status': 'Sehat',
      'statusColor': Color(0xFF4CAF50),
    },
    {
      'id': 'DOM-002',
      'berat': '32.8 kg',
      'status': 'Bunting',
      'statusColor': Color(0xFFCFBFA5),
    },
    {
      'id': 'DOM-005',
      'berat': '38.2 kg',
      'status': 'Sehat',
      'statusColor': Color(0xFF4CAF50),
    },
  ];

  final List<Map<String, dynamic>> _confidenceItems = [
    {
      'label': 'CATATAN BERAT\nDOMBA',
      'value': 0.95,
      'pct': '95%',
      'color': Color(0xFF4CAF50),
    },
    {
      'label': 'Tanggal',
      'value': 0.92,
      'pct': '92%',
      'color': Color(0xFF4CAF50),
    },
    {
      'label': 'DOM-001 34.5 kg',
      'value': 0.89,
      'pct': '89%',
      'color': Color(0xFF4CAF50),
    },
    {
      'label': 'DOM-002 32.8 kg',
      'value': 0.68,
      'pct': '68%',
      'color': Color(0xFFFF9800),
    },
    {
      'label': 'DOM-005 38.2 kg',
      'value': 0.91,
      'pct': '91%',
      'color': Color(0xFF4CAF50),
    },
  ];

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
      setState(() {
        _pickedImage = image;
        _isProcessing = true;
      });
      // Simulate OCR processing
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _hasImage = true;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _isProcessing = true;
      });
      // Simulate OCR processing
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _hasImage = true;
          _isProcessing = false;
        });
      }
    }
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
          _buildUploadBox(),
          const SizedBox(height: 14),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildOcrResult(),
          const SizedBox(height: 14),
          _buildConfidenceDetail(),
          const SizedBox(height: 16),
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

  // ─── Upload box (shown after image is processed) ──────────────────────────

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: showSourcePickerSheet,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECE4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFB8A8), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _whiteOpacity60,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 28,
                color: Color(0xFF6B7A8D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Foto / Upload Gambar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: navyDark,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketuk untuk ambil foto atau pilih dari galeri',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _pickFromGallery,
            style: OutlinedButton.styleFrom(
              foregroundColor: navyDark,
              side: const BorderSide(color: Color(0xFFBFB8A8), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text(
              'Dari Galeri',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _pickFromCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text(
              'Kamera',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ─── OCR Result ───────────────────────────────────────────────────────────

  Widget _buildOcrResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hasil OCR',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navyDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _greenOpacity30),
              ),
              child: const Text(
                'Confidence: 87%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF388E3C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: navyDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['CATATAN', 'BERAT', 'DOMBA']
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _whiteOpacity12,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              _ocrInfoRow('Tanggal:', '10 Maret 2026', highlight: true),
              const SizedBox(height: 6),
              _ocrInfoRow('Kandang B', '— 12 ekor', highlight: true),
              const SizedBox(height: 14),
              ..._ocrItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${item['id']} :',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _whiteOpacity12,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item['berat'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '—',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (item['statusColor'] as Color).withOpacity(
                            item['status'] == 'Bunting' ? 0.4 : 0.2,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: item['status'] == 'Bunting'
                                ? const Color(0xFFE8D5B0)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ocrInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: highlight
              ? BoxDecoration(
                  color: _whiteOpacity12,
                  borderRadius: BorderRadius.circular(5),
                )
              : null,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _whiteOpacity12,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ─── Confidence Detail Card ───────────────────────────────────────────────

  Widget _buildConfidenceDetail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: _blackOpacity05,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Confidence',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: navyDark,
            ),
          ),
          const SizedBox(height: 14),
          ..._confidenceItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      item['label'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item['value'],
                        minHeight: 7,
                        backgroundColor: const Color(0xFFEEE9DF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item['color'],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 34,
                    child: Text(
                      item['pct'],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: item['color'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Actions ───────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _hasImage = false;
                _pickedImage = null;
              });
              showSourcePickerSheet();
            },
            icon: const Icon(Icons.crop_free_rounded, size: 16),
            label: const Text('Scan Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: navyDark,
              side: const BorderSide(color: Color(0xFFBFB8A8), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: navyDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text(
              'Simpan Hasil',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
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
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
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
