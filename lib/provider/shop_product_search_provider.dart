import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/product_api.dart';
import '../core/errors/app_exception.dart';
import '../model/shop_product.dart';

// ── Status enum ───────────────────────────────────────────────────────────────

enum ShopSearchStatus { idle, loading, success, empty, error }

// ── State ─────────────────────────────────────────────────────────────────────

class ShopProductSearchState {
  final String query;
  final String sortBy;
  final List<ShopProduct> items;
  final int page;
  final bool hasMore;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final ShopSearchStatus status;
  final String? error;

  const ShopProductSearchState({
    this.query = '',
    this.sortBy = 'rel',
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.status = ShopSearchStatus.idle,
    this.error,
  });

  factory ShopProductSearchState.idle() => const ShopProductSearchState();

  ShopProductSearchState copyWith({
    String? query,
    String? sortBy,
    List<ShopProduct>? items,
    int? page,
    bool? hasMore,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    ShopSearchStatus? status,
    String? error,
    bool clearError = false,
    bool clearCursor = false,
  }) =>
      ShopProductSearchState(
        query: query ?? this.query,
        sortBy: sortBy ?? this.sortBy,
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ShopProductSearchNotifier
    extends StateNotifier<ShopProductSearchState> {
  ShopProductSearchNotifier(this._shopId, this._userLat, this._userLng)
      : super(ShopProductSearchState.idle());

  final String _shopId;
  final double _userLat;
  final double _userLng;
  CancelToken? _cancelToken;

  static const int _pageSize = 20;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fire a new search for [query]. Cancels any in-flight request.
  /// Resets to idle when [query] is shorter than 3 characters.
  Future<void> setQuery(String query) async {
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
    final q = query.trim();
    if (q.length < 3) {
      state = ShopProductSearchState.idle();
      return;
    }
    state = state.copyWith(
      query: q,
      items: [],
      page: 0,
      hasMore: true,
      isLoading: true,
      status: ShopSearchStatus.loading,
      clearError: true,
      clearCursor: true,
    );
    await _fetchPage(page: 0, cursor: null, replace: true);
  }

  /// Change the sort order, reset and reload.
  Future<void> setSort(String sortBy) async {
    if (sortBy == state.sortBy) return;
    _cancelAndRefresh();
    state = state.copyWith(
      sortBy: sortBy,
      items: [],
      page: 0,
      hasMore: true,
      isLoading: true,
      status: ShopSearchStatus.loading,
      clearError: true,
      clearCursor: true,
    );
    await _fetchPage(page: 0, cursor: null, replace: true);
  }

  /// Append the next page. Uses cursor pagination when available.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetchPage(
      page: state.page + 1,
      cursor: state.nextCursor,
      replace: false,
    );
  }

  /// Retry the last failed request from the same page.
  Future<void> retry() async {
    state = state.copyWith(
      isLoading: true,
      status: ShopSearchStatus.loading,
      clearError: true,
    );
    await _fetchPage(page: state.page, cursor: state.nextCursor, replace: true);
  }

  /// Reset to initial idle state.
  void reset() {
    _cancelToken?.cancel('reset');
    state = ShopProductSearchState.idle();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _cancelAndRefresh() {
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
  }

  Future<void> _fetchPage({
    required int page,
    required String? cursor,
    required bool replace,
  }) async {
    try {
      final result = await ProductApi.searchInShop(
        shopId: _shopId,
        keyword: state.query.isEmpty ? null : state.query,
        cursor: cursor,
        page: page,
        pageSize: _pageSize,
        sortBy: state.sortBy,
        userLat: _userLat != 0.0 ? _userLat : null,
        userLng: _userLng != 0.0 ? _userLng : null,
        cancelToken: _cancelToken,
      );

      if (!mounted) return;

      final merged = replace
          ? result.products
          : [...state.items, ...result.products];

      state = state.copyWith(
        items: merged,
        page: result.page,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
        isLoading: false,
        isLoadingMore: false,
        status: merged.isEmpty ? ShopSearchStatus.empty : ShopSearchStatus.success,
        clearError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // stale request — ignore
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        status: ShopSearchStatus.error,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        status: ShopSearchStatus.error,
        error: e.toString(),
      );
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Key for the shop product search family provider.
/// Combines shopId with the user's delivery coordinates so that each
/// (shop, user-location) pair gets isolated state and ETA-enriched results.
typedef ShopSearchKey = ({String shopId, double userLat, double userLng});

/// Family provider keyed by [ShopSearchKey].
/// Each (shop, user-location) combination gets its own isolated search state.
///
/// Usage:
///   final key = (shopId: shop.id, userLat: lat, userLng: lng);
///   final searchState = ref.watch(shopProductSearchPod(key));
///   ref.read(shopProductSearchPod(key).notifier).setQuery('laptop');
final shopProductSearchPod = StateNotifierProvider.family<
    ShopProductSearchNotifier, ShopProductSearchState, ShopSearchKey>(
  (ref, key) => ShopProductSearchNotifier(key.shopId, key.userLat, key.userLng),
);
