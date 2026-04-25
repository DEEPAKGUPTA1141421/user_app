import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';
import 'section_shell.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

/// Logo chip row — brand_spotlight_v1.
class BrandRailWidget extends StatelessWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;
  const BrandRailWidget({super.key, required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = section.cappedItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final itemW = section.itemWidth.clamp(60.0, 120.0);
    final isCircle = section.shape != 'square';

    return SectionShell(
      section: section,
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final item = items[i];
            final imageUrl = item.imageUrl ?? '';
            final name = item.title ?? '';

            return GestureDetector(
              onTap: () {
                final id = item.itemRefId ?? '';
                if (id.isNotEmpty) {
                  onNavigate?.call('/brand/$id', {});
                }
              },
              child: SizedBox(
                width: itemW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: itemW * 0.7,
                      height: itemW * 0.7,
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
                                  ? BorderRadius.circular(itemW)
                                  : BorderRadius.circular(10),
                              child: Image.network(imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _initial(name)),
                            )
                          : _initial(name),
                    ),
                    if (section.showName && name.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _initial(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white),
        ),
      );
}
