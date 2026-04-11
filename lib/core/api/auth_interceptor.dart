import 'package:dio/dio.dart';
import 'package:user_app/utils/StorageService.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

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

    // Only handle auth errors
    if (statusCode != 401 && statusCode != 403) {
      return handler.next(err);
    }

    // Avoid infinite loop on the refresh endpoint itself
    if (err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      await StorageService.clearTokens();
      return handler.next(err);
    }

    // Queue subsequent requests while a refresh is already in flight
    if (_isRefreshing) {
      _retryQueue.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        return handler.next(err);
      }

      // POST /api/v1/auth/refresh without the auth header to avoid recursion
      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data?['success'] == true) {
        final newAccess  = data!['data']['accessToken']  as String;
        final newRefresh = data['data']['refreshToken'] as String;

        await StorageService.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        // Retry the original failed request with the new token
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
  }
}
