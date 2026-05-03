import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/interaction_tracker_provider.dart';
import '../../provider/similarity_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';

/// Renders the three "similar products" rails on the PDP.
///
/// - Fires all three variant requests in parallel (via [similarProvider])
/// - Hides a rail entirely when it has no items
/// - Attributes clicks via `source: "similar:<variant>"`
class SimilarRailsSection extends ConsumerWidget {
  final String productId;
  const SimilarRailsSection({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(similarProvider(productId));

    final rails = SimilarVariant.values
        .map((v) => state.rails[v])
        .whereType<SimilarRail>()
        .where((r) => r.isLoading || r.hasItems)
        .toList();

    if (rails.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rail in rails) _RailSection(rail: rail),
      ],
    );
  }
}

class _RailSection extends ConsumerWidget {
  final SimilarRail rail;
  const _RailSection({required this.rail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rail.isLoading) {
      return _RailScaffold(
        title: rail.variant.label,
        child: const SizedBox(
          height: 200,
          child: Center(child: AppSpinner(size: 22)),
        ),
      );
    }
    if (!rail.hasItems) return const SizedBox.shrink();

    return _RailScaffold(
      title: rail.variant.label,
      child: SizedBox(
        height: 232,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: rail.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final item = rail.items[i];
            return _SimilarCard(
              item: item,
              onTap: () {
                ref.read(interactionBufferProvider).trackNow(
                      productId: item.productId,
                      type: InteractionType.click,
                      context: InteractionContext.pdp,
                      source: rail.variant.source,
                    );
                Navigator.pushNamed(
                    context, '/productDetail/${item.productId}');
              },
            );
          },
        ),
      ),
    );
  }
}

class _RailScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _RailScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4)),
          ),
          child,
        ],
      ),
    );
  }
}

class _SimilarCard extends StatelessWidget {
  final SimilarItem item;
  final VoidCallback onTap;
  const _SimilarCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: AppColors.surface2,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.greyDark)))
                    : Container(color: AppColors.surface2),
              ),
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
                  Row(
                    children: [
                      Text('₹${item.priceRupees.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      if (item.discountPct != null) ...[
                        const SizedBox(width: 6),
                        Text('${item.discountPct!.toStringAsFixed(0)}% off',
                            style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  if (item.avgRating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(item.avgRating!.toStringAsFixed(1),
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 10)),
                      ],
                    ),
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
