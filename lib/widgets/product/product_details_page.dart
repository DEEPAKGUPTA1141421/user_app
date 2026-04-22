import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/product_provider.dart';
import '../../provider/cart_provider.dart';
import '../../provider/rider_provider.dart';
import '../../core/api/api_client.dart';
import '../../utils/app_colors.dart';
import '../../screens/buy_now_button.dart';
import '../../widgets/real_search_page.dart';
import 'share_sheet.dart';
import 'product_image_carousel.dart';
import 'delivery_info.dart';
import 'service_features.dart';
import 'best_review.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  bool _argsLoaded = false;
  late String itemType;
  late String title;
  late String imageUrl;
  late String itemId;

  String? _selectedSize;
  bool _isAddingToCart = false;
  bool _isTogglingWishlist = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    Future.microtask(() {
      ref.read(productPod.notifier).fetchProductDetail(widget.productId);
    });
  }

  // ── Add to Cart ──────────────────────────────────────────────────────────
  Future<void> _handleAddToCart(String variantId) async {
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    try {
      await ref.read(cartProvider.notifier).addItem({
        'productId': widget.productId,
        'variantId': variantId,
        'quantity': 1,
      });
      // Refresh user so cartItemIds updates instantly
      await ref.read(riderPod.notifier).getUserDetail();
      if (mounted) {
        _showSnack('Added to cart!', isSuccess: true);
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to add to cart', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  // ── Wishlist toggle ──────────────────────────────────────────────────────
  Future<void> _handleWishlist(bool currentlyInWishlist) async {
    if (_isTogglingWishlist) return;
    setState(() => _isTogglingWishlist = true);
    try {
      final client = ApiClient.instance.productClient;
      if (currentlyInWishlist) {
        await client.delete('/api/v1/wishlist/${widget.productId}');
        if (mounted) _showSnack('Removed from wishlist');
      } else {
        await client.post('/api/v1/wishlist/${widget.productId}');
        if (mounted) _showSnack('Added to wishlist!', isSuccess: true);
      }
      // Refresh user so wishlistItemIds updates instantly
      await ref.read(riderPod.notifier).getUserDetail();
    } catch (_) {
      if (mounted) _showSnack('Something went wrong');
    } finally {
      if (mounted) setState(() => _isTogglingWishlist = false);
    }
  }

  // ── Share ────────────────────────────────────────────────────────────────
  void _handleShare(String name, double price) {
    showShareSheet(
      context,
      productName: name,
      price: price,
      productId: widget.productId,
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.white, fontSize: 13)),
        backgroundColor:
            isSuccess ? Colors.green.shade900 : AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        itemType = args['itemType'] ?? 'Product';
        title = args['title'] ?? 'Unnamed Product';
        imageUrl = args['imageUrl'] ?? '';
        itemId = args['itemId'] ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(productPod.notifier).saveSearch(
                itemId: itemId,
                itemType: itemType,
                title: title,
                imageUrl: imageUrl,
              );
        });
      }
      _argsLoaded = true;
    }
  }

  // ── Parse malformed image URLs from API ──────────────────────────────────
  List<String> _parseImages(List? raw) {
    if (raw == null) return [];
    return raw
        .map((e) => e
            .toString()
            .replaceAll('"', '')
            .replaceAll('[', '')
            .replaceAll(']', '')
            .trim())
        .where((u) => u.startsWith('http'))
        .toList();
  }

  // ── Group flat attributes by name ─────────────────────────────────────────
  Map<String, List<String>> _groupAttrs(List attrs) {
    final map = <String, List<String>>{};
    for (final a in attrs) {
      final n = (a['name'] as String? ?? '').trim();
      final v = (a['value'] as String? ?? '').trim();
      if (n.isNotEmpty && v.isNotEmpty) (map[n] ??= []).add(v);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productPod);
    final isLoading = productState.isLoading;
    final detail = productState.productDetail;
    final userData = ref.watch(riderPod);

    // ── Unpack new API shape: data.product + data.ratingSummary ──────────
    final product = detail['product'] as Map<String, dynamic>? ?? {};
    final ratingSummary =
        detail['ratingSummary'] as Map<String, dynamic>? ?? {};

    final variantId = product['variant_id'] as String? ?? '';

    final isInCart = userData.cartItemIds.contains(widget.productId) ||
        (variantId.isNotEmpty && userData.cartItemIds.contains(variantId));

    final isInWishlist =
        userData.wishlistItemIds.contains(widget.productId) ||
        (variantId.isNotEmpty &&
            userData.wishlistItemIds.contains(variantId));

    final name = product['name'] as String? ?? 'Unnamed Product';
    final description = product['description'] as String? ?? '';
    final brand = product['brand_name'] as String? ?? '';
    final inStock = product['in_stock'] as bool? ?? true;
    final freeDelivery = product['free_delivery'] as bool? ?? true;
    final deliveryDays = (product['delivery_days'] as num?)?.toInt() ?? 5;
    final deliveryText = freeDelivery
        ? 'Free Delivery in $deliveryDays days'
        : 'Delivery in $deliveryDays days';

    final price =
        ((product['min_price_paise'] as num?)?.toDouble() ?? 0.0) / 100;
    final originalPrice =
        ((product['original_price_paise'] as num?)?.toDouble() ?? 0.0) / 100;
    final discountPct = (product['discount_percent'] as num?)?.toInt() ?? 0;

    final avgRating =
        (ratingSummary['averageRating'] as num?)?.toDouble() ?? 0.0;
    final totalRatings =
        (ratingSummary['totalRatings'] as num?)?.toInt() ?? 0;

    final rawImages = product['images'] as List?;
    final imageUrls = _parseImages(rawImages);

    final rawAttrs = product['attributes'] as List? ?? [];
    final attrGroups = _groupAttrs(rawAttrs);

    // Trigger fade-in once content is ready
    if (!isLoading && detail.isNotEmpty && !_fadeCtrl.isCompleted) {
      _fadeCtrl.forward();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.white, size: 15),
                  ),
                ),
                title: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RealSearchPage()),
                  ),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 12),
                        Icon(CupertinoIcons.search,
                            color: AppColors.grey, size: 15),
                        SizedBox(width: 8),
                        Text('Search for products',
                            style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppColors.divider),
                ),
              ),

              // ── Content ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: isLoading
                    ? _buildShimmer()
                    : detail.isEmpty
                        ? _buildEmpty()
                        : FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image carousel
                                  ProductImageCarousel(
                                    imageUrls: imageUrls,
                                    productDetails: const {},
                                    rating: avgRating,
                                    ratingCount: _fmtCount(totalRatings),
                                    isInWishlist: isInWishlist,
                                    isTogglingWishlist: _isTogglingWishlist,
                                    onWishlist: () =>
                                        _handleWishlist(isInWishlist),
                                    onShare: () => _handleShare(name, price),
                                  ),

                                  const SizedBox(height: 4),

                                  // ── Identity card ────────────────────
                                  _buildIdentityCard(
                                    name: name,
                                    brand: brand,
                                    badge: inStock ? null : 'Out of Stock',
                                    price: price,
                                    originalPrice: originalPrice > price
                                        ? originalPrice
                                        : null,
                                    discountPct:
                                        discountPct > 0 ? discountPct : null,
                                    rating: avgRating,
                                    reviewCount: totalRatings,
                                    deliveryText: deliveryText,
                                    freeDelivery: freeDelivery,
                                    description: description,
                                  ),

                                  const SizedBox(height: 10),

                                  // ── Attributes ───────────────────────
                                  _buildAttrGroups(attrGroups),

                                  const SizedBox(height: 10),

                                  // ── Delivery & Services ──────────────
                                  const _SectionLabel('DELIVERY & SERVICES'),
                                  _card(
                                    child: DeliveryInfo(
                                      deliveryDays: deliveryDays,
                                      brandName: brand,
                                      freeDelivery: freeDelivery,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _card(child: const ServiceFeatures()),

                                  const SizedBox(height: 10),

                                  // ── Ratings & Reviews ─────────────────
                                  const _SectionLabel('RATINGS & REVIEWS'),
                                  _card(
                                    child: BestReview(
                                      productId: widget.productId,
                                      ratingSummary: ratingSummary,
                                    ),
                                  ),

                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),

          // ── Sticky Bottom Bar ────────────────────────────────────────
          ProductActionBar(
            isInCart: isInCart,
            inStock: inStock,
            isAddingToCart: _isAddingToCart,
            onAddToCart: variantId.isNotEmpty
                ? () => _handleAddToCart(variantId)
                : null,
            productId: widget.productId,
            variantId: variantId,
            productName: name,
            productImage: imageUrls.isNotEmpty ? imageUrls.first : null,
            price: price,
          ),
        ],
      ),
    );
  }

  // ── Identity Card ──────────────────────────────────────────────────────────
  Widget _buildIdentityCard({
    required String name,
    required String brand,
    required String? badge,
    required double price,
    required double? originalPrice,
    required int? discountPct,
    required double rating,
    required int reviewCount,
    required String deliveryText,
    required bool freeDelivery,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + badge
          Row(
            children: [
              if (brand.isNotEmpty)
                Text(brand.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(name,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: -0.3)),

          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              if (originalPrice != null) ...[
                const SizedBox(width: 8),
                Text('₹${originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.greyDark,
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.greyDark)),
              ],
              if (discountPct != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$discountPct% off',
                      style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Rating row
          if (reviewCount > 0) ...[
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: rating >= 4
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.white, size: 11),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('${_fmtCount(reviewCount)} ratings',
                    style:
                        const TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Delivery
          Row(
            children: [
              Icon(
                freeDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.delivery_dining_outlined,
                color: freeDelivery ? AppColors.green : AppColors.grey,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(deliveryText,
                    style: TextStyle(
                        color: freeDelivery ? AppColors.green : AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),

          // Description
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Text(description,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.6)),
          ],
        ],
      ),
    );
  }

  // ── Attribute Groups (flat API format) ─────────────────────────────────────
  Widget _buildAttrGroups(Map<String, List<String>> groups) {
    if (groups.isEmpty) return const SizedBox.shrink();

    // Separate "Size" from other text attributes
    final sizeValues = groups['Size'] ?? groups['size'] ?? [];
    final others = Map<String, List<String>>.from(groups)
      ..remove('Size')
      ..remove('size');

    return Column(
      children: [
        // Size selector
        if (sizeValues.isNotEmpty) ...[
          _buildSizeSection(sizeValues),
          const SizedBox(height: 10),
        ],
        // Text attributes table
        if (others.isNotEmpty) _buildAttributeTable(others),
      ],
    );
  }

  Widget _buildSizeSection(List<String> sizes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SIZE',
                  style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4)),
              if (_selectedSize != null) ...[
                const SizedBox(width: 8),
                Text(_selectedSize!,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map<Widget>((s) {
              final isSelected = _selectedSize == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSize = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white.withOpacity(0.1)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.white : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          color:
                              isSelected ? AppColors.white : AppColors.grey,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeTable(Map<String, List<String>> attrs) {
    final entries = attrs.entries.toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text('PRODUCT DETAILS',
                    style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4)),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          ...entries.asMap().entries.map((e) {
            final isLast = e.key == entries.length - 1;
            final name = e.value.key;
            final vals = e.value.value;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(name,
                            style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text(vals.join(', '),
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Container(height: 1, color: AppColors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Card wrapper ───────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Column(
      children: [
        _Shimmer(child: Container(height: 320, color: AppColors.surface)),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Shimmer(child: _shimBox(80, 10)),
              const SizedBox(height: 12),
              _Shimmer(child: _shimBox(double.infinity, 16)),
              const SizedBox(height: 8),
              _Shimmer(child: _shimBox(200, 16)),
              const SizedBox(height: 16),
              _Shimmer(child: _shimBox(120, 28)),
              const SizedBox(height: 12),
              _Shimmer(child: _shimBox(140, 12)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Shimmer(child: _shimBox(60, 10)),
              const SizedBox(height: 14),
              Row(children: [
                for (int i = 0; i < 4; i++) ...[
                  _Shimmer(child: _shimBox(50, 36)),
                  const SizedBox(width: 8),
                ],
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.greyDark, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Product not found',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('This product may no longer be available.',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K+' : '$n';
}

// ─── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4)),
    );
  }
}

// ─── Shimmer helpers ───────────────────────────────────────────────────────────
class _Shimmer extends StatelessWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface2,
      highlightColor: AppColors.border,
      child: child,
    );
  }
}

Widget _shimBox(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
    );

