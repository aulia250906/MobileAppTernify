import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class OCRApiService {
  late Dio _dio;

  OCRApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseURL,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
        contentType: "application/json",
      ),
    );

    // Tambahkan interceptor untuk logging
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  /// Upload gambar ke OCR API dan dapatkan hasil
  /// Returns: Map dengan hasil OCR atau error
  Future<Map<String, dynamic>> scanDocument(XFile xFile) async {
    try {
      // Baca byte gambar - bekerja di semua platform termasuk Web
      final bytes = await xFile.readAsBytes();

      // Buat FormData untuk multipart upload
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: xFile.name),
      });

      // Send POST request
      final response = await _dio.post(
        ApiConfig.scanEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': 'Gagal memproses gambar',
          'details': response.data,
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      print("OCRApiService DioException: $e");
      if (e.response != null) {
        print("OCRApiService response data: ${e.response?.data}");
      }
      return {
        'success': false,
        'error': 'Kesalahan jaringan atau server tidak tersedia',
        'details': e.message ?? e.toString(),
        'type': e.type.toString(),
      };
    } catch (e, stack) {
      print("OCRApiService unexpected exception: $e");
      print(stack);
      return {
        'success': false,
        'error': 'Kesalahan tidak terduga',
        'details': e.toString(),
      };
    }
  }

  /// Cek status kesehatan API
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(ApiConfig.healthEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update base URL secara dinamis
  void setBaseURL(String newURL) {
    _dio.options.baseUrl = newURL;
  }
}
