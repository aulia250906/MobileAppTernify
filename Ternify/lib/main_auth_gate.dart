import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
// import screen lainnya sesuai struktur kamu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ternify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Georgia'),
      // Cek token dulu sebelum menentukan halaman awal
      home: const AuthGate(),
      routes: {
        '/': (ctx) => const LoginScreen(),
        '/dashboard': (ctx) =>
            const Placeholder(), // ganti dengan DashboardScreen()
        // tambahkan route lain sesuai kebutuhan
      },
    );
  }
}

/// Widget yang mengecek apakah user sudah login atau belum
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash sederhana saat cek token
    return const Scaffold(
      backgroundColor: Color(0xFF1A2B45),
      body: Center(
        child: Text(
          'Ternify',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
