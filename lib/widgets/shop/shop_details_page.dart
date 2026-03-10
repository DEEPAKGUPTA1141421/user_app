import 'package:flutter/material.dart';
import './mock_data.dart';
import './models.dart';
import './app_theme.dart';
import './product_card.dart';
import './reviews_page.dart';

class ShopDetailsPage extends StatefulWidget {
  final String shopId;
  const ShopDetailsPage({super.key, required this.shopId});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Shop? get shop => mockShops.firstWhere((s) => s.id == widget.shopId, orElse: () => mockShops.first);

  List<ProductCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return shop!.productCategories;
    return shop!.productCategories
        .map((cat) => ProductCategory(
              name: cat.name,
              products: cat.products
                  .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList(),
            ))
        .where((cat) => cat.products.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = shop;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Shop not found')),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          // Hero banner + app bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: kTextPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    s.bannerImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6)),
                  ),
                  // Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                  // Shop info at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(s.category, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          const SizedBox(height: 6),
                          Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          Text(s.description, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shop meta info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating, distance, delivery, reviews button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(s.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${_formatCount(s.ratingCount)} ratings', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 14, color: kPrimary),
                      const SizedBox(width: 4),
                      Text(s.distance, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReviewsPage(shopId: s.id)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 14, color: kPrimary),
                        label: const Text('Reviews', style: TextStyle(color: kPrimary, fontSize: 13)),
                        style: TextButton.styleFrom(
                          backgroundColor: kPrimaryLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: kTextMuted),
                      const SizedBox(width: 4),
                      Text('Delivery: ${s.deliveryTime}', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                    ],
                  ),

                  // Offer banner
                  if (s.offer != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kPrimary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.percent, size: 16, color: kPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.offer!, style: const TextStyle(fontSize: 13, color: kPrimary)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tags
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: s.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.label_outline, size: 11, color: kTextMuted),
                          const SizedBox(width: 4),
                          Text(tag, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Sticky search bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search products in ${s.name}...',
                    hintStyle: const TextStyle(fontSize: 13, color: kTextMuted),
                    prefixIcon: const Icon(Icons.search, color: kTextMuted, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // Products by category
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _filteredCategories.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                const Icon(Icons.search_off, size: 48, color: Color(0xFFD1D5DB)),
                                const SizedBox(height: 12),
                                Text('No products found for "$_searchQuery"',
                                    style: const TextStyle(color: kTextSecondary)),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Text('Clear search', style: TextStyle(color: kPrimary)),
                                ),
                              ],
                            ),
                          ),
                        )
                      ]
                    : _filteredCategories.map((category) => _buildCategoryRow(category)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(ProductCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary)),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: const [
                    Text('See all', style: TextStyle(color: kPrimary, fontSize: 13)),
                    Icon(Icons.chevron_right, size: 16, color: kPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: category.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => ProductCard(product: category.products[index]),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => true;
}