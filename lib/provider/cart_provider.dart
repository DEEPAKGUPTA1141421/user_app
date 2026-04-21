import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class CartState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> cartData;
  final List<dynamic> bestCoupons;
  final List<dynamic> moreCoupons;

  const CartState({
    this.isLoading = false,
    this.error,
    this.cartData = const {},
    this.bestCoupons = const [],
    this.moreCoupons = const [],
  });

  // Convenience getters so UI doesn't need to cast raw map values
  List<dynamic> get items =>
      (cartData['items'] as List<dynamic>?) ?? const [];

  double get totalAmount =>
      (cartData['totalAmount'] as num?)?.toDouble() ?? 0.0;

  double get discount =>
      (cartData['discount'] as num?)?.toDouble() ?? 0.0;

  double get deliveryFee =>
      (cartData['deliveryFee'] as num?)?.toDouble() ?? 0.0;

  String? get appliedCoupon => cartData['cartCoupon'] as String?;

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? cartData,
    List<dynamic>? bestCoupons,
    List<dynamic>? moreCoupons,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      error: error,                         // null intentionally clears error
      cartData: cartData ?? this.cartData,
      bestCoupons: bestCoupons ?? this.bestCoupons,
      moreCoupons: moreCoupons ?? this.moreCoupons,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  Dio get _client => ApiClient.instance.productClient;

  // ── Fetch cart ───────────────────────────────────────────────────────────

  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.cart);
      final data = (res.data as Map<String, dynamic>?)?['data']
          as Map<String, dynamic>? ?? {};
      state = state.copyWith(isLoading: false, cartData: data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Add item ─────────────────────────────────────────────────────────────

  Future<void> addItem(Map<String, dynamic> itemRequest) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.post(ApiEndpoints.cartItems, data: itemRequest);
      await fetchCart();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Update quantity ───────────────────────────────────────────────────────

  Future<void> updateCartItem(String itemId, int qty) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.put(
        '${ApiEndpoints.cartItems}/$itemId',
        queryParameters: {'qty': qty},
      );
      final data = (res.data as Map<String, dynamic>?)?['data']
          as Map<String, dynamic>? ?? {};
      state = state.copyWith(isLoading: false, cartData: data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Remove item ───────────────────────────────────────────────────────────

  Future<void> removeItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.delete('${ApiEndpoints.cartItems}/$itemId');
      await fetchCart();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Clear cart ────────────────────────────────────────────────────────────

  Future<void> clearCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.delete(ApiEndpoints.cart);
      state = state.copyWith(isLoading: false, cartData: {});
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Fetch available coupons ───────────────────────────────────────────────

  Future<void> fetchCoupons() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.cartCoupons);
      final data = (res.data as Map<String, dynamic>?)?['data']
          as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        isLoading: false,
        bestCoupons: (data['bestCoupons'] as List<dynamic>?) ?? const [],
        moreCoupons: (data['moreCoupons'] as List<dynamic>?) ?? const [],
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

  // ── Apply / remove coupon ─────────────────────────────────────────────────

  Future<void> applyCoupon(String couponCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final url = couponCode.isEmpty
          ? ApiEndpoints.removeCartCoupon
          : ApiEndpoints.applyCartCoupon(couponCode);

      final res = await _client.post(url);
      final data = (res.data as Map<String, dynamic>?)?['data']
          as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        cartData: {
          ...data,
          if (couponCode.isNotEmpty) 'cartCoupon': couponCode,
        },
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
}

// ── Provider ──────────────────────────────────────────────────────────────────

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
