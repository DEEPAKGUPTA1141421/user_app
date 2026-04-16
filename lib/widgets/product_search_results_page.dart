import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../utils/app_colors.dart';
import '../widgets/real_search_page.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _FilterOption {
  final String id;
  final String label;
  final String value;
  bool selected;

  _FilterOption({
    required this.id,
    required this.label,
    required this.value,
    this.selected = false,
  });

  _FilterOption copy() =>
      _FilterOption(id: id, label: label, value: value, selected: selected);
}

class _FilterChip {
  final String id;
  final String label;
  final IconData icon;
  final String filterType; // 'SINGLE_SELECT' | 'RANGE'
  final String paramKey;
  final List<_FilterOption> options;
  final double minValue;
  final double maxValue;
  double selectedMin;
  double selectedMax;
  bool isActive;

  _FilterChip({
    required this.id,
    required this.label,
    required this.icon,
    required this.filterType,
    required this.paramKey,
    this.options = const [],
    this.minValue = 0,
    this.maxValue = 1000000,
    double? selectedMin,
    double? selectedMax,
    this.isActive = false,
  })  : selectedMin = selectedMin ?? 0,
        selectedMax = selectedMax ?? 1000000;

  bool get hasActiveSelection {
    if (filterType == 'RANGE') {
      return selectedMin > minValue || selectedMax < maxValue;
    }
    return options.any((o) => o.selected);
  }

  int get selectedCount {
    if (filterType == 'RANGE') return hasActiveSelection ? 1 : 0;
    return options.where((o) => o.selected).length;
  }

  // Label shown on the chip when sort is selected
  String get displayLabel {
    if (id == 'sort') {
      final sel = options.where((o) => o.selected).firstOrNull;
      if (sel != null) return sel.label;
    }
    return label;
  }
}

class _Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final bool hasVideo;
  final String? badge;
  final String deliveryText;
  final bool isSponsored;
  bool isWishlisted;

  _Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.images,
    this.hasVideo = false,
    this.badge,
    required this.deliveryText,
    this.isSponsored = false,
    this.isWishlisted = false,
  });

  int? get discountPercent {
    if (originalPrice == null || originalPrice == 0) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

IconData _iconFor(String id) {
  switch (id) {
    case 'sort':     return Icons.sort_rounded;
    case 'price':    return Icons.currency_rupee_rounded;
    case 'rating':   return Icons.star_rounded;
    case 'color':    return Icons.palette_rounded;
    case 'brand':    return Icons.workspace_premium_rounded;
    case 'size':     return Icons.straighten_rounded;
    case 'discount': return Icons.local_offer_rounded;
    case 'delivery': return Icons.bolt_rounded;
    default:         return Icons.tune_rounded;
  }
}

_FilterChip _chipFromApi(Map<String, dynamic> f) {
  final id         = f['id'] as String? ?? '';
  final filterType = f['filterType'] as String? ?? 'SINGLE_SELECT';
  final minVal     = (f['minValue'] as num?)?.toDouble() ?? 0.0;
  final maxVal     = (f['maxValue'] as num?)?.toDouble() ?? 1000000.0;
  final options    = (f['options'] as List? ?? []).map((o) {
    final raw = o as Map<String, dynamic>;
    return _FilterOption(
      id: raw['id'] as String? ?? '',
      label: raw['label'] as String? ?? '',
      value: raw['value'] as String? ?? '',
    );
  }).toList();

  return _FilterChip(
    id: id,
    label: f['label'] as String? ?? id,
    icon: _iconFor(id),
    filterType: filterType,
    paramKey: f['paramKey'] as String? ?? id,
    options: options,
    minValue: minVal,
    maxValue: maxVal,
    selectedMin: minVal,
    selectedMax: maxVal,
  );
}

_Product _productFromJson(Map<String, dynamic> p) {
  final images = (p['images'] as List?)?.cast<String>() ?? [];
  final salePrice = (p['discountPrice'] as num?)?.toDouble()
      ?? (p['salePrice'] as num?)?.toDouble()
      ?? (p['price'] as num?)?.toDouble()
      ?? 0.0;
  final origPrice = (p['price'] as num?)?.toDouble()
      ?? (p['originalPrice'] as num?)?.toDouble();
  return _Product(
    id: p['id']?.toString() ?? '',
    name: p['name'] as String? ?? 'Unnamed',
    brand: p['brand'] as String? ?? p['category'] as String? ?? '',
    price: salePrice,
    originalPrice: (origPrice != null && origPrice > salePrice) ? origPrice : null,
    rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: (p['ratingCount'] as int?) ?? 0,
    images: images,
    deliveryText: 'Free Delivery',
    isSponsored: p['isSponsored'] == true,
    badge: p['isBestseller'] == true ? 'Bestseller' : null,
  );
}

String _fmtPrice(double v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(0)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
  return '₹${v.toInt()}';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ProductSearchResultsPage extends StatefulWidget {
  final String query;
  final Map<String, dynamic> filterPayload;

  const ProductSearchResultsPage({
    super.key,
    required this.query,
    this.filterPayload = const {},
  });

  @override
  State<ProductSearchResultsPage> createState() => _State();
}

class _State extends State<ProductSearchResultsPage> {
  late final TextEditingController _ctrl;

  List<_FilterChip> _chips    = [];
  List<_Product>    _products = [];
  bool _filtersLoading = true;
  bool _productsLoading = true;
  int  _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
    _loadAll();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Fetch filters + products in parallel ──────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([_fetchFilters(), _fetchProducts()]);
  }

  Future<void> _fetchFilters() async {
    final categoryId = widget.filterPayload['categoryId'] as String?;
    if (categoryId == null || categoryId.isEmpty) {
      if (mounted) setState(() => _filtersLoading = false);
      return;
    }
    try {
      final res = await ApiClient.instance.productClient
          .get(ApiEndpoints.categoryFilters(categoryId));
      final data = (res.data as Map<String, dynamic>?)?['data']
          as Map<String, dynamic>? ?? {};
      final rawFilters = (data['filters'] as List? ?? []);
      if (mounted) {
        setState(() {
          _chips = rawFilters
              .map((f) => _chipFromApi(Map<String, dynamic>.from(f)))
              .toList();
          _filtersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _filtersLoading = false);
    }
  }

  Future<void> _fetchProducts() async {
    if (mounted) setState(() => _productsLoading = true);
    try {
      final params = _buildQueryParams();
      final res = await ApiClient.instance.productClient
          .get(ApiEndpoints.searchProducts, queryParameters: params);
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final rawProducts = (data['products'] as List? ?? []);
      if (mounted) {
        setState(() {
          _products = rawProducts
              .map((p) => _productFromJson(Map<String, dynamic>.from(p)))
              .toList();
          _productsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _productsLoading = false);
    }
  }

  // ── Build search query params from active filters ─────────────────────────
  Map<String, dynamic> _buildQueryParams() {
    final params = <String, dynamic>{'keyword': widget.query};

    // Pass categoryId and any pre-set filters from the payload
    final categoryId = widget.filterPayload['categoryId'];
    if (categoryId != null) params['categoryId'] = categoryId;

    final payloadFilters =
        widget.filterPayload['filters'] as Map<String, dynamic>? ?? {};
    payloadFilters.forEach((k, v) {
      params[k] = v is List ? v.join(',') : v;
    });

    // User-selected chip values
    for (final chip in _chips) {
      if (chip.filterType == 'RANGE') {
        if (chip.hasActiveSelection) {
          params[chip.paramKey] =
              '${chip.selectedMin.toInt()}-${chip.selectedMax.toInt()}';
        }
      } else {
        final selected =
            chip.options.where((o) => o.selected).map((o) => o.value).toList();
        if (selected.isNotEmpty) {
          params[chip.paramKey] =
              selected.length == 1 ? selected.first : selected.join(',');
        }
      }
    }

    return params;
  }

  // ── Active filter count ───────────────────────────────────────────────────
  int get _activeCount =>
      _chips.fold(0, (s, c) => s + c.selectedCount);

  // ── Open filter bottom sheet ──────────────────────────────────────────────
  void _openSheet(_FilterChip chip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _Sheet(
        chip: chip,
        onApply: (updated) {
          setState(() {
            final i = _chips.indexWhere((c) => c.id == updated.id);
            if (i >= 0) _chips[i] = updated;
          });
          _fetchProducts(); // re-fetch with new filters
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      for (final c in _chips) {
        for (final o in c.options) { o.selected = false; }
        c.selectedMin = c.minValue;
        c.selectedMax = c.maxValue;
        c.isActive = false;
      }
    });
    _fetchProducts();
  }

  void _wishlist(_Product p) {
    setState(() {
      final i = _products.indexWhere((x) => x.id == p.id);
      if (i >= 0) _products[i].isWishlisted = !_products[i].isWishlisted;
    });
    _snack(
      _products.firstWhere((x) => x.id == p.id).isWishlisted
          ? 'Added to wishlist'
          : 'Removed from wishlist',
      Icons.favorite_rounded,
    );
  }

  void _addCart(_Product p) {
    setState(() => _cartCount++);
    _snack('Added to cart', Icons.shopping_bag_outlined);
  }

  void _snack(String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: AppColors.white, size: 15),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(color: AppColors.white, fontSize: 13)),
      ]),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          _buildFilterBar(),
          Expanded(
            child: _productsLoading ? _shimmerProducts() : _grid(),
          ),
        ]),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RealSearchPage()),
              ),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _ctrl,
                    style:
                        const TextStyle(color: AppColors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search products, brands...',
                      hintStyle:
                          TextStyle(color: AppColors.grey, fontSize: 13),
                      prefixIcon: Icon(CupertinoIcons.search,
                          color: AppColors.grey, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Cart badge
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/order-summary'),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.white, size: 20),
              ),
              if (_cartCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.white, shape: BoxShape.circle),
                    child: Text('$_cartCount',
                        style: const TextStyle(
                            color: AppColors.bg,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
        ]),
      );

  // ── Filter bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() => Container(
        color: AppColors.surface,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_filtersLoading)
            _shimmerFilters()
          else if (_chips.isNotEmpty)
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                itemCount: _chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _chips[i];
                  final active = c.hasActiveSelection;
                  final cnt = c.selectedCount;
                  return GestureDetector(
                    onTap: () => _openSheet(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppColors.white : AppColors.border,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(c.icon,
                            size: 13,
                            color: active ? AppColors.white : AppColors.grey),
                        const SizedBox(width: 5),
                        Text(
                          c.displayLabel,
                          style: TextStyle(
                            color: active ? AppColors.white : AppColors.grey,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        if (cnt > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('$cnt',
                                style: const TextStyle(
                                    color: AppColors.bg,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ] else ...[
                          const SizedBox(width: 3),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: active ? AppColors.white : AppColors.greyDark),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ),
          Container(height: 1, color: AppColors.divider),
        ]),
      );

  // ── Filter bar shimmer ────────────────────────────────────────────────────
  Widget _shimmerFilters() => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, __) => Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surface2,
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      );

  // ── Products grid ─────────────────────────────────────────────────────────
  Widget _grid() => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(children: [
                Text('${_products.length} results  ',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12)),
                Flexible(
                  child: Text('"${widget.query}"',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                const Spacer(),
                if (_activeCount > 0)
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.white.withOpacity(0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.close, size: 11, color: AppColors.white),
                        SizedBox(width: 3),
                        Text('Clear All',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
          if (_products.isEmpty)
            SliverFillRemaining(
              child: _emptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.56,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _Card(
                    product: _products[i],
                    onWishlist: () => _wishlist(_products[i]),
                    onAddToCart: () => _addCart(_products[i]),
                    onTap: () => Navigator.pushNamed(
                        context, '/productDetail/${_products[i].id}'),
                  ),
                  childCount: _products.length,
                ),
              ),
            ),
        ],
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(CupertinoIcons.search,
                color: AppColors.greyDark, size: 28),
          ),
          const SizedBox(height: 20),
          Text('No results for "${widget.query}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters or search term.',
              style: TextStyle(color: AppColors.grey, fontSize: 13)),
          if (_activeCount > 0) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Clear Filters',
                    style: TextStyle(
                        color: AppColors.bg,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ]),
      );

  // ── Product shimmer ───────────────────────────────────────────────────────
  Widget _shimmerProducts() => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.56),
        itemCount: 6,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surface2,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PRODUCT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final _Product product;
  final VoidCallback onWishlist;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _Card({
    required this.product,
    required this.onWishlist,
    required this.onAddToCart,
    required this.onTap,
  });

  String _fmt(double v) {
    final n = v.toInt();
    if (n >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    final s = n.toString();
    return s.length > 3
        ? '₹${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : '₹$s';
  }

  String _fmtN(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 52,
            child: Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: p.images.isNotEmpty
                      ? Image.network(p.images.first, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surface2,
                              child: const Center(
                                  child: Icon(Icons.image_not_supported_outlined,
                                      color: AppColors.greyDark, size: 28))))
                      : Container(color: AppColors.surface2),
                ),
              ),
              if (p.hasVideo)
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_fill, color: AppColors.white, size: 13),
                      SizedBox(width: 4),
                      Text('Video', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              if (p.isSponsored)
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Sponsored',
                        style: TextStyle(color: AppColors.grey, fontSize: 9, fontWeight: FontWeight.w500)),
                  ))
              else if (p.badge != null)
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.badge!.contains('%') ? Colors.green.shade700 : AppColors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(p.badge!, style: const TextStyle(color: AppColors.bg, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  ))
              else if (p.discountPercent != null)
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(5)),
                    child: Text('${p.discountPercent}% off', style: const TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  )),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onWishlist,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.52),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        p.isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(p.isWishlisted),
                        color: p.isWishlisted ? Colors.red.shade400 : AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),

          Expanded(
            flex: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.brand.toUpperCase(),
                    style: const TextStyle(color: AppColors.grey, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.rating >= 4 ? Colors.green.shade800 : Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, color: AppColors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(p.rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width: 5),
                  Text('(${_fmtN(p.reviewCount)})', style: const TextStyle(color: AppColors.grey, fontSize: 10)),
                ]),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmt(p.price), style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (p.originalPrice != null) ...[
                    const SizedBox(width: 5),
                    Text(_fmt(p.originalPrice!),
                        style: const TextStyle(color: AppColors.grey, fontSize: 10,
                            decoration: TextDecoration.lineThrough, decorationColor: AppColors.grey)),
                  ],
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.local_shipping_outlined, color: AppColors.green, size: 11),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(p.deliveryText,
                        style: const TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_shopping_cart_rounded, color: AppColors.white, size: 13),
                      SizedBox(width: 5),
                      Text('Add to Cart', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _Sheet extends StatefulWidget {
  final _FilterChip chip;
  final ValueChanged<_FilterChip> onApply;

  const _Sheet({required this.chip, required this.onApply});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late List<_FilterOption> _opts;
  late double _rangeMin;
  late double _rangeMax;

  bool get _isRange => widget.chip.filterType == 'RANGE';

  @override
  void initState() {
    super.initState();
    _opts = widget.chip.options.map((o) => o.copy()).toList();
    _rangeMin = widget.chip.selectedMin;
    _rangeMax = widget.chip.selectedMax;
  }

  void _clear() {
    if (_isRange) {
      setState(() {
        _rangeMin = widget.chip.minValue;
        _rangeMax = widget.chip.maxValue;
      });
    } else {
      setState(() {
        for (final o in _opts) { o.selected = false; }
      });
    }
  }

  void _apply() {
    final isActive = _isRange
        ? (_rangeMin > widget.chip.minValue || _rangeMax < widget.chip.maxValue)
        : _opts.any((o) => o.selected);

    widget.onApply(_FilterChip(
      id: widget.chip.id,
      label: widget.chip.label,
      icon: widget.chip.icon,
      filterType: widget.chip.filterType,
      paramKey: widget.chip.paramKey,
      options: _opts,
      minValue: widget.chip.minValue,
      maxValue: widget.chip.maxValue,
      selectedMin: _rangeMin,
      selectedMax: _rangeMax,
      isActive: isActive,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cnt = _isRange
        ? (_rangeMin > widget.chip.minValue || _rangeMax < widget.chip.maxValue ? 1 : 0)
        : _opts.where((o) => o.selected).length;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Icon(widget.chip.icon, color: AppColors.white, size: 18),
              const SizedBox(width: 10),
              Text(widget.chip.label,
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              if (cnt > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text('$cnt selected',
                      style: const TextStyle(
                          color: AppColors.bg, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              if (cnt > 0)
                GestureDetector(
                  onTap: _clear,
                  child: const Text('Clear',
                      style: TextStyle(color: AppColors.white, fontSize: 13)),
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.close, color: AppColors.grey, size: 14),
                ),
              ),
            ]),
          ),

          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── RANGE slider ────────────────────────────────────────────────
          if (_isRange) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                // Price display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PriceLabel(label: 'Min', value: _fmtPrice(_rangeMin)),
                    _PriceLabel(label: 'Max', value: _fmtPrice(_rangeMax)),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.white,
                    inactiveTrackColor: AppColors.surface2,
                    thumbColor: AppColors.white,
                    overlayColor: AppColors.white.withOpacity(0.15),
                    trackHeight: 3,
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 10),
                  ),
                  child: RangeSlider(
                    min: widget.chip.minValue,
                    max: widget.chip.maxValue,
                    values: RangeValues(_rangeMin, _rangeMax),
                    onChanged: (v) =>
                        setState(() { _rangeMin = v.start; _rangeMax = v.end; }),
                  ),
                ),
                // Range labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtPrice(widget.chip.minValue),
                        style: const TextStyle(color: AppColors.greyDark, fontSize: 11)),
                    Text(_fmtPrice(widget.chip.maxValue),
                        style: const TextStyle(color: AppColors.greyDark, fontSize: 11)),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ]
          // ── SINGLE_SELECT options ───────────────────────────────────────
          else ...[
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _opts.map((o) => GestureDetector(
                    onTap: () => setState(() {
                      // Sort is single-select only
                      if (widget.chip.id == 'sort') {
                        for (final x in _opts) { x.selected = false; }
                      }
                      o.selected = !o.selected;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: o.selected ? AppColors.white.withOpacity(0.12) : AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: o.selected ? AppColors.white : AppColors.border,
                          width: o.selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (o.selected) ...[
                          const Icon(Icons.check_rounded, color: AppColors.white, size: 13),
                          const SizedBox(width: 5),
                        ],
                        Text(o.label,
                            style: TextStyle(
                              color: o.selected ? AppColors.white : AppColors.grey,
                              fontSize: 13,
                              fontWeight: o.selected ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ]),
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _clear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('Clear All',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _apply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(cnt > 0 ? 'Apply ($cnt)' : 'Apply',
                          style: const TextStyle(
                              color: AppColors.bg,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Price label widget ────────────────────────────────────────────────────────
class _PriceLabel extends StatelessWidget {
  final String label;
  final String value;

  const _PriceLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      const SizedBox(height: 2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withOpacity(0.4)),
        ),
        child: Text(value,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}
