import 'package:flutter/foundation.dart';

/// A single product returned by the shop-scoped ES search endpoint.
///
/// Mirrors the `SearchProductDto` shape from the backend.
/// Field names follow the JSON keys: `wishlisted` and `inCart`
/// (not `isWishlisted`/`isInCart`) because Java Lombok serialises them that way.
@immutable
class ShopProduct {
  final String id;
  final String name;
  final String? brand;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final String? badge;
  final String? deliveryText;
  final bool freeDelivery;
  final String? categoryId;
  final String? categoryName;
  final String? variantId;
  final bool isWishlisted;
  final bool isInCart;

  const ShopProduct({
    required this.id,
    required this.name,
    this.brand,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.rating,
    required this.reviewCount,
    required this.images,
    this.badge,
    this.deliveryText,
    this.freeDelivery = false,
    this.categoryId,
    this.categoryName,
    this.variantId,
    this.isWishlisted = false,
    this.isInCart = false,
  });

  String get imageUrl => images.isNotEmpty ? images.first : '';

  factory ShopProduct.fromJson(Map<String, dynamic> j) => ShopProduct(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        brand: j['brand'] as String?,
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        originalPrice: (j['originalPrice'] as num?)?.toDouble(),
        discountPercent: j['discountPercent'] as int?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: j['reviewCount'] as int? ?? 0,
        images: _parseImages(j['images']),
        badge: j['badge'] as String?,
        deliveryText: j['deliveryText'] as String?,
        freeDelivery: j['freeDelivery'] as bool? ?? false,
        categoryId: j['categoryId'] as String?,
        categoryName: j['categoryName'] as String?,
        variantId: j['variantId'] as String?,
        isWishlisted: j['wishlisted'] as bool? ?? false,
        isInCart: j['inCart'] as bool? ?? false,
      );

  // Images may contain JSON-encoding artefacts (extra quotes/brackets).
  // Extract just the URL from each element.
  static final _urlPattern = RegExp(r'https?://[^\s"\\\[\]]+');

  static List<String> _parseImages(dynamic raw) {
    if (raw is! List) return const [];
    final result = <String>[];
    for (final item in raw) {
      final m = _urlPattern.firstMatch(item.toString());
      if (m != null) result.add(m.group(0)!);
    }
    return result;
  }
}

/// One page of shop-scoped product search results.
@immutable
class ShopSearchPage {
  final List<ShopProduct> products;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  /// Opaque cursor for the next page (search_after).
  /// Non-null only when [hasMore] is true.
  final String? nextCursor;

  const ShopSearchPage({
    required this.products,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.nextCursor,
  });

  factory ShopSearchPage.fromJson(Map<String, dynamic> j) {
    final rawList = j['products'] as List<dynamic>? ?? const [];
    return ShopSearchPage(
      products: rawList
          .whereType<Map<String, dynamic>>()
          .map(ShopProduct.fromJson)
          .toList(),
      totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
      page: j['page'] as int? ?? 0,
      pageSize: j['pageSize'] as int? ?? 20,
      hasMore: j['hasMore'] as bool? ?? false,
      nextCursor: j['nextCursor'] as String?,
    );
  }

  static const ShopSearchPage empty = ShopSearchPage(
    products: [],
    totalCount: 0,
    page: 0,
    pageSize: 20,
    hasMore: false,
  );
}
