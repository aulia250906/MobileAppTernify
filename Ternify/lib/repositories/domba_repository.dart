import 'package:dio/dio.dart';
import '../models/domba_model.dart';
import '../services/api_service.dart';

class DombaRepository {
  final Dio _dio = ApiService.dio;

  /// GET /api/domba — Daftar semua domba (dengan filter & search)
  Future<List<Domba>> fetchDomba({
    String? search,
    String? jenisKelamin,
    String? idBangsa,
    int perPage = 15,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
        params['jenis_kelamin'] = jenisKelamin;
      }
      if (idBangsa != null && idBangsa.isNotEmpty) params['id_bangsa'] = idBangsa;
      params['per_page'] = perPage;

      final res = await _dio.get('/domba', queryParameters: params);
      return (res.data['data'] as List).map((e) => Domba.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /api/domba/{id} — Detail satu domba
  Future<Domba> fetchDombaById(String id) async {
    try {
      final res = await _dio.get('/domba/$id');
      return Domba.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /api/domba — Tambah domba baru
  Future<Domba> createDomba(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/domba', data: payload);
      return Domba.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT /api/domba/{id} — Update data domba
  Future<Domba> updateDomba(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/domba/$id', data: payload);
      return Domba.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE /api/domba/{id} — Hapus domba (soft delete)
  Future<void> deleteDomba(String id) async {
    try {
      await _dio.delete('/domba/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /api/domba/betina/list — Daftar domba betina (untuk dropdown induk)
  Future<List<Domba>> fetchBetina() async {
    try {
      final res = await _dio.get('/domba/betina/list');
      return (res.data['data'] as List).map((e) => Domba.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /api/domba/jantan/list — Daftar domba jantan (untuk dropdown pejantan)
  Future<List<Domba>> fetchJantan() async {
    try {
      final res = await _dio.get('/domba/jantan/list');
      return (res.data['data'] as List).map((e) => Domba.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Error handler
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        // Laravel validation errors
        final errors = data['errors'];
        if (errors != null && errors is Map) {
          return errors.values.map((v) => v is List ? v.first : v).join('\n');
        }
        return data['message'] ?? 'Terjadi kesalahan.';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout. Coba lagi.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Pastikan IP server benar dan server berjalan.';
    }
    return 'Tidak dapat terhubung ke server.';
  }
}