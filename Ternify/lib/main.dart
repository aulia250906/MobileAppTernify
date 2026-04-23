import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/data_domba_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TernakDigitalApp());
}

class TernakDigitalApp extends StatelessWidget {
  const TernakDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ternify2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E2D4A),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainShell(initialIndex: 0),
        '/riwayat': (context) => const MainShell(initialIndex: 1),
        '/scan': (context) => const MainShell(initialIndex: 2),
        '/kandang': (context) => const MainShell(initialIndex: 3),
        '/profil': (context) => const MainShell(initialIndex: 4),
        '/data-domba': (context) => const DataDombaScreen(),
      },
    );
  }
}
