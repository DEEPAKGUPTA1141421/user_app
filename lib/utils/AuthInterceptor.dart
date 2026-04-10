import 'package:dio/dio.dart';
import './StorageService.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  bool _isRefreshing = false;
  final List<RequestOptions> _retryQueue = [];

  AuthInterceptor(this.dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageService.getAccessToken();

    if (token != null) {
      options.headers["Authorization"] = "Bearer $token";
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // ❗ Prevent infinite loop
    if (err.requestOptions.path.contains("/refresh")) {
      return handler.next(err);
    }

    if (statusCode == 403) {
      final refreshToken = await StorageService.getRefreshToken();

      if (refreshToken == null) {
        return handler.next(err);
      }

      // 🔁 If already refreshing → queue request
      if (_isRefreshing) {
        _retryQueue.add(err.requestOptions);
        return;
      }

      _isRefreshing = true;

      try {
        // 🔁 CALL REFRESH API
        final response = await dio.post(
          "/refresh",
          data: {
            "refreshToken": refreshToken,
          },
        );

        final data = response.data;

        if (data['success'] == true) {
          final newAccessToken = data['data']['accessToken'];
          final newRefreshToken = data['data']['refreshToken'];

          // 💾 SAVE TOKENS
          await StorageService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // 🔁 RETRY FAILED REQUEST
          final requestOptions = err.requestOptions;
          requestOptions.headers["Authorization"] =
              "Bearer $newAccessToken";

          final retryResponse = await dio.fetch(requestOptions);

          // 🔁 RETRY QUEUED REQUESTS
          for (var req in _retryQueue) {
            req.headers["Authorization"] = "Bearer $newAccessToken";
            dio.fetch(req);
          }

          _retryQueue.clear();

          return handler.resolve(retryResponse);
        } else {
          // ❌ Refresh failed → logout
          await StorageService.clearTokens();
          return handler.next(err);
        }
      } catch (e) {
        await StorageService.clearTokens();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }
}