// ---------------- Shimmer Skeleton ----------------
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/product_provider.dart'; // adjust path
import '../utils/app_colors.dart';

class DefaultSections extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> popularProducts;
  final List<String> categories;
  final Function(String) onCategoryTap;

  const DefaultSections({
    super.key,
    required this.popularProducts,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  ConsumerState<DefaultSections> createState() => _DefaultSectionsState();
}

class _DefaultSectionsState extends ConsumerState<DefaultSections> {
  List<Map<String, dynamic>> recentSearches = [];
  List<Map<String, dynamic>> trendingSearches = [];

  @override
  void initState() {
    super.initState();
    debugPrint("✅ DefaultSections initState called");

    // 🔁 Fetch both recent + trending searches when the widget is mounted
    Future.microtask(() async {
      debugPrint("🔁 Fetching recent + trending searches...");
      final recent = await ref.read(productPod.notifier).getRecentSearches();
      final trending = await ref.read(productPod.notifier).getTrendingSearches();

      setState(() {
        recentSearches = List<Map<String, dynamic>>.from(recent);
        trendingSearches = List<Map<String, dynamic>>.from(trending);
      });

      debugPrint(
          "✅ Recent Searches Count: ${recentSearches.length}, Trending: ${trendingSearches.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productPod);
    final isLoading = productState.isLoading;

    if (isLoading) {
      debugPrint("🟡 Showing shimmer skeleton...");
      return const SearchSkeleton();
    }

    debugPrint("🟢 Rendering DefaultSections UI");

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- Recent Searches ----------------
          if (recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  final item = recentSearches[index];
                  return GestureDetector(
                    onTap: () => widget.onCategoryTap(item['title']),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(item['imageUrl']),
                          ),
                          const SizedBox(height: 6),
                          Text(
  item['title'],
  style: const TextStyle(
    color: AppColors.white,
    fontSize: 13,
  ),
),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ---------------- Trending Searches ----------------
          if (trendingSearches.isNotEmpty) ...[
            Text('Trending Searches',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trendingSearches.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final item = trendingSearches[index];
                return GestureDetector(
                  onTap: () => widget.onCategoryTap(item['title']),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.shade300, blurRadius: 3)
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.network(item['imageUrl'],
                            width: 40, height: 40, fit: BoxFit.cover),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(item['title'],
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // ---------------- Popular Products ----------------
          Text(
            'Popular Products',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.popularProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final product = widget.popularProducts[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 3)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(product['image'],
                            fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
  product['brand'],
  style: const TextStyle(
    color: AppColors.white,
    fontWeight: FontWeight.w600,
  ),
),
                              Text(
                                product['category'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
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
          const SizedBox(height: 16),

          // ---------------- Discover More ---------------
          Text(
            'Discover More',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((category) {
              return ElevatedButton(
                onPressed: () => widget.onCategoryTap(category),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  Widget _shimmerContainer(
      {double width = double.infinity,
      double height = 16,
      BorderRadius? radius}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: radius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Search Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text("Recent Searches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (_, __) => Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    _shimmerContainer(
                        width: 70,
                        height: 70,
                        radius: BorderRadius.circular(35)),
                    const SizedBox(height: 6),
                    _shimmerContainer(
                        width: 50,
                        height: 10,
                        radius: BorderRadius.circular(6)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trending Search Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text("Trending Searches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, __) => Row(
              children: [
                _shimmerContainer(
                    width: 40, height: 40, radius: BorderRadius.circular(8)),
                const SizedBox(width: 8),
                Expanded(child: _shimmerContainer(height: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Popular Products Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text("Popular Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerContainer(
                    height: 120, radius: BorderRadius.circular(12)),
                const SizedBox(height: 8),
                _shimmerContainer(width: 80, height: 12),
                const SizedBox(height: 4),
                _shimmerContainer(width: 50, height: 10),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Discover More Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text("Discover More",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
                6,
                (_) => _shimmerContainer(
                    width: 80, height: 30, radius: BorderRadius.circular(20))),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
