import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

final InfiniteproductProvider =
    StateNotifierProvider<InfiniteProductNotifier, InfiniteProductState>(
  (ref) => InfiniteProductNotifier(),
);

class InfiniteProductState {
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final List<Map<String, dynamic>> products;
  final int page;

  const InfiniteProductState({
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.products = const [],
    this.page = 0,
  });

  InfiniteProductState copyWith({
    bool? isLoading,
    bool? hasMore,
    String? error,
    List<Map<String, dynamic>>? products,
    int? page,
  }) =>
      InfiniteProductState(
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        products: products ?? this.products,
        page: page ?? this.page,
      );
}

class InfiniteProductNotifier extends StateNotifier<InfiniteProductState> {
  InfiniteProductNotifier() : super(const InfiniteProductState());

  static const int _pageSize = 10;
  Dio get _client => ApiClient.instance.productClient;

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (state.isLoading) return;
    if (loadMore && !state.hasMore) return;

    final nextPage = loadMore ? state.page + 1 : 0;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _client.get(
        ApiEndpoints.popularProducts,
        queryParameters: {'page': nextPage, 'size': _pageSize},
      );

      final body = res.data;
      List<dynamic> raw = const [];
      if (body is Map) {
        final data = body['data'];
        if (data is List) {
          raw = data;
        } else if (data is Map) {
          raw = (data['content'] ?? data['products'] ?? data['items'] ?? []) as List;
        }
      } else if (body is List) {
        raw = body;
      }

      final fetched = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final updated = loadMore
          ? [...state.products, ...fetched]
          : fetched;

      state = state.copyWith(
        isLoading: false,
        products: updated,
        page: nextPage,
        hasMore: fetched.length >= _pageSize,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasMore: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasMore: false,
        error: e.toString(),
      );
    }
  }
}
