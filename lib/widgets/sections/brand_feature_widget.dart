import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';
import 'section_shell.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

/// Landscape brand cards with tagline + CTA — brand_feature_v1.
class BrandFeatureWidget extends StatelessWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;
  const BrandFeatureWidget({super.key, required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = section.cappedItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final cardW = section.itemWidth.clamp(220.0, 320.0);
    final cardH = cardW * (9 / 16);

    return SectionShell(
      section: section,
      child: SizedBox(
        height: cardH + 10,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final item = items[i];
            final imageUrl = item.imageUrl ?? '';
            final name = item.title ?? '';
            final tagline = item.tagline ?? item.subtitle ?? '';
            final cta = item.ctaText ?? section.ctaText;

            return GestureDetector(
              onTap: () {
                final id = item.itemRefId ?? '';
                if (id.isNotEmpty) onNavigate?.call('/brand/$id', {});
              },
              child: Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      if (imageUrl.isNotEmpty)
                        Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      // Text + CTA
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            if (section.showTagline && tagline.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(tagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.grey, fontSize: 12)),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(cta,
                                  style: const TextStyle(
                                      color: AppColors.bg,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
