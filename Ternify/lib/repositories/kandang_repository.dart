import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kandang_model.dart';
import '../services/api_service.dart';

class KandangRepository {

  /// GET /api/kandang — Daftar semua kandang
  Future<List<Kandang>> fetchKandang() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/kandang'),
        headers: await ApiService.authHeaders(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return (body['data'] as List).map((e) => Kandang.fromJson(e)).toList();
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// GET /api/kandang/statistik — Statistik kandang
  Future<Map<String, int>> fetchStatistik() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/kandang/statistik'),
        headers: await ApiService.authHeaders(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final d = body['data'];
        return {
          'total_kandang': d['total_kandang'] as int,
          'total_domba':   d['total_domba'] as int,
        };
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// POST /api/kandang — Tambah kandang baru
  Future<Kandang> createKandang(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/kandang'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201 || res.statusCode == 200) {
        return Kandang.fromJson(body['data']);
      }
      if (body['errors'] != null) {
        final errors = body['errors'] as Map;
        throw errors.values.map((v) => v is List ? v[0] : v).join('\n');
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// PUT /api/kandang/{id} — Update kandang
  Future<Kandang> updateKandang(String id, Map<String, dynamic> payload) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/kandang/$id'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return Kandang.fromJson(body['data']);
      }
      if (body['errors'] != null) {
        final errors = body['errors'] as Map;
        throw errors.values.map((v) => v is List ? v[0] : v).join('\n');
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// DELETE /api/kandang/{id} — Hapus kandang
  Future<void> deleteKandang(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/kandang/$id'),
        headers: await ApiService.authHeaders(),
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw body['message'] ?? 'Gagal menghapus kandang.';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }
}