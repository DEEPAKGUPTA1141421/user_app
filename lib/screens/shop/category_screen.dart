import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Placeholder imports for components
import 'search_bar.dart' as local;
import 'shop_card.dart';
import 'button.dart';

class CategoryScreen extends StatefulWidget {
  final String name;
  const CategoryScreen({super.key, required this.name});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String searchQuery = "";
  String selectedLocation = "All Locations";

  final List<Map<String, dynamic>> mockCategoryShops = [
    {
      "id": "1",
      "name": "Urban Threads",
      "description": "Contemporary streetwear and casual fashion",
      "images": [
        "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80",
        "https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80",
      ],
    },
    {
      "id": "2",
      "name": "Elegance Boutique",
      "description": "High-end formal wear and accessories",
      "images": [
        "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80",
        "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80",
      ],
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
              // Sticky header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Button(
                            variant: ButtonVariant.ghost,
                            size: ButtonSize.icon,
                            child: const Icon(CupertinoIcons.chevron_left),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: local.SearchBar(
                        placeholder: "Search ${widget.name} shops...",
                        value: searchQuery,
                        onChange: (value) =>
                            setState(() => searchQuery = value),
                      ),
                    ),

                    // Location filter buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Button(
                            variant: selectedLocation == "All Locations"
                                ? ButtonVariant.defaultVariant
                                : ButtonVariant.outline,
                            size: ButtonSize.sm,
                            child: const Text("All Locations"),
                            onPressed: () => setState(
                                () => selectedLocation = "All Locations"),
                          ),
                          const SizedBox(width: 8),
                          Button(
                            variant: selectedLocation == "Nearby"
                                ? ButtonVariant.defaultVariant
                                : ButtonVariant.outline,
                            size: ButtonSize.sm,
                            child: Row(
                              children: const [
                                Icon(CupertinoIcons.location, size: 16),
                                SizedBox(width: 4),
                                Text("Nearby"),
                              ],
                            ),
                            onPressed: () =>
                                setState(() => selectedLocation = "Nearby"),
                          ),
                          const SizedBox(width: 8),
                          Button(
                            variant: selectedLocation == "New York"
                                ? ButtonVariant.defaultVariant
                                : ButtonVariant.outline,
                            size: ButtonSize.sm,
                            child: const Text("New York"),
                            onPressed: () =>
                                setState(() => selectedLocation = "New York"),
                          ),
                          const SizedBox(width: 8),
                          Button(
                            variant: selectedLocation == "Los Angeles"
                                ? ButtonVariant.defaultVariant
                                : ButtonVariant.outline,
                            size: ButtonSize.sm,
                            child: const Text("Los Angeles"),
                            onPressed: () => setState(
                                () => selectedLocation = "Los Angeles"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Shops list
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${mockCategoryShops.length} shops found",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: mockCategoryShops
                          .map(
                            (shop) => ShopCard(
                              id: shop['id'],
                              name: shop['name'],
                              description: shop['description'],
                              images: List<String>.from(shop['images']),
                            ),
                          )
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
