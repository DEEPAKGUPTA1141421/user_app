import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../provider/product_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/product_search_results_page.dart';

const Color _kBrand = Color(0xFFFF5200);

// ─── Suggestion Model ─────────────────────────────────────────────────────────
class SearchSuggestion {
  final String id;
  final String keyword;
  final String imageUrl;
  final String suggestionType;
  final Map<String, dynamic> filterPayload;

  SearchSuggestion({
    required this.id,
    required this.keyword,
    required this.imageUrl,
    required this.suggestionType,
    required this.filterPayload,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      id: json['id'] ?? '',
      keyword: json['keyword'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      suggestionType: json['suggestionType'] ?? 'AUTO',
      filterPayload: Map<String, dynamic>.from(json['filterPayload'] ?? {}),
    );
  }
}

// ─── Search Result Item Model ─────────────────────────────────────────────────
class SearchResultItem {
  final String id;
  final String name;
  final String? imageUrl;
  final double? price;
  final double? discountPrice;
  final String? category;
  final String? brand;
  final double? rating;
  final int? ratingCount;
  final String type;

  SearchResultItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.price,
    this.discountPrice,
    this.category,
    this.brand,
    this.rating,
    this.ratingCount,
    required this.type,
  });

  factory SearchResultItem.fromProduct(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    return SearchResultItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unnamed Product',
      imageUrl: (images != null && images.isNotEmpty) ? images[0] : null,
      price: (json['price'] as num?)?.toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      category: json['category'],
      brand: json['brand'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
      type: 'PRODUCT',
    );
  }

  factory SearchResultItem.fromBrand(Map<String, dynamic> json) {
    return SearchResultItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Brand',
      imageUrl: json['logoUrl'],
      category: json['description'],
      type: 'BRAND',
    );
  }
}

// ─── Real Search Page ─────────────────────────────────────────────────────────
class RealSearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;

  const RealSearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<RealSearchPage> createState() => _RealSearchPageState();
}

class _RealSearchPageState extends ConsumerState<RealSearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  String _query = '';
  bool _isLoadingSuggestions = false;
  bool _isLoadingResults = false;
  List<SearchSuggestion> _suggestions = [];
  List<SearchResultItem> _results = [];
  String _errorMessage = '';
  bool _hasSearched = false;

  // ── Default state data ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _recentSearches = [];
  List<Map<String, dynamic>> _trendingSearches = [];
  List<Map<String, dynamic>> _popularProducts = [];
  bool _loadingDefault = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    final initial = widget.initialQuery;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _query = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(initial);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    _loadDefaultSections();
  }

  // ── Load all three default sections in parallel ───────────────────────────
  Future<void> _loadDefaultSections() async {
    setState(() => _loadingDefault = true);
    final notifier = ref.read(productPod.notifier);
    final results = await Future.wait([
      notifier.getRecentSearches(),
      notifier.getTrendingSearches(),
      notifier.getPopularProducts(),
    ]);
    if (mounted) {
      setState(() {
        _recentSearches = results[0].cast<Map<String, dynamic>>();
        _trendingSearches = results[1].cast<Map<String, dynamic>>();
        _popularProducts = results[2].cast<Map<String, dynamic>>();
        _loadingDefault = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Fetch suggestions ─────────────────────────────────────────────────────
  Future<void> _fetchSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _isLoadingSuggestions = true);
    try {
      final res = await ApiClient.instance.productClient.get(
        ApiEndpoints.searchProducts,
        queryParameters: {'keyword': query},
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as List? ?? [];
        setState(() {
          _suggestions = data
              .map((e) => SearchSuggestion.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        });
      }
    } catch (_) {
      // Silently fail — suggestions are non-critical
    } finally {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  // ── Perform search ────────────────────────────────────────────────────────
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingResults = true;
      _hasSearched = true;
      _suggestions = [];
      _errorMessage = '';
      _results = [];
    });
    _focusNode.unfocus();
    try {
      final res = await ApiClient.instance.productClient.get(
        ApiEndpoints.searchProducts,
        queryParameters: {'keyword': query},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final products = (data['products'] ?? []) as List;
      final brands = (data['brands'] ?? []) as List;
      final List<SearchResultItem> items = [
        ...brands.map((b) => SearchResultItem.fromBrand(Map<String, dynamic>.from(b))),
        ...products.map((p) => SearchResultItem.fromProduct(Map<String, dynamic>.from(p))),
      ];
      setState(() => _results = items);
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoadingResults = false);
    }
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      if (value.isEmpty) {
        _hasSearched = false;
        _suggestions = [];
        _results = [];
      }
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.length >= 2) _fetchSuggestions(value);
    });
  }

  void _selectSuggestion(SearchSuggestion s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductSearchResultsPage(
          query: s.keyword,
          filterPayload: s.filterPayload,
        ),
      ),
    );
  }

  void _searchKeyword(String keyword) {
    _controller.text = keyword;
    setState(() => _query = keyword);
    _performSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.white, size: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: AppColors.white,
                style: const TextStyle(
                    color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w400),
                onChanged: _onQueryChanged,
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products, brands...',
                  hintStyle: const TextStyle(color: AppColors.greyDark, fontSize: 14),
                  prefixIcon: const Icon(CupertinoIcons.search, size: 17, color: AppColors.grey),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _hasSearched = false;
                              _suggestions = [];
                              _results = [];
                            });
                            _focusNode.requestFocus();
                          },
                          child: const Icon(CupertinoIcons.xmark_circle_fill,
                              size: 16, color: AppColors.grey),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _performSearch(_query),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.search, color: AppColors.bg, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body Router ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoadingResults) return _buildLoadingResults();
    if (_hasSearched && _results.isNotEmpty) return _buildResults();
    if (_hasSearched && !_isLoadingResults) return _buildEmptyResults();
    if (_suggestions.isNotEmpty && _query.length >= 2) return _buildSuggestions();
    return _buildDefaultState();
  }

  // ── Default / Landing State ────────────────────────────────────────────────
  Widget _buildDefaultState() {
    if (_loadingDefault) return _buildDefaultShimmer();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recent Searches ──────────────────────────────────────────────
          if (_recentSearches.isNotEmpty) ...[
            _sectionLabel('RECENT SEARCHES', Icons.history_rounded),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recentSearches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) {
                  final item = _recentSearches[i];
                  final title = item['title'] as String? ?? '';
                  final imageUrl = item['imageUrl'] as String? ?? '';
                  return GestureDetector(
                    onTap: () => _searchKeyword(title),
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RecentAvatar(imageUrl: imageUrl, label: title),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            const _Divider(),
          ],

          // ── Trending Now ─────────────────────────────────────────────────
          if (_trendingSearches.isNotEmpty) ...[
            _sectionLabel('TRENDING NOW', Icons.local_fire_department_rounded, accentIcon: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  _trendingSearches.length.clamp(0, 8),
                  (i) {
                    final item = _trendingSearches[i];
                    final keyword = item['keyword'] as String? ?? item['name'] as String? ?? '';
                    final imgUrl = item['imageUrl'] as String? ?? '';
                    return InkWell(
                      onTap: () => _searchKeyword(keyword),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            // Rank number
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: i < 3 ? _kBrand : AppColors.greyDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Thumbnail if available
                            if (imgUrl.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  imgUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(width: 36, height: 36),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                keyword,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Icon(Icons.north_west_rounded,
                                size: 13, color: AppColors.greyDark),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const _Divider(),
          ],

          // ── Popular Products ─────────────────────────────────────────────
          if (_popularProducts.isNotEmpty) ...[
            _sectionLabel('POPULAR PRODUCTS', Icons.star_rounded),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: _popularProducts.length.clamp(0, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (_, i) {
                final p = _popularProducts[i];
                return _PopularProductCard(
                  product: p,
                  onTap: () {
                    final id = p['id']?.toString() ?? '';
                    if (id.isEmpty) return;
                    Navigator.pushNamed(
                      context,
                      '/productDetail/$id',
                      arguments: {
                        'itemType': 'PRODUCT',
                        'title': p['name'] ?? '',
                        'imageUrl': (p['images'] as List?)?.firstOrNull ?? '',
                        'itemId': id,
                      },
                    );
                  },
                );
              },
            ),
          ],

          // If all three are empty after loading
          if (!_loadingDefault &&
              _recentSearches.isEmpty &&
              _trendingSearches.isEmpty &&
              _popularProducts.isEmpty)
            _buildSearchHint(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, {bool accentIcon = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: accentIcon ? _kBrand : AppColors.grey),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHint() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(CupertinoIcons.search,
                  color: AppColors.greyDark, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Start typing to search',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Find products, brands, categories and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ── Default Shimmer ────────────────────────────────────────────────────────
  Widget _buildDefaultShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent shimmer row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _shimBox(80, 10),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimCircle(48),
                  const SizedBox(height: 6),
                  _shimBox(48, 9),
                ],
              ),
            ),
          ),
          const _Divider(),
          // Trending shimmer list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _shimBox(100, 10),
          ),
          ...List.generate(5, (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _shimBox(20, 13),
              const SizedBox(width: 10),
              Expanded(child: _shimBox(double.infinity, 13)),
            ]),
          )),
          const _Divider(),
          // Popular products shimmer grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _shimBox(120, 10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: _shimBox(double.infinity, double.infinity),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimBox(double.infinity, 11),
                          const SizedBox(height: 6),
                          _shimBox(70, 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions Dropdown ───────────────────────────────────────────────────
  Widget _buildSuggestions() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Container(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) {
        final s = _suggestions[i];
        final hasPrice = s.filterPayload['price'] != null;
        final hasMaterial = s.filterPayload['filters']?['material'] != null;
        final hasFit = s.filterPayload['filters']?['fit'] != null;
        final hasFabric = s.filterPayload['filters']?['fabric'] != null;
        final hasLength = s.filterPayload['filters']?['length'] != null;

        String? badge;
        if (hasPrice) badge = '₹';
        if (hasMaterial) badge = '🧵';
        if (hasFit) badge = '✂️';
        if (hasFabric) badge = '🌿';
        if (hasLength) badge = '📏';

        return InkWell(
          onTap: () => _selectSuggestion(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: badge != null
                        ? Text(badge, style: const TextStyle(fontSize: 16))
                        : const Icon(CupertinoIcons.search,
                            size: 14, color: AppColors.grey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(s.keyword,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                ),
                const Icon(Icons.north_west_rounded,
                    size: 14, color: AppColors.greyDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Loading Results ────────────────────────────────────────────────────────
  Widget _buildLoadingResults() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _ShimmerItem(),
    );
  }

  // ── Results List ───────────────────────────────────────────────────────────
  Widget _buildResults() {
    final brands = _results.where((r) => r.type == 'BRAND').toList();
    final products = _results.where((r) => r.type == 'PRODUCT').toList();

    return CustomScrollView(
      slivers: [
        if (brands.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _resultSectionHeader(
                '${brands.length} Brand${brands.length > 1 ? 's' : ''}',
                Icons.storefront_outlined),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _BrandResultCard(item: brands[i]),
              childCount: brands.length,
            ),
          ),
        ],
        if (products.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _resultSectionHeader(
                '${products.length} Product${products.length > 1 ? 's' : ''}',
                Icons.shopping_bag_outlined),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductResultCard(item: products[i], query: _query),
              childCount: products.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  Widget _resultSectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty Results ──────────────────────────────────────────────────────────
  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text('No results for "$_query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3)),
            const SizedBox(height: 8),
            const Text('Try a different keyword or check for spelling mistakes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {
                  _query = '';
                  _hasSearched = false;
                  _results = [];
                });
                _focusNode.requestFocus();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Clear Search',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent avatar ─────────────────────────────────────────────────────────────
class _RecentAvatar extends StatelessWidget {
  final String imageUrl;
  final String label;
  const _RecentAvatar({required this.imageUrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(label))
            : _fallback(label),
      ),
    );
  }

  Widget _fallback(String label) {
    return Container(
      color: AppColors.surface2,
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppColors.grey, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─── Popular product card ──────────────────────────────────────────────────────
class _PopularProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _PopularProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final images = product['images'] as List?;
    final imgUrl = (images != null && images.isNotEmpty) ? images[0] as String : '';
    final name = product['name'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble();
    final discountPrice = (product['discountPrice'] as num?)?.toDouble();
    final hasDiscount = price != null && discountPrice != null && discountPrice < price;
    final discountPct = hasDiscount
        ? (((price - discountPrice) / price) * 100).toStringAsFixed(0)
        : null;

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
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: AppColors.surface2,
                  width: double.infinity,
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (discountPrice != null)
                        Text('₹${discountPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700))
                      else if (price != null)
                        Text('₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 5),
                        Text(
                          '$discountPct% off',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.shopping_bag_outlined,
          color: AppColors.greyDark, size: 28),
    );
  }
}

// ─── Divider ───────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, margin: const EdgeInsets.only(top: 8), color: AppColors.divider);
  }
}

// ─── Shimmer helpers (module-level) ───────────────────────────────────────────
Widget _shimBox(double w, double h, {double radius = 6}) {
  return _ShimmerBlock(width: w, height: h, radius: radius);
}

Widget _shimCircle(double size) {
  return _ShimmerBlock(width: size, height: size, radius: size / 2);
}

class _ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBlock(
      {required this.width, required this.height, required this.radius});

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
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
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_anim.value - 1).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 1).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Brand Result Card ─────────────────────────────────────────────────────────
class _BrandResultCard extends StatelessWidget {
  final SearchResultItem item;
  const _BrandResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(
              child: item.imageUrl != null &&
                      item.imageUrl!.isNotEmpty &&
                      item.imageUrl != 'DEFAULT_IMAGE'
                  ? Image.network(item.imageUrl!, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2)),
                if (item.category != null && item.category!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(item.category!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppColors.grey, fontSize: 12)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('Brand',
                style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surface2,
      child: const Icon(Icons.storefront_outlined,
          color: AppColors.greyDark, size: 22),
    );
  }
}

// ─── Product Result Card ───────────────────────────────────────────────────────
class _ProductResultCard extends StatelessWidget {
  final SearchResultItem item;
  final String query;
  const _ProductResultCard({required this.item, required this.query});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.price != null &&
        item.discountPrice != null &&
        item.discountPrice! < item.price!;
    final discountPct = hasDiscount
        ? (((item.price! - item.discountPrice!) / item.price!) * 100)
            .toStringAsFixed(0)
        : null;

    return GestureDetector(
      onTap: () {
        if (item.id.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/productDetail/${item.id}',
            arguments: {
              'itemType': 'PRODUCT',
              'title': item.name,
              'imageUrl': item.imageUrl ?? '',
              'itemId': item.id,
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.surface2,
                child: item.imageUrl != null &&
                        item.imageUrl!.isNotEmpty &&
                        item.imageUrl != 'DEFAULT_IMAGE'
                    ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(text: item.name, highlight: query),
                  if (item.brand != null && item.brand!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(item.brand!,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 11)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.discountPrice != null)
                        Text('₹${item.discountPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700))
                      else if (item.price != null)
                        Text('₹${item.price!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text('₹${item.price!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.greyDark,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('$discountPct% off',
                              style: TextStyle(
                                  color: Colors.green.shade300,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  if (item.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 9, color: Colors.greenAccent),
                              const SizedBox(width: 2),
                              Text(item.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (item.ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text('(${_formatCount(item.ratingCount!)})',
                              style: const TextStyle(
                                  color: AppColors.greyDark, fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.greyDark, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: AppColors.surface2,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined,
            color: AppColors.greyDark, size: 28),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

// ─── Highlighted Text ──────────────────────────────────────────────────────────
class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  const _HighlightedText({required this.text, required this.highlight});

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3));
    }

    final lowerText = text.toLowerCase();
    final lowerHL = highlight.toLowerCase();
    final idx = lowerText.indexOf(lowerHL);

    if (idx == -1) {
      return Text(text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.3),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + highlight.length),
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(idx + highlight.length)),
        ],
      ),
    );
  }
}

// ─── Shimmer Item (for search results loading) ─────────────────────────────────
class _ShimmerItem extends StatefulWidget {
  @override
  State<_ShimmerItem> createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<_ShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimBox(double w, double h, {double radius = 6}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_anim.value - 1).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 1).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _shimBox(72, 72, radius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimBox(double.infinity, 13),
                const SizedBox(height: 8),
                _shimBox(120, 11),
                const SizedBox(height: 10),
                _shimBox(80, 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
