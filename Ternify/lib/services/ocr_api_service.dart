import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class OCRApiService {
  late final Dio _dio;

  OCRApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseURL,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  Future<Map<String, dynamic>> scanDocument(XFile xFile) async {
    try {
      final bytes = await xFile.readAsBytes();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: xFile.name,
        ),
      });

      final response = await _dio.post(
        ApiConfig.scanEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return {
        'success': true,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      print('OCRApiService DioException: $e');

      String detailMessage = e.message ?? e.toString();

      if (e.response != null) {
        print('OCRApiService response data: ${e.response?.data}');

        final responseData = e.response?.data;

        if (responseData is Map && responseData['detail'] != null) {
          detailMessage = responseData['detail'].toString();
        } else {
          detailMessage = responseData.toString();
        }
      }

      return {
        'success': false,
        'error': 'Kesalahan dari server OCR',
        'details': detailMessage,
        'type': e.type.toString(),
        'statusCode': e.response?.statusCode,
      };
    } catch (e, stack) {
      print('OCRApiService unexpected exception: $e');
      print(stack);

      return {
        'success': false,
        'error': 'Kesalahan tidak terduga',
        'details': e.toString(),
      };
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(ApiConfig.healthEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  void setBaseURL(String newURL) {
    _dio.options.baseUrl = newURL;
  }
}