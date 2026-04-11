import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class SavedPaymentMethodsState {
  final bool isLoading;
  final String? error;
  final List<dynamic> methods;

  const SavedPaymentMethodsState({
    this.isLoading = false,
    this.error,
    this.methods = const [],
  });

  bool get isEmpty => methods.isEmpty;

  SavedPaymentMethodsState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? methods,
  }) {
    return SavedPaymentMethodsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      methods: methods ?? this.methods,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SavedPaymentMethodsNotifier
    extends StateNotifier<SavedPaymentMethodsState> {
  SavedPaymentMethodsNotifier() : super(const SavedPaymentMethodsState());

  Dio get _client => ApiClient.instance.orderClient;

  // ── Fetch all saved methods ────────────────────────────────────────────────

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.paymentMethods);
      final body = res.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        methods: (body['data'] as List<dynamic>?) ?? const [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Save card ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> saveCard({
    required String gatewayToken,
    required String cardLast4,
    required String cardBrand,
    required String cardHolderName,
    required String cardExpiry,
    required String cardType,
    required String gateway,
    String? nickname,
    bool makeDefault = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.saveCard,
        data: {
          'gatewayToken': gatewayToken,
          'cardLast4': cardLast4,
          'cardBrand': cardBrand,
          'cardHolderName': cardHolderName,
          'cardExpiry': cardExpiry,
          'cardType': cardType,
          'gateway': gateway,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          'makeDefault': makeDefault,
        },
      );
      state = state.copyWith(isLoading: false);
      await fetchAll();
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Save UPI ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> saveUpi({
    required String upiId,
    String? upiDisplayName,
    String? nickname,
    bool makeDefault = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.saveUpi,
        data: {
          'upiId': upiId,
          if (upiDisplayName != null && upiDisplayName.isNotEmpty)
            'upiDisplayName': upiDisplayName,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          'makeDefault': makeDefault,
        },
      );
      state = state.copyWith(isLoading: false);
      await fetchAll();
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Delete (optimistic) ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> delete(String id) async {
    final previous = state.methods;
    state = state.copyWith(
      methods: state.methods
          .where((m) => m['id']?.toString() != id)
          .toList(),
    );
    try {
      final res = await _client.delete(
        ApiEndpoints.deletePaymentMethod(id),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      state = state.copyWith(methods: previous); // revert
      return {'success': false, 'message': AppException.fromDioError(e).message};
    } catch (e) {
      state = state.copyWith(methods: previous);
      return {'success': false, 'message': e.toString()};
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final savedPaymentMethodsProvider = StateNotifierProvider<
    SavedPaymentMethodsNotifier, SavedPaymentMethodsState>(
  (ref) => SavedPaymentMethodsNotifier(),
);
