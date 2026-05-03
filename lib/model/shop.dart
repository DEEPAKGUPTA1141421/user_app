import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ShopSortBy {
  distance,
  rating,
  deliveryTime,
  newest;

  String get label => switch (this) {
        ShopSortBy.distance     => 'Distance',
        ShopSortBy.rating       => 'Top Rated',
        ShopSortBy.deliveryTime => 'Fastest Delivery',
        ShopSortBy.newest       => 'Newest',
      };

  String get apiValue => switch (this) {
        ShopSortBy.distance     => 'DISTANCE',
        ShopSortBy.rating       => 'RATING',
        ShopSortBy.deliveryTime => 'DELIVERY_TIME',
        ShopSortBy.newest       => 'NEWEST',
      };
}

// ── Shop (summary) ────────────────────────────────────────────────────────────

class Shop {
  final String id;
  final String displayName;
  final String? logoUrl;
  final List<String> images;
  final String city;
  final double avgRating;
  final int reviewCount;
  final String deliveryEtaLabel; // "45 mins" | "Tomorrow" | "2–3 days"
  final double distanceKm;
  final bool isOpen;
  final String? categoryName;
  final String? categoryId;

  const Shop({
    required this.id,
    required this.displayName,
    this.logoUrl,
    this.images = const [],
    required this.city,
    required this.avgRating,
    required this.reviewCount,
    required this.deliveryEtaLabel,
    required this.distanceKm,
    required this.isOpen,
    this.categoryName,
    this.categoryId,
  });

  factory Shop.fromJson(Map<String, dynamic> j) {
    // logoUrl can be a plain String, a List<dynamic>, or null
    final rawLogo = j['logoUrl'];
    final List<String> logoImages = switch (rawLogo) {
      String s when s.isNotEmpty => [s],
      List l => l.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
      _ => const [],
    };

    // Merge any explicit `images` array too
    final rawImages = j['images'];
    final List<String> extraImages = rawImages is List
        ? rawImages.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const [];

    final allImages = [...logoImages, ...extraImages
        .where((u) => !logoImages.contains(u))];

    return Shop(
      id:               j['shopId']           as String,
      displayName:      j['displayName']       as String,
      logoUrl:          allImages.isNotEmpty ? allImages.first : null,
      images:           allImages,
      city:             j['city']              as String? ?? '',
      avgRating:        (j['avgRating']        as num?)?.toDouble() ?? 0.0,
      reviewCount:      (j['reviewCount']      as int?)             ?? 0,
      deliveryEtaLabel: j['deliveryEtaLabel']  as String? ?? '—',
      distanceKm:       (j['distanceKm']       as num?)?.toDouble() ?? 0.0,
      isOpen:           j['isOpen']            as bool?             ?? true,
      categoryName:     j['categoryName']      as String?,
      categoryId:       j['categoryId']        as String?,
    );
  }

  /// First letter of display name — used as avatar fallback.
  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  /// Formatted distance string.
  String get distanceLabel =>
      distanceKm < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km';
}

// ── ShopDetail (full, used on detail screen) ──────────────────────────────────

class ShopDetail extends Shop {
  final String? description;
  final String? address;
  final String? openHours;
  final int totalProducts;

