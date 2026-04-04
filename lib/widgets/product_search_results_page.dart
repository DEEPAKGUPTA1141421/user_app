// Place at: lib/widgets/search_results_page.dart
//
// Imported by search_results.dart as:
//   import 'search_results_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

// ─── Color Scheme (matches EditProfile / AppColors) ───────────────────────────
const _bg      = Color(0xFF000000);
const _surface  = Color(0xFF111111);
const _surface2 = Color(0xFF1A1A1A);
const _border   = Color(0xFF2A2A2A);
const _divider  = Color(0xFF222222);
const _white    = Colors.white;
const _grey     = Color(0xFF888888);
const _greyDark = Color(0xFF444444);
const _brand    = Color(0xFFFF5200);

// ─── Models ───────────────────────────────────────────────────────────────────
class _FilterChip {
  final String id;
  final String label;
  final IconData icon;
  final List<_FilterOption> options;
  bool isActive;
  _FilterChip({required this.id, required this.label, required this.icon, required this.options, this.isActive = false});
}

class _FilterOption {
  final String id;
  final String label;
  bool selected;
  _FilterOption({required this.id, required this.label, this.selected = false});
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
    required this.id, required this.name, required this.brand,
    required this.price, this.originalPrice, required this.rating,
    required this.reviewCount, required this.images, this.hasVideo = false,
    this.badge, required this.deliveryText, this.isSponsored = false,
    this.isWishlisted = false,
  });

  int? get discountPercent {
    if (originalPrice == null || originalPrice == 0) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }
}

// ─── Mock data (swap with real API) ───────────────────────────────────────────
List<_Product> _mockProducts(String query) => [
  _Product(id:'1', name:'iPhone 16 Pro Max 512GB Natural Titanium', brand:'Apple',
    price:134900, originalPrice:159900, rating:4.8, reviewCount:12453,
    images:['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400'],
    badge:'Bestseller', deliveryText:'Tomorrow, Free'),
  _Product(id:'2', name:'Samsung Galaxy S25 Ultra 256GB Titanium Silver', brand:'Samsung',
    price:94999, originalPrice:134999, rating:4.6, reviewCount:8234,
    images:['https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=400'],
    hasVideo:true, badge:'30% Off', deliveryText:'In 2 Days, Free', isWishlisted:true),
  _Product(id:'3', name:'OnePlus 13 16GB + 512GB Midnight Ocean', brand:'OnePlus',
    price:69999, originalPrice:79999, rating:4.5, reviewCount:5621,
    images:['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400'],
    deliveryText:'Tomorrow, Free'),
  _Product(id:'4', name:'Google Pixel 9 Pro 256GB Obsidian', brand:'Google',
    price:79999, originalPrice:99999, rating:4.7, reviewCount:3891,
    images:['https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=400'],
    badge:'Top Rated', deliveryText:'In 3 Days', isSponsored:true),
  _Product(id:'5', name:'Xiaomi 14 Ultra 512GB White', brand:'Xiaomi',
    price:84999, originalPrice:99999, rating:4.4, reviewCount:2145,
    images:['https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=400'],
    hasVideo:true, deliveryText:'In 2 Days, Free'),
  _Product(id:'6', name:'Sony Xperia 1 VI 256GB Black', brand:'Sony',
    price:89990, originalPrice:104990, rating:4.3, reviewCount:876,
    images:['https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=400'],
    badge:'New Launch', deliveryText:'In 4 Days'),
];

List<_FilterChip> _buildChips() => [
  _FilterChip(id:'sort',     label:'Sort',          icon:Icons.sort_rounded,
    options:[_FilterOption(id:'rel',label:'Relevance'),_FilterOption(id:'pl',label:'Price: Low to High'),
             _FilterOption(id:'ph',label:'Price: High to Low'),_FilterOption(id:'rt',label:'Customer Rating'),
             _FilterOption(id:'nw',label:'Newest First'),_FilterOption(id:'dc',label:'Discount')]),
  _FilterChip(id:'filter',   label:'Filters',        icon:Icons.tune_rounded,
    options:[_FilterOption(id:'u10',label:'Under ₹10,000'),_FilterOption(id:'1030',label:'₹10K – ₹30K'),
             _FilterOption(id:'3060',label:'₹30K – ₹60K'),_FilterOption(id:'a60',label:'Above ₹60,000')]),
  _FilterChip(id:'delivery', label:'Fast Delivery',  icon:Icons.bolt_rounded,
    options:[_FilterOption(id:'sd',label:'Same Day'),_FilterOption(id:'tm',label:'Tomorrow'),
             _FilterOption(id:'fr',label:'Free Delivery')]),
  _FilterChip(id:'trending', label:'Trending',        icon:Icons.trending_up_rounded,
    options:[_FilterOption(id:'bs',label:'Bestsellers'),_FilterOption(id:'tr',label:'Top Rated'),
             _FilterOption(id:'na',label:'New Arrivals')]),
  _FilterChip(id:'brand',    label:'Brand',           icon:Icons.workspace_premium_rounded,
    options:[_FilterOption(id:'ap',label:'Apple'),_FilterOption(id:'sa',label:'Samsung'),
             _FilterOption(id:'op',label:'OnePlus'),_FilterOption(id:'go',label:'Google'),
             _FilterOption(id:'xi',label:'Xiaomi'),_FilterOption(id:'so',label:'Sony')]),
  _FilterChip(id:'rating',   label:'Rating',          icon:Icons.star_rounded,
    options:[_FilterOption(id:'4p',label:'4★ & above'),_FilterOption(id:'3p',label:'3★ & above')]),
  _FilterChip(id:'storage',  label:'Storage',         icon:Icons.storage_rounded,
    options:[_FilterOption(id:'128',label:'128 GB'),_FilterOption(id:'256',label:'256 GB'),
             _FilterOption(id:'512',label:'512 GB'),_FilterOption(id:'1tb',label:'1 TB')]),
  _FilterChip(id:'discount', label:'Discount',        icon:Icons.local_offer_rounded,
    options:[_FilterOption(id:'10p',label:'10% or more'),_FilterOption(id:'20p',label:'20% or more'),
             _FilterOption(id:'30p',label:'30% or more'),_FilterOption(id:'50p',label:'50% or more')]),
  _FilterChip(id:'color',    label:'Color',           icon:Icons.palette_rounded,
    options:[_FilterOption(id:'bk',label:'Black'),_FilterOption(id:'wh',label:'White'),
             _FilterOption(id:'bl',label:'Blue'),_FilterOption(id:'gd',label:'Gold'),
             _FilterOption(id:'ti',label:'Titanium')]),
];

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════════════════════
class ProductSearchResultsPage extends StatefulWidget {
  final String query;
  const ProductSearchResultsPage({super.key, required this.query});

  @override
  State<ProductSearchResultsPage> createState() => _State();
}

class _State extends State<ProductSearchResultsPage> {
  late final TextEditingController _ctrl;
  late List<_FilterChip>  _chips;
  late List<_Product>     _products;
  bool _loading = true;
  int  _cartCount = 3;

  @override
  void initState() {
    super.initState();
    _ctrl     = TextEditingController(text: widget.query);
    _chips    = _buildChips();
    _products = _mockProducts(widget.query);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  int get _activeCount => _chips.fold(0, (s,c) => s + c.options.where((o)=>o.selected).length);

  void _openSheet(_FilterChip chip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _Sheet(
        chip: chip,
        onApply: (updated) => setState(() {
          final i = _chips.indexWhere((c) => c.id == updated.id);
          if (i >= 0) { _chips[i] = updated; _chips[i].isActive = updated.options.any((o)=>o.selected); }
        }),
      ),
    );
  }

  void _wishlist(_Product p) {
    setState(() { final i = _products.indexWhere((x)=>x.id==p.id); if(i>=0) _products[i].isWishlisted = !_products[i].isWishlisted; });
    _snack(p.isWishlisted ? 'Removed from wishlist' : 'Added to wishlist', Icons.favorite_rounded);
  }

  void _addCart(_Product p) {
    setState(() => _cartCount++);
    _snack('Added to cart', Icons.shopping_bag_outlined);
  }

  void _snack(String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color:_brand, size:15), const SizedBox(width:8), Text(msg, style:const TextStyle(color:_white, fontSize:13))]),
      backgroundColor: _surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(10), side:const BorderSide(color:_border)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          _buildFilterBar(),
          Expanded(child: _loading ? _shimmer() : _grid()),
        ]),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: const BoxDecoration(color:_surface, border:Border(bottom:BorderSide(color:_divider))),
    child: Row(children: [
      // Back
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color:_surface2, borderRadius:BorderRadius.circular(10), border:Border.all(color:_border)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color:_white, size:16),
        ),
      ),
      const SizedBox(width:10),

      // Search field
      Expanded(
        child: Container(
          height: 42,
          decoration: BoxDecoration(color:_surface2, borderRadius:BorderRadius.circular(12), border:Border.all(color:_border)),
          child: StatefulBuilder(
            builder: (_, ss) => TextField(
              controller: _ctrl,
              onChanged: (_) => ss((){}),
              style: const TextStyle(color:_white, fontSize:14),
              cursorColor: _brand,
              decoration: InputDecoration(
                hintText: 'Search products, brands...',
                hintStyle: const TextStyle(color:_grey, fontSize:13),
                prefixIcon: const Icon(CupertinoIcons.search, color:_grey, size:18),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? GestureDetector(onTap: () { _ctrl.clear(); ss((){}); }, child: const Icon(Icons.close, color:_grey, size:16))
                    : const Icon(CupertinoIcons.mic_fill, color:_grey, size:16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical:12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width:10),

      // Cart badge
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/order-summary'),
        child: Stack(clipBehavior:Clip.none, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color:_surface2, borderRadius:BorderRadius.circular(10), border:Border.all(color:_border)),
            child: const Icon(Icons.shopping_bag_outlined, color:_white, size:20),
          ),
          if (_cartCount > 0)
            Positioned(
              top:-5, right:-5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color:_brand, shape:BoxShape.circle),
                child: Text('$_cartCount', style:const TextStyle(color:_white, fontSize:9, fontWeight:FontWeight.w700)),
              ),
            ),
        ]),
      ),
    ]),
  );

  // ── Filter bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() => Container(
    color: _surface,
    child: Column(mainAxisSize:MainAxisSize.min, children: [
      SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal:12, vertical:7),
          itemCount: _chips.length,
          separatorBuilder: (_,__) => const SizedBox(width:8),
          itemBuilder: (_, i) {
            final c = _chips[i];
            final active = c.options.any((o) => o.selected);
            final cnt    = c.options.where((o) => o.selected).length;
            return GestureDetector(
              onTap: () => _openSheet(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds:180),
                padding: const EdgeInsets.symmetric(horizontal:11, vertical:5),
                decoration: BoxDecoration(
                  color: active ? _brand.withOpacity(0.14) : _surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? _brand : _border, width: active ? 1.5 : 1),
                ),
                child: Row(mainAxisSize:MainAxisSize.min, children: [
                  Icon(c.icon, size:13, color: active ? _brand : _grey),
                  const SizedBox(width:5),
                  Text(c.label, style:TextStyle(color: active ? _brand : _grey, fontSize:12, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
                  if (cnt > 0) ...[
                    const SizedBox(width:5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal:5, vertical:1),
                      decoration: BoxDecoration(color:_brand, borderRadius:BorderRadius.circular(8)),
                      child: Text('$cnt', style:const TextStyle(color:_white, fontSize:9, fontWeight:FontWeight.w700)),
                    ),
                  ] else ...[
                    const SizedBox(width:3),
                    Icon(Icons.keyboard_arrow_down_rounded, size:14, color: active ? _brand : _greyDark),
                  ],
                ]),
              ),
            );
          },
        ),
      ),
      Container(height:1, color:_divider),
    ]),
  );

  // ── Grid ───────────────────────────────────────────────────────────────────
  Widget _grid() => CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Text('${_products.length} results  ', style:const TextStyle(color:_grey, fontSize:12)),
            Flexible(child: Text('"${widget.query}"', style:const TextStyle(color:_white, fontSize:12, fontWeight:FontWeight.w600), overflow:TextOverflow.ellipsis)),
            const Spacer(),
            if (_activeCount > 0)
              GestureDetector(
                onTap: () => setState(() { for (final c in _chips) { for (final o in c.options) o.selected=false; c.isActive=false; } }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
                  decoration: BoxDecoration(color:_brand.withOpacity(0.1), borderRadius:BorderRadius.circular(8), border:Border.all(color:_brand.withOpacity(0.3))),
                  child: const Row(mainAxisSize:MainAxisSize.min, children:[
                    Icon(Icons.close, size:11, color:_brand),
                    SizedBox(width:3),
                    Text('Clear All', style:TextStyle(color:_brand, fontSize:11, fontWeight:FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:2, mainAxisSpacing:12, crossAxisSpacing:12, childAspectRatio:0.56),
          delegate: SliverChildBuilderDelegate(
            (_, i) => _Card(
              product: _products[i],
              onWishlist: () => _wishlist(_products[i]),
              onAddToCart: () => _addCart(_products[i]),
              onTap: () => Navigator.pushNamed(context, '/productDetail/${_products[i].id}'),
            ),
            childCount: _products.length,
          ),
        ),
      ),
    ],
  );

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _shimmer() => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, mainAxisSpacing:12, crossAxisSpacing:12, childAspectRatio:0.56),
    itemCount: 6,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: _surface,
      highlightColor: _surface2,
      child: Container(decoration:BoxDecoration(color:_surface, borderRadius:BorderRadius.circular(14))),
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

  const _Card({required this.product, required this.onWishlist, required this.onAddToCart, required this.onTap});

  String _fmt(double v) {
    final n = v.toInt();
    if (n >= 100000) return '₹${(v/100000).toStringAsFixed(1)}L';
    final s = n.toString();
    return s.length > 3 ? '₹${s.substring(0,s.length-3)},${s.substring(s.length-3)}' : '₹$s';
  }
  String _fmtN(int n) => n >= 1000 ? '${(n/1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color:_surface, borderRadius:BorderRadius.circular(14), border:Border.all(color:_border)),
        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
          // ── Media ──────────────────────────────────────────────────
          Expanded(
            flex: 52,
            child: Stack(children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top:Radius.circular(14)),
                child: SizedBox(
                  width: double.infinity, height: double.infinity,
                  child: p.images.isNotEmpty
                      ? Image.network(p.images.first, fit:BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(color:_surface2, child:const Center(child:Icon(Icons.image_not_supported_outlined, color:_greyDark, size:28))))
                      : Container(color:_surface2),
                ),
              ),

              // Video pill
              if (p.hasVideo)
                Positioned(
                  bottom:8, left:8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:7, vertical:3),
                    decoration: BoxDecoration(color:Colors.black.withOpacity(0.72), borderRadius:BorderRadius.circular(12)),
                    child: const Row(mainAxisSize:MainAxisSize.min, children:[
                      Icon(Icons.play_circle_fill, color:_white, size:13),
                      SizedBox(width:4),
                      Text('Video', style:TextStyle(color:_white, fontSize:10, fontWeight:FontWeight.w600)),
                    ]),
                  ),
                ),

              // Top-left badge
              if (p.isSponsored)
                Positioned(top:8, left:8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:6, vertical:2),
                    decoration: BoxDecoration(color:Colors.black.withOpacity(0.6), borderRadius:BorderRadius.circular(4)),
                    child: const Text('Sponsored', style:TextStyle(color:_grey, fontSize:9, fontWeight:FontWeight.w500)),
                  ))
              else if (p.badge != null)
                Positioned(top:8, left:8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:7, vertical:3),
                    decoration: BoxDecoration(color: p.badge!.contains('%') ? Colors.green.shade700 : _brand, borderRadius:BorderRadius.circular(5)),
                    child: Text(p.badge!, style:const TextStyle(color:_white, fontSize:9, fontWeight:FontWeight.w700, letterSpacing:0.2)),
                  ))
              else if (p.discountPercent != null)
                Positioned(top:8, left:8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:7, vertical:3),
                    decoration: BoxDecoration(color:Colors.green.shade700, borderRadius:BorderRadius.circular(5)),
                    child: Text('${p.discountPercent}% off', style:const TextStyle(color:_white, fontSize:9, fontWeight:FontWeight.w700)),
                  )),

              // Wishlist heart
              Positioned(
                top:6, right:6,
                child: GestureDetector(
                  onTap: onWishlist,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color:Colors.black.withOpacity(0.52), shape:BoxShape.circle),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds:220),
                      child: Icon(
                        p.isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(p.isWishlisted),
                        color: p.isWishlisted ? Colors.red.shade400 : _white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),

          // ── Info ───────────────────────────────────────────────────
          Expanded(
            flex: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
                // Brand
                Text(p.brand.toUpperCase(), style:const TextStyle(color:_grey, fontSize:9, fontWeight:FontWeight.w700, letterSpacing:1)),
                const SizedBox(height:3),
                // Name
                Text(p.name, maxLines:2, overflow:TextOverflow.ellipsis, style:const TextStyle(color:_white, fontSize:12, fontWeight:FontWeight.w500, height:1.3)),
                const SizedBox(height:6),
                // Rating
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal:5, vertical:2),
                    decoration: BoxDecoration(color: p.rating >= 4 ? Colors.green.shade800 : Colors.orange.shade800, borderRadius:BorderRadius.circular(4)),
                    child: Row(mainAxisSize:MainAxisSize.min, children:[
                      const Icon(Icons.star_rounded, color:_white, size:10),
                      const SizedBox(width:2),
                      Text(p.rating.toStringAsFixed(1), style:const TextStyle(color:_white, fontSize:10, fontWeight:FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width:5),
                  Text('(${_fmtN(p.reviewCount)})', style:const TextStyle(color:_greyDark, fontSize:10)),
                ]),
                const SizedBox(height:6),
                // Price
                Row(crossAxisAlignment:CrossAxisAlignment.end, children:[
                  Text(_fmt(p.price), style:const TextStyle(color:_white, fontSize:15, fontWeight:FontWeight.w700)),
                  if (p.originalPrice != null) ...[
                    const SizedBox(width:5),
                    Text(_fmt(p.originalPrice!), style:const TextStyle(color:_greyDark, fontSize:10, decoration:TextDecoration.lineThrough, decorationColor:_greyDark)),
                  ],
                ]),
                const SizedBox(height:3),
                // Delivery
                Row(children:[
                  const Icon(Icons.local_shipping_outlined, color:Colors.green, size:11),
                  const SizedBox(width:3),
                  Flexible(child:Text(p.deliveryText, style:const TextStyle(color:Colors.green, fontSize:10, fontWeight:FontWeight.w500), overflow:TextOverflow.ellipsis)),
                ]),
                const Spacer(),
                // Add to cart
                GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical:7),
                    decoration: BoxDecoration(color:_surface2, borderRadius:BorderRadius.circular(8), border:Border.all(color:_border)),
                    child: const Row(mainAxisAlignment:MainAxisAlignment.center, children:[
                      Icon(Icons.add_shopping_cart_rounded, color:_brand, size:13),
                      SizedBox(width:5),
                      Text('Add to Cart', style:TextStyle(color:_brand, fontSize:11, fontWeight:FontWeight.w600)),
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
//  FILTER SHEET
// ═══════════════════════════════════════════════════════════════════════════════
class _Sheet extends StatefulWidget {
  final _FilterChip chip;
  final ValueChanged<_FilterChip> onApply;
  const _Sheet({required this.chip, required this.onApply});
  @override State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late List<_FilterOption> _opts;

  @override
  void initState() {
    super.initState();
    _opts = widget.chip.options.map((o) => _FilterOption(id:o.id, label:o.label, selected:o.selected)).toList();
  }

  void _clear() => setState(() { for (final o in _opts) o.selected = false; });

  void _apply() {
    widget.onApply(_FilterChip(id:widget.chip.id, label:widget.chip.label, icon:widget.chip.icon, options:_opts, isActive:_opts.any((o)=>o.selected)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cnt = _opts.where((o) => o.selected).length;
    return Container(
      padding: EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color:_surface, borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize:MainAxisSize.min, children:[
        // Handle
        Container(margin:const EdgeInsets.only(top:12), width:36, height:4, decoration:BoxDecoration(color:_border, borderRadius:BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20,16,20,12),
          child: Row(children:[
            Icon(widget.chip.icon, color:_brand, size:18),
            const SizedBox(width:10),
            Text(widget.chip.label, style:const TextStyle(color:_white, fontSize:16, fontWeight:FontWeight.w700)),
            if (cnt > 0) ...[
              const SizedBox(width:8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal:7, vertical:2),
                decoration: BoxDecoration(color:_brand, borderRadius:BorderRadius.circular(10)),
                child: Text('$cnt selected', style:const TextStyle(color:_white, fontSize:10, fontWeight:FontWeight.w600)),
              ),
            ],
            const Spacer(),
            if (cnt > 0) GestureDetector(onTap:_clear, child:const Text('Clear', style:TextStyle(color:_brand, fontSize:13))),
            const SizedBox(width:12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color:_surface2, borderRadius:BorderRadius.circular(8), border:Border.all(color:_border)),
                child: const Icon(Icons.close, color:_grey, size:14),
              ),
            ),
          ]),
        ),
        Container(height:1, color:_divider),
        const SizedBox(height:14),
        // Options
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal:20),
            child: Wrap(
              spacing:10, runSpacing:10,
              children: _opts.map((o) => GestureDetector(
                onTap: () => setState(() => o.selected = !o.selected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds:150),
                  padding: const EdgeInsets.symmetric(horizontal:16, vertical:10),
                  decoration: BoxDecoration(
                    color: o.selected ? _brand.withOpacity(0.12) : _surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: o.selected ? _brand : _border, width: o.selected ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize:MainAxisSize.min, children:[
                    if (o.selected) ...[const Icon(Icons.check_rounded, color:_brand, size:13), const SizedBox(width:5)],
                    Text(o.label, style:TextStyle(color: o.selected ? _brand : _grey, fontSize:13, fontWeight: o.selected ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height:16),
        // Buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20,0,20,8),
          child: Row(children:[
            Expanded(
              child: GestureDetector(
                onTap: _clear,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical:13),
                  decoration: BoxDecoration(borderRadius:BorderRadius.circular(12), border:Border.all(color:_border)),
                  child: const Center(child:Text('Clear All', style:TextStyle(color:_grey, fontSize:14, fontWeight:FontWeight.w600))),
                ),
              ),
            ),
            const SizedBox(width:12),
            Expanded(
              flex:2,
              child: GestureDetector(
                onTap: _apply,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical:13),
                  decoration: BoxDecoration(color:_white, borderRadius:BorderRadius.circular(12)),
                  child: Center(child:Text(cnt > 0 ? 'Apply ($cnt)' : 'Apply', style:const TextStyle(color:_bg, fontSize:14, fontWeight:FontWeight.w700))),
                ),
              ),
            ),
          ]),
        ),
      ])),
    );
  }
}