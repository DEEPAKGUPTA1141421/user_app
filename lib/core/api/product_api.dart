import 'package:dio/dio.dart';
import '../../model/shop_product.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// API methods for product-related calls to ProductClientService.
class ProductApi {
  ProductApi._();

  static Dio get _client => ApiClient.instance.productClient;

  /// Search products scoped to a single shop.
  ///
  /// Maps to: GET /api/v1/search/results?sellerId=<shopId>&...
  ///
  /// Pass a [cancelToken] so the caller can cancel in-flight requests when a
  /// newer search fires before the previous one completes.
  ///
  /// Pass [cursor] (from a previous [ShopSearchPage.nextCursor]) to use
  /// server-side search_after pagination instead of offset — required for
  /// pages beyond the offset limit.
  static Future<ShopSearchPage> searchInShop({
    required String shopId,
    String? keyword,
    String? cursor,
    int page = 0,
    int pageSize = 20,
    String sortBy = 'rel',
    double? userLat,
    double? userLng,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{
      'sellerId': shopId,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
    };
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (cursor != null) params['cursor'] = cursor;
    if (userLat != null && userLat != 0.0) params['userLat'] = userLat;
    if (userLng != null && userLng != 0.0) params['userLng'] = userLng;

    final res = await _client.get(
      ApiEndpoints.searchResults,
      queryParameters: params,
      cancelToken: cancelToken,
    );

    final body = res.data as Map<String, dynamic>;
    // Backend wraps in ApiResponse<SearchResultsResponse>
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return ShopSearchPage.fromJson(data);
  }
}
