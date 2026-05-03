import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../model/shop.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ShopState {
  final List<Shop> shops;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final ShopFilter filter;
  final String query;
  final int _nextPage;

  const ShopState({
    this.shops        = const [],
    this.isLoading    = false,
    this.isLoadingMore = false,
    this.hasMore      = true,
    this.error,
    this.filter       = const ShopFilter.empty(),
    this.query        = '',
    int nextPage      = 0,
  }) : _nextPage = nextPage;

  int get nextPage => _nextPage;

  ShopState copyWith({
    List<Shop>?  shops,
    bool?        isLoading,
    bool?        isLoadingMore,
    bool?        hasMore,
    String?      error,
    ShopFilter?  filter,
    String?      query,
    int?         nextPage,
    bool         clearError = false,
  }) =>
      ShopState(
        shops:          shops          ?? this.shops,
        isLoading:      isLoading      ?? this.isLoading,
        isLoadingMore:  isLoadingMore  ?? this.isLoadingMore,
        hasMore:        hasMore        ?? this.hasMore,
        error:          clearError     ? null : error ?? this.error,
        filter:         filter         ?? this.filter,
        query:          query          ?? this.query,
        nextPage:       nextPage       ?? _nextPage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier() : super(const ShopState());

  static const int _pageSize = 20;

  Dio get _client => ApiClient.instance.productClient;

  // ── Load nearby (initial / refresh) ──────────────────────────────────────

  Future<void> loadNearby({
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(
      isLoading:   true,
      shops:       [],
      nextPage:    0,
      query:       '',
      hasMore:     true,
      clearError:  true,
    );
    try {
      final data = await _fetchNearby(lat: lat, lng: lng, page: 0);
      state = state.copyWith(
        isLoading:  false,
        shops:      data.shops,
        hasMore:    data.hasMore,
        nextPage:   1,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Load more (pagination) ────────────────────────────────────────────────

  Future<void> loadMore({
    required double lat,
    required double lng,
  }) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final isSearch = state.query.isNotEmpty;
      final data = isSearch
          ? await _fetchSearch(q: state.query, lat: lat, lng: lng, page: state.nextPage)
          : await _fetchNearby(lat: lat, lng: lng, page: state.nextPage);

      state = state.copyWith(
        isLoadingMore: false,
        shops:         [...state.shops, ...data.shops],
        hasMore:       data.hasMore,
        nextPage:      state.nextPage + 1,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error:         AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // ── Text search ───────────────────────────────────────────────────────────

  Future<void> search(
    String q, {
    required double lat,
    required double lng,
  }) async {
    if (q.trim().isEmpty) {
      return loadNearby(lat: lat, lng: lng);
    }
    state = state.copyWith(
      isLoading:  true,
      shops:      [],
      nextPage:   0,
      query:      q.trim(),
      hasMore:    true,
      clearError: true,
    );
    try {
      final data = await _fetchSearch(q: q.trim(), lat: lat, lng: lng, page: 0);
      state = state.copyWith(
        isLoading: false,
        shops:     data.shops,
        hasMore:   data.hasMore,
        nextPage:  1,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  void applyFilter(ShopFilter filter, {required double lat, required double lng}) {
    state = state.copyWith(filter: filter);
    if (state.query.isNotEmpty) {
      search(state.query, lat: lat, lng: lng);
    } else {
      loadNearby(lat: lat, lng: lng);
    }
  }

  void clearFilter({required double lat, required double lng}) =>
      applyFilter(const ShopFilter.empty(), lat: lat, lng: lng);

  // ── Suggestions (autocomplete) ────────────────────────────────────────────

  Future<List<String>> getSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) return [];
    try {
      final res = await _client.get(
        ApiEndpoints.shopsSuggest,
        queryParameters: {'q': prefix.trim()},
      );
      final body = res.data as Map<String, dynamic>;
      // Backend returns ApiResponse<List<String>> — data is the list directly
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Shop detail ───────────────────────────────────────────────────────────

  Future<ShopDetail?> getShopDetail(
    String shopId, {
    required double lat,
    required double lng,
  }) async {
    try {
      final res = await _client.get(
        ApiEndpoints.shopDetail(shopId),
        queryParameters: {'userLat': lat, 'userLng': lng},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ShopDetail.fromJson(data);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<_PageResult> _fetchNearby({
    required double lat,
    required double lng,
    required int page,
  }) async {
    final res = await _client.get(
      ApiEndpoints.shopsNearby,
      queryParameters: {
        'userLat':  lat,
        'userLng':  lng,
        'page':     page,
        'size':     _pageSize,
        ...state.filter.toQueryParams(),
      },
    );
    return _parsePageResponse(res.data);
  }

  Future<_PageResult> _fetchSearch({
    required String q,
    required double lat,
    required double lng,
    required int page,
  }) async {
    final res = await _client.get(
      ApiEndpoints.shopsSearch,
      queryParameters: {
        'q':        q,
        'userLat':  lat,
        'userLng':  lng,
        'page':     page,
        'size':     _pageSize,
        ...state.filter.toQueryParams(),
      },
    );
    return _parsePageResponse(res.data);
  }

  _PageResult _parsePageResponse(dynamic responseData) {
    final body    = responseData as Map<String, dynamic>;
    // Backend wraps in ApiResponse<Page<ShopSummaryDto>>
    // shape: { success, message, data: { content: [...], last: bool }, statusCode }
    final pageMap = (body['data'] as Map<String, dynamic>?) ?? body;
    final content = (pageMap['content'] as List<dynamic>?) ?? [];
    final isLast  = pageMap['last']  as bool? ?? true;

    final shops = content
        .whereType<Map<String, dynamic>>()
        .map(Shop.fromJson)
        .toList();

    return _PageResult(shops: shops, hasMore: !isLast);
  }
}

// ── Internal result wrapper ────────────────────────────────────────────────────

class _PageResult {
  final List<Shop> shops;
  final bool hasMore;
  const _PageResult({required this.shops, required this.hasMore});
}

// ── Provider ──────────────────────────────────────────────────────────────────

final shopPod =
    StateNotifierProvider<ShopNotifier, ShopState>((ref) => ShopNotifier());
