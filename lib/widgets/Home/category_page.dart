// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../provider/category_sections.dart';
// import '../../provider/banner_provider.dart';
// import '../responsive_banner_carousel.dart';
// import './section_wrapper.dart';
// import './product_card.dart';

// class CategoryPage extends ConsumerStatefulWidget {
//   final String? categoryId;
//   const CategoryPage({super.key, required this.categoryId});

//   @override
//   ConsumerState<CategoryPage> createState() => _CategoryPageState();
// }

// class _CategoryPageState extends ConsumerState<CategoryPage> {
//   static const String _never = '__NEVER__';
//   String _lastKey = _never;

//   // @override
//   void initState() {
//     super.initState();
//     // ✅ Future() with no delay runs after the current build frame is fully
//     //    committed — safe to modify providers here, avoids the
//     //    "modified provider while building" error.
//     Future(() {
//       if (mounted) _triggerFetch(widget.categoryId);
//     });
//   }

//   @override
//   void didUpdateWidget(CategoryPage oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.categoryId != widget.categoryId) {
//       // ✅ Same pattern for didUpdateWidget — defer past current build
//       Future(() {
//         if (mounted) _triggerFetch(widget.categoryId);
//       });
//     }
//   }

//   void _triggerFetch(String? categoryId) {
//     final key = categoryId ?? '__NULL__';
//     if (_lastKey == key) return;
//     _lastKey = key;

//     debugPrint('🔄 CategoryPage._triggerFetch → categoryId=$categoryId');

//     // 1. Sections
//     ref
//         .read(categorySectionsProvider.notifier)
//         .fetchSectionsOfCategory(categoryId: categoryId);

//     // 2. Banners — clear first, then fetch
//     ref.read(bannerProvider.notifier).clearBanners();
//     if (categoryId != null && categoryId.isNotEmpty) {
//       ref.read(bannerProvider.notifier).fetchBannersByCategory(categoryId);
//     }

//     // 3. Brands
//     final brandsId = (categoryId != null && categoryId.isNotEmpty)
//         ? categoryId
//         : '5d70fc95-8a6b-4d04-95e9-9620269ab15e';
//     ref.read(categorySectionsProvider.notifier).fetchBrands(brandsId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state       = ref.watch(categorySectionsProvider);
//     final bannerState = ref.watch(bannerProvider);

//     final sectionsLoading = state['sectionsLoading'] as bool? ?? false;
//     final brandsLoading   = state['brandsLoading']   as bool? ?? false;
//     final sectionsData    = state['sectionsData']     as List<dynamic>? ?? [];
//     final brands          = state['brands']           as List<dynamic>? ?? [];
//     final bannerIsLoading = bannerState['isLoading']  as bool? ?? false;
//     final banners         = bannerState['banners']    as List<dynamic>? ?? [];

//     // Show loader only on the very first load when there's nothing to show yet
//     if (sectionsLoading && sectionsData.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 32),
//         child: Center(
//           child: CircularProgressIndicator(color: Color(0xFFFF5200)),
//         ),
//       );
//     }

//     if (sectionsData.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: sectionsData.map<Widget>((section) {
//         final type  = (section['type']  ?? '').toString().toUpperCase();
//         final title = (section['title'] ?? '').toString();
//         final items = (section['items'] ?? []) as List<dynamic>;

//         switch (type) {

//           case 'BANNER':
//             if (bannerIsLoading) return _shimmerBanner();
//             if (banners.isEmpty) return const SizedBox.shrink();
//             return ResponsiveBannerCarousel(
//               banners: banners,
//               categoryId: widget.categoryId ?? '',
//             );

//           case 'BRAND':
//             if (brandsLoading && brands.isEmpty) return _shimmerSection(title);
//             if (brands.isEmpty) return const SizedBox.shrink();
//             return SectionWrapper(
//               title: title,
//               variant: SectionVariant.primary,
//               hasArrow: false,
//               child: SizedBox(
//                 height: 160,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: brands.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 8),
//                   itemBuilder: (_, i) => ProductCard(
//                     product: brands[i]['metadata'] ?? brands[i],
//                     showDiscount: false,
//                     section: section,
//                   ),
//                 ),
//               ),
//             );

//           case 'SPONSORED':
//           case 'PRODUCT_SCROLL':
//           case 'PRODUCT_GRID':
//           case 'CATEGORY':
//             if (items.isEmpty) return const SizedBox.shrink();
//             return SectionWrapper(
//               title: title,
//               variant: SectionVariant.primary,
//               hasArrow: false,
//               child: SizedBox(
//                 height: 160,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: items.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 8),
//                   itemBuilder: (_, i) => ProductCard(
//                     product: items[i]['metadata'] ?? {},
//                     showDiscount: true,
//                     section: section,
//                   ),
//                 ),
//               ),
//             );

//           default:
//             return const SizedBox.shrink();
//         }
//       }).toList(),
//     );
//   }

//   Widget _shimmerBanner() {
//     return Container(
//       height: 200,
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade300,
//         borderRadius: BorderRadius.circular(12),
//       ),
//     );
//   }

//   Widget _shimmerSection(String title) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.deepPurple,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white)),
//           const SizedBox(height: 8),
//           SizedBox(
//             height: 100,
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: 5,
//               separatorBuilder: (_, __) => const SizedBox(width: 8),
//               itemBuilder: (_, __) => Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   color: Colors.white24,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/widgets/Home/category_page.dart
// DROP-IN REPLACEMENT — works with your existing categorySectionsProvider + bannerProvider.
//
// Key differences from old file:
//  • Sections from the backend are parsed into the new Section model
//  • SectionWidget factory picks the right layout per type
//  • _navigate() handles PRODUCT, CATEGORY, BRAND, BANNER routing
//  • Shimmer loading keeps existing UX

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_sections.dart';
import '../../provider/banner_provider.dart';
import '../responsive_banner_carousel.dart';
import '../../model/section_model.dart';
import './section_widget.dart';

class CategoryPage extends ConsumerStatefulWidget {
  final String? categoryId;
  const CategoryPage({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  static const String _never = '__NEVER__';
  String _lastKey = _never;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFetch(widget.categoryId);
    });
  }

  @override
  void didUpdateWidget(CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _triggerFetch(widget.categoryId);
    }
  }

  void _triggerFetch(String? categoryId) {
    final key = categoryId ?? '__NULL__';
    if (_lastKey == key) return;
    _lastKey = key;

    ref
        .read(categorySectionsProvider.notifier)
        .fetchSectionsOfCategory(categoryId: categoryId);

    ref.read(bannerProvider.notifier).clearBanners();
    if (categoryId != null && categoryId.isNotEmpty) {
      ref.read(bannerProvider.notifier).fetchBannersByCategory(categoryId);
    }

    final brandsId = (categoryId != null && categoryId.isNotEmpty)
        ? categoryId
        : '5d70fc95-8a6b-4d04-95e9-9620269ab15e';
    ref.read(categorySectionsProvider.notifier).fetchBrands(brandsId);
  }

  void _navigate(String route, Map<String, String> params) {
    // Build query string if params present
    final uri = Uri(path: route, queryParameters: params.isEmpty ? null : params);
    Navigator.pushNamed(context, uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final bannerState = ref.watch(bannerProvider);

    final sectionsLoading = state['sectionsLoading'] as bool? ?? false;
    final rawSections = state['sectionsData'] as List<dynamic>? ?? [];
    final bannerIsLoading = bannerState['isLoading'] as bool? ?? false;
    final banners = bannerState['banners'] as List<dynamic>? ?? [];

    // Parse sections via Section model
    final List<Section> sections = rawSections.map((e) {
      try {
        return Section.fromJson(Map<String, dynamic>.from(e));
      } catch (_) {
        return null;
      }
    }).whereType<Section>().where((s) => s.active).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    if (sectionsLoading && sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF5200))),
      );
    }

    if (sections.isEmpty && !sectionsLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner carousel (if exists) ────────────────────────────────────
        if (bannerIsLoading)
          _ShimmerBanner()
        else if (banners.isNotEmpty)
          ResponsiveBannerCarousel(
            banners: banners,
            categoryId: widget.categoryId ?? '',
          ),

        // ── Dynamic sections ───────────────────────────────────────────────
        ...sections.map<Widget>((section) {
          return SectionWidget(section: section, onNavigate: _navigate);
        }),
      ],
    );
  }
}

class _ShimmerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}