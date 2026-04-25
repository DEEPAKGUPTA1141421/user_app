import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../provider/interaction_tracker_provider.dart';
import 'section_product_card.dart';
import 'section_shell.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

class RailWidget extends StatelessWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;
  const RailWidget({super.key, required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = section.cappedItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final itemW = section.itemWidth.clamp(100.0, 220.0);
    // Peek: show ~10% of next card by making list overflow
    final peek = section.peekNext ? 12.0 : 0.0;

    return SectionShell(
      section: section,
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(12, 0, 12 - peek, 0),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final item = items[i];
            return SectionProductCard(
              item: item,
              variant: 'compact',
              width: itemW,
              showDiscount: section.showDiscount,
              onTap: () => _tap(item),
            );
          },
        ),
      ),
    );
  }

  void _tap(SectionItemV2 item) {
    final id = item.itemRefId ?? item.product?.id ?? '';
    if (id.isNotEmpty) {
      InteractionBuffer.instance.trackNow(
        productId: id,
        type: InteractionType.click,
        context: InteractionContext.home,
      );
      onNavigate?.call('/productDetail/$id', {});
    }
  }
}