  const ShopDetail({
    required super.id,
    required super.displayName,
    super.logoUrl,
    super.images = const [],
    required super.city,
    required super.avgRating,
    required super.reviewCount,
    required super.deliveryEtaLabel,
    required super.distanceKm,
    required super.isOpen,
    super.categoryName,
    super.categoryId,
    this.description,
    this.address,
    this.openHours,
    this.totalProducts = 0,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> j) {
    final rawLogo = j['logoUrl'];
    final List<String> logoImages = switch (rawLogo) {
      String s when s.isNotEmpty => [s],
      List l => l.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
      _ => const [],
    };

    final rawImages = j['images'];
    final List<String> extraImages = rawImages is List
        ? rawImages.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const [];

    final allImages = [...logoImages, ...extraImages
        .where((u) => !logoImages.contains(u))];

    return ShopDetail(
      id:               j['shopId']           as String,
      displayName:      j['displayName']       as String,
      logoUrl:          allImages.isNotEmpty ? allImages.first : null,
      images:           allImages,
      city:             j['city']              as String? ?? '',
      avgRating:        (j['avgRating']        as num?)?.toDouble() ?? 0.0,
      reviewCount:      (j['reviewCount']      as int?)             ?? 0,
      deliveryEtaLabel: j['deliveryEtaLabel']  as String? ?? '—',
      distanceKm:       (j['distanceKm']       as num?)?.toDouble() ?? 0.0,
      isOpen:           j['isOpen']            as bool?             ?? true,
      categoryName:     j['categoryName']      as String?,
      categoryId:       j['categoryId']        as String?,
      description:      j['description']       as String?,
      address:          j['address']           as String?,
      openHours:        j['openHours']         as String?,
      totalProducts:    (j['totalProducts']    as int?)             ?? 0,
    );
  }
}

// ── ShopFilter ────────────────────────────────────────────────────────────────

class ShopFilter {
  final String? categoryId;
  final String? categoryName; // kept for chip label display
  final double? minRating;
  final int? maxDeliveryMinutes;
  final ShopSortBy sortBy;

  const ShopFilter({
    this.categoryId,
    this.categoryName,
    this.minRating,
    this.maxDeliveryMinutes,
    this.sortBy = ShopSortBy.distance,
  });

  bool get isActive =>
      categoryId != null ||
      minRating != null ||
      maxDeliveryMinutes != null ||
      sortBy != ShopSortBy.distance;

  ShopFilter copyWith({
    String? categoryId,
    String? categoryName,
    double? minRating,
    int? maxDeliveryMinutes,
    ShopSortBy? sortBy,
    bool clearCategory       = false,
    bool clearRating         = false,
    bool clearDelivery       = false,
  }) =>
      ShopFilter(
        categoryId:          clearCategory  ? null : categoryId          ?? this.categoryId,
        categoryName:        clearCategory  ? null : categoryName         ?? this.categoryName,
        minRating:           clearRating    ? null : minRating            ?? this.minRating,
        maxDeliveryMinutes:  clearDelivery  ? null : maxDeliveryMinutes   ?? this.maxDeliveryMinutes,
        sortBy:              sortBy                                        ?? this.sortBy,
      );

  const ShopFilter.empty()
      : categoryId          = null,
        categoryName        = null,
        minRating           = null,
        maxDeliveryMinutes  = null,
        sortBy              = ShopSortBy.distance;

  Map<String, dynamic> toQueryParams() => {
        if (categoryId != null)         'category':            categoryId,
        if (minRating != null)          'minRating':           minRating,
        if (maxDeliveryMinutes != null) 'maxDeliveryMinutes':  maxDeliveryMinutes,
        'sortBy':                        sortBy.apiValue,
      };

  // ── Rating chip helpers ────────────────────────────────────────────────────

  static const List<double?> ratingOptions = [null, 3.0, 4.0, 4.5];

  String ratingLabel(double? v) => v == null ? 'Any' : '${v.toStringAsFixed(1)}+';

  // ── Delivery chip helpers ──────────────────────────────────────────────────

  static const List<int?> deliveryOptions = [null, 60, 120, 1440];

  String deliveryLabel(int? minutes) => switch (minutes) {
        null => 'Any',
        60   => '< 1 hr',
        120  => '< 2 hrs',
        1440 => '< 1 day',
        _    => '< ${minutes}m',
      };

  // ── Chip color helpers (dark theme) ───────────────────────────────────────

  Color chipBackground(bool active) =>
      active ? AppColors.white : AppColors.surface2;

  Color chipForeground(bool active) =>
      active ? AppColors.bg : AppColors.grey;
}
