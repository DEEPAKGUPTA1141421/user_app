import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CheckoutState {
  final bool isLoading;
  final String? error;

  // Step 1 – Booking (one entry per shop)
  final List<Map<String, dynamic>> bookings;
  final String? expiresAt;
  final String? couponApplied;

  // Step 2 – Payment results
  final List<String> transactionIds; // one per booking (used for COD OTP)
  final String? paymentId;
  final String? paymentMode; // CASH_ON_DELIVERY | ONLINE

  // Step 3 – Verification
  final bool paymentVerified;
  final String? paymentStatus;

  // Delivery address (stored for order-success screen)
  final Map<String, dynamic>? selectedAddress;

  const CheckoutState({
    this.isLoading = false,
    this.error,
    this.bookings = const [],
    this.expiresAt,
    this.couponApplied,
    this.transactionIds = const [],
    this.paymentId,
    this.paymentMode,
    this.paymentVerified = false,
    this.paymentStatus,
    this.selectedAddress,
  });

  /// First bookingId — used by order-success and tracking screens.
  String? get bookingId =>
      bookings.isNotEmpty ? bookings.first['bookingId'] as String? : null;

  /// First transactionId — convenient for single-shop COD OTP.
  String? get transactionId =>
      transactionIds.isNotEmpty ? transactionIds.first : null;

  /// Grand total across all bookings (rupees).
  double get totalAmountRupees => bookings.fold(
        0.0,
        (sum, b) =>
            sum + ((b['totalAmountRupees'] as num?)?.toDouble() ?? 0.0),
      );

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? bookings,
    String? expiresAt,
    String? couponApplied,
    List<String>? transactionIds,
    String? paymentId,
    String? paymentMode,
    bool? paymentVerified,
    String? paymentStatus,
    Map<String, dynamic>? selectedAddress,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // intentionally always overwritten (null clears it)
      bookings: bookings ?? this.bookings,
      expiresAt: expiresAt ?? this.expiresAt,
      couponApplied: couponApplied ?? this.couponApplied,
      transactionIds: transactionIds ?? this.transactionIds,
      paymentId: paymentId ?? this.paymentId,
      paymentMode: paymentMode ?? this.paymentMode,
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

  // ─── Step 1: Create Bookings from Cart ────────────────────────────────────
  //
  // GET /api/v1/booking/checkout?deliveryAddress=<UUID>
  // Response: { data: { totalBookings, couponApplied, expiresAt, bookings: [...] } }
  Future<bool> createBooking({required String deliveryAddress}) async {
    state = state.copyWith(isLoading: true, error: null, bookings: const []);
    try {
      final res = await _client.get(
        ApiEndpoints.checkoutBooking,
        queryParameters: {'deliveryAddress': deliveryAddress},
      );

      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final rawBookings = data['bookings'] as List<dynamic>;

      final bookings = rawBookings
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        bookings: bookings,
        expiresAt: data['expiresAt'] as String?,
        couponApplied: data['couponApplied'] as String?,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false, error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Step 2: Create Payment ───────────────────────────────────────────────
  //
  // POST /api/v1/payment  — called once per booking.
  // gateway: 'cod'     → pgPayment:false, pgPaymentAmount:"0"
  // gateway: 'phonepe' → pgPayment:true,  pgPaymentAmount:"<rupees>"
  Future<bool> createPayment({
    required String userId,
    required String gateway, // 'cod' | 'phonepe'
  }) async {
    if (state.bookings.isEmpty) {
      state = state.copyWith(error: 'No bookings found. Please try again.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);

    final isCod = gateway == 'cod';
    final txIds = <String>[];
    String? firstPaymentId;

    try {
      for (final booking in state.bookings) {
        final bookingId = booking['bookingId'] as String;
        final amountRupees =
            (booking['totalAmountRupees'] as num?)?.toStringAsFixed(2) ?? '0.00';
        // Use first UUID segment only — full UUIDs exceed the 64-char limit.
        // Format matches the API example: "d38a9231-f3a1c2d4-1713200000000"
        final shortUser    = userId.split('-').first;
        final shortBooking = bookingId.split('-').first;
        final idempotencyKey =
            '$shortUser-$shortBooking-${DateTime.now().millisecondsSinceEpoch}';

        final res = await _client.post(
          ApiEndpoints.createPayment,
          data: {
            'gateway': gateway,
            'bookingId': bookingId,
            'userId': userId,
            'idempotencyKey': idempotencyKey,
            'pgPaymentAmount': isCod ? '0' : amountRupees,
            'pgPayment': !isCod,
            'pointPayment': false,
            'pointPaymentAmount': null,
          },
        );

        final body = res.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final txId = data['transactionId']?.toString();
          if (txId != null && txId.isNotEmpty) txIds.add(txId);
          firstPaymentId ??= data['paymentId']?.toString();
        }
      }

      state = state.copyWith(
        isLoading: false,
        transactionIds: txIds,
        paymentId: firstPaymentId,
        paymentMode: isCod ? 'CASH_ON_DELIVERY' : 'ONLINE',
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false, error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Step 3: Validate / Verify Payment (PhonePe only) ────────────────────
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
          isLoading: false, error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── COD: Generate OTP ────────────────────────────────────────────────────
  //
  // POST /api/v1/payment/cod/generate-otp  { transactionId }
  // Returns: { data: { otp, expiresInMinutes, transactionId } }
  Future<Map<String, dynamic>> generateCodOtp(String transactionId) async {
    try {
      final res = await _client.post(
        ApiEndpoints.codGenerateOtp,
        data: {'transactionId': transactionId},
      );
      final body = res.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      return {'error': AppException.fromDioError(e).message};
    } catch (e) {
      return {'error': e.toString()};
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
