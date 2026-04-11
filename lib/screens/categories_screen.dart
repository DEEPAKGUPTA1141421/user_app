import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/category_sections.dart';

const brandColor = Color(0xFFFF5200);

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String activeCategory = 'for-you';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(categorySectionsProvider.notifier)
          .fetchCategories(includeChildItem: true, level: "SUPER_CATEGORY");
      await ref
          .read(categorySectionsProvider.notifier)
          .fetchBrands('5d70fc95-8a6b-4d04-95e9-9620269ab15e');
    });
  }

  void handleCategoryClick(String categoryId) {
    setState(() => activeCategory = categoryId);
    ref.read(categorySectionsProvider.notifier).fetchBrands(categoryId);
  }

  Future<void> _refresh() async {
    await ref
        .read(categorySectionsProvider.notifier)
        .fetchCategories(includeChildItem: true, level: "SUPER_CATEGORY");
    await ref
        .read(categorySectionsProvider.notifier)
        .fetchBrands(activeCategory);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final bool isLoading = state.isLoading;
    final List<dynamic> brandData = state.brands;
    final List<dynamic> categories = state.categories;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 900;

    // Sidebar width scales with screen
    final sidebarWidth = isDesktop ? 100.0 : isTablet ? 88.0 : 72.0;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sidebar ──────────────────────────────────────────────
          _ResponsiveSidebar(
            width: sidebarWidth,
            activeCategory: activeCategory,
            onCategoryClick: handleCategoryClick,
            isLoading: isLoading,
            categories: categories,
          ),

          // ── Main Content ──────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: brandColor,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: 24,
                  left: isTablet ? 14 : 10,
                  right: isTablet ? 14 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Section
                    if (isLoading)
                      _BrandShimmer(isTablet: isTablet, isDesktop: isDesktop)
                    else
                      _BrandSection(
                        brands: brandData,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),

                    const SizedBox(height: 20),

                    // Category Sub-sections
                    if (isLoading)
                      _CategoryGridShimmer(
                          isTablet: isTablet, isDesktop: isDesktop)
                    else if (categories.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No categories available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      for (var parent in categories)
                        for (var category in (parent['children'] ?? [])) ...[
                          _CategorySubSection(
                            title: category['name'] ?? 'Untitled',
                            items: List<dynamic>.from(
                                category['children'] ?? []),
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 18),
                        ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _ResponsiveSidebar extends StatelessWidget {
  final double width;
  final String activeCategory;
  final Function(String) onCategoryClick;
  final bool isLoading;
  final List<dynamic> categories;

  const _ResponsiveSidebar({
    required this.width,
    required this.activeCategory,
    required this.onCategoryClick,
    required this.isLoading,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: isLoading ? _shimmer() : _list(),
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final id = cat['id'] ?? '';
        final label = cat['name'] ?? '';
        final imgUrl = cat['imageurl'] ?? '';
        final isActive = activeCategory == id;

        return GestureDetector(
          onTap: () => onCategoryClick(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
            decoration: BoxDecoration(
              color: isActive ? brandColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: brandColor.withOpacity(0.35), width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circle image or letter avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? brandColor : Colors.grey.shade300,
                      width: isActive ? 2 : 1,
                    ),
                    image: imgUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imgUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: isActive
                        ? brandColor.withOpacity(0.1)
                        : Colors.grey.shade200,
                  ),
                  child: imgUrl.isEmpty
                      ? Center(
                          child: Text(
                            label.isNotEmpty ? label[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: isActive ? brandColor : Colors.grey[600],
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? brandColor : Colors.grey[700],
                    height: 1.2,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 20,
                    height: 3,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (_, __) => _ShimmerItem(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _shimBox(width: 46, height: 46, circle: true),
            const SizedBox(height: 6),
            _shimBox(width: 44, height: 9),
            const SizedBox(height: 3),
            _shimBox(width: 32, height: 9),
          ],
        ),
      ),
    );
  }

  Widget _shimBox(
      {required double width,
      required double height,
      bool circle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _BrandSection extends StatelessWidget {
  final List<dynamic> brands;
  final bool isTablet;
  final bool isDesktop;

  const _BrandSection({
    required this.brands,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();

    final crossAxisCount = isDesktop ? 5 : isTablet ? 4 : 3;
    final itemHeight = isTablet ? 115.0 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Brands You Like'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: brands.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: itemHeight,
          ),
          itemBuilder: (_, i) {
            final b = brands[i];
            final name = b['name'] ?? 'Brand';
            final logo = b['logoUrl'] ?? '';
            final avatarSize = isTablet ? 58.0 : 50.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: logo.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: Colors.grey),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 11.5 : 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY SUB-SECTION (with expand/collapse)
// ─────────────────────────────────────────────────────────────────────────────
class _CategorySubSection extends StatefulWidget {
  final String title;
  final List<dynamic> items;
  final bool isTablet;
  final bool isDesktop;

  const _CategorySubSection({
    required this.title,
    required this.items,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  State<_CategorySubSection> createState() => _CategorySubSectionState();
}

class _CategorySubSectionState extends State<_CategorySubSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = widget.isDesktop ? 5 : widget.isTablet ? 4 : 3;
    final initialCount = crossAxisCount * 2; // 2 rows
    final hasMore = widget.items.length > initialCount;
    final displayed = _showAll
        ? widget.items
        : widget.items.take(initialCount).toList();
    final itemHeight = widget.isTablet ? 118.0 : 102.0;
    final avatarSize = widget.isTablet ? 56.0 : 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: widget.title),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayed.length + (hasMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            mainAxisExtent: itemHeight,
          ),
          itemBuilder: (_, index) {
            // "View all / less" last tile
            if (hasMore && index == displayed.length) {
              return GestureDetector(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: brandColor,
                      ),
                      child: Icon(
                        _showAll
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _showAll ? 'Less' : 'View All',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: brandColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            final sub = displayed[index];
            final name = sub['name'] ?? 'Unnamed';
            final imgUrl = sub['imageurl'] ??
                'https://picsum.photos/200?random=${sub['id'] ?? index}';

            return GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.category_outlined,
                          color: Colors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 11 : 10,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _BrandShimmer extends StatelessWidget {
  final bool isTablet;
  final bool isDesktop;
  const _BrandShimmer({required this.isTablet, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 5 : isTablet ? 4 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerItem(child: _shimRect(width: 110, height: 14)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: isTablet ? 115 : 100,
          ),
          itemBuilder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShimmerItem(child: _shimCircle(isTablet ? 58 : 50)),
              const SizedBox(height: 6),
              _ShimmerItem(child: _shimRect(width: 44, height: 9)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryGridShimmer extends StatelessWidget {
  final bool isTablet;
  final bool isDesktop;
  const _CategoryGridShimmer(
      {required this.isTablet, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 5 : isTablet ? 4 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerItem(child: _shimRect(width: 120, height: 14)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            mainAxisExtent: isTablet ? 118 : 102,
          ),
          itemBuilder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShimmerItem(child: _shimCircle(isTablet ? 56 : 50)),
              const SizedBox(height: 6),
              _ShimmerItem(child: _shimRect(width: 48, height: 9)),
              const SizedBox(height: 3),
              _ShimmerItem(child: _shimRect(width: 36, height: 9)),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _shimCircle(double size) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );

Widget _shimRect({required double width, required double height}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );

class _ShimmerItem extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _ShimmerItem({required this.child, this.margin});

  @override
  State<_ShimmerItem> createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<_ShimmerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          margin: widget.margin,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_anim.value - 1).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 1).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF0F0F0),
                Color(0xFFE0E0E0),
              ],
            ).createShader(bounds),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}