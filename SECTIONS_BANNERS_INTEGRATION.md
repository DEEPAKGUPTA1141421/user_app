# Sections & Banners Integration — Frontend Guide

Banners are now integrated into the Sections API. A single `GET /api/v1/sections/{categoryId}` call returns both banners and product sections.

---

## Architecture

```
GET /api/v1/sections/{categoryId}
    ↓
    Response: List<SectionResponseDto>
        ├─ Section 1: Hero Banner (widgetKey: "banner_hero_v1")
        │   └─ items[0]: BANNER itemType + metadata (imageUrl, tapAction, pixels)
        │
        ├─ Section 2: Product Grid (widgetKey: "product_grid_v1")
        │   └─ items: PRODUCT itemTypes (title, price, rating)
        │
        ├─ Section 3: Mid-Page Banner (widgetKey: "banner_hero_v1")
        │   └─ items[0]: BANNER itemType + metadata
        │
        └─ Section 4: Product Scroll (widgetKey: "product_scroll_v1")
            └─ items: PRODUCT itemTypes
```

---

## API Response Example

```json
{
  "success": true,
  "data": [
    {
      "id": "10000003-0000-0000-0000-000000000001",
      "title": "Latest Phones",
      "widgetKey": "banner_hero_v1",
      "dataKind": "BANNER",
      "position": 1,
      "config": {
        "height": 220,
        "aspectRatio": "16:6",
        "autoplay": true,
        "theme": {
          "bg": "#1a1a1a",
          "fg": "#FFF",
        }
      },
      "items": [
        {
          "itemType": "BANNER",
          "itemRefId": "campaign-uuid",
          "metadata": {
            "campaignId": "diwali_2026_mobile_hero",
            "imageUrl": "https://cdn.example.com/banners/diwali-mobile-hero.webp",
            "altText": "Diwali Sale: Premium phones at unbeatable prices",
            "tapAction": {
              "kind": "DEEPLINK",
              "value": "app://category/mobiles/offers"
            },
            "impressionPixel": "https://analytics.example.com/i?c=diwali_mobile_hero&v=1",
            "clickPixel": "https://analytics.example.com/c?c=diwali_mobile_hero&v=1"
          }
        }
      ]
    },
    {
      "id": "10000003-0000-0000-0000-000000000002",
      "title": "Best Sellers",
      "widgetKey": "product_grid_v1",
      "dataKind": "PRODUCT_GRID",
      "position": 2,
      "config": {
        "columns": 3,
        "rows": 2,
        "cardVariant": "standard",
        "showDiscount": true,
        "showRating": true
      },
      "items": [
        {
          "itemType": "PRODUCT",
          "itemRefId": "product-uuid-1",
          "productId": "product-uuid-1",
          "title": "iPhone 15 Pro",
          "pricePaise": 129900,
          "discountPct": 10,
          "thumbnailUrl": "https://images.example.com/iphone-15.jpg",
          "avgRating": 4.8
        },
        {
          "itemType": "PRODUCT",
          "itemRefId": "product-uuid-2",
          "productId": "product-uuid-2",
          "title": "Samsung Galaxy S24",
          "pricePaise": 79900,
          "discountPct": 15,
          "thumbnailUrl": "https://images.example.com/s24.jpg",
          "avgRating": 4.6
        }
      ]
    },
    {
      "id": "10000003-0000-0000-0000-000000000003",
      "title": "Celebrity Picks",
      "widgetKey": "banner_hero_v1",
      "dataKind": "BANNER",
      "position": 4,
      "config": {
        "height": 180,
        "aspectRatio": "16:7"
      },
      "items": [
        {
          "itemType": "BANNER",
          "metadata": {
            "campaignId": "celebrity_picks_q1_2026",
            "imageUrl": "https://cdn.example.com/banners/celebrity-picks.webp",
            "altText": "Celebrity picks: Top smartphones they use",
            "tapAction": {
              "kind": "DEEPLINK",
              "value": "app://collections/celebrity-picks"
            }
          }
        }
      ]
    }
  ]
}
```

