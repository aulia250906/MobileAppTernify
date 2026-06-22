import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// API Configuration
/// Ubah URL di bawah sesuai dengan server FastAPI Anda
class ApiConfig {
  // Ubah 192.168.1.100 dengan IP address atau hostname server Anda
  // Untuk testing lokal: http://localhost:8000
  // Untuk production: http://your-server.com atau https://your-server.com

  static String get baseURL {
    if (kIsWeb) {
      return "http://localhost:8001";
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return "http://127.0.0.1:8001";
    }
    return "http://192.168.18.59:8001"; // Untuk Android Emulator. Ubah ke "http://192.168.0.178:8001" jika menggunakan HP Fisik.
  }

  // Timeout configuration (dalam seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;

  // Endpoint paths
  static const String scanEndpoint = "/api/v1/scan";
  static const String healthEndpoint = "/health";

  /// Method untuk update URL secara dinamis (jika diperlukan)
  static String getFullURL(String endpoint) {
    return baseURL + endpoint;
  }
}
