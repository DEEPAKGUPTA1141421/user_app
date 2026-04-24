import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

enum SimilarVariant { alsoViewed, completeLook, similarCheaper }

extension SimilarVariantX on SimilarVariant {
  String get wire {
    switch (this) {
      case SimilarVariant.alsoViewed:     return 'ALSO_VIEWED';
      case SimilarVariant.completeLook:   return 'COMPLETE_LOOK';
      case SimilarVariant.similarCheaper: return 'SIMILAR_CHEAPER';
    }
  }

  String get label {
    switch (this) {
      case SimilarVariant.alsoViewed:     return 'Customers also viewed';
      case SimilarVariant.completeLook:   return 'Complete the look';
      case SimilarVariant.similarCheaper: return 'Similar items, lower price';
    }
  }

  String get source => 'similar:$wire';
}

class SimilarItem {
  final String productId;
  final String title;
  final int pricePaise;
  final double? discountPct;
  final String? thumbnailUrl;
  final double? avgRating;
  final double? score;

  SimilarItem({
    required this.productId,
    required this.title,
    required this.pricePaise,
    this.discountPct,
    this.thumbnailUrl,
    this.avgRating,
    this.score,
  });

  double get priceRupees => pricePaise / 100.0;

  factory SimilarItem.fromJson(Map<String, dynamic> j) => SimilarItem(
        productId: j['productId'] as String,
        title: (j['title'] as String?) ?? '',
        pricePaise: (j['pricePaise'] as num?)?.toInt() ?? 0,
        discountPct: (j['discountPct'] as num?)?.toDouble(),
        thumbnailUrl: j['thumbnailUrl'] as String?,
        avgRating: (j['avgRating'] as num?)?.toDouble(),
        score: (j['score'] as num?)?.toDouble(),
      );
}

class SimilarRail {
  final SimilarVariant variant;
  final String? modelVersion;
  final List<SimilarItem> items;
  final bool isLoading;
  final String? error;

  const SimilarRail({
    required this.variant,
    this.modelVersion,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasItems => items.isNotEmpty;

  SimilarRail copyWith({
    String? modelVersion,
    List<SimilarItem>? items,
    bool? isLoading,
    String? error,
  }) =>
      SimilarRail(
        variant: variant,
        modelVersion: modelVersion ?? this.modelVersion,
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SimilarState {
  final String productId;
  final Map<SimilarVariant, SimilarRail> rails;

  const SimilarState({required this.productId, required this.rails});

  factory SimilarState.initial(String productId) => SimilarState(
        productId: productId,
        rails: {
          for (final v in SimilarVariant.values)
            v: SimilarRail(variant: v, isLoading: true),
        },
      );
}

class SimilarNotifier extends StateNotifier<SimilarState> {
  final String productId;
  SimilarNotifier(this.productId) : super(SimilarState.initial(productId)) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait(SimilarVariant.values.map(_loadVariant));
  }

  Future<void> _loadVariant(SimilarVariant variant) async {
    try {
      final res = await ApiClient.instance.productClient.get(
        ApiEndpoints.similarProducts(productId),
        queryParameters: {'variant': variant.wire, 'k': 20},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final rawItems = (data?['items'] as List?) ?? const [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(SimilarItem.fromJson)
          .toList();

      _updateRail(variant, SimilarRail(
        variant: variant,
        modelVersion: data?['modelVersion'] as String?,
        items: items,
        isLoading: false,
      ));
    } catch (e) {
      // Empty items must render silently per spec.
      _updateRail(variant, SimilarRail(variant: variant, isLoading: false));
    }
  }

  void _updateRail(SimilarVariant variant, SimilarRail next) {
    final rails = Map<SimilarVariant, SimilarRail>.from(state.rails);
    rails[variant] = next;
    state = SimilarState(productId: state.productId, rails: rails);
  }
}

final similarProvider = StateNotifierProvider.family
    .autoDispose<SimilarNotifier, SimilarState, String>(
  (ref, productId) => SimilarNotifier(productId),
);
