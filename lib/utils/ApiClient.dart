import 'package:dio/dio.dart';
import './AuthInterceptor.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "YOUR_BASE_URL",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static void init() {
    dio.interceptors.add(AuthInterceptor(dio));
  }
}