import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class WishlistState {
  final bool isLoading;
  final String? error;
  final List<dynamic> items;
  final List<dynamic> priceDrops;

  const WishlistState({
    this.isLoading = false,
    this.error,
    this.items      = const [],
    this.priceDrops = const [],
  });

  bool get isEmpty => items.isEmpty;

  WishlistState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? items,
    List<dynamic>? priceDrops,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      priceDrops: priceDrops ?? this.priceDrops,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier() : super(const WishlistState());

  Dio get _client => ApiClient.instance.productClient;

  // ── Fetch wishlist ────────────────────────────────────────────────────────

  Future<void> fetchWishlist() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.wishlist);
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        isLoading: false,
        items: (data['items'] as List<dynamic>?) ?? const [],
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

  // ── Add item ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addItem(
    String productId, {
    String? variantId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.wishlistItem(productId),
        queryParameters: variantId != null ? {'variantId': variantId} : null,
      );
      final body = res.data as Map<String, dynamic>;
      await fetchWishlist();
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

  // ── Remove item (optimistic) ──────────────────────────────────────────────

  Future<Map<String, dynamic>> removeItem(String productId) async {
    // Optimistic removal
    final previous = state.items;
    state = state.copyWith(
      items: state.items
          .where((i) =>
              i['productId']?.toString() != productId &&
              i['id']?.toString() != productId)
          .toList(),
    );
    try {
      final res = await _client.delete(ApiEndpoints.wishlistItem(productId));
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Revert on failure
      state = state.copyWith(items: previous);
      final msg = AppException.fromDioError(e).message;
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(items: previous);
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Clear wishlist ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> clearWishlist() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.delete(ApiEndpoints.wishlist);
      state = state.copyWith(isLoading: false, items: const []);
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

  // ── Move to cart ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> moveToCart(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        ApiEndpoints.wishlistMoveToCart(productId),
      );
      // Remove locally after successful move
      state = state.copyWith(
        isLoading: false,
        items: state.items
            .where((i) => i['productId']?.toString() != productId)
            .toList(),
      );
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

  // ── Price drops (non-critical) ────────────────────────────────────────────

  Future<void> fetchPriceDrops() async {
    try {
      final res = await _client.get(ApiEndpoints.wishlistPriceDrops);
      final body = res.data as Map<String, dynamic>;
      state = state.copyWith(
        priceDrops: (body['data'] as List<dynamic>?) ?? const [],
      );
    } catch (_) {
      // Silent — price drops are non-critical
    }
  }

  // ── Share wishlist ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> shareWishlist({int? ttlDays}) async {
    try {
      final res = await _client.post(
        ApiEndpoints.wishlistShare,
        queryParameters: ttlDays != null ? {'ttlDays': ttlDays} : null,
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {'success': false, 'message': AppException.fromDioError(e).message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) => WishlistNotifier(),
);
