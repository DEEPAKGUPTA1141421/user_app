import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// ── Tap Action ────────────────────────────────────────────────────────────────
class TapAction {
  final String kind; // DEEPLINK | CATEGORY | PRODUCT | URL | SEARCH
  final String value;
  const TapAction({required this.kind, required this.value});

  factory TapAction.fromJson(Map<String, dynamic> json) => TapAction(
        kind: (json['kind'] as String? ?? 'URL').toUpperCase(),
        value: json['value'] as String? ?? '',
      );
}

// ── Embedded Product ─────────────────────────────────────────────────────────
class EmbeddedProduct {
  final String id;
  final String title;
  final double priceRupees;
  final int discountPct;
  final String thumbnailUrl;
  final double? avgRating;
  final int? ratingCount;
  final bool isBestseller;
  final bool isSponsored;

  double get originalPriceRupees => discountPct > 0
      ? priceRupees / (1 - discountPct / 100)
      : priceRupees;

  const EmbeddedProduct({
    required this.id,
    required this.title,
    required this.priceRupees,
    required this.discountPct,
    required this.thumbnailUrl,
    this.avgRating,
    this.ratingCount,
    this.isBestseller = false,
    this.isSponsored = false,
  });

  factory EmbeddedProduct.fromJson(Map<String, dynamic> json) {
    // Accept pricePaise (new API) or price/salePrice (old API)
    final pricePaise = (json['pricePaise'] as num?)?.toDouble();
    final priceRupees = pricePaise != null
        ? pricePaise / 100
        : ((json['salePrice'] ?? json['price'] ?? json['finalPrice']) as num?)
                ?.toDouble() ??
            0.0;

    final thumbnailUrl = json['thumbnailUrl'] as String? ??
        json['imageUrl'] as String? ??
        json['imageurl'] as String? ??
        json['image'] as String? ??
        '';

    return EmbeddedProduct(
      id: (json['id'] ?? json['productId'] ?? '').toString(),
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      priceRupees: priceRupees,
      discountPct: (json['discountPct'] ?? json['discount'] as num? ?? 0).toInt(),
      thumbnailUrl: thumbnailUrl,
      avgRating: (json['avgRating'] ?? json['rating'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] ?? json['reviewCount'] as num?)?.toInt(),
      isBestseller: json['isBestseller'] == true,
      isSponsored: json['isSponsored'] == true,
    );
  }
}

// ── Section Item ──────────────────────────────────────────────────────────────
class SectionItemV2 {
  final String itemType;
  final String? itemRefId;
  final EmbeddedProduct? product;
  final Map<String, dynamic> metadata;

  const SectionItemV2({
    required this.itemType,
    this.itemRefId,
    this.product,
    required this.metadata,
  });

  factory SectionItemV2.fromJson(Map<String, dynamic> json) {
    final meta = Map<String, dynamic>.from(json['metadata'] as Map? ?? {});
    EmbeddedProduct? product;
    if (json['product'] is Map) {
      try {
        product = EmbeddedProduct.fromJson(
            Map<String, dynamic>.from(json['product'] as Map));
      } catch (_) {}
    }

    return SectionItemV2(
      itemType: (json['itemType'] as String? ?? 'UNKNOWN').toUpperCase(),
      itemRefId: json['itemRefId'] as String?,
      product: product,
      metadata: meta,
    );
  }

  // ── Convenience getters ──────────────────────────────────────────────────
  String? get imageUrl =>
      metadata['imageUrl'] as String? ??
      metadata['imageurl'] as String? ??
      metadata['posterUrl'] as String? ??
      product?.thumbnailUrl;

  String? get title =>
      metadata['title'] as String? ??
      metadata['name'] as String? ??
      product?.title;

  String? get subtitle =>
      metadata['subtitle'] as String? ?? metadata['description'] as String?;

  TapAction? get tapAction {
    final ta = metadata['tapAction'];
    if (ta is Map) {
      try {
        return TapAction.fromJson(Map<String, dynamic>.from(ta));
      } catch (_) {}
    }
    return null;
  }

  String? get videoUrl => metadata['videoUrl'] as String?;
  String? get posterUrl => metadata['posterUrl'] as String?;
  String? get tagline => metadata['tagline'] as String?;
  String? get ctaText => metadata['ctaText'] as String?;
  String? get reason => metadata['reason'] as String?;
  String? get campaignId => metadata['campaignId'] as String?;
}

// ── Section Pagination ────────────────────────────────────────────────────────
class SectionPagination {
  final String? nextCursor;
  final bool hasMore;
  const SectionPagination({this.nextCursor, this.hasMore = false});

