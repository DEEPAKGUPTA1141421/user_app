import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:user_app/utils/StorageService.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  /// Set this once in main.dart so the interceptor can navigate to /login
  /// when both access and refresh tokens are invalid.
  static GlobalKey<NavigatorState>? navigatorKey;

  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _retryQueue = [];

  AuthInterceptor(this._dio);

  // ── Attach access token to every outgoing request ─────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── On 401/403: attempt token refresh once, then retry ─────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    if (statusCode != 401 && statusCode != 403) {
      return handler.next(err);
    }

    // Refresh endpoint itself returned 401/403 → full logout
    if (err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      await _clearAndDrain(err, handler);
      return;
    }

    // Queue while a refresh is already in flight
    if (_isRefreshing) {
      _retryQueue.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        await _clearAndDrain(err, handler);
        return;
      }

      // ── Use a CLEAN Dio with no interceptors so the expired access token
      //    is NOT re-attached to the refresh request by onRequest above.
      final cleanDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ));

      final response = await cleanDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>?;
      if (data?['success'] == true) {
        final newAccess  = data!['data']['accessToken']  as String;
        final newRefresh = data['data']['refreshToken'] as String;

        await StorageService.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        // Retry the original request with the new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(err.requestOptions);

        // Drain queued requests
        for (final item in _retryQueue) {
          item.options.headers['Authorization'] = 'Bearer $newAccess';
          _dio.fetch(item.options).then(
            (r) => item.handler.resolve(r),
            onError: (e) => item.handler.next(e as DioException),
          );
        }
        _retryQueue.clear();

        return handler.resolve(retried);
      } else {
        await _clearAndDrain(err, handler);
      }
    } catch (_) {
      await _clearAndDrain(err, handler);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearAndDrain(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await StorageService.clearTokens();
    for (final item in _retryQueue) {
      item.handler.next(err);
    }
    _retryQueue.clear();
    handler.next(err);

    // Navigate to login and clear the back stack
    navigatorKey?.currentState
        ?.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}
