import 'package:dio/dio.dart';
import '../models/kandang_model.dart';
import '../services/api_service.dart';

class KandangRepository {
  final Dio _dio = ApiService.dio;

  Future<List<Kandang>> fetchKandang() async {
    try {
      final res = await _dio.get('/kandang');
      return (res.data['data'] as List).map((e) => Kandang.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, int>> fetchStatistik() async {
    try {
      final res = await _dio.get('/kandang/statistik');
      final d = res.data['data'];
      return {
        'total_kandang': d['total_kandang'] as int,
        'total_domba':   d['total_domba'] as int,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Kandang> createKandang(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/kandang', data: payload);
      return Kandang.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Kandang> updateKandang(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/kandang/$id', data: payload);
      return Kandang.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteKandang(String id) async {
    try {
      await _dio.delete('/kandang/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final errors = e.response?.data?['errors'];
      if (errors != null) {
        return (errors as Map).values.map((v) => v[0]).join('\n');
      }
      return e.response?.data?['message'] ?? 'Terjadi kesalahan.';
    }
    return 'Tidak dapat terhubung ke server.';
  }
}