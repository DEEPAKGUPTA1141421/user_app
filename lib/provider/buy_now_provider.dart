import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/errors/app_exception.dart';

// ─── State ─────────────────────────────────────────────────────────────────────

class BuyNowState {
  final bool isLoading;
  final String? error;

  // Step 1 – Booking
  final String? bookingId;
  final String? shopId;
  final String? productName;
  final String? expiresAt;
  final String? totalAmountPaise;
  final double? totalAmountRupees;
  final Map<String, dynamic>? breakdown;
  final String? bookingStatus; // INITIATED | CONFIRMED | etc.

  // Step 2 – Payment
  final String? transactionId;
  final String? paymentId;
  final String? paymentMode;
  final String? paymentStatus;

  // Step 3 – Verified
  final bool paymentVerified;

  const BuyNowState({
    this.isLoading = false,
    this.error,
    this.bookingId,
    this.shopId,
    this.productName,
    this.expiresAt,
    this.totalAmountPaise,
    this.totalAmountRupees,
    this.breakdown,
    this.bookingStatus,
    this.transactionId,
    this.paymentId,
    this.paymentMode,
    this.paymentStatus,
    this.paymentVerified = false,
  });

  bool get hasBooking => bookingId != null;

  BuyNowState copyWith({
    bool? isLoading,
    String? error,
    String? bookingId,
    String? shopId,
    String? productName,
    String? expiresAt,
    String? totalAmountPaise,
    double? totalAmountRupees,
    Map<String, dynamic>? breakdown,
    String? bookingStatus,
    String? transactionId,
    String? paymentId,
    String? paymentMode,
    String? paymentStatus,
    bool? paymentVerified,
  }) {
    return BuyNowState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookingId: bookingId ?? this.bookingId,
      shopId: shopId ?? this.shopId,
      productName: productName ?? this.productName,
      expiresAt: expiresAt ?? this.expiresAt,
      totalAmountPaise: totalAmountPaise ?? this.totalAmountPaise,
      totalAmountRupees: totalAmountRupees ?? this.totalAmountRupees,
      breakdown: breakdown ?? this.breakdown,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      transactionId: transactionId ?? this.transactionId,
      paymentId: paymentId ?? this.paymentId,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentVerified: paymentVerified ?? this.paymentVerified,
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class BuyNowNotifier extends StateNotifier<BuyNowState> {
  BuyNowNotifier() : super(const BuyNowState());

  Dio get _client => ApiClient.instance.orderClient;

  void reset() => state = const BuyNowState();

  // ── Step 1: POST /api/v1/buy-now ─────────────────────────────────────────
  Future<bool> createBooking({
    required String productId,
    required String variantId,
    required String deliveryAddressId,
    int quantity = 1,
  }) async {
    state = const BuyNowState(isLoading: true);
    try {
      final res = await _client.post(
        '/api/v1/buy-now',
        data: {
          'productId': productId,
          'variantId': variantId,
          'quantity': quantity,
          'deliveryAddressId': deliveryAddressId,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        bookingId: data['bookingId'] as String?,
        shopId: data['shopId'] as String?,
        productName: data['productName'] as String?,
        expiresAt: data['expiresAt'] as String?,
        totalAmountPaise: data['totalAmountPaise']?.toString(),
        totalAmountRupees: (data['totalAmountRupees'] as num?)?.toDouble(),
        breakdown: data['breakdown'] as Map<String, dynamic>?,
        bookingStatus: data['status'] as String? ?? 'INITIATED',
      );
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      // Extract the raw message for business-rule errors (409 etc.)
      String msg = ex.message;
      if (e.response?.data is Map) {
        msg = (e.response!.data as Map)['message'] as String? ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Step 2: POST /api/v1/payment ─────────────────────────────────────────
  Future<bool> createPayment({
    required String userId,
    required String gateway, // 'cod' | 'phonepe'
  }) async {
    final bookingId = state.bookingId;
    final amountRupees = state.totalAmountRupees ?? 0.0;
    if (bookingId == null) {
      state = state.copyWith(error: 'No booking found. Please try again.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    final isCod = gateway == 'cod';

    try {
      final shortUser = userId.split('-').first;
      final shortBooking = bookingId.split('-').first;
      final idempotencyKey =
          'buynow-$shortUser-$shortBooking-${DateTime.now().millisecondsSinceEpoch}';

      final res = await _client.post(
        '/api/v1/payment',
        data: {
          'gateway': gateway,
          'bookingId': bookingId,
          'idempotencyKey': idempotencyKey,
          'pgPaymentAmount': isCod ? '0' : amountRupees.toStringAsFixed(2),
          'pgPayment': !isCod,
          'pointPayment': false,
          'pointPaymentAmount': null,
        },
      );

      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;

      state = state.copyWith(
        isLoading: false,
        transactionId: data?['transactionId']?.toString(),
        paymentId: data?['paymentId']?.toString(),
        paymentMode: isCod ? 'CASH_ON_DELIVERY' : 'ONLINE',
        paymentStatus: isCod ? 'PENDING' : 'PENDING',
      );
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      String msg = ex.message;
      if (e.response?.data is Map) {
        msg = (e.response!.data as Map)['message'] as String? ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Step 3: Validate PhonePe payment ─────────────────────────────────────
  Future<bool> validatePayment() async {
    final bookingId = state.bookingId;
    if (bookingId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(
        '/api/v1/payment/validate-payment',
        queryParameters: {
          'merchantOrderId': bookingId,
          'gateway': 'phonepe',
        },
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final status = data?['state'] as String? ?? 'UNKNOWN';
      final isSuccess = status == 'COMPLETED' || status == 'SUCCESS';
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

  void setPhonePeResult(String status) {
    state = state.copyWith(
      paymentStatus: status,
      paymentVerified: status == 'COMPLETED' || status == 'SUCCESS',
    );
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final buyNowProvider =
    StateNotifierProvider<BuyNowNotifier, BuyNowState>(
  (ref) => BuyNowNotifier(),
);