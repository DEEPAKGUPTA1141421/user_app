import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import 'interaction_tracker_provider.dart';

class RecoItem {
  final String productId;
  final String title;
  final int pricePaise;
  final double? discountPct;
  final String? thumbnailUrl;
  final double? avgRating;
  final String? reason;

  RecoItem({
    required this.productId,
    required this.title,
    required this.pricePaise,
    this.discountPct,
    this.thumbnailUrl,
    this.avgRating,
    this.reason,
  });

  double get priceRupees => pricePaise / 100.0;

  factory RecoItem.fromJson(Map<String, dynamic> j) => RecoItem(
        productId: j['productId'] as String,
        title: (j['title'] as String?) ?? '',
        pricePaise: (j['pricePaise'] as num?)?.toInt() ?? 0,
        discountPct: (j['discountPct'] as num?)?.toDouble(),
        thumbnailUrl: j['thumbnailUrl'] as String?,
        avgRating: (j['avgRating'] as num?)?.toDouble(),
        reason: j['reason'] as String?,
      );
}

class RecoState {
  final bool isLoading;
  final String? error;
  final String? recoId;
  final String? modelVersion;
  final String? experimentVariant;
  final bool coldStart;
  final List<RecoItem> items;

  const RecoState({
    this.isLoading = false,
    this.error,
    this.recoId,
    this.modelVersion,
    this.experimentVariant,
    this.coldStart = false,
    this.items = const [],
  });

  /// `source` string to attach to tracking events for clicks/views that
  /// originated from this reco list.
  String? get attributionSource =>
      recoId == null ? null : 'reco:$recoId';

  RecoState copyWith({
    bool? isLoading,
    String? error,
    String? recoId,
    String? modelVersion,
    String? experimentVariant,
    bool? coldStart,
    List<RecoItem>? items,
  }) =>
      RecoState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        recoId: recoId ?? this.recoId,
        modelVersion: modelVersion ?? this.modelVersion,
        experimentVariant: experimentVariant ?? this.experimentVariant,
        coldStart: coldStart ?? this.coldStart,
        items: items ?? this.items,
      );
}

class RecoNotifier extends StateNotifier<RecoState> {
  RecoNotifier(this._ref) : super(const RecoState());

  final Ref _ref;

  Future<void> load({String context = 'HOME', int k = 20}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.productClient.get(
        ApiEndpoints.recoForYou,
        queryParameters: {'context': context, 'k': k},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final rawItems = (data?['items'] as List?) ?? const [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(RecoItem.fromJson)
          .toList();

      final recoId = data?['recoId'] as String?;

      state = RecoState(
        isLoading: false,
        recoId: recoId,
        modelVersion: data?['modelVersion'] as String?,
        experimentVariant: data?['experimentVariant'] as String?,
        coldStart: data?['coldStart'] == true,
        items: items,
      );

      // Remember recoId on the tracker so background events (e.g. scroll
      // VIEWs on Home) automatically carry the correct attribution.
      _ref.read(interactionBufferProvider).currentRecoId = recoId;
    } catch (e) {
      // Degraded / empty. Keep items silent per spec.
      state = const RecoState(isLoading: false);
    }
  }

  /// Fire-and-forget dismiss/like feedback from the home rail.
  Future<void> sendFeedback(String productId, String action) async {
    final recoId = state.recoId;
    if (recoId == null) return;
    try {
      await ApiClient.instance.productClient.post(
        ApiEndpoints.recoFeedback,
        data: {'recoId': recoId, 'productId': productId, 'action': action},
      );
      if (action == 'DISMISS' || action == 'NOT_INTERESTED') {
        state = state.copyWith(
          items: state.items.where((i) => i.productId != productId).toList(),
        );
      }
    } catch (_) {}
  }
}

final recommendationsProvider =
    StateNotifierProvider<RecoNotifier, RecoState>((ref) => RecoNotifier(ref));
