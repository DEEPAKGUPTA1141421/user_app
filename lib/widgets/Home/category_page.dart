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
    // ✅ Always defer past the current build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerFetch(widget.categoryId);
    });
  }

  @override
  void didUpdateWidget(CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      // ✅ Defer — didUpdateWidget is called inside the build pipeline;
      //    mutating a StateNotifier here causes the crash shown in the screenshot.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerFetch(widget.categoryId);
      });
    }
  }

  void _triggerFetch(String? categoryId) {
    final key = categoryId ?? '__NULL__';
    // Guard: skip if we already fetched for this key
    if (_lastKey == key) return;
    _lastKey = key;

    debugPrint('🔄 CategoryPage._triggerFetch → categoryId=$categoryId');

    // 1. Sections
    ref
        .read(categorySectionsProvider.notifier)
        .fetchSectionsOfCategory(categoryId: categoryId);

    // 2. Banners — clear first, then fetch for real category
    ref.read(bannerProvider.notifier).clearBanners();
    if (categoryId != null && categoryId.isNotEmpty) {
      ref.read(bannerProvider.notifier).fetchBannersByCategory(categoryId);
    }

    // 3. Brands
    final brandsId = (categoryId != null && categoryId.isNotEmpty)
        ? categoryId
        : '5d70fc95-8a6b-4d04-95e9-9620269ab15e';
    ref.read(categorySectionsProvider.notifier).fetchBrands(brandsId);
  }

  void _navigate(String route, Map<String, String> params) {
    final uri = Uri(
        path: route,
        queryParameters: params.isEmpty ? null : params);
    Navigator.pushNamed(context, uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final bannerState = ref.watch(bannerProvider);

    final sectionsLoading = state.sectionsLoading;
    final rawSections = state.sections;
    final bannerIsLoading = bannerState.isLoading;
    final banners = bannerState.banners;

    // Parse + sort sections via the Section model
    final List<Section> sections = rawSections
        .map((e) {
          try {
            return Section.fromJson(Map<String, dynamic>.from(e));
          } catch (_) {
            return null;
          }
        })
        .whereType<Section>()
        .where((s) => s.active)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // First-load spinner
    if (sectionsLoading && sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5200)),
        ),
      );
    }

    if (sections.isEmpty && !sectionsLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner carousel ────────────────────────────────────────────
        if (bannerIsLoading)
          _ShimmerBanner()
        else if (banners.isNotEmpty)
          ResponsiveBannerCarousel(
            banners: banners,
            categoryId: widget.categoryId ?? '',
          ),

        // ── Dynamic sections ───────────────────────────────────────────
        ...sections.map<Widget>(
          (section) => SectionWidget(section: section, onNavigate: _navigate),
        ),
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