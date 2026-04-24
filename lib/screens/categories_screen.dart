import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/category_sections.dart';
import '../utils/app_colors.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with TickerProviderStateMixin {
  String activeCategory = 'for-you';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    Future.microtask(() async {
      await ref
          .read(categorySectionsProvider.notifier)
          .fetchCategoryList();
      await ref
          .read(categorySectionsProvider.notifier)
          .fetchBrands('5d70fc95-8a6b-4d04-95e9-9620269ab15e');
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void handleCategoryClick(String categoryId) {
    setState(() => activeCategory = categoryId);
    ref.read(categorySectionsProvider.notifier).fetchBrands(categoryId);
  }

  Future<void> _refresh() async {
    await ref
        .read(categorySectionsProvider.notifier)
        .fetchCategoryList();
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

    final sidebarWidth = isDesktop ? 104.0 : isTablet ? 92.0 : 76.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResponsiveSidebar(
              width: sidebarWidth,
              activeCategory: activeCategory,
              onCategoryClick: handleCategoryClick,
              isLoading: isLoading,
              categories: categories,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.white,
                backgroundColor: AppColors.surface,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: 24,
                    left: isTablet ? 14 : 10,
                    right: isTablet ? 14 : 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading)
                        _BrandShimmer(isTablet: isTablet, isDesktop: isDesktop)
                      else
                        _BrandSection(
                          brands: brandData,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        ),
                      const SizedBox(height: 12),
                      if (isLoading)
                        _CategoryGridShimmer(
                            isTablet: isTablet, isDesktop: isDesktop)
                      else if (categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No categories available',
                              style: TextStyle(
                                  color: AppColors.grey, fontSize: 13),
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
                            const SizedBox(height: 14),
                          ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
              right: BorderSide(color: AppColors.divider)),
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
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.white : Colors.transparent,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.white : AppColors.border,
                      width: isActive ? 1.5 : 1,
                    ),
                    image: imgUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imgUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: AppColors.bg,
                  ),
                  child: imgUrl.isEmpty
                      ? Center(
                          child: Text(
                            label.isNotEmpty ? label[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.white : AppColors.grey,
                    height: 1.2,
                    letterSpacing: 0.1,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 20,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.white,
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
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _shimCircle(46),
            const SizedBox(height: 6),
            _shimRect(width: 44, height: 9),
            const SizedBox(height: 3),
            _shimRect(width: 32, height: 9),
          ],
        ),
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
    final itemHeight = isTablet ? 118.0 : 104.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('BRANDS YOU LIKE'),
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
                    color: AppColors.surface2,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: logo.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: AppColors.grey),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 11.5 : 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
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
    final initialCount = crossAxisCount * 2;
    final hasMore = widget.items.length > initialCount;
    final displayed = _showAll
        ? widget.items
        : widget.items.take(initialCount).toList();
    final itemHeight = widget.isTablet ? 120.0 : 104.0;
    final avatarSize = widget.isTablet ? 56.0 : 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(widget.title.toUpperCase()),
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
            if (hasMore && index == displayed.length) {
              return GestureDetector(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface2,
                        border: Border.all(
                            color: AppColors.white, width: 1.5),
                      ),
                      child: Icon(
                        _showAll
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showAll ? 'Less' : 'View All',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        letterSpacing: 0.4,
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
                      color: AppColors.surface2,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.category_outlined,
                          color: AppColors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 11 : 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
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
// SECTION LABEL  (ALL-CAPS, tracked)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 16, 4, 10),
          child: _ShimmerItem(child: SizedBox(width: 110, height: 10)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: isTablet ? 118 : 104,
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
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 16, 4, 10),
          child: _ShimmerItem(child: SizedBox(width: 120, height: 10)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            mainAxisExtent: isTablet ? 120 : 104,
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
        color: AppColors.surface2,
      ),
    );

Widget _shimRect({required double width, required double height}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface2,
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
      duration: const Duration(milliseconds: 1200),
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
                AppColors.surface2,
                AppColors.border,
                AppColors.surface2,
              ],
            ).createShader(bounds),
            child: widget.child,
          ),
        );
      },
    );
  }
}
