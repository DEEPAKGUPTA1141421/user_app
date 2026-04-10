import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../provider/product_provider.dart';
import '../utils/app_colors.dart';
import '../utils/StorageService.dart';
import '../constant/ServerApi.dart';
import '../widgets/product_search_results_page.dart';

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
      imageUrl: json['imageUrl'] ?? 'DEFAULT_IMAGE',
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
  final String type; // 'PRODUCT' | 'BRAND'

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
  const RealSearchPage({super.key});

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

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Popular categories / trending tags for empty state
  final List<String> _trendingTags = [
    'Tops & Tunics', 'Kurtas', 'Sarees', 'Jeans',
    'Sneakers', 'Watches', 'Handbags', 'Sunglasses',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Fetch suggestions from API ────────────────────────────────────────────
  Future<void> _fetchSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    try {
      final token = await StorageService.getAccessToken();
      final uri = Uri.parse(
          '${ServerApi.productClientService}/api/v1/product/search')
          .replace(queryParameters: {'keyword': query});

      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          setState(() {
            _suggestions = data
                .map((e) => SearchSuggestion.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList();
          });
        }
      }
    } catch (_) {
      // Silently fail — suggestions are non-critical
    } finally {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  // ── Perform search ─────────────────────────────────────────────────────────
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
      final token = await StorageService.getAccessToken();
      final uri = Uri.parse(
          '${ServerApi.searchProduct}?keyword=${Uri.encodeComponent(query)}');

      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'] ?? {};
        final products = (data['products'] ?? []) as List;
        final brands = (data['brands'] ?? []) as List;

        final List<SearchResultItem> items = [
          ...brands.map((b) => SearchResultItem.fromBrand(
              Map<String, dynamic>.from(b))),
          ...products.map((p) => SearchResultItem.fromProduct(
              Map<String, dynamic>.from(p))),
        ];

        setState(() => _results = items);
      } else {
        setState(() => _errorMessage = 'Search failed. Please try again.');
      }
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
              Expanded(
                child: _buildBody(),
              ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Back
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

          // Input
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
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
                onChanged: _onQueryChanged,
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products, brands...',
                  hintStyle: const TextStyle(
                      color: AppColors.greyDark, fontSize: 14),
                  prefixIcon: const Icon(CupertinoIcons.search,
                      size: 17, color: AppColors.grey),
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
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Search button
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
              child: const Icon(CupertinoIcons.search,
                  color: AppColors.bg, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body Router ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoadingResults) return _buildLoadingResults();
    if (_hasSearched && _results.isNotEmpty)
      return _buildResults();
    if (_hasSearched && !_isLoadingResults)
      return _buildEmptyResults();
    if (_suggestions.isNotEmpty && _query.length >= 2)
      return _buildSuggestions();
    return _buildDefaultState();
  }

  // ── Default / Landing State ─────────────────────────────────────────────
  Widget _buildDefaultState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // Trending heading
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TRENDING SEARCHES',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _trendingTags.map((tag) {
              return GestureDetector(
                onTap: () {
                  _controller.text = tag;
                  setState(() => _query = tag);
                  _performSearch(tag);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 13, color: AppColors.grey),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          // Search hint illustration
          Container(
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
                const Text(
                  'Start typing to search',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find products, brands, categories\nand much more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
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
      separatorBuilder: (_, __) =>
          Container(height: 1, color: AppColors.divider),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
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
                        ? Text(badge,
                            style: const TextStyle(fontSize: 16))
                        : const Icon(CupertinoIcons.search,
                            size: 14, color: AppColors.grey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    s.keyword,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
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
    // Group: brands first, then products
    final brands =
        _results.where((r) => r.type == 'BRAND').toList();
    final products =
        _results.where((r) => r.type == 'PRODUCT').toList();

    return CustomScrollView(
      slivers: [
        if (brands.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _sectionHeader(
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
            child: _sectionHeader(
                '${products.length} Product${products.length > 1 ? 's' : ''}',
                Icons.shopping_bag_outlined),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductResultCard(
                item: products[i],
                query: _query,
              ),
              childCount: products.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, IconData icon) {
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
            Text(
              'No results for "$_query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different keyword or check\nfor spelling mistakes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
          // Brand logo
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
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (item.category != null && item.category!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.category!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Brand',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
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
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.surface2,
                child: item.imageUrl != null &&
                        item.imageUrl!.isNotEmpty &&
                        item.imageUrl != 'DEFAULT_IMAGE'
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with highlighted query
                  _HighlightedText(
                    text: item.name,
                    highlight: query,
                  ),

                  if (item.brand != null && item.brand!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.brand!,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      // Price
                      if (item.discountPrice != null)
                        Text(
                          '₹${item.discountPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (item.price != null)
                        Text(
                          '₹${item.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${item.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.greyDark,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPct% off',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Rating
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
                                  size: 9,
                                  color: Colors.greenAccent),
                              const SizedBox(width: 2),
                              Text(
                                item.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${_formatCount(item.ratingCount!)})',
                            style: const TextStyle(
                              color: AppColors.greyDark,
                              fontSize: 10,
                            ),
                          ),
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
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerHL = highlight.toLowerCase();
    final idx = lowerText.indexOf(lowerHL);

    if (idx == -1) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + highlight.length),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(idx + highlight.length)),
        ],
      ),
    );
  }
}

// ─── Shimmer Item ──────────────────────────────────────────────────────────────
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