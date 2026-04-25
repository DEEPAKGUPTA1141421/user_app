import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';
import 'section_shell.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

/// Icon grid of category tiles — category_tiles_v1.
class CategoryTilesWidget extends StatelessWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;
  const CategoryTilesWidget(
      {super.key, required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = section.cappedItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final cols = section.columns.clamp(2, 5);
    final iconSz = section.iconSize.clamp(36, 72).toDouble();
    final isCircle = section.shape != 'square';
    final itemH = iconSz + (section.showName ? 30.0 : 8.0);

    return SectionShell(
      section: section,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
          mainAxisExtent: itemH,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          final imageUrl = item.imageUrl ?? '';
          final name = item.title ?? '';

          return GestureDetector(
            onTap: () {
              final id = item.itemRefId ?? '';
              if (id.isNotEmpty) {
                onNavigate?.call('/category/$id', {});
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSz,
                  height: iconSz,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius:
                        isCircle ? null : BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: isCircle
                              ? BorderRadius.circular(iconSz)
                              : BorderRadius.circular(10),
                          child: Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _initial(name, iconSz)),
                        )
                      : _initial(name, iconSz),
                ),
                if (section.showName && name.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _initial(String name, double size) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: AppColors.white),
        ),
      );
}