  factory SectionPagination.fromJson(Map<String, dynamic> json) =>
      SectionPagination(
        nextCursor: json['nextCursor'] as String?,
        hasMore: json['hasMore'] == true,
      );
}

// ── Section Theme ─────────────────────────────────────────────────────────────
class SectionTheme {
  final Color bg;
  final Color fg;
  final Color accent;
  final double paddingX;
  final double paddingY;
  final double cornerRadius;

  const SectionTheme({
    this.bg = AppColors.surface,
    this.fg = AppColors.white,
    this.accent = const Color(0xFFFF5200),
    this.paddingX = 16,
    this.paddingY = 12,
    this.cornerRadius = 14,
  });

  factory SectionTheme.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SectionTheme();
    final padding = json['padding'] as Map?;
    return SectionTheme(
      bg: _parseColor(json['bg'] as String?) ?? AppColors.surface,
      fg: _parseColor(json['fg'] as String?) ?? AppColors.white,
      accent: _parseColor(json['accent'] as String?) ?? const Color(0xFFFF5200),
      paddingX: (padding?['x'] as num?)?.toDouble() ?? 16,
      paddingY: (padding?['y'] as num?)?.toDouble() ?? 12,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 14,
    );
  }

  static Color? _parseColor(String? v) {
    if (v == null || v.isEmpty) return null;
    final s = v.trim();
    if (s.startsWith('#') && s.length == 7) {
      return Color(int.parse('FF${s.substring(1)}', radix: 16));
    }
    return null;
  }
}

// ── Section V2 ────────────────────────────────────────────────────────────────
class SectionV2 {
  final String id;
  final String title;
  final String widgetKey;
  final String dataKind;
  final String dataSource;
  final int position;
  final bool active;
  final Map<String, dynamic> config;
  final List<SectionItemV2> items;
  final SectionPagination? pagination;

  const SectionV2({
    required this.id,
    required this.title,
    required this.widgetKey,
    required this.dataKind,
    required this.dataSource,
    required this.position,
    required this.active,
    required this.config,
    required this.items,
    this.pagination,
  });

  factory SectionV2.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List? ?? [])
        .map((e) => SectionItemV2.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    SectionPagination? pagination;
    if (json['pagination'] is Map) {
      pagination = SectionPagination.fromJson(
          Map<String, dynamic>.from(json['pagination'] as Map));
    }

    return SectionV2(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      widgetKey: json['widgetKey'] as String? ?? '',
      dataKind: (json['dataKind'] as String? ?? 'UNKNOWN').toUpperCase(),
      dataSource: (json['dataSource'] as String? ?? 'STATIC').toUpperCase(),
      position: (json['position'] as num?)?.toInt() ?? 0,
      active: json['active'] != false, // default true
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
      items: itemsList,
      pagination: pagination,
    );
  }

  // ── Config helpers ──────────────────────────────────────────────────────
  int get columns => (config['columns'] as num?)?.toInt() ?? 3;
  int get rows => (config['rows'] as num?)?.toInt() ?? 2;
  String get cardVariant => config['cardVariant'] as String? ?? 'standard';
  bool get showDiscount => config['showDiscount'] as bool? ?? true;
  bool get showRating => config['showRating'] as bool? ?? false;
  bool get showBadge => config['showBadge'] as bool? ?? true;
  double get itemWidth => (config['itemWidth'] as num?)?.toDouble() ?? 140;
  bool get peekNext => config['peekNext'] as bool? ?? true;
  double get bannerHeight => (config['height'] as num?)?.toDouble() ?? 180;
  bool get autoplay => config['autoplay'] as bool? ?? true;
  int get loopMs => (config['loopMs'] as num?)?.toInt() ?? 4000;
  String get shape => config['shape'] as String? ?? 'circle';
  bool get showName => config['showName'] as bool? ?? true;
  bool get showTagline => config['showTagline'] as bool? ?? false;
  String get ctaText => config['ctaText'] as String? ?? 'View';
  int get maxItems => (config['maxItems'] as num?)?.toInt() ?? 20;
  int get iconSize => (config['iconSize'] as num?)?.toInt() ?? 56;
  bool get showPriceStrikethrough =>
      config['showPriceStrikethrough'] as bool? ?? true;

  SectionTheme get theme =>
      SectionTheme.fromJson(config['theme'] as Map<String, dynamic>?);

  List<SectionItemV2> get cappedItems =>
      maxItems > 0 ? items.take(maxItems).toList() : items;
}
