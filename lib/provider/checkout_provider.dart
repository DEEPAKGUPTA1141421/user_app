import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../utils/StorageService.dart';
import '../constant/ServerApi.dart';

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

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void setAddress(Map<String, dynamic> address) {
    state = state.copyWith(selectedAddress: address);
  }

  void reset() {
    state = const CheckoutState();
  }

  // ─── Step 1: Create Booking from Cart ─────────────────────────────────────
  //  POST /api/v1/booking/checkout  →  { bookingId, totalAmount, ... }
  Future<bool> createBooking() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse(ServerApi.checkoutBooking),
        headers: headers,
      );
      final body = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = body['data'];
        // data can be a List (one booking per shop) or a single Map
        String bookingId;
        if (data is List && data.isNotEmpty) {
          bookingId = (data.first as Map<String, dynamic>)['id'] as String;
        } else if (data is Map) {
          bookingId = data['id'] as String;
        } else {
          state = state.copyWith(isLoading: false, error: 'Unexpected booking response');
          return false;
        }
        state = state.copyWith(isLoading: false, bookingId: bookingId);
        return true;
      } else {
        state = state.copyWith(
            isLoading: false,
            error: body['message'] as String? ?? 'Booking failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Step 2: Create Payment (PhonePe) ─────────────────────────────────────
  //  POST /api/v1/payment
  //  Body: CreateOrderDto { gateway, bookingId, userId, idempotencyKey,
  //                         pgPaymentAmount, pgPayment, pointPayment,
  //                         pointPaymentAmount? }
  Future<bool> createPayment({
    required String userId,
    required String amount,  // rupees as string e.g. "2187.84"
  }) async {
    if (state.bookingId == null) {
      state = state.copyWith(error: 'No booking found');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final headers = await _authHeaders();
      final idempotencyKey = 'PAY-${state.bookingId}-${DateTime.now().millisecondsSinceEpoch}';

      final res = await http.post(
        Uri.parse(ServerApi.createPayment),
        headers: headers,
        body: json.encode({
          'gateway': 'phonepe',
          'bookingId': state.bookingId,
          'userId': userId,
          'idempotencyKey': idempotencyKey,
          'pgPaymentAmount': amount,
          'pgPayment': true,
          'pointPayment': false,
          'pointPaymentAmount': null,
        }),
      );

      final body = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = body['data'] as Map<String, dynamic>?;
        // Backend returns: { bookingId, paymentId, transactions }
        // The gateway transaction carries the phonePe orderId/token
        // We need to call PhonePe SDK with the token returned
        // For now, capture paymentId and transactionId
        final paymentId = data?['paymentId']?.toString();
        final transactions = data?['transactions'];

        // Fetch the PhonePe token by calling validate-payment
        // OR the token was embedded in the transaction — adjust per your backend
        state = state.copyWith(
          isLoading: false,
          paymentId: paymentId,
          // phonePeToken will be set after we call validate or it comes embedded
        );
        return true;
      } else {
        state = state.copyWith(
            isLoading: false,
            error: body['message'] as String? ?? 'Payment creation failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Step 3: Validate / Verify Payment ────────────────────────────────────
  //  GET /api/v1/payment/validate-payment?merchantOrderId={id}&gateway=phonepe
  Future<bool> validatePayment() async {
    if (state.bookingId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final headers = await _authHeaders();
      // merchantOrderId is the bookingId we used to create the payment
      final uri = Uri.parse(ServerApi.validatePayment)
          .replace(queryParameters: {
        'merchantOrderId': state.bookingId!,
        'gateway': 'phonepe',
      });

      final res = await http.get(uri, headers: headers);
      final body = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
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
      } else {
        state = state.copyWith(
            isLoading: false,
            error: body['message'] as String? ?? 'Validation failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Helper: Set PhonePe token after SDK returns ───────────────────────────
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