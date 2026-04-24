import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/interaction_tracker_provider.dart';
import '../../provider/recommendations_provider.dart';
import '../../utils/app_colors.dart';

/// Home-feed "For You" rail. Fetches personalised recommendations
/// and attributes downstream clicks via `source: "reco:<recoId>"`.
class ForYouRail extends ConsumerStatefulWidget {
  const ForYouRail({super.key});

  @override
  ConsumerState<ForYouRail> createState() => _ForYouRailState();
}

class _ForYouRailState extends ConsumerState<ForYouRail> {
  static const double _cardWidth = 150;
  static const double _gap = 10;
  static const double _hPad = 14;
  static const Duration _dwell = Duration(milliseconds: 2500);

  final ScrollController _scroll = ScrollController();
  final Set<String> _viewed = {};
  Timer? _dwellTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(recommendationsProvider.notifier).load());
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() => _scheduleVisibilityCheck();

  void _scheduleVisibilityCheck() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(_dwell, _flushVisibleViews);
  }

  void _flushVisibleViews() {
    if (!mounted || !_scroll.hasClients) return;
    final state = ref.read(recommendationsProvider);
    if (state.items.isEmpty) return;

    final offset = _scroll.offset;
    final viewport = _scroll.position.viewportDimension;
    final itemStride = _cardWidth + _gap;

    // Indices whose centers are within the viewport.
    final firstVisible =
        ((offset - _hPad) / itemStride).floor().clamp(0, state.items.length - 1);
    final lastVisible = ((offset + viewport - _hPad) / itemStride)
        .ceil()
        .clamp(0, state.items.length - 1);

    final tracker = ref.read(interactionBufferProvider);
    for (var i = firstVisible; i <= lastVisible; i++) {
      final item = state.items[i];
      if (_viewed.add(item.productId)) {
        tracker.trackNow(
          productId: item.productId,
          type: InteractionType.view,
          context: InteractionContext.home,
          source: state.attributionSource,
          dwellMs: _dwell.inMilliseconds,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsProvider);

    // Spec: never treat empty items as error. Hide silently.
    if (!state.isLoading && state.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Kick off a visibility check once items land, so the first
    // on-screen cards generate VIEW events after the dwell window.
    if (state.items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleVisibilityCheck();
      });
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                const Text('FOR YOU',
                    style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4)),
                if (state.coldStart) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('TRENDING',
                        style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 246,
            child: state.isLoading && state.items.isEmpty
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2),
                    ),
                  )
                : ListView.separated(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: _gap),
                    itemBuilder: (_, i) {
                      final item = state.items[i];
                      return _RecoCard(
                        item: item,
                        onTap: () {
                          ref.read(interactionBufferProvider).trackNow(
                                productId: item.productId,
                                type: InteractionType.click,
                                context: InteractionContext.home,
                                source: state.attributionSource,
                              );
                          Navigator.pushNamed(
                              context, '/productDetail/${item.productId}');
                        },
                        onDismiss: () => ref
                            .read(recommendationsProvider.notifier)
                            .sendFeedback(item.productId, 'NOT_INTERESTED'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecoCard extends StatelessWidget {
  final RecoItem item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _RecoCard({
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: item.thumbnailUrl != null
                        ? Image.network(item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surface2))
                        : Container(color: AppColors.surface2),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: AppColors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3)),
                  const SizedBox(height: 6),
                  Text('₹${item.priceRupees.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  if (item.reason != null && item.reason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.reason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
