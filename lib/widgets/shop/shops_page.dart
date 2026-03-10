import 'package:flutter/material.dart';
import './mock_data.dart';
import './models.dart';
import './app_theme.dart';
import './shop_card.dart';
import './filter_drawer.dart';
import './shop_details_page.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _activeCategory;
  FilterOptions _filters = const FilterOptions();

  List<String> get _allCategories =>
      mockShops.map((s) => s.category).toSet().toList();

  List<Shop> get _filteredShops {
    return mockShops.where((shop) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!shop.name.toLowerCase().contains(q) &&
            !shop.category.toLowerCase().contains(q) &&
            !shop.tags.any((t) => t.toLowerCase().contains(q))) {
          return false;
        }
      }

      // Category filter
      if (_activeCategory != null && shop.category != _activeCategory) {
        return false;
      }

      // Distance filter
      if (_filters.distance.isNotEmpty) {
        final shopDist = double.tryParse(shop.distance.replaceAll(' km', '')) ?? 99;
        final matches = _filters.distance.any((filter) {
          final maxDist = double.tryParse(filter.replaceAll('< ', '').replaceAll(' km', '')) ?? 0;
          return shopDist < maxDist;
        });
        if (!matches) return false;
      }

      // Category filter from drawer
      if (_filters.categories.isNotEmpty && !_filters.categories.contains(shop.category)) {
        return false;
      }

      // Rating filter
      if (_filters.rating.isNotEmpty) {
        final matches = _filters.rating.any((filter) {
          final minRating = double.tryParse(filter.replaceAll('+', '')) ?? 0;
          return shop.rating >= minRating;
        });
        if (!matches) return false;
      }

      // Offers filter
      if (_filters.offers.isNotEmpty && shop.offer == null) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterDrawer(
        filters: _filters,
        onApplyFilters: (filters) {
          setState(() => _filters = filters);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shops = _filteredShops;

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.location_on, size: 16, color: kPrimary),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivering to', style: TextStyle(fontSize: 11, color: kTextMuted)),
                              Row(
                                children: const [
                                  Text('Koramangala, Bangalore', style: TextStyle(fontSize: 13, color: kTextPrimary, fontWeight: FontWeight.w500)),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: kPrimary),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search + Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search shops, brands, categories...',
                                hintStyle: const TextStyle(fontSize: 13, color: kTextMuted),
                                prefixIcon: const Icon(Icons.search, color: kTextMuted, size: 20),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _showFilterDrawer,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: kBorder, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.tune, size: 20, color: kTextSecondary),
                                ),
                                if (_filters.totalSelected > 0)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          '${_filters.totalSelected}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    children: [
                      _buildCategoryPill('All', null),
                      ..._allCategories.map((cat) => _buildCategoryPill(cat, cat)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _activeCategory != null ? '$_activeCategory Shops' : 'Popular Shops Near You',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kTextPrimary),
                    ),
                    Text('${shops.length} shops', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          if (shops.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store_outlined, size: 56, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 16),
                    const Text('No shops found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTextSecondary)),
                    const SizedBox(height: 8),
                    const Text('Try adjusting your search or filters', style: TextStyle(color: kTextMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _activeCategory = null;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 360,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShopCard(
                    shop: shops[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ShopDetailsPage(shopId: shops[index].id)),
                    ),
                  ),
                  childCount: shops.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, String? category) {
    final isActive = _activeCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = isActive ? null : category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? kPrimary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : kTextSecondary,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}