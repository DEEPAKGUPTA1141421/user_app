import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

// Placeholder imports for components
import 'search_bar.dart' as local;
import 'product_card.dart';
import 'button.dart';
import 'textarea.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  String searchQuery = "";
  String newComment = "";
  final Map<String, List<Map<String, dynamic>>> mockProducts = {
    "shirts": [
      {
        "id": "p1",
        "name": "Classic White Shirt",
        "price": 49.99,
        "image":
            "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400&q=80"
      },
      {
        "id": "p2",
        "name": "Denim Casual Shirt",
        "price": 39.99,
        "image":
            "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&q=80"
      },
    ],
    "pants": [
      {
        "id": "p3",
        "name": "Slim Fit Jeans",
        "price": 69.99,
        "image":
            "https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&q=80"
      },
      {
        "id": "p4",
        "name": "Chino Pants",
        "price": 54.99,
        "image":
            "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400&q=80"
      },
    ],
  };

  final List<Map<String, dynamic>> reviews = [
    {
      "id": 1,
      "name": "Sarah M.",
      "rating": 5,
      "comment": "Amazing quality and fast shipping!",
      "date": "2 days ago"
    },
    {
      "id": 2,
      "name": "John D.",
      "rating": 4,
      "comment": "Great products, will shop again.",
      "date": "1 week ago"
    },
  ];

  // Helper to create product section
  Widget buildProductSection(
      String title, List<Map<String, dynamic>> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              title.toLowerCase() == "shirts" ? Colors.pink : Colors.blue,
              title.toLowerCase() == "shirts" ? Colors.orange : Colors.cyan,
            ]),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: products
              .map(
                (product) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: ProductCard(
                    id: product["id"],
                    name: product["name"],
                    price: product["price"],
                    image: product["image"],
                    shopId: widget.shopId,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(bottom: 80),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: [
                    Button(
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.icon,
                      child: const Icon(CupertinoIcons.back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Fashion Forward",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Banner
              SizedBox(
                height: 192,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80",
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Shop description + search
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Your one-stop shop for trendy fashion",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    local.SearchBar(
                      placeholder: "Search products...",
                      value: searchQuery,
                      onChange: (value) => setState(() => searchQuery = value),
                    ),
                  ],
                ),
              ),

              // Product sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildProductSection("Shirts", mockProducts["shirts"]!),
                    const SizedBox(height: 16),
                    buildProductSection("Pants", mockProducts["pants"]!),
                    const SizedBox(height: 16),

                    // Reviews
                    const Text("Reviews & Ratings",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Column(
                      children: reviews
                          .map(
                            (review) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(review["name"],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Row(
                                        children: List.generate(
                                          review["rating"],
                                          (index) => const Icon(
                                              CupertinoIcons.star_fill,
                                              size: 16,
                                              color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(review["comment"],
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(review["date"],
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    // Add review
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text("Add your review",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Textarea(
                            placeholder: "Share your experience...",
                            value: newComment,
                            onChange: (value) =>
                                setState(() => newComment = value),
                          ),
                          const SizedBox(height: 8),
                          Button(
                            child: const Text("Submit Review"),
                            onPressed: () {},
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
    );
  }
}
