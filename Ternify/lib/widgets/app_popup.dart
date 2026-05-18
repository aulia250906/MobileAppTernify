import 'package:flutter/material.dart';

/// Widget popup kustom yang muncul di tengah layar.
/// Tidak mengganggu layout BottomNavigationBar / FAB.
class AppPopup {
  static const Color navyDark   = Color(0xFF1A2B45);
  static const Color redError   = Color(0xFFC0392B);
  static const Color beigeLight = Color(0xFFFAF7F2);

  /// Tampilkan popup sukses/error di tengah layar
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _PopupOverlay(
        message: message,
        isError: isError,
        duration: duration,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _PopupOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismiss;

  const _PopupOverlay({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<_PopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );

    _animCtrl.forward();

    // Auto-dismiss setelah durasi tertentu
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError  = widget.isError;
    final accent   = isError ? AppPopup.redError : AppPopup.navyDark;
    final iconData = isError ? Icons.error_outline_rounded : Icons.check_circle_rounded;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.18 * _fadeAnim.value),
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _buildCard(accent, iconData),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(Color accent, IconData iconData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: accent, size: 30),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            widget.isError ? 'Gagal' : 'Berhasil',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF6B7A8D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
