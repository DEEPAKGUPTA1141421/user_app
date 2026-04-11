import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

/// Singleton Dio client.
///
/// Exposes two pre-configured clients:
///   - [productClient] → product/user/cart/wishlist/banner service
///   - [orderClient]   → order/payment/notification service
///
/// Both share the same [AuthInterceptor] for transparent token refresh.
class ApiClient {
  ApiClient._();

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  late final Dio _productClient = _build(ApiEndpoints.productServiceBase);
  late final Dio _orderClient   = _build(ApiEndpoints.orderServiceBase);

  Dio get productClient => _productClient;
  Dio get orderClient   => _orderClient;

  Dio _build(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          error: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }

    return dio;
  }
}
