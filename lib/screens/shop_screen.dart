import 'package:flutter/material.dart';

// Assume these widgets will be implemented separately
import './shop/search_bar.dart' as local;
import './shop/shop_card.dart';
import './shop/category_pill.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String searchQuery = "";

  final List<Map<String, dynamic>> categories = [
    {"name": "Fashion", "icon": "👗", "gradient": "bg-gradient-fashion"},
    {
      "name": "Electronics",
      "icon": "📱",
      "gradient": "bg-gradient-electronics"
    },
    {"name": "Beauty", "icon": "💄", "gradient": "bg-gradient-beauty"},
    {"name": "Food", "icon": "🍔", "gradient": "bg-gradient-food"},
  ];

  final List<Map<String, dynamic>> mockShops = [
    {
      "id": "1",
      "name": "TechHub Store",
      "description": "Latest gadgets and electronics at amazing prices",
      "images": [
        "https://images.unsplash.com/photo-1498049794561-7780e7231661?w=800&q=80",
        "https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800&q=80",
        "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&q=80",
      ],
    },
    {
      "id": "2",
      "name": "Fashion Forward",
      "description": "Trendy clothing and accessories for modern style",
      "images": [
        "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80",
        "https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80",
        "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80",
      ],
    },
    {
      "id": "3",
      "name": "Beauty Bliss",
      "description": "Premium cosmetics and skincare products",
      "images": [
        "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800&q=80",
        "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80",
        "https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=800&q=80",
      ],
      "isSponsored": true,
    },
    {
      "id": "4",
      "name": "Gourmet Delights",
      "description": "Fresh ingredients and specialty foods delivered daily",
      "images": [
        "https://images.unsplash.com/photo-1543083477-4f785aeafaa9?w=800&q=80",
        "https://images.unsplash.com/photo-1526367790999-0150786686a2?w=800&q=80",
        "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=800&q=80",
      ],
    },
  ];

  final List<Map<String, dynamic>> sponsoredShops = [
    {
      "id": "5",
      "name": "Premium Watches",
      "description": "Luxury timepieces from world-renowned brands",
      "images": [
        "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80",
        "https://images.unsplash.com/photo-1526045612212-70caf35c14df?w=800&q=80",
        "https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=800&q=80",
      ],
      "isSponsored": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(bottom: 80),
          color: Colors.white, // bg-background
          child: Column(
            children: [
              // Sticky search bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8), // bg-background/80
                  border: Border(
                      bottom: BorderSide(color: Colors.grey)), // border-border
                ),
                child: local.SearchBar(
                  placeholder: "Search  shops...",
                  value: searchQuery,
                  onChange: (value) => setState(() => searchQuery = value),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories
                    const Text("Shop by Category",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories
                            .map((category) => CategoryPill(
                                  name: category['name'],
                                  icon: category['icon'],
                                  gradient: getGradient(category['gradient']),
                                ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // All Shops
                    const Text("All Shops",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Column(
                      children: mockShops
                          .map((shop) => ShopCard(
                                id: shop['id'],
                                name: shop['name'],
                                description: shop['description'],
                                images: List<String>.from(shop['images']),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 24),
                    // Sponsored Shops
                    const Text("✨ Sponsored Shops",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Column(
                      children: sponsoredShops
                          .map((shop) => ShopCard(
                                id: shop['id'],
                                name: shop['name'],
                                description: shop['description'],
                                images: List<String>.from(shop['images']),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

LinearGradient getGradient(String gradientName) {
  switch (gradientName) {
    case "bg-gradient-fashion":
      return const LinearGradient(colors: [Colors.pink, Colors.orange]);
    case "bg-gradient-electronics":
      return const LinearGradient(colors: [Colors.blue, Colors.cyan]);
    case "bg-gradient-beauty":
      return const LinearGradient(colors: [Colors.purple, Colors.pink]);
    case "bg-gradient-food":
      return const LinearGradient(colors: [Colors.orange, Colors.yellow]);
    default:
      return const LinearGradient(colors: [Colors.grey, Colors.grey]);
  }
}
