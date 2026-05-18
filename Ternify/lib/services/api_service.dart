import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP/URL server kamu
  // Emulator Android  : http://10.0.2.2:8000/api
  // Device fisik      : http://192.168.x.x:8000/api
  // Production        : https://domain-kamu.com/api
static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'user_data';

  // ─────────────────────────────────────────────
  // TOKEN MANAGEMENT (persistent login)
  // ─────────────────────────────────────────────

  /// Simpan token & data user ke SharedPreferences
  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Ambil token yang tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Ambil data user yang tersimpan
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Hapus session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // HELPER: build headers
  // ─────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'nama_lengkap':            namaLengkap,
          'email':                   email,
          'password':                password,
          'password_confirmation':   passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        await saveSession(data['token'], data['user']);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        await saveSession(data['token'], data['user']);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ─────────────────────────────────────────────
  // GET PROFILE
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await authHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Perbarui data user lokal
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(data['user']));
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE PROFILE
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    String? namaLengkap,
    String? email,
    String? noTelepon,
    String? namaPeternakan,
    String? lokasi,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (namaLengkap    != null) body['nama_lengkap']    = namaLengkap;
      if (email          != null) body['email']           = email;
      if (noTelepon      != null) body['no_telepon']      = noTelepon;
      if (namaPeternakan != null) body['nama_peternakan'] = namaPeternakan;
      if (lokasi         != null) body['lokasi']          = lokasi;

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: await authHeaders(),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Perbarui data user lokal
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(data['user']));
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await authHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Hapus session lokal apapun hasilnya
      await clearSession();

      return data;
    } catch (e) {
      await clearSession(); // tetap hapus lokal walaupun koneksi gagal
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}