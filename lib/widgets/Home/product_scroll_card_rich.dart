import 'package:flutter/material.dart';

import '../../model/section_model.dart';

const Color _kBrand = Color(0xFFFF5200);

class ProductScrollCardRich extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const ProductScrollCardRich({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final hasImage =
        meta.imageUrl != null && !meta.imageUrl!.contains('localimage');
    final hasGradient = meta.colorType == ColorType.gradient &&
        meta.firstHalf != null &&
        meta.secondHalf != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: hasGradient ? null : meta.background,
          gradient: hasGradient
              ? LinearGradient(
                  colors: [meta.firstHalf!, meta.secondHalf!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: hasImage
                        ? Image.network(
                            meta.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (meta.showDiscount &&
                    meta.filter?.type == 'percent' &&
                    meta.filter?.discount != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kBrand,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${meta.filter!.discount}% off',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meta.showName && meta.name != null)
                    Text(
                      meta.name!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  if (meta.showDescription && meta.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (meta.showRating && meta.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meta.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (meta.ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${meta.ratingCount})',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (meta.showPrice && meta.filter?.gte != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${meta.filter!.gte!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kBrand,
                      ),
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

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
      ),
    );
  }
}

class ProductHeroCard extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const ProductHeroCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final hasImage =
        meta.imageUrl != null && !meta.imageUrl!.contains('localimage');
    final screenWidth = MediaQuery.of(context).size.width;
    final hasGradient = meta.colorType == ColorType.gradient &&
        meta.firstHalf != null &&
        meta.secondHalf != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth - 48,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: hasGradient ? null : meta.background,
          gradient: hasGradient
              ? LinearGradient(
                  colors: [meta.firstHalf!, meta.secondHalf!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 120,
                height: 120,
                child: hasImage
                    ? Image.network(
                        meta.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta.showName && meta.name != null)
                      Text(
                        meta.name!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (meta.showDescription && meta.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (meta.showPrice && meta.filter?.gte != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rs ${meta.filter!.gte!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _kBrand,
                        ),
                      ),
                    ],
                    if (meta.showDiscount && meta.filter?.discount != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${meta.filter!.discount}% off',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Icon(
          Icons.shopping_bag_outlined,
          size: 36,
          color: Colors.grey,
        ),
      );
}
