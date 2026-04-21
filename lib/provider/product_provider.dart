import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class ProductState {
  final bool isLoading;
  final String? error;
  final List<dynamic> products;
  final List<dynamic> brands;
  final Map<String, dynamic> productDetail;

  const ProductState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.brands   = const [],
    this.productDetail = const {},
  });

  ProductState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? products,
    List<dynamic>? brands,
    Map<String, dynamic>? productDetail,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      products: products ?? this.products,
      brands: brands ?? this.brands,
      productDetail: productDetail ?? this.productDetail,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier() : super(const ProductState());

  Dio get _client => ApiClient.instance.productClient;

  // ── Product detail ───────────────────────────────────────────────────────

  Future<void> fetchProductDetail(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get('${ApiEndpoints.productDetail}/$productId');
      final data = (res.data as Map<String, dynamic>?)?['data']
          as Map<String, dynamic>? ?? {};
      state = state.copyWith(isLoading: false, productDetail: data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> searchProduct(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(
        ApiEndpoints.searchSuggestions,
        queryParameters: {'keyword': query},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        isLoading: false,
        products: (data['products'] as List<dynamic>?) ?? const [],
        brands:   (data['brands']   as List<dynamic>?) ?? const [],
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

  // ── Save search history ───────────────────────────────────────────────────

  Future<void> saveSearch({
    required String itemId,
    required String itemType,
    required String title,
    required String imageUrl,
    String? meta,
  }) async {
    try {
      await _client.post(
        ApiEndpoints.saveSearchItem,
        data: {
          'itemId': itemId,
          'itemType': itemType,
          'title': title,
          'imageUrl': imageUrl,
          'meta': meta ?? '',
        },
      );
    } catch (_) {
      // Non-critical — silent failure is acceptable
    }
  }

  // ── Recent searches ───────────────────────────────────────────────────────

  Future<List<dynamic>> getRecentSearches() async {
    try {
      final res = await _client.get(ApiEndpoints.recentSearches);
      final body = res.data as Map<String, dynamic>;
      return (body['data'] as List<dynamic>?) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  // ── Trending searches ─────────────────────────────────────────────────────

  Future<List<dynamic>> getTrendingSearches() async {
    try {
      final res = await _client.get(ApiEndpoints.trendingSearch);
      final body = res.data as Map<String, dynamic>;
      return (body['data'] as List<dynamic>?) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  // ── Popular products ──────────────────────────────────────────────────────

  Future<List<dynamic>> getPopularProducts() async {
    try {
      final res = await _client.get(ApiEndpoints.popularProducts);
      final body = res.data as Map<String, dynamic>;
      return (body['data'] as List<dynamic>?) ?? const [];
    } catch (_) {
      return const [];
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final productPod = StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(),
);
