import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/category_sections.dart';
import '../utils/app_colors.dart';
import '../widgets/product_search_results_page.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  String? _activeSuperCategoryId;
  final ScrollController _rightScroll = ScrollController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // If categories are already cached, auto-select the first one immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cats = ref.read(categorySectionsProvider).categories;
      if (cats.isNotEmpty) {
        final id = cats.first['id']?.toString() ?? '';
        if (id.isNotEmpty) _selectSuperCategory(id);
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _rightScroll.dispose();
    super.dispose();
  }

  void _selectSuperCategory(String id) {
    if (id.isEmpty || _activeSuperCategoryId == id) return;
    setState(() => _activeSuperCategoryId = id);
    if (_rightScroll.hasClients) _rightScroll.jumpTo(0);
    ref.read(categorySectionsProvider.notifier).fetchBrowseCategories(id);
  }

  Future<void> _refresh() async {
    if (_activeSuperCategoryId == null) return;
    // Force re-fetch by clearing cached id in provider and re-calling.
    ref.read(categorySectionsProvider.notifier).fetchBrowseCategories(
          _activeSuperCategoryId!,
          forceRefresh: true,
        );
  }

  void _openResults(SubSubCategoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductSearchResultsPage(
          query: item.name,
          filterPayload: {'categoryId': item.id},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final sidebarWidth = isTablet ? 96.0 : 80.0;

    // Auto-select the first SUPER_CATEGORY when categories finish loading.
    // ref.listen fires on every state transition — more reliable than
    // addPostFrameCallback inside build.
    ref.listen<CategorySectionsState>(categorySectionsProvider, (prev, next) {
      if (_activeSuperCategoryId != null) return;
      if (next.categoriesLoading || next.categories.isEmpty) return;
      final id = next.categories.first['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _selectSuperCategory(id);
        });
      }
    });

    // Decide what to show in the right panel.
    Widget rightPanel;
    if (_activeSuperCategoryId == null || state.browseLoading) {
      rightPanel = _BrowseShimmer(isTablet: isTablet);
    } else if (state.error != null && state.browseGroups.isEmpty) {
      rightPanel = _ErrorPanel(message: state.error!);
    } else {
      rightPanel = _BrowseContent(
        groups: state.browseGroups,
        isTablet: isTablet,
        onItemTap: _openResults,
        scrollController: _rightScroll,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
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
            // ── Left sidebar: SUPER_CATEGORY ──────────────────────────
            _SuperCategorySidebar(
              width: sidebarWidth,
              categories: state.categories,
              isLoading: state.categoriesLoading,
              activeId: _activeSuperCategoryId,
              onTap: _selectSuperCategory,
            ),

            // ── Right panel: SUBCATEGORY headings + SUBSUBCATEGORY items
            Expanded(
              child: state.browseGroups.isNotEmpty && _activeSuperCategoryId != null
                  ? RefreshIndicator(
                      color: AppColors.white,
                      backgroundColor: AppColors.surface,
                      onRefresh: _refresh,
                      child: rightPanel,
                    )
                  : rightPanel,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Left Sidebar ─────────────────────────────────────────────────────────────

class _SuperCategorySidebar extends StatelessWidget {
  final double width;
  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final String? activeId;
  final void Function(String) onTap;

  const _SuperCategorySidebar({
    required this.width,
    required this.categories,
    required this.isLoading,
    required this.activeId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.divider)),
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
        final id = cat['id']?.toString() ?? '';
        final label = cat['name'] ?? '';
        final imgUrl = cat['imageUrl'] ?? ''; // camelCase from Spring
        final isActive = activeId == id;

        return GestureDetector(
          onTap: () => onTap(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color:
                      isActive ? const Color(0xFFFF5200) : Colors.transparent,
                  width: 3,
                ),
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
                    color: AppColors.bg,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFF5200)
                          : AppColors.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: imgUrl.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _initial(label),
                            ),
                          )
                        : _initial(label),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.white : AppColors.grey,
                    height: 1.2,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _initial(String label) => Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      );

  Widget _shimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (_, __) => _ShimmerBox(
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

// ─── Error Panel ──────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  final String message;
  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.grey, size: 32),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Right Panel ──────────────────────────────────────────────────────────────

class _BrowseContent extends StatelessWidget {
  final List<BrowseSubcategory> groups;
  final bool isTablet;
  final void Function(SubSubCategoryItem) onItemTap;
  final ScrollController scrollController;

  const _BrowseContent({
    required this.groups,
    required this.isTablet,
    required this.onItemTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(
        child: Text('No categories found',
            style: TextStyle(color: AppColors.grey, fontSize: 13)),
      );
    }

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: groups.length,
      separatorBuilder: (_, __) =>
          Container(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) => _SubcategorySection(
        group: groups[i],
        isTablet: isTablet,
        onItemTap: onItemTap,
      ),
    );
  }
}

// ─── Subcategory Section ──────────────────────────────────────────────────────

class _SubcategorySection extends StatefulWidget {
  final BrowseSubcategory group;
  final bool isTablet;
  final void Function(SubSubCategoryItem) onItemTap;

  const _SubcategorySection({
    required this.group,
    required this.isTablet,
    required this.onItemTap,
  });

  @override
  State<_SubcategorySection> createState() => _SubcategorySectionState();
}

class _SubcategorySectionState extends State<_SubcategorySection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = widget.isTablet ? 4 : 3;
    final initialCount = crossAxisCount * 2;
    final items = widget.group.subCategories;
    final hasMore = items.length > initialCount;
    final displayed = _showAll ? items : items.take(initialCount).toList();
    final avatarSize = widget.isTablet ? 56.0 : 48.0;
    final itemHeight = widget.isTablet ? 116.0 : 104.0;

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUBCATEGORY heading (matches _SectionLabel in payment_page.dart)
          _SectionLabel(widget.group.name.toUpperCase()),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('No items',
                  style: TextStyle(color: AppColors.greyDark, fontSize: 12)),
            )
          else
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
                // "View All" button
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
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showAll ? 'Less' : 'View All',
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

                final item = displayed[index];
                return GestureDetector(
                  onTap: () => widget.onItemTap(item),
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
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.category_outlined,
                                color: AppColors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
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
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _BrowseShimmer extends StatelessWidget {
  final bool isTablet;
  const _BrowseShimmer({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isTablet ? 4 : 3;
    final itemHeight = isTablet ? 116.0 : 104.0;

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: 3,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(
              child: _shimRect(width: 110, height: 10),
              margin: const EdgeInsets.only(bottom: 10)),
          _ShimmerBox(child: _shimRect(width: double.infinity, height: 1),
              margin: const EdgeInsets.only(bottom: 12)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: crossAxisCount * 2,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              mainAxisExtent: itemHeight,
            ),
            itemBuilder: (_, __) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimmerBox(child: _shimCircle(isTablet ? 56 : 48)),
                const SizedBox(height: 6),
                _ShimmerBox(child: _shimRect(width: 44, height: 9)),
                const SizedBox(height: 3),
                _ShimmerBox(child: _shimRect(width: 32, height: 9)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Shared Shimmer Helpers ───────────────────────────────────────────────────

Widget _shimCircle(double size) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.surface2),
    );

Widget _shimRect({required double width, required double height}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: AppColors.surface2, borderRadius: BorderRadius.circular(4)),
    );

class _ShimmerBox extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _ShimmerBox({required this.child, this.margin});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, __) => Container(
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
      ),
    );
  }
}
