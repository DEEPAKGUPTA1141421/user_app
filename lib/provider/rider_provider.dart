import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user = const {},
  });

  // Convenience getters
  String get firstName => user['firstName'] as String? ?? '';
  String get lastName  => user['lastName']  as String? ?? '';
  String get fullName  => '$firstName $lastName'.trim();
  String get phone     => user['phone']     as String? ?? '';
  String? get avatarUrl => user['avatarUrl'] as String?;

  List<dynamic> get addresses =>
      (user['addresses'] as List<dynamic>?) ?? const [];

  bool get isEmpty => user.isEmpty;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiderNotifier extends StateNotifier<AuthState> {
  RiderNotifier() : super(const AuthState());

  Dio get _client => ApiClient.instance.productClient;

  // ── Login ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String phone, String userType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'typeOfUser': userType},
      );
      final body = res.data as Map<String, dynamic>;
      state = state.copyWith(isLoading: false);
      return body;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Verify OTP ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String userType,
    String otp,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'typeOfUser': userType, 'otp_code': otp},
      );
      final body = res.data as Map<String, dynamic>;
      state = state.copyWith(isLoading: false);
      return body;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Get user detail ──────────────────────────────────────────────────────

  Future<void> getUserDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.userDetails);
      final body = res.data as Map<String, dynamic>;
      final userData = body['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(isLoading: false, user: userData);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Add address ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addAddress(
    String latitude,
    String longitude,
    bool isDefault,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.addAddress,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'isDefault': isDefault,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final userData = body['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(isLoading: false, user: userData);
      return body;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Set default address ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> makeAddressDefault(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.put(
        '${ApiEndpoints.setDefaultAddr}/$addressId',
      );
      final body = res.data as Map<String, dynamic>;
      final userData = body['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(isLoading: false, user: userData);
      return body;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final riderPod =
    StateNotifierProvider<RiderNotifier, AuthState>((ref) => RiderNotifier());
