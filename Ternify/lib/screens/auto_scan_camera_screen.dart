import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Auto-scan camera screen that detects table/document patterns and
/// auto-captures when a stable rectangular document is found.
class AutoScanCameraScreen extends StatefulWidget {
  const AutoScanCameraScreen({super.key});

  @override
  State<AutoScanCameraScreen> createState() => _AutoScanCameraScreenState();
}

class _AutoScanCameraScreenState extends State<AutoScanCameraScreen>
    with TickerProviderStateMixin {
  CameraController? _camCtrl;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasError = false;
  String _errorMsg = '';

  // Detection state
  int _stableFrames = 0;
  static const int _requiredStableFrames = 8;
  bool _tableDetected = false;
  bool _isAnalyzing = false;
  Timer? _analysisTimer;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _borderCtrl;
  late Animation<double> _borderAnim;

  // UI colors
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color _scanGreen = Color(0xFF4CAF50);
  static const Color _scanGreen85 = Color(0xD94CAF50);
  static const Color _white15 = Color(0x26FFFFFF);
  static const Color _white80 = Color(0xCCFFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white90 = Color(0xE6FFFFFF);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _borderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _borderAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderCtrl, curve: Curves.easeOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMsg = 'Tidak ditemukan kamera pada perangkat ini.';
        });
        return;
      }

      final backCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _camCtrl = CameraController(
        backCam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _camCtrl!.initialize();

      if (!mounted) return;

      setState(() => _isInitialized = true);
      _startFrameAnalysis();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = 'Gagal mengakses kamera: ${e.toString()}';
        });
      }
    }
  }

  void _startFrameAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isAnalyzing && !_isCapturing && _isInitialized && mounted) {
        _analyzeCurrentFrame();
      }
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    _isAnalyzing = true;

    try {
      final XFile tempFile = await _camCtrl!.takePicture();
      final bytes = await tempFile.readAsBytes();
      final detected = _detectTablePattern(bytes);

      if (!mounted) return;

      if (detected) {
        _stableFrames++;
        if (!_tableDetected) {
          setState(() => _tableDetected = true);
          _borderCtrl.forward();
        }

        if (_stableFrames >= _requiredStableFrames && !_isCapturing) {
          _autoCapture(tempFile);
          return;
        }
      } else {
        if (_stableFrames > 0) {
          _stableFrames = math.max(0, _stableFrames - 2);
        }
        if (_stableFrames == 0 && _tableDetected) {
          setState(() => _tableDetected = false);
          _borderCtrl.reverse();
        }
      }

      try {
        await File(tempFile.path).delete();
      } catch (_) {}
    } catch (_) {
      // Camera might be busy, skip this frame
    } finally {
      _isAnalyzing = false;
    }
  }

  /// Detect if the captured image likely contains a table/document.
  bool _detectTablePattern(Uint8List bytes) {
    if (bytes.length < 5000) return false;

    // Documents with text/tables compress less efficiently -> larger files
    if (bytes.length < 40000) return false;

    // Check for high-contrast byte transitions (text & table lines)
    int sharpTransitions = 0;
    const sampleSize = 8000;
    final end = math.min(bytes.length, sampleSize);

    for (int i = 1; i < end; i++) {
      final diff = (bytes[i] - bytes[i - 1]).abs();
      if (diff > 60) sharpTransitions++;
    }

    final ratio = sharpTransitions / end;
    if (ratio < 0.12) return false;

    // Check for repeating byte patterns (horizontal lines in tables)
    int periodicMatches = 0;
    const stride = 32;
    for (int i = stride; i < end - stride; i += stride) {
      int blockMatch = 0;
      for (int j = 0; j < 8 && i + j < end; j++) {
        if ((bytes[i + j] - bytes[i - stride + j]).abs() < 20) blockMatch++;
      }
      if (blockMatch >= 5) periodicMatches++;
    }

    final periodicRatio = periodicMatches / (end / stride);
    return periodicRatio > 0.08;
  }

  Future<void> _autoCapture(XFile capturedFile) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    _analysisTimer?.cancel();

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context).pop(capturedFile);
    }
  }

  Future<void> _manualCapture() async {
    if (_isCapturing || _camCtrl == null) return;
    setState(() => _isCapturing = true);
    _analysisTimer?.cancel();

    try {
      final XFile file = await _camCtrl!.takePicture();
      if (mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        _startFrameAnalysis();
      }
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _pulseCtrl.dispose();
    _borderCtrl.dispose();
    _camCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError
          ? _buildErrorView()
          : !_isInitialized
              ? _buildLoadingView()
              : _buildCameraView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Memulai kamera...', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_outlined, size: 56, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: navyDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview — fill the whole screen
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _camCtrl!.value.previewSize!.height,
                height: _camCtrl!.value.previewSize!.width,
                child: CameraPreview(_camCtrl!),
              ),
            ),
          ),
        ),

        // Scan overlay
        _buildScanOverlay(),

        // Top bar
        _buildTopBar(),

        // Bottom controls
        _buildBottomControls(),

        // Capture flash
        if (_isCapturing) _buildCaptureFlash(),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return ListenableBuilder(
      listenable: Listenable.merge([_pulseCtrl, _borderCtrl]),
      builder: (context, _) {
        final borderColor = _tableDetected
            ? Color.lerp(Colors.transparent, _scanGreen, _borderAnim.value)!
            : Color.lerp(
                Colors.transparent,
                Color.fromRGBO(255, 152, 0, _pulseAnim.value), // orange pulse
                0.4,
              )!;

        return IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ScanOverlayPainter(
              borderColor: borderColor,
              borderWidth: _tableDetected ? 3.0 : 1.5,
              cornerRadius: 16.0,
              progress: _stableFrames / _requiredStableFrames,
              showProgress: _tableDetected,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
                const Spacer(),
                // Status indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _tableDetected ? _scanGreen85 : _white15,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tableDetected ? Icons.check_circle : Icons.search,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isCapturing
                            ? 'Memotret...'
                            : _tableDetected
                                ? 'Tabel terdeteksi!'
                                : 'Mencari tabel...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hint text
                Text(
                  _tableDetected
                      ? 'Tahan posisi — otomatis memotret...'
                      : 'Arahkan kamera ke dokumen tabel',
                  style: const TextStyle(color: _white80, fontSize: 13),
                ),
                const SizedBox(height: 20),
                // Manual capture row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 56),
                    // Shutter button
                    GestureDetector(
                      onTap: _isCapturing ? null : _manualCapture,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          final pulseOpacity = 0.6 + 0.4 * _pulseAnim.value;
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _tableDetected
                                    ? _scanGreen
                                    : Color.fromRGBO(255, 255, 255, pulseOpacity),
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isCapturing ? _scanGreen : _white90,
                                ),
                                child: _isCapturing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Manual label
                    const SizedBox(
                      width: 56,
                      child: Text(
                        'Manual',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _white50, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureFlash() {
    return AnimatedOpacity(
      opacity: _isCapturing ? 0.6 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: Container(color: Colors.white),
    );
  }
}

/// Custom painter for the scan overlay with document cutout area
class _ScanOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final double progress;
  final bool showProgress;

  _ScanOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.cornerRadius,
    required this.progress,
    required this.showProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final docW = size.width * 0.85;
    final docH = size.height * 0.55;
    final left = (size.width - docW) / 2;
    final top = (size.height - docH) / 2 - 20;

    final docRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, docW, docH),
      Radius.circular(cornerRadius),
    );

    // Dark overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(docRect);
    final combinedPath =
        Path.combine(PathOperation.difference, overlayPath, cutoutPath);
    canvas.drawPath(
      combinedPath,
      Paint()..color = const Color(0x66000000),
    );

    // Border around document area
    if (borderColor.a > 0.01) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRRect(docRect, borderPaint);

      _drawCornerAccents(canvas, docRect, borderColor, borderWidth);
    }

    // Progress bar below document area
    if (showProgress && progress > 0) {
      final progressBarWidth = docW * 0.6;
      final progressLeft = left + (docW - progressBarWidth) / 2;
      final progressTop = top + docH + 12;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(progressLeft, progressTop, progressBarWidth, 4),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0x33FFFFFF),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            progressLeft,
            progressTop,
            progressBarWidth * progress.clamp(0.0, 1.0),
            4,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = borderColor,
      );
    }
  }

  void _drawCornerAccents(
      Canvas canvas, RRect rrect, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 1.5
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    final r = rrect.tlRadiusX;
    final rect = rrect.outerRect;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + r + len)
        ..lineTo(rect.left, rect.top + r)
        ..arcToPoint(Offset(rect.left + r, rect.top),
            radius: Radius.circular(r))
        ..lineTo(rect.left + r + len, rect.top),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - r - len, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + r),
            radius: Radius.circular(r))
        ..lineTo(rect.right, rect.top + r + len),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - r - len)
        ..lineTo(rect.left, rect.bottom - r)
        ..arcToPoint(Offset(rect.left + r, rect.bottom),
            radius: Radius.circular(r))
        ..lineTo(rect.left + r + len, rect.bottom),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - r - len, rect.bottom)
        ..lineTo(rect.right - r, rect.bottom)
        ..arcToPoint(Offset(rect.right, rect.bottom - r),
            radius: Radius.circular(r))
        ..lineTo(rect.right, rect.bottom - r - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.progress != progress ||
      old.showProgress != showProgress;
}