---

## Dart Implementation

### Add DTOs

Update `lib/models/sections.dart`:

```dart
@JsonSerializable()
class SectionResponseDto {
  final String id;
  final String title;
  final String widgetKey;
  final String dataKind;
  final int position;
  final Map<String, dynamic>? config;
  final List<SectionItemDto> items;

  SectionResponseDto({
    required this.id,
    required this.title,
    required this.widgetKey,
    required this.dataKind,
    required this.position,
    this.config,
    required this.items,
  });

  // Helpers
  bool get isBanner => dataKind == 'BANNER';
  bool get isProductGrid => widgetKey.contains('product_grid');
  bool get isProductScroll => widgetKey.contains('product_scroll');
  bool get isProductHighlight => widgetKey.contains('highlight');
  bool get isVideoRail => widgetKey.contains('video_rail');

  factory SectionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SectionResponseDtoFromJson(json);
}

@JsonSerializable()
class SectionItemDto {
  final String itemType;
  final String itemRefId;
  
  // Product fields
  final String? productId;
  final String? title;
  final String? thumbnailUrl;
  final int? pricePaise;
  final int? discountPct;
  final double? avgRating;
  final double? score;
  
  // Banner-specific
  final Map<String, dynamic>? metadata;

  SectionItemDto({
    required this.itemType,
    required this.itemRefId,
    this.productId,
    this.title,
    this.thumbnailUrl,
    this.pricePaise,
    this.discountPct,
    this.avgRating,
    this.score,
    this.metadata,
  });

  // Helpers for banner items
  bool get isBanner => itemType == 'BANNER';
  String? get bannerImageUrl => metadata?['imageUrl'] as String?;
  String? get bannerAltText => metadata?['altText'] as String?;
  String? get campaignId => metadata?['campaignId'] as String?;
  Map<String, dynamic>? get tapAction => metadata?['tapAction'] as Map<String, dynamic>?;
  String? get impressionPixel => metadata?['impressionPixel'] as String?;
  String? get clickPixel => metadata?['clickPixel'] as String?;

  factory SectionItemDto.fromJson(Map<String, dynamic> json) =>
      _$SectionItemDtoFromJson(json);
}
```

### Fetch sections

```dart
// lib/providers/section_provider.dart
class SectionProvider extends ChangeNotifier {
  late SectionService _service;
  List<SectionResponseDto> _sections = [];
  bool _loading = false;

  List<SectionResponseDto> get sections => _sections;
  bool get loading => _loading;

  SectionProvider(this._service);

  Future<void> fetchSections(String categoryId) async {
    _loading = true;
    notifyListeners();
    
    try {
      _sections = await _service.getPageSections(categoryId);
    } catch (e) {
      print('Error fetching sections: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

// lib/services/section_service.dart
class SectionService {
  final HttpClient _http;

  SectionService(this._http);

  Future<List<SectionResponseDto>> getPageSections(String categoryId) async {
    final response = await _http.get(
      '/api/v1/sections/$categoryId',
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List;
      return data
        .map((item) => SectionResponseDto.fromJson(item as Map<String, dynamic>))
        .toList();
    }
    throw Exception('Failed to fetch sections: ${response.statusCode}');
  }
}
```

### Render sections

```dart
// lib/screens/category_page.dart
class CategoryPage extends StatefulWidget {
  final String categoryId;
  const CategoryPage({required this.categoryId});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<SectionProvider>().fetchSections(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      body: Consumer<SectionProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.sections.isEmpty) {
            return const Center(child: Text('No sections available'));
          }

          return ListView.builder(
            itemCount: provider.sections.length,
            itemBuilder: (context, index) {
              final section = provider.sections[index];

              // Render banners
              if (section.isBanner) {
                return _BannerSection(section: section);
              }

              // Render products
              if (section.isProductGrid) {
                return _ProductGridSection(section: section);
              }
              if (section.isProductScroll) {
                return _ProductScrollSection(section: section);
              }
              if (section.isProductHighlight) {
                return _HighlightSection(section: section);
              }

              return SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// BANNER WIDGET
// ============================================================================

class _BannerSection extends StatefulWidget {
  final SectionResponseDto section;
  const _BannerSection({required this.section});

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  @override
  void initState() {
    super.initState();
    _fireImpressionPixel();
  }

  void _fireImpressionPixel() {
    final item = widget.section.items.firstOrNull;
    if (item == null) return;

    final pixelUrl = item.impressionPixel;
    if (pixelUrl != null && pixelUrl.isNotEmpty) {
      // Fire in background (don't await)
      http.get(Uri.parse(pixelUrl)).catchError((_) {});
    }
  }

  void _handleTap() {
    final item = widget.section.items.firstOrNull;
    if (item == null) return;

    // Fire click pixel
    if (item.clickPixel != null && item.clickPixel!.isNotEmpty) {
      http.get(Uri.parse(item.clickPixel!)).catchError((_) {});
    }

    // Handle deeplink
    final tapAction = item.tapAction;
    if (tapAction == null) return;

    final kind = tapAction['kind'] as String?;
    final value = tapAction['value'] as String?;

    if (value == null) return;

    switch (kind) {
      case 'DEEPLINK':
        // Navigator.pushNamed(context, value);
        print('DEEPLINK: $value');
        break;
      case 'CATEGORY':
        print('CATEGORY: $value');
        break;
      case 'URL':
        // canLaunchUrl(Uri.parse(value)).then((can) {
        //   if (can) launchUrl(Uri.parse(value));
        // });
        print('URL: $value');
        break;
      case 'SEARCH':
        print('SEARCH: $value');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.section.items.firstOrNull;
    if (item == null) return SizedBox.shrink();

    final config = widget.section.config ?? {};
    final height = (config['height'] as num?)?.toDouble() ?? 180.0;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: height,
        color: Colors.grey[200],
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image
            if (item.bannerImageUrl != null)
              Image.network(
                item.bannerImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackBanner(
                  altText: item.bannerAltText,
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.2)],
                ),
              ),
            ),

            // Fallback text
            if (item.bannerImageUrl == null)
              _FallbackBanner(altText: item.bannerAltText),
          ],
        ),
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  final String? altText;
  const _FallbackBanner({this.altText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        altText ?? 'Banner',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================================
// PRODUCT GRID WIDGET (existing, reuse)
// ============================================================================

class _ProductGridSection extends StatelessWidget {
  final SectionResponseDto section;
  const _ProductGridSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final config = section.config ?? {};
    final columns = (config['columns'] as num?)?.toInt() ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
          ),
          itemCount: section.items.length,
          itemBuilder: (context, index) => ProductCard(item: section.items[index]),
        ),
      ],
    );
  }
}

// Similarly for _ProductScrollSection, _HighlightSection, etc.
```

---

## Key differences: Old vs New

| Aspect | Old Banner API | New Sections API |
|--------|----------------|-----------------|
| **Endpoint** | `GET /api/v1/banners?category=X` | `GET /api/v1/sections/{categoryId}` |
| **Multiple per category** | ❌ Requires workaround | ✅ Native (position field) |
| **With products** | ❌ Separate calls | ✅ Same response |
| **Scheduling** | ❌ Manual logic | ✅ `starts_at`, `ends_at` fields |
| **Analytics** | ❌ Custom tracking | ✅ `impressionPixel`, `clickPixel` in metadata |
| **Navigation** | ❌ Manual deeplinks | ✅ `tapAction` object |

---

## Testing

1. **Fetch a category:**
   ```
   GET http://localhost:8081/api/v1/sections/{categoryId}
   ```

2. **Verify response includes sections with:**
   - `dataKind: "BANNER"` sections with `BANNER` items
   - Product sections with `PRODUCT` items
   - Correct positioning

3. **Test banner render:**
   - Image loads
   - Tap fires pixel + deeplink
   - Fallback text appears if image fails

4. **Monitor analytics:**
   - Impression pixels fired on page load
   - Click pixels fired on tap
