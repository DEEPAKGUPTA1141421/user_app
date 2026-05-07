import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/shop_product_search_provider.dart';
import '../../model/shop_product.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';
import '../../widgets/shop/shop_product_empty_state.dart';

// ─── Screen ────────────────────────────────────────────────────────────────────

class ShopProductSearchScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;
  final double userLat;
  final double userLng;

  const ShopProductSearchScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    this.userLat = 0.0,
    this.userLng = 0.0,
  });

  @override
  ConsumerState<ShopProductSearchScreen> createState() =>
      _ShopProductSearchScreenState();
}

class _ShopProductSearchScreenState
    extends ConsumerState<ShopProductSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTextChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(shopProductSearchPod((shopId: widget.shopId, userLat: widget.userLat, userLng: widget.userLng)).notifier).setQuery(q);
    });
  }

  void _clearQuery() {
    _ctrl.clear();
    _debounce?.cancel();
    ref.read(shopProductSearchPod((shopId: widget.shopId, userLat: widget.userLat, userLng: widget.userLng)).notifier).reset();
    _focus.requestFocus();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.offset < _scroll.position.maxScrollExtent - 300) return;
    ref.read(shopProductSearchPod((shopId: widget.shopId, userLat: widget.userLat, userLng: widget.userLng)).notifier).loadMore();
  }

  void _openProduct(String productId) =>
      Navigator.pushNamed(context, '/productDetail/$productId');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProductSearchPod((shopId: widget.shopId, userLat: widget.userLat, userLng: widget.userLng)));
    final isIdle = state.query.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _SearchBar(
        ctrl: _ctrl,
        focus: _focus,
        hint: 'Search in ${widget.shopName}',
        onChanged: _onTextChanged,
        onClear: _clearQuery,
        onBack: () => Navigator.pop(context),
      ),
      body: isIdle
          ? _IdleHint(shopName: widget.shopName)
          : _buildResults(state),
    );
  }

  Widget _buildResults(ShopProductSearchState state) {
    if (state.status == ShopSearchStatus.loading && state.items.isEmpty) {
      return const Center(child: AppSpinner());
    }

    if (state.status == ShopSearchStatus.error) {
      return ShopProductEmptyState(
        message: state.error ?? 'Search failed. Please try again.',
        icon: Icons.wifi_off_rounded,
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(shopProductSearchPod((shopId: widget.shopId, userLat: widget.userLat, userLng: widget.userLng)).notifier).retry(),
      );
    }

    if (state.items.isEmpty) {
      return ShopProductEmptyState(
        message: 'No products found for "${state.query}"',
        icon: Icons.search_off_rounded,
        actionLabel: 'Clear search',
        onAction: _clearQuery,
      );
    }

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: state.items
                .map((p) => _ProductCard(
                      product: p,
                      onTap: () => _openProduct(p.id),
                    ))
                .toList(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: state.isLoadingMore
                ? const Center(child: AppSpinner(size: 20))
                : const SizedBox.shrink(),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 16),
        ),
      ],
    );
  }
}

// ─── App-bar search field ─────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _SearchBar({
    required this.ctrl,
    required this.focus,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChanged);
    super.dispose();
  }

  void _onCtrlChanged() {
    final v = widget.ctrl.text.isNotEmpty;
    if (v != _hasText) setState(() => _hasText = v);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.white, size: 18),
        onPressed: widget.onBack,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: widget.ctrl,
        focusNode: widget.focus,
        onChanged: widget.onChanged,
        autofocus: false,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: AppColors.greyDark,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        textInputAction: TextInputAction.search,
      ),
      actions: [
        if (_hasText)
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.grey, size: 20),
            onPressed: widget.onClear,
          )
        else
          const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

// ─── Idle state (no query typed yet) ─────────────────────────────────────────

class _IdleHint extends StatelessWidget {
  final String shopName;

  const _IdleHint({required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_rounded, size: 48, color: AppColors.greyDark),
          const SizedBox(height: 14),
          Text(
            'Search products in $shopName',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product card (2-col grid) ────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ShopProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(11)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surface2,
                      child: product.images.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _Badge(product.badge!),
                    ),
                  if (product.discountPercent != null &&
                      product.discountPercent! > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${product.discountPercent}% off',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    if (product.rating > 0) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 11, color: Color(0xFFFFC107)),
                          const SizedBox(width: 3),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price) ...[
                          const SizedBox(width: 5),
                          Text(
                            '₹${product.originalPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.greyDark,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.shopping_bag_outlined,
            size: 32, color: AppColors.grey),
      );
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;

  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
