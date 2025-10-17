import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/product_provider.dart';
import 'search_result_item.dart';

class SearchResults extends ConsumerWidget {
  final String query;

  const SearchResults({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productPod);
    final isLoading = productState['isLoading'] ?? false;
    final products = productState['products'] ?? [];
    final brands = productState['brands'] ?? [];
    final message = productState['message'] ?? '';

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    print(
        "✅ Brands count: ${brands.length}, Products count: ${products.length}");

    // ❌ Old: only checked products
    // ✅ New: check if both are empty
    if (products.isEmpty && brands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            message.isNotEmpty ? message : 'No results found for "$query"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // ✅ Use SingleChildScrollView + Column to show both brands & products
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (brands.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Brands",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return SearchResultItem(
                  image: brand['logoUrl'] ?? "https://via.placeholder.com/150",
                  title: brand['name'] ?? "Unknown Brand",
                  category: brand['description'] ?? "No description",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/brandDetail',
                      arguments: brand['id'],
                    );
                  },
                );
              },
            ),
          ],
          if (products.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return SearchResultItem(
                  image: (product['images'] != null &&
                          product['images'] is List &&
                          product['images'].isNotEmpty)
                      ? product['images'][0]
                      : "https://via.placeholder.com/150",
                  title: product['name'] ?? "Unnamed Product",
                  category: product['description'] ?? "Unknown",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/productDetail/${product['id']}',
                      arguments: {
                        'itemType': "PRODUCT",
                        'title': product['name'] ?? "Unnamed Product",
                        'imageUrl': (product['images'] != null &&
                                product['images'] is List &&
                                product['images'].isNotEmpty)
                            ? product['images'][0]
                            : "https://via.placeholder.com/150",
                        'itemId': product['id'] ?? "",
                      }, // dynamic URL
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
