import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../provider/interaction_tracker_provider.dart';
import 'section_product_card.dart';
import 'section_shell.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

/// 2-up large cards with heavier typography (product_highlight_v1).
class HighlightWidget extends StatelessWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;
  const HighlightWidget({super.key, required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = section.cappedItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final cols = section.columns.clamp(1, 3);
    final rows = section.rows > 0 ? section.rows : 2;
    final displayed = items.take(cols * rows).toList();

    return SectionShell(
      section: section,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: displayed.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.55,
        ),
        itemBuilder: (_, i) {
          final item = displayed[i];
          return SectionProductCard(
            item: item,
            variant: 'highlight',
            showDiscount: section.showDiscount,
            showPriceStrikethrough: section.showPriceStrikethrough,
            onTap: () => _tap(item),
          );
        },
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
