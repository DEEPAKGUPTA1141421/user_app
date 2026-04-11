import 'package:dio/dio.dart';

/// Typed exception for all app-level errors.
///
/// Use [AppException.fromDioError] to convert Dio errors into human-readable
/// messages. All UI error text should come through here so wording is consistent.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  // ── Named constructors ────────────────────────────────────────────────────

  factory AppException.network() => const AppException(
        'No internet connection. Please check your network and try again.',
      );

  factory AppException.timeout() => const AppException(
        'Request timed out. Please try again.',
      );

  factory AppException.unauthorized() => const AppException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );

  factory AppException.server(int code) => AppException(
        'Server error. Please try again later. ($code)',
        statusCode: code,
      );

  factory AppException.unknown() =>
      const AppException('Something went wrong. Please try again.');

  /// Convert any Dio error into an [AppException] with a friendly message.
  factory AppException.fromDioError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException.timeout();

        case DioExceptionType.connectionError:
          return AppException.network();

        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 401 || code == 403) return AppException.unauthorized();
          if (code != null && code >= 500) return AppException.server(code);
          final msg = _extractMessage(error.response?.data);
          return AppException(msg ?? 'Request failed ($code)', statusCode: code);

        default:
          final msg = _extractMessage(error.response?.data);
          return AppException(msg ?? error.message ?? 'Unknown error');
      }
    }
    return AppException(error.toString());
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  @override
  String toString() => message;
}
