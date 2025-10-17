import 'package:flutter/material.dart';
import 'default_sections.dart';
import 'search_results.dart';
import '../provider/product_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RealSearchPage extends ConsumerStatefulWidget {
  const RealSearchPage({super.key});

  @override
  ConsumerState<RealSearchPage> createState() => _RealSearchPageState();
}

class _RealSearchPageState extends ConsumerState<RealSearchPage> {
  String searchQuery = "";
  static const brandColor = Color(0xFFFF5200);

  final recentSearches = [
    {
      "id": 1,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "label": "iphone 15 plus"
    },
    {
      "id": 2,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "label": "iphone 15 plus"
    },
  ];

  final trendingSearches = [
    {
      "id": 1,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "label": "Vivo v 60 5g"
    },
    {
      "id": 2,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "label": "Boat ear buds"
    },
    {
      "id": 3,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "label": "Realme 15x 5g"
    },
  ];

  final popularProducts = [
    {
      "id": 1,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "brand": "Samsung",
      "category": "Mobiles"
    },
    {
      "id": 2,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "brand": "JBL",
      "category": "Party Speakers"
    },
  ];

  final categories = [
    "Mobiles",
    "Shoes",
    "Laptops",
    "Watches",
  ];

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty || query.length < 3) return;
    print("make the query to backend");
    await ref.read(productPod.notifier).searchProduct(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF5200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      cursorColor: brandColor,
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                        _searchProducts(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for products',
                        prefixIcon: Icon(Icons.search, color: brandColor),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conditional content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: searchQuery.isEmpty
                    ? DefaultSections(
                        popularProducts: popularProducts,
                        categories: categories,
                        onCategoryTap: (val) =>
                            setState(() => searchQuery = val),
                      )
                    : SearchResults(query: searchQuery),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
