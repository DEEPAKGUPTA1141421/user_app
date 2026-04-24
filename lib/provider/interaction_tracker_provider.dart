import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

enum InteractionType {
  view,
  click,
  addToCart,
  removeFromCart,
  wishlist,
  share,
  beginCheckout,
  purchasePrepaid,
  purchaseCod,
  cancel,
  returnItem,
}

extension InteractionTypeX on InteractionType {
  String get wire {
    switch (this) {
      case InteractionType.view:            return 'VIEW';
      case InteractionType.click:           return 'CLICK';
      case InteractionType.addToCart:       return 'ADD_TO_CART';
      case InteractionType.removeFromCart:  return 'REMOVE_FROM_CART';
      case InteractionType.wishlist:        return 'WISHLIST';
      case InteractionType.share:           return 'SHARE';
      case InteractionType.beginCheckout:   return 'BEGIN_CHECKOUT';
      case InteractionType.purchasePrepaid: return 'PURCHASE_PREPAID';
      case InteractionType.purchaseCod:     return 'PURCHASE_COD';
      case InteractionType.cancel:          return 'CANCEL';
      case InteractionType.returnItem:      return 'RETURN';
    }
  }
}

enum InteractionContext { home, pdp, cart, search, category }

extension InteractionContextX on InteractionContext {
  String get wire {
    switch (this) {
      case InteractionContext.home:     return 'HOME';
      case InteractionContext.pdp:      return 'PDP';
      case InteractionContext.cart:     return 'CART';
      case InteractionContext.search:   return 'SEARCH';
      case InteractionContext.category: return 'CATEGORY';
    }
  }
}

class InteractionEvent {
  final String productId;
  final InteractionType type;
  final InteractionContext? context;
  final String? source;
  final int? dwellMs;
  final String ts;

  InteractionEvent({
    required this.productId,
    required this.type,
    this.context,
    this.source,
    this.dwellMs,
    String? ts,
  }) : ts = ts ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'type': type.wire,
        if (context != null) 'context': context!.wire,
        if (source != null) 'source': source,
        if (dwellMs != null) 'dwellMs': dwellMs,
        'ts': ts,
      };
}

/// Simple UUID v4 — avoids pulling a new dependency.
String _uuidV4() {
  final r = Random.secure();
  String hex(int bytes) {
    final buf = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buf.write(r.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  final h = hex(16);
  final b6 = (int.parse(h.substring(12, 14), radix: 16) & 0x0f | 0x40).toRadixString(16).padLeft(2, '0');
  final b8 = (int.parse(h.substring(16, 18), radix: 16) & 0x3f | 0x80).toRadixString(16).padLeft(2, '0');
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-$b6${h.substring(14, 16)}-$b8${h.substring(18, 20)}-${h.substring(20, 32)}';
}

class InteractionBuffer with WidgetsBindingObserver {
  InteractionBuffer._() {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  static final InteractionBuffer instance = InteractionBuffer._();

  // Flush cadence — periodic only. No immediate-on-full flush, so a burst
  // of events during a single frame cannot trigger multiple network calls.
  static const Duration _flushInterval = Duration(seconds: 10);
  // Minimum wall-clock gap between two successful POSTs. Protects the
  // backend from back-to-back calls even if lifecycle events coincide with
  // a timer tick.
  static const Duration _minGap = Duration(seconds: 8);
  static const int _maxBatch = 20;
  static const int _maxQueue = 200;

  final String sessionId = _uuidV4();
  final List<InteractionEvent> _queue = [];
  Timer? _timer;
  bool _flushing = false;
  DateTime _lastFlush = DateTime.fromMillisecondsSinceEpoch(0);

  /// Last rendered `recoId` from For-You. Used as the default attribution
  /// source for events originating on the home feed.
  String? currentRecoId;

  void track(InteractionEvent event) {
    _queue.add(event);
    if (_queue.length > _maxQueue) {
      _queue.removeRange(0, _queue.length - _maxQueue);
    }
    if (kDebugMode) {
      debugPrint(
          '[tracker] queued ${event.type.wire} · ${event.context?.wire ?? '-'} · ${event.productId}  (queue=${_queue.length})');
    }
  }

  void trackNow({
    required String productId,
    required InteractionType type,
    InteractionContext? context,
    String? source,
    int? dwellMs,
  }) {
    track(InteractionEvent(
      productId: productId,
      type: type,
      context: context,
      source: source,
      dwellMs: dwellMs,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flush();
    }
  }

  Future<void> _flush() async {
    if (_flushing || _queue.isEmpty) return;
    if (DateTime.now().difference(_lastFlush) < _minGap) return;
    _flushing = true;
    final batch = _queue.take(_maxBatch).toList();
    if (kDebugMode) {
      final summary = <String, int>{};
      for (final e in batch) {
        final k = '${e.type.wire}/${e.context?.wire ?? '-'}';
        summary[k] = (summary[k] ?? 0) + 1;
      }
      debugPrint('[tracker] flushing ${batch.length} events → $summary');
    }
    try {
      await ApiClient.instance.productClient.post(
        ApiEndpoints.trackInteraction,
        data: {
          'sessionId': sessionId,
          'events': batch.map((e) => e.toJson()).toList(),
        },
      );
      _queue.removeRange(0, batch.length);
      _lastFlush = DateTime.now();
    } catch (_) {
      // Fire-and-forget: keep the queue intact (up to max) and retry on next tick.
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

final interactionBufferProvider = Provider<InteractionBuffer>((ref) {
  return InteractionBuffer.instance;
});
