import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

class CheckoutState {
  final bool isLoading;
  final String? error;

  // Step 1 – Booking
  final String? bookingId;

  // Step 2 – Payment creation (PhonePe token)
  final String? paymentId;
  final String? phonePeToken;   // SDK token to launch PhonePe sheet
  final String? phonePeOrderId; // PhonePe's orderId (merchantOrderId)
  final String? transactionId;  // Our internal transaction / gateway txn number

  // Step 3 – Verification result
  final bool paymentVerified;
  final String? paymentStatus; // COMPLETED | FAILED | PENDING

  // Delivery address used at checkout
  final Map<String, dynamic>? selectedAddress;

  const CheckoutState({
    this.isLoading = false,
    this.error,
    this.bookingId,
    this.paymentId,
    this.phonePeToken,
    this.phonePeOrderId,
    this.transactionId,
    this.paymentVerified = false,
    this.paymentStatus,
    this.selectedAddress,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    String? bookingId,
    String? paymentId,
    String? phonePeToken,
    String? phonePeOrderId,
    String? transactionId,
    bool? paymentVerified,
    String? paymentStatus,
    Map<String, dynamic>? selectedAddress,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,                          // always overwrite (null clears it)
      bookingId: bookingId ?? this.bookingId,
      paymentId: paymentId ?? this.paymentId,
      phonePeToken: phonePeToken ?? this.phonePeToken,
      phonePeOrderId: phonePeOrderId ?? this.phonePeOrderId,
      transactionId: transactionId ?? this.transactionId,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  Dio get _client => ApiClient.instance.orderClient;

  void setAddress(Map<String, dynamic> address) =>
      state = state.copyWith(selectedAddress: address);

  void reset() => state = const CheckoutState();

  // ─── Step 1: Create Booking from Cart ─────────────────────────────────────
  Future<bool> createBooking() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.checkoutBooking);
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];

      String bookingId;
      if (data is List && data.isNotEmpty) {
        bookingId = (data.first as Map<String, dynamic>)['id'] as String;
      } else if (data is Map<String, dynamic>) {
        bookingId = data['id'] as String;
      } else {
        state = state.copyWith(
            isLoading: false, error: 'Unexpected booking response');
        return false;
      }
      state = state.copyWith(isLoading: false, bookingId: bookingId);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Step 2: Create Payment (PhonePe) ─────────────────────────────────────
  Future<bool> createPayment({
    required String userId,
    required String amount, // rupees as string e.g. "2187.84"
  }) async {
    if (state.bookingId == null) {
      state = state.copyWith(error: 'No booking found');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idempotencyKey =
          'PAY-${state.bookingId}-${DateTime.now().millisecondsSinceEpoch}';

      final res = await _client.post(
        ApiEndpoints.createPayment,
        data: {
          'gateway': 'phonepe',
          'bookingId': state.bookingId,
          'userId': userId,
          'idempotencyKey': idempotencyKey,
          'pgPaymentAmount': amount,
          'pgPayment': true,
          'pointPayment': false,
          'pointPaymentAmount': null,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final paymentId = data?['paymentId']?.toString();
      state = state.copyWith(isLoading: false, paymentId: paymentId);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Step 3: Validate / Verify Payment ────────────────────────────────────
  Future<bool> validatePayment() async {
    if (state.bookingId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(
        ApiEndpoints.validatePayment,
        queryParameters: {
          'merchantOrderId': state.bookingId!,
          'gateway': 'phonepe',
        },
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final status = data?['state'] as String? ?? 'UNKNOWN';
      final isSuccess = status == 'COMPLETED';
      state = state.copyWith(
        isLoading: false,
        paymentVerified: isSuccess,
        paymentStatus: status,
        error: isSuccess ? null : 'Payment $status',
      );
      return isSuccess;
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Helper: Record PhonePe SDK result ────────────────────────────────────
  void setPhonePeResult(String status) {
    state = state.copyWith(
      paymentStatus: status,
      paymentVerified: status == 'COMPLETED',
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(),
);