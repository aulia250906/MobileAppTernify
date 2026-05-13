import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/domba_model.dart';
import '../services/api_service.dart';

class DombaRepository {

  /// GET /api/domba — Daftar semua domba (dengan filter & search)
  Future<List<Domba>> fetchDomba({
    String? search,
    String? jenisKelamin,
    String? idBangsa,
    int perPage = 15,
  }) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
        params['jenis_kelamin'] = jenisKelamin;
      }
      if (idBangsa != null && idBangsa.isNotEmpty) params['id_bangsa'] = idBangsa;
      params['per_page'] = perPage.toString();

      final uri = Uri.parse('${ApiService.baseUrl}/domba').replace(queryParameters: params);
      final res = await http.get(uri, headers: await ApiService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return (body['data'] as List).map((e) => Domba.fromJson(e)).toList();
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// GET /api/domba/{id} — Detail satu domba
  Future<Domba> fetchDombaById(String id) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/domba/$id'),
        headers: await ApiService.authHeaders(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return Domba.fromJson(body['data']);
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// POST /api/domba — Tambah domba baru
  Future<Domba> createDomba(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/domba'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201 || res.statusCode == 200) {
        return Domba.fromJson(body['data']);
      }
      // Laravel validation errors
      if (body['errors'] != null && body['errors'] is Map) {
        final errors = body['errors'] as Map;
        throw errors.values.map((v) => v is List ? v.first : v).join('\n');
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// PUT /api/domba/{id} — Update data domba
  Future<Domba> updateDomba(String id, Map<String, dynamic> payload) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/domba/$id'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return Domba.fromJson(body['data']);
      }
      if (body['errors'] != null && body['errors'] is Map) {
        final errors = body['errors'] as Map;
        throw errors.values.map((v) => v is List ? v.first : v).join('\n');
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// DELETE /api/domba/{id} — Hapus domba (soft delete)
  Future<void> deleteDomba(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/domba/$id'),
        headers: await ApiService.authHeaders(),
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw body['message'] ?? 'Gagal menghapus domba.';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// GET /api/domba/betina/list — Daftar domba betina (untuk dropdown induk)
  Future<List<Domba>> fetchBetina() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/domba/betina/list'),
        headers: await ApiService.authHeaders(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return (body['data'] as List).map((e) => Domba.fromJson(e)).toList();
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }

  /// GET /api/domba/jantan/list — Daftar domba jantan (untuk dropdown pejantan)
  Future<List<Domba>> fetchJantan() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/domba/jantan/list'),
        headers: await ApiService.authHeaders(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return (body['data'] as List).map((e) => Domba.fromJson(e)).toList();
      }
      throw body['message'] ?? 'Terjadi kesalahan.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Tidak dapat terhubung ke server: $e';
    }
  }
}