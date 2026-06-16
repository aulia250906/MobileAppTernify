import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiService {
  // Ganti dengan IP/URL server kamu
  // Emulator Android  : http://10.0.2.2:8000/api
  // Device fisik      : http://192.168.x.x:8000/api
  // Production        : https://domain-kamu.com/api
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000/api";
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return "http://127.0.0.1:8000/api";
    }
    return "http://10.0.2.2:8000/api"; // Untuk Android Emulator. Ubah ke "http://192.168.0.178:8000/api" jika menggunakan HP Fisik.
  }

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
    // ─────────────────────────────────────────────
  // DOMBA API
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchDomba({
    String? search,
    String? jenisKelamin,
  }) async {
    final query = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
      query['jenis_kelamin'] = jenisKelamin;
    }

    final uri = Uri.parse('$baseUrl/domba').replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: await authHeaders(),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      return [];
    }

    throw Exception(decoded['message'] ?? 'Gagal mengambil data domba');
  }

  static Future<Map<String, dynamic>> createDomba(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/domba'),
      headers: await authHeaders(),
      body: jsonEncode(payload),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded['message'] ?? 'Gagal menambahkan domba');
  }

  static Future<Map<String, dynamic>> updateDomba(
    String idDomba,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/domba/$idDomba'),
      headers: await authHeaders(),
      body: jsonEncode(payload),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded['message'] ?? 'Gagal memperbarui domba');
  }

  static Future<void> deleteDomba(String idDomba) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/domba/$idDomba'),
      headers: await authHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['message'] ?? 'Gagal menghapus domba');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBetina() async {
    final response = await http.get(
      Uri.parse('$baseUrl/domba/betina/list'),
      headers: await authHeaders(),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      return [];
    }

    throw Exception(decoded['message'] ?? 'Gagal mengambil data betina');
  }

  static Future<List<Map<String, dynamic>>> fetchJantan() async {
    final response = await http.get(
      Uri.parse('$baseUrl/domba/jantan/list'),
      headers: await authHeaders(),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      return [];
    }

    throw Exception(decoded['message'] ?? 'Gagal mengambil data jantan');
  }

  static Future<Map<String, dynamic>> fetchDombaStatistik() async {
    final response = await http.get(
      Uri.parse('$baseUrl/domba/statistik'),
      headers: await authHeaders(),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded['data'] ?? {});
    }

    throw Exception(decoded['message'] ?? 'Gagal mengambil statistik domba');
  }
}