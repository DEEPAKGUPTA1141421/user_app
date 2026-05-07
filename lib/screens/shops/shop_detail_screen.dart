import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/widgets/app_loader.dart';
import '../../model/shop.dart';
import '../../model/shop_product.dart';
import '../../provider/shop_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product/share_sheet.dart';
import '../../widgets/shop/shop_product_empty_state.dart';
import 'shop_product_search_screen.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class _Product {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final String? badge;
  final String? categoryId;
  final String? categoryName;
  final bool isWishlisted;
  final bool isInCart;

  const _Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.rating,
    required this.reviewCount,
    required this.images,
    this.badge,
    this.categoryId,
    this.categoryName,
    this.isWishlisted = false,
    this.isInCart = false,
  });

  factory _Product.fromShopProduct(ShopProduct p) => _Product(
        id: p.id,
        name: p.name,
        price: p.price,
        originalPrice: p.originalPrice,
        discountPercent: p.discountPercent,
        rating: p.rating,
        reviewCount: p.reviewCount,
        images: List<String>.from(p.images),
        badge: p.badge,
        categoryId: p.categoryId,
        categoryName: p.categoryName,
        isWishlisted: p.isWishlisted,
        isInCart: p.isInCart,
      );

  factory _Product.fromJson(Map<String, dynamic> j) => _Product(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        originalPrice: (j['originalPrice'] as num?)?.toDouble(),
        discountPercent: j['discountPercent'] as int?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: j['reviewCount'] as int? ?? 0,
        images: _cleanImages(j['images']),
        badge: j['badge'] as String?,
        categoryId: j['categoryId'] as String?,
        categoryName: j['categoryName'] as String?,
        isWishlisted: j['wishlisted'] as bool? ?? false,
        isInCart: j['inCart'] as bool? ?? false,
      );

  // Strip malformed quote artefacts from image URLs
  static List<String> _cleanImages(dynamic raw) {
    if (raw is! List) return [];
    final urlPattern = RegExp(r'https?://[^\s"\\\[\]]+');
    return raw
        .map((e) {
          final m = urlPattern.firstMatch(e.toString());
          return m?.group(0);
        })
        .whereType<String>()
        .toList();
  }

  String get imageUrl => images.isNotEmpty ? images.first : '';
}

class _StorefrontSection {
  final String type; // 'BUY_AGAIN' | 'CATEGORY'
  final String title;
  final String subtitle;
  final String? categoryId;
  final int priority;
  final int totalCount;
  final List<_Product> products;

  const _StorefrontSection({
    required this.type,
    required this.title,
    required this.subtitle,
    this.categoryId,
    required this.priority,
    required this.totalCount,
    required this.products,
  });

  factory _StorefrontSection.fromJson(Map<String, dynamic> j) {
    final rawProducts = j['products'] as List<dynamic>? ?? [];
    return _StorefrontSection(
      type: j['type'] as String? ?? 'CATEGORY',
      title: j['title'] as String? ?? '',
      subtitle: j['subtitle'] as String? ?? '',
      categoryId: j['categoryId'] as String?,
      priority: j['priority'] as int? ?? 0,
      totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(_Product.fromJson)
          .toList(),
    );
  }

  bool get isBuyAgain => type == 'BUY_AGAIN';
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  final ScrollController _scroll = ScrollController();

  Shop? _shop;
  String? _shopId;
  double _userLat = 0.0;
  double _userLng = 0.0;

  ShopDetail? _detail;
  bool _detailLoading = true;

  // Storefront (section-based browse)
  List<_StorefrontSection> _sections = [];
  bool _storefrontLoading = true;

  // Category pill selection — null = "All sections"
  String? _selectedCategoryId;

  // In-category grid (when a category pill is selected and has > RAIL products)
  List<_Product> _categoryProducts = [];
  bool _categoryLoading = false;
  bool _categoryHasMore = false;
  int _categoryPage = 0;

  static const int _pageSize = 20;

  bool _appBarSolid = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _init() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final routeName = ModalRoute.of(context)?.settings.name;
    final uri = routeName != null ? Uri.tryParse(routeName) : null;

    _shop = args?['shop'] as Shop?;
    _shopId = _shop?.id ??
        (uri?.pathSegments.length == 2 && uri?.pathSegments[0] == 'shop'
            ? uri!.pathSegments[1]
            : null);
    _userLat = args?['userLat'] as double? ?? 0.0;
    _userLng = args?['userLng'] as double? ?? 0.0;

    _loadDetail();
    _loadStorefront();
  }

  // ── Detail ────────────────────────────────────────────────────────────────

  Future<void> _loadDetail() async {
    final shopId = _shopId;
    if (shopId == null || shopId.isEmpty) {
      if (mounted) setState(() => _detailLoading = false);
      return;
    }
    final detail = await ref.read(shopPod.notifier).getShopDetail(
          shopId,
          lat: _userLat,
          lng: _userLng,
        );
    if (mounted) setState(() { _detail = detail; _shop = detail ?? _shop; _detailLoading = false; });
  }

  // ── Storefront sections ───────────────────────────────────────────────────

  Future<void> _loadStorefront() async {
    final shopId = _shopId;
    if (shopId == null || shopId.isEmpty) {
      if (mounted) setState(() => _storefrontLoading = false);
      return;
    }
    try {
      final res = await ApiClient.instance.productClient.get(
        ApiEndpoints.shopStorefront(shopId),
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final rawSections = data['sections'] as List<dynamic>? ?? [];
      final sections = rawSections
          .whereType<Map<String, dynamic>>()
          .map(_StorefrontSection.fromJson)
          .toList();
      if (mounted) setState(() { _sections = sections; _storefrontLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _storefrontLoading = false);
    }
  }

  // ── Category drill-down ───────────────────────────────────────────────────

  void _selectCategory(String? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _categoryProducts = [];
      _categoryPage = 0;
      _categoryHasMore = false;
    });
    if (categoryId != null) _loadCategoryProducts(refresh: true);
  }

  Future<void> _loadCategoryProducts({bool refresh = false}) async {
    if (_categoryLoading) return;
    final shopId = _shopId;
    if (shopId == null) return;

    // Find section to check if all products are already in-memory
    final section = _sections.firstWhere(
      (s) => s.categoryId == _selectedCategoryId,
      orElse: () => const _StorefrontSection(
          type: 'CATEGORY', title: '', subtitle: '', priority: 0, totalCount: 0, products: []),
    );

    // If we already have all products locally, just use them
    if (section.products.isNotEmpty &&
        section.products.length >= section.totalCount) {
      setState(() {
        _categoryProducts = section.products;
        _categoryHasMore = false;
      });
      return;
    }

    setState(() => _categoryLoading = true);
    final page = refresh ? 0 : _categoryPage;
    try {
      final res = await ApiClient.instance.productClient.get(
        ApiEndpoints.searchResults,
        queryParameters: {
          'sellerId': shopId,
          'categoryId': _selectedCategoryId,
          'page': page,
          'pageSize': _pageSize,
          if (_userLat != 0.0) 'userLat': _userLat,
          if (_userLng != 0.0) 'userLng': _userLng,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final list = (data['products'] as List<dynamic>?) ?? [];
      final hasMore = data['hasMore'] as bool? ?? false;
      final parsed = list.whereType<Map<String, dynamic>>().map(_Product.fromJson).toList();

      if (mounted) {
        setState(() {
          _categoryProducts = refresh ? parsed : [..._categoryProducts, ...parsed];
          _categoryHasMore = hasMore;
          _categoryPage = page + 1;
          _categoryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoryLoading = false);
    }
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scroll.hasClients) return;

    // Toggle app bar solid state based on scroll offset (cover photo ~220px tall)
    final solid = _scroll.offset > 180;
    if (solid != _appBarSolid) setState(() => _appBarSolid = solid);

    final atBottom = _scroll.offset >= _scroll.position.maxScrollExtent - 300;
    if (!atBottom) return;
    if (_selectedCategoryId != null && _categoryHasMore && !_categoryLoading) {
      _loadCategoryProducts();
    }
  }

  void _openProduct(String productId) => Navigator.pushNamed(
        context,
        '/productDetail/$productId',
        arguments: {
          'etaLabel': _shop?.deliveryEtaLabel,
        },
      );

  void _shareShop(Shop shop) {
    final tagline = StringBuffer();
    tagline.write('⭐ ${shop.avgRating.toStringAsFixed(1)}');
    if (shop.reviewCount > 0) tagline.write(' (${shop.reviewCount} reviews)');
    tagline.write('  ·  🕒 ${shop.deliveryEtaLabel}');
    tagline.write('  ·  📍 ${shop.distanceLabel}');
    if (!shop.isOpen) tagline.write('  ·  ⚠️ Currently closed');
    showShopShareSheet(
      context,
      shopName: shop.displayName,
      shopId: shop.id,
      tagline: tagline.toString(),
    );
  }

  Future<bool> _toggleFollow(bool currentlyFollowed) async {
    final shopId = _shopId;
    if (shopId == null) return currentlyFollowed;

    bool success;
    if (currentlyFollowed) {
      success = await ref.read(shopPod.notifier).unfollowShop(shopId);
    } else {
      success = await ref.read(shopPod.notifier).followShop(shopId);
    }

    if (success && mounted && _detail != null) {
      final newFollowed = !currentlyFollowed;
      final delta = newFollowed ? 1 : -1;
      setState(() {
        _detail = _detail!.copyWith(
          isFollowed: newFollowed,
          followerCount: (_detail!.followerCount + delta).clamp(0, 9999999999),
        );
        _shop = _detail;
      });
    }
    return success;
  }

  // ── Derived helpers ───────────────────────────────────────────────────────

  // Category pills: unique categories from storefront sections (excluding BUY_AGAIN)
  List<_StorefrontSection> get _categorySections =>
      _sections.where((s) => !s.isBuyAgain).toList();

  // Sections shown in "All" view — filtered if category pill selected
  List<_StorefrontSection> get _visibleSections {
    if (_selectedCategoryId == null) return _sections;
    return _sections.where((s) => s.categoryId == _selectedCategoryId).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    if (shop == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: AppSpinner()),
      );
    }

    final shopId = _shopId;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // ── App bar — transparent over cover, solid when scrolled ─────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: _appBarSolid
                ? AppColors.bg
                : Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _FloatingIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
                forceDark: _appBarSolid,
              ),
            ),
            title: _appBarSolid
                ? Text(
                    shop.displayName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  )
                : null,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _FloatingIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _shareShop(shop),
                  forceDark: _appBarSolid,
                ),
              ),
            ],
            bottom: _appBarSolid
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: AppColors.divider),
                  )
                : null,
          ),

          // ── Shop hero ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ShopHero(
              shop: shop,
              detail: _detail,
              detailLoading: _detailLoading,
              onShare: () => _shareShop(shop),
              onToggleFollow: _toggleFollow,
            ),
          ),

          // ── Search bar (tap to open full-screen search) ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _TapToSearchBar(
                hint: 'Search in ${shop.displayName}',
                onTap: shopId != null
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopProductSearchScreen(
                              shopId: shopId,
                              shopName: shop.displayName,
                              userLat: _userLat,
                              userLng: _userLng,
                            ),
                          ),
                        )
                    : null,
              ),
            ),
          ),

          // ── Category pills ─────────────────────────────────────────────────
          if (_categorySections.isNotEmpty)
            SliverToBoxAdapter(
              child: _CategoryPills(
                sections: _categorySections,
                selectedId: _selectedCategoryId,
                onSelect: _selectCategory,
              ),
            ),

          // ── Loading storefront ─────────────────────────────────────────────
          if (_storefrontLoading)
            const SliverFillRemaining(child: Center(child: AppSpinner())),

          // ── CATEGORY GRID (pill selected) ──────────────────────────────────
          if (_selectedCategoryId != null) ...[
            if (_categoryLoading && _categoryProducts.isEmpty)
              const SliverFillRemaining(child: Center(child: AppSpinner()))
            else if (_categoryProducts.isEmpty && !_categoryLoading) ...[
              // Use in-memory products from section rail
              ..._buildCategoryGrid(_visibleSections.isNotEmpty
                  ? _visibleSections.first.products
                  : []),
            ] else
              ..._buildCategoryGrid(_categoryProducts),
          ],

          // ── STOREFRONT SECTIONS (all / no pill selected) ───────────────────
          if (_selectedCategoryId == null && !_storefrontLoading) ...[
            if (_sections.isEmpty)
              const SliverFillRemaining(
                child: ShopProductEmptyState(
                  message: 'No products listed yet.',
                  icon: Icons.shopping_bag_outlined,
                ),
              )
            else
              ..._buildStorefrontSections(),
          ],

          // ── Load-more spinner ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: (_categoryLoading && _categoryProducts.isNotEmpty)
                  ? const Center(child: AppSpinner(size: 20))
                  : const SizedBox.shrink(),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  List<Widget> _buildStorefrontSections() {
    return _sections.expand<Widget>((section) {
      return [
        SliverToBoxAdapter(
          child: section.isBuyAgain
              ? _BuyAgainSection(
                  section: section,
                  onProductTap: _openProduct,
                )
              : _CategorySection(
                  section: section,
                  onProductTap: _openProduct,
                  onSeeAll: section.totalCount > section.products.length
                      ? () => _selectCategory(section.categoryId)
                      : null,
                ),
        ),
      ];
    }).toList();
  }

  List<Widget> _buildCategoryGrid(List<_Product> products) {
    if (products.isEmpty) {
      return [
        const SliverFillRemaining(
          child: ShopProductEmptyState(
            message: 'No products in this category.',
            icon: Icons.category_outlined,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
          children: products
              .map((p) => _ProductCard(product: p, onTap: () => _openProduct(p.id)))
              .toList(),
        ),
      ),
    ];
  }
}

// ─── Buy Again section ────────────────────────────────────────────────────────

class _BuyAgainSection extends StatelessWidget {
  final _StorefrontSection section;
  final ValueChanged<String> onProductTap;

  const _BuyAgainSection({required this.section, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.replay_rounded,
                    size: 14, color: AppColors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buy Again',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    section.subtitle,
                    style: const TextStyle(color: AppColors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Horizontal rail
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: section.products.length,
            itemBuilder: (_, i) => _RailCard(
              product: section.products[i],
              onTap: () => onProductTap(section.products[i].id),
              showRepeatBadge: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }
}

// ─── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final _StorefrontSection section;
  final ValueChanged<String> onProductTap;
  final VoidCallback? onSeeAll;

  const _CategorySection({
    required this.section,
    required this.onProductTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — title left, count + See All right, all on one line
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Product count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${section.totalCount}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onSeeAll != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 9, color: AppColors.greyDark),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Horizontal product rail
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: section.products.length,
            itemBuilder: (_, i) => _RailCard(
              product: section.products[i],
              onTap: () => onProductTap(section.products[i].id),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }
}

// ─── Category pills ───────────────────────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final List<_StorefrontSection> sections;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _CategoryPills({
    required this.sections,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          // "All" pill
          _Pill(
            label: 'All',
            active: selectedId == null,
            onTap: () => onSelect(null),
          ),
          ...sections.map((s) => _Pill(
                label: s.title,
                active: selectedId == s.categoryId,
                onTap: () => onSelect(s.categoryId),
              )),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: active ? AppColors.white : AppColors.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? AppColors.white : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.bg : AppColors.grey,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Rail card (horizontal scroll) ───────────────────────────────────────────

class _RailCard extends StatelessWidget {
  final _Product product;
  final VoidCallback onTap;
  final bool showRepeatBadge;

  const _RailCard({
    required this.product,
    required this.onTap,
    this.showRepeatBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 57,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(11)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surface2,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imgFallback(),
                            )
                          : _imgFallback(),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _SmallBadge(product.badge!),
                    ),
                  if (showRepeatBadge)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay_rounded,
                                size: 9, color: AppColors.white),
                            SizedBox(width: 3),
                            Text(
                              'Repeat',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
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
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => const Center(
        child: Icon(Icons.shopping_bag_outlined, size: 28, color: AppColors.grey),
      );
}

// ─── Full product card (2-col grid) ──────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final _Product product;
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
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
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
                      child: _SmallBadge(product.badge!),
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
        child: Icon(Icons.shopping_bag_outlined, size: 32, color: AppColors.grey),
      );
}

// ─── Shop hero (world-class redesign) ────────────────────────────────────────

class _ShopHero extends StatefulWidget {
  final Shop shop;
  final ShopDetail? detail;
  final bool detailLoading;
  final VoidCallback onShare;
  final Future<bool> Function(bool currentlyFollowed) onToggleFollow;

  const _ShopHero({
    required this.shop,
    required this.detail,
    required this.detailLoading,
    required this.onShare,
    required this.onToggleFollow,
  });

  @override
  State<_ShopHero> createState() => _ShopHeroState();
}

class _ShopHeroState extends State<_ShopHero> {
  bool _followLoading = false;

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final detail = widget.detail;
    final coverUrl = detail?.coverImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover photo ──────────────────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image with gradient
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl != null
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CoverPlaceholder(shop: shop),
                        )
                      : _CoverPlaceholder(shop: shop),
                  // Gradient overlay — bottom fade
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.bg.withOpacity(0.7),
                          AppColors.bg,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Shop avatar overlapping the cover bottom
            Positioned(
              bottom: -36,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.bg, width: 3),
                ),
                child: _ShopAvatar(shop: shop, size: 72),
              ),
            ),

            // Open/Closed badge — top right of cover
            Positioned(
              top: 12,
              right: 16,
              child: _OpenBadge(isOpen: shop.isOpen),
            ),
          ],
        ),

        const SizedBox(height: 44), // space for avatar overlap

        // ── Shop name + category ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.displayName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (shop.categoryName != null || shop.city.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [if (shop.categoryName != null) shop.categoryName!, if (shop.city.isNotEmpty) shop.city]
                      .join(' · '),
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Stats row: Products | Followers | Rating ─────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _StatsColumn(
                value: detail != null ? _formatCount(detail.totalProducts) : '—',
                label: 'Products',
              ),
              _VertDivider(),
              _StatsColumn(
                value: detail != null ? _formatCount(detail.followerCount) : '—',
                label: 'Followers',
              ),
              _VertDivider(),
              _StatsColumn(
                value: shop.avgRating > 0 ? shop.avgRating.toStringAsFixed(1) : '—',
                label: '${shop.reviewCount} reviews',
                valueColor: shop.avgRating > 0 ? const Color(0xFFFFC107) : AppColors.white,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Follow + Share buttons ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _FollowButton(
                  shopId: widget.shop.id,
                  detail: detail,
                  loading: _followLoading,
                  onTap: _handleFollow,
                ),
              ),
              const SizedBox(width: 10),
              _ShareIconButton(onTap: widget.onShare),
            ],
          ),
        ),

        // ── Delivery info row ─────────────────────────────────────────────────
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _InfoChip(icon: Icons.schedule_outlined, label: shop.deliveryEtaLabel),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.near_me_outlined, label: shop.distanceLabel),
              if (detail?.websiteUrl != null) ...[
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.language_outlined, label: 'Website'),
              ],
            ],
          ),
        ),

        // ── Bio ───────────────────────────────────────────────────────────────
        if (detail?.bio != null && detail!.bio!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              detail.bio!,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],

        // ── Tags ──────────────────────────────────────────────────────────────
        if (detail != null && detail.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemCount: detail.tags.length,
              itemBuilder: (_, i) => _TagChip(detail.tags[i]),
            ),
          ),
        ],

        // ── Trust badges ──────────────────────────────────────────────────────
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TrustBadge(icon: Icons.verified_outlined, label: 'Verified Seller'),
              _TrustBadge(icon: Icons.local_shipping_outlined, label: 'Fast Delivery'),
              if (detail?.avgRating != null && detail!.avgRating >= 4.0)
                const _TrustBadge(icon: Icons.thumb_up_outlined, label: 'Top Rated'),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }

  Future<void> _handleFollow() async {
    final detail = widget.detail;
    if (detail == null || _followLoading) return;

    setState(() => _followLoading = true);
    await widget.onToggleFollow(detail.isFollowed);
    if (mounted) setState(() => _followLoading = false);
  }

  String _formatCount(num count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ShopAvatar extends StatelessWidget {
  final Shop shop;
  final double size;
  const _ShopAvatar({required this.shop, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: shop.logoUrl != null
          ? Image.network(shop.logoUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Initial(shop.initial))
          : _Initial(shop.initial),
    );
  }
}

class _Initial extends StatelessWidget {
  final String letter;
  const _Initial(this.letter);
  @override
  Widget build(BuildContext context) => Center(
        child: Text(letter,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
      );
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOpen ? const Color(0xFF0F2E1A) : AppColors.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isOpen ? const Color(0xFF1E6B3A) : AppColors.border),
        ),
        child: Text(
          isOpen ? 'OPEN' : 'CLOSED',
          style: TextStyle(
            color: isOpen ? const Color(0xFF4CAF50) : AppColors.greyDark,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}


// ─── Small badge ──────────────────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  final String text;
  const _SmallBadge(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );
}

// ─── Floating icon button (over cover photo) ──────────────────────────────────

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool forceDark;

  const _FloatingIconButton({
    required this.icon,
    required this.onTap,
    this.forceDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: forceDark ? Colors.transparent : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }
}

// ─── Cover placeholder ────────────────────────────────────────────────────────

class _CoverPlaceholder extends StatelessWidget {
  final Shop shop;
  const _CoverPlaceholder({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface2,
      child: Center(
        child: Text(
          shop.initial,
          style: const TextStyle(
            color: AppColors.greyDark,
            fontSize: 64,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Stats column ─────────────────────────────────────────────────────────────

class _StatsColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatsColumn({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.greyDark, fontSize: 11),
            ),
          ],
        ),
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.divider);
}

// ─── Follow button ────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final String shopId;
  final ShopDetail? detail;
  final bool loading;
  final VoidCallback onTap;

  const _FollowButton({
    required this.shopId,
    required this.detail,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final followed = detail?.isFollowed ?? false;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        decoration: BoxDecoration(
          color: followed ? AppColors.surface2 : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: followed ? AppColors.border : AppColors.white),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: followed ? AppColors.grey : AppColors.bg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      followed ? Icons.check_rounded : Icons.add_rounded,
                      size: 16,
                      color: followed ? AppColors.grey : AppColors.bg,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      followed ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: followed ? AppColors.grey : AppColors.bg,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Share icon button ────────────────────────────────────────────────────────

class _ShareIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.ios_share_rounded,
              size: 18, color: AppColors.white),
        ),
      );
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

// ─── Tag chip ─────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip(this.tag);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

// ─── Trust badge ──────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.green),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

// ─── Tap-to-search bar ────────────────────────────────────────────────────────

class _TapToSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;

  const _TapToSearchBar({required this.hint, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: AppColors.greyDark, size: 18),
            const SizedBox(width: 8),
            Text(
              hint,
              style: const TextStyle(
                color: AppColors.greyDark,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

