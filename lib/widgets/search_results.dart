// lib/widgets/search_results.dart  ← REPLACE existing file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/product_provider.dart';
import 'search_result_item.dart';
import '../widgets/product_search_results_page.dart';

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brands ────────────────────────────────────────────────────────
          if (brands.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Brands", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  // ✅ Navigate to full results page using the brand name as query
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductSearchResultsPage(
                        query: brand['name'] ?? query,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          // ── Products ──────────────────────────────────────────────────────
          if (products.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  // ✅ Navigate to full search results page with filters + grid
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductSearchResultsPage(query: query),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}