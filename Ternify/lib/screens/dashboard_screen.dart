import 'package:flutter/material.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // warna statis
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color cardWhite = Colors.white;
  static const Color healthy = Color(0xFF1A2B45);
  static const Color pregnant = Color(0xFFCFBFA5);
  static const Color sick = Color(0xFFD0D5DD);

  // Warna pra-kalkulasi
  static const Color _whiteOpacity55 = Color(0x8CFFFFFF);
  static const Color _whiteOpacity10 = Color(0x1AFFFFFF);
  static const Color _whiteOpacity15 = Color(0x26FFFFFF);
  static const Color _whiteOpacity20 = Color(0x33FFFFFF);
  static const Color _blackOpacity05 = Color(0x0D000000);
  static const Color _blackOpacity04 = Color(0x0A000000);
  static const Color _greenOpacity10 = Color(0x1A4CAF50);
  static const Color _orangeOpacity10 = Color(0x1AFF9800);

  final List<Map<String, dynamic>> _scanItems = [
    {
      'icon': Icons.description_outlined,
      'name': 'Catatan_Maret_01',
      'date': '10 Mar 2026',
      'kandang': 'Kandang B',
      'confidence': 92,
      'color': Color(0xFF4CAF50),
      'bgColor': Color(0x1A4CAF50),
    },
    {
      'icon': Icons.camera_alt_outlined,
      'name': 'vaksinasi_feb.jpg',
      'date': '28 Feb 2026',
      'kandang': 'Kandang A',
      'confidence': 68,
      'color': Color(0xFFFF9800),
      'bgColor': Color(0x1AFF9800),
    },
    {
      'icon': Icons.image_outlined,
      'name': 'berat_bulanan_jan.jpg',
      'date': '31 Jan 2026',
      'kandang': 'Semua',
      'confidence': 95,
      'color': Color(0xFF4CAF50),
      'bgColor': Color(0x1A4CAF50),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      body: Column(
        children: [
            _buildAppBar(),

          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildWeightChart(),
                  const SizedBox(height: 16),
                  RepaintBoundary(child: _buildHealthStatus()),
                  const SizedBox(height: 20),
                  _buildRecentScans(),
                  const SizedBox(height: 20),
                  _buildAlerts(),
                ],
              ),
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
              // Title + date
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kamis, 12 Maret 2026',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _whiteOpacity55,
                      ),
                    ),
                  ],
                ),
              ),

              // Bell
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _whiteOpacity10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_outlined,
                        color: Colors.white70, size: 20),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: _NotifDot(),
                    ),
                  ],
                ),
              ),

              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _whiteOpacity15,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _whiteOpacity20, width: 1),
                ),
                child: const Center(
                  child: Text(
                    'AF',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final List<Map<String, dynamic>> stats = [
      {
        'value': '248',
        'label': 'Total Domba',
        'sub': '▲ 12 bulan ini',
        'subColor': const Color(0xFF4CAF50),
        'route': '/kandang',
      },
      {
        'value': '8',
        'label': 'Kandang Aktif',
        'sub': '▲ 1 baru',
        'subColor': const Color(0xFF4CAF50),
        'route': '/kandang',
      },
      {
        'value': '142',
        'label': 'Total Scan',
        'sub': '▲ 23 minggu ini',
        'subColor': const Color(0xFF4CAF50),
        'route': '/riwayat',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: navyDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = stats[i];
              return GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, s['route'] as String),
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(14),
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
                      Text(
                        s['value'],
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: navyDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s['label'],
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s['sub'],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: s['subColor'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    final months = ['Okt', 'Nov', 'Des', 'Jan', 'Feb', 'Mar'];
    final heights = [0.55, 0.60, 0.58, 0.68, 0.72, 0.82];
    final isBeige = [false, false, false, true, true, false];

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Berat Domba\n(6 Bln)',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                    height: 1.4,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDD8CE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Semua',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(months.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: heights[i],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isBeige[i]
                                      ? const Color(0xFFCFBFA5)
                                      : const Color(0xFF2D4A6E),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          months[i],
                          style: const TextStyle(
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatus() {
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
            'Status Kesehatan',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: navyDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _DonutPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '248',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: navyDark,
                          ),
                        ),
                        Text(
                          'ekor',
                          style: TextStyle(fontSize: 10, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow('Sehat', '193 (78%)', healthy),
                    const SizedBox(height: 10),
                    _buildLegendRow('Bunting', '35 (14%)', pregnant),
                    const SizedBox(height: 10),
                    _buildLegendRow('Sakit', '20 (8%)', sick),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: textMuted),
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

  Widget _buildRecentScans() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Scan Terbaru',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navyDark,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/riwayat'),
              child: const Text(
                'Lihat Semua →',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D5A8E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_scanItems.length, (i) {
          final item = _scanItems[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/riwayat'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardWhite,
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item['icon'], size: 18, color: textMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: navyDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['date']} · ${item['kandang']}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item['confidence']}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item['color'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey.shade300),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peringatan',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: navyDark,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/kandang'),
          child: _buildAlertCard(
            '⚠️  DOM-003 perlu perhatian — status sakit sejak kemarin',
            const Color(0xFFFFF3CD),
            const Color(0x4DE6A817),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/riwayat'),
          child: _buildAlertCard(
            '✔  3 catatan menunggu verifikasi confidence rendah',
            const Color(0xFFF0F0F0),
            const Color(0x4D888888),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(String message, Color bg, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: navyDark, height: 1.4),
      ),
    );
  }
}

// Notif dot widget — const untuk menghindari rebuild
class _NotifDot extends StatelessWidget {
  const _NotifDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFFFF6B6B),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Donut chart painter ──
class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 10.0;

    final segments = [
      {'fraction': 0.78, 'color': const Color(0xFF1A2B45)},
      {'fraction': 0.14, 'color': const Color(0xFFCFBFA5)},
      {'fraction': 0.08, 'color': const Color(0xFFD0D5DD)},
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    const gap = 0.05;

    for (final seg in segments) {
      final fraction = seg['fraction'] as double;
      final sweepAngle = fraction * 2 * math.pi - gap;
      paint.color = seg['color'] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}