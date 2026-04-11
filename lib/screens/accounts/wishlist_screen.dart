import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/wishlist_notifier.dart';
import '../../provider/cart_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  static const brandColor = Colors.black;
  String activeTab = "wishlist"; // "wishlist" or "priceDrops"

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(wishlistProvider.notifier).fetchWishlist();
      ref.read(wishlistProvider.notifier).fetchPriceDrops();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(wishlistProvider.notifier).fetchWishlist();
    await ref.read(wishlistProvider.notifier).fetchPriceDrops();
  }

  void _removeItem(String productId) async {
    final res = await ref.read(wishlistProvider.notifier).removeItem(productId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'Removed from wishlist' : 'Failed to remove'),
          backgroundColor: res['success'] == true ? Colors.black87 : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _moveToCart(String productId) async {
    final res = await ref.read(wishlistProvider.notifier).moveToCart(productId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'Added to cart!' : 'Failed to add to cart'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareWishlist() async {
    final res = await ref.read(wishlistProvider.notifier).shareWishlist();
    if (mounted && res['success'] == true) {
      final data = res['data'] ?? {};
      final url = data['shareUrl'] ?? '';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Share Wishlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your wishlist share link:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(url, style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = ref.watch(wishlistProvider);
    final isLoading  = state.isLoading;
    final items      = state.items;
    final priceDrops = state.priceDrops;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareWishlist,
            tooltip: 'Share Wishlist',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                _TabButton(
                  label: 'My Wishlist',
                  count: items.length,
                  isActive: activeTab == 'wishlist',
                  onTap: () => setState(() => activeTab = 'wishlist'),
                ),
                _TabButton(
                  label: 'Price Drops',
                  count: priceDrops.length,
                  isActive: activeTab == 'priceDrops',
                  onTap: () => setState(() => activeTab = 'priceDrops'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: brandColor,
        child: activeTab == 'wishlist'
            ? _buildWishlistTab(isLoading, items)
            : _buildPriceDropsTab(isLoading, priceDrops),
      ),
    );
  }

  Widget _buildWishlistTab(bool isLoading, List<dynamic> items) {
    if (isLoading && items.isEmpty) {
      return _buildShimmerGrid();
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        subtitle: 'Save items you love and come back to them anytime',
        cta: 'Start Exploring',
        onCta: () => Navigator.pop(context),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _WishlistCard(
          item: item,
          onRemove: () => _removeItem(item['productId']?.toString() ?? ''),
          onMoveToCart: () => _moveToCart(item['productId']?.toString() ?? ''),
        );
      },
    );
  }

  Widget _buildPriceDropsTab(bool isLoading, List<dynamic> drops) {
    if (isLoading && drops.isEmpty) {
      return _buildShimmerList();
    }

    if (drops.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_down,
        title: 'No price drops yet',
        subtitle: 'We\'ll notify you when prices drop on your wishlisted items',
        cta: 'View Wishlist',
        onCta: () => setState(() => activeTab = 'wishlist'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: drops.length,
      itemBuilder: (context, index) {
        final drop = drops[index];
        return _PriceDropCard(drop: drop);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String cta,
    required VoidCallback onCta,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: brandColor),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(cta),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5200);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? brandColor : Colors.grey[600],
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? brandColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              Container(height: 2, color: brandColor)
            else
              Container(height: 2, color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  const _WishlistCard({
    required this.item,
    required this.onRemove,
    required this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5200);
    final name = item['name'] ?? item['productId'] ?? 'Product';
    final imageUrl = item['imageUrl'] ?? item['image'] ?? '';
    final price = item['price']?.toString() ?? '';
    final addedPrice = item['addedPrice']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + remove button
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                  const Spacer(),
                  if (price.isNotEmpty)
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onMoveToCart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandColor,
                        side: const BorderSide(color: brandColor),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.grey),
      ),
    );
  }
}

class _PriceDropCard extends StatelessWidget {
  final Map<String, dynamic> drop;

  const _PriceDropCard({required this.drop});

  @override
  Widget build(BuildContext context) {
    final name = drop['productName'] ?? 'Product';
    final imageUrl = drop['imageUrl'] ?? '';
    final currentPrice = drop['currentPrice']?.toString() ?? '';
    final addedPrice = drop['addedPrice']?.toString() ?? '';
    final dropAmount = drop['dropAmount']?.toString() ?? '';
    final dropPercent = (drop['dropPercent'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: Colors.grey[100], child: const Icon(Icons.image_not_supported_outlined)))
                : Container(width: 72, height: 72, color: Colors.grey[100], child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey)),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('₹$currentPrice',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    if (addedPrice.isNotEmpty)
                      Text('₹$addedPrice',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '↓ ${dropPercent.toStringAsFixed(1)}% off  ₹$dropAmount saved',
                        style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}