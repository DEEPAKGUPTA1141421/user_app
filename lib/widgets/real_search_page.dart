import 'package:flutter/material.dart';

// Mock image placeholders for demo (use your own assets in real app)
const String placeholderImage = 'https://via.placeholder.com/150';

// -------------- Search Header ------------------

class SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onCameraTap;

  const SearchHeader({
    Key? key,
    required this.controller,
    required this.onBack,
    required this.onCameraTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              splashRadius: 24,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'watches',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 40),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.blue.shade600),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                  Positioned(
                    right: 8,
                    child: InkWell(
                      onTap: onCameraTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------- Category Discovery ------------------

class CategoryDiscovery extends StatelessWidget {
  final List<List<String>> categories = const [
    ["Mobiles", "Shoes", "Laptops", "Watches"],
    ["Tv", "Sarees", "Headphones", "Bluetooth"],
    ["Fridge", "Bedsheet", "Water bottle", "Jeans"],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up, size: 20),
              SizedBox(width: 8),
              Text(
                "Discover More",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: categories.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  children: row
                      .map(
                        (category) => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            backgroundColor: Colors.orange.shade100,
                            foregroundColor: Colors.orange.shade800,
                            elevation: 0,
                          ),
                          onPressed: () {},
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -------------- Popular Products ------------------

class PopularProduct {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String price;

  PopularProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
  });
}

class PopularProducts extends StatelessWidget {
  final List<PopularProduct> products = [
    PopularProduct(
      id: 1,
      name: "GOBOULT",
      description: "True Wireless",
      imageUrl: placeholderImage,
      price: "₹1,999",
    ),
    PopularProduct(
      id: 2,
      name: "rabba",
      description: "Women's Pon...",
      imageUrl: placeholderImage,
      price: "₹2,499",
    ),
    PopularProduct(
      id: 3,
      name: "OnePlus",
      description: "Headset",
      imageUrl: placeholderImage,
      price: "₹3,999",
    ),
    PopularProduct(
      id: 4,
      name: "Samsung",
      description: "Tablets with C...",
      imageUrl: placeholderImage,
      price: "₹25,999",
    ),
    PopularProduct(
      id: 5,
      name: "SONY",
      description: "PS5",
      imageUrl: placeholderImage,
      price: "₹49,999",
    ),
    PopularProduct(
      id: 6,
      name: "Lenovo",
      description: "Gaming Laptop...",
      imageUrl: placeholderImage,
      price: "₹75,999",
    ),
    PopularProduct(
      id: 7,
      name: "ANIRAV",
      description: "Women's Rea...",
      imageUrl: placeholderImage,
      price: "₹1,799",
    ),
    PopularProduct(
      id: 8,
      name: "CHG",
      description: "PSP",
      imageUrl: placeholderImage,
      price: "₹8,999",
    ),
    PopularProduct(
      id: 9,
      name: "Boho Girl",
      description: "Messenger B...",
      imageUrl: placeholderImage,
      price: "₹899",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Popular Products",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            product.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.price,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// -------------- Recent Searches ------------------

class RecentSearches extends StatelessWidget {
  final List<String> recentSearches = ['t shirts'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Searches",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((term) {
              return Chip(
                label: Text(term,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Colors.grey.shade200,
                avatar:
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -------------- Recommended Stores ------------------

class Store {
  final int id;
  final String name;
  final String imageUrl;
  final String category;

  Store({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
  });
}

class RecommendedStores extends StatelessWidget {
  final List<Store> stores = [
    Store(
        id: 1,
        name: "Earphones",
        imageUrl: placeholderImage,
        category: "Electronics"),
    Store(
        id: 2,
        name: "T-shirts",
        imageUrl: placeholderImage,
        category: "Fashion"),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommended Stores For You",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final store = stores[index];
                return Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child:
                              Image.network(store.imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          store.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// -------------- Trending Searches ------------------

class TrendingSearchItem {
  final int id;
  final String title;
  final String category;
  final String imageUrl;

  TrendingSearchItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
  });
}

class TrendingSearches extends StatelessWidget {
  final List<TrendingSearchItem> trendingItems = [
    TrendingSearchItem(
      id: 1,
      title: "Oppo k13 turbo 5g",
      category: "Mobile",
      imageUrl: placeholderImage,
    ),
    TrendingSearchItem(
      id: 2,
      title: "Kurta set for women wit",
      category: "Fashion",
      imageUrl: placeholderImage,
    ),
    TrendingSearchItem(
      id: 3,
      title: "Snitch shirts",
      category: "Clothing",
      imageUrl: placeholderImage,
    ),
    TrendingSearchItem(
      id: 4,
      title: "Ssc gd book 2026",
      category: "Books",
      imageUrl: placeholderImage,
    ),
    TrendingSearchItem(
      id: 5,
      title: "Oppo k 13 turbo pro",
      category: "Mobile",
      imageUrl: placeholderImage,
    ),
    TrendingSearchItem(
      id: 6,
      title: "Gs sudha book",
      category: "Books",
      imageUrl: placeholderImage,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trending Searches",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingItems.map((item) {
              return Chip(
                label: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                avatar: CircleAvatar(
                  backgroundImage: NetworkImage(item.imageUrl),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Assume all the previous widgets (SearchHeader, CategoryDiscovery, etc.) are imported or defined above

class RealSearchPage extends StatefulWidget {
  const RealSearchPage({Key? key}) : super(key: key);

  @override
  State<RealSearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<RealSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  void _onCameraTap() {
    // TODO: Implement camera search or image upload logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera search tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional AppBar or keep blank for full custom header
      body: SafeArea(
        child: Column(
          children: [
            // Sticky search header
            SearchHeader(
              controller: _searchController,
              onBack: _onBackPressed,
              onCameraTap: _onCameraTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    bottom: 80), // for bottom nav bar space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryDiscovery(),
                    PopularProducts(),
                    RecentSearches(),
                    RecommendedStores(),
                    TrendingSearches(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Your bottom navigation can go here, e.g.
      // bottomNavigationBar: YourBottomNavigationWidget(),
    );
  }
}
