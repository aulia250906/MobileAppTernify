import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/riwayat_scan_screen.dart';
import 'screens/scan_catatan_screen.dart';
import 'screens/kandang_screen.dart';
import 'screens/profil_screen.dart';

/// MainShell mengelola semua halaman utama dengan bottom navigation bersama.
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;

  static const Color navyDark = Color(0xFF1A2B45);

  // Halaman (tanpa bottom nav sendiri — sudah dihandle di sini)
  final List<Widget> _pages = [
    const DashboardScreen(),
    const RiwayatScanScreen(),
    ScanCatatanScreen(key: ScanCatatanScreen.globalKey),
    const KandangScreen(),
    const ProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildScanFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Dashboard'},
      {'icon': Icons.history_outlined, 'activeIcon': Icons.history, 'label': 'Riwayat'},
      null, // FAB placeholder
      {'icon': Icons.grid_view_outlined, 'activeIcon': Icons.grid_view, 'label': 'Kandang'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              if (items[i] == null) return const SizedBox(width: 64);
              final item = items[i]!;
              final isSelected = _selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        size: 22,
                        color: isSelected ? navyDark : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? navyDark : Colors.grey.shade400,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) {
      // Show source picker popup when navigating to scan tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScanCatatanScreen.globalKey.currentState?.showSourcePickerSheet();
      });
    }
  }

  Widget _buildScanFAB() {
    final isActive = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 58,
        height: 58,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [const Color(0xFF3A6098), const Color(0xFF243655)]
                : [const Color(0xFF243655), const Color(0xFF1A2B45)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2B45).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isActive
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
              : null,
        ),
        child: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}