import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../constants.dart';
import '../models/analysis_response.dart';

class ApiService {
  ApiService({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? apiBaseUrl,
            connectTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5),
            // Keep receiving bytes for /convert.
            responseType: ResponseType.json,
          ),
        ) {
    if (allowInsecureConnections && _dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (_, __, ___) => true;
        return client;
      };
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Avoid logging large bodies (e.g. APK bytes), but log endpoints.
          // ignore: avoid_print
          print('[Dio] --> ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('[Dio] <-- ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (e, handler) {
          final status = e.response?.statusCode;
          final uri = e.requestOptions.uri;
          // ignore: avoid_print
          print('[Dio] xx  $uri');
          // ignore: avoid_print
          print('[Dio]     type=${e.type} status=$status message=${e.message}');
          // ignore: avoid_print
          if (e.response?.data != null) print('[Dio]     data=${e.response?.data}');
          handler.next(e);
        },
      ),
    );
  }

  final Dio _dio;

  /// Analyze AAB: size, manifest, top files, signed status.
  Future<AnalysisResponse> analyze(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
    });
    final response = await _dio.post<Map<String, dynamic>>(analyzeEndpoint, data: formData);
    final data = response.data;
    if (data == null) throw Exception('Analyze API returned null');
    return AnalysisResponse.fromJson(data);
  }

  /// Convert AAB to APK; [onProgress] receives 0.0..1.0.
  Future<List<int>> convert(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
    });
    final response = await _dio.post<List<int>>(
      convertEndpoint,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) throw Exception('Convert API returned no data');
    return bytes;
  }
}
