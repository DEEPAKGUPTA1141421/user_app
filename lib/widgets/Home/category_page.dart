import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_sections.dart'; // adjust the path
import '../banner_section.dart';

class CategoryPage extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryPage({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  @override
  void initState() {
    super.initState();
    print("render CategoryPage1");
    Future.microtask(
        () => ref.read(categorySection.notifier).fetchSectionsOfCategory());
    print("render CategoryPage 2");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySection);
    final isLoading = state['isLoading'] ?? false;
    final sectionsData = state['sectionsData'] as List<dynamic>? ?? [];
    print("render CategoryPage 3 $isLoading, $sectionsData");

    // Show loader while fetching
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5200)),
      );
    }

    // If no sections, show empty
    if (sectionsData.isEmpty) {
      return const Center(child: Text("No sections found"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionsData.map((section) {
        final type = section['type'] ?? '';
        final data = section['items'] ?? []; // use 'items' from your API
        print("Data is ${data[0]['']}");

        switch (type.toUpperCase()) {
          case 'CATEGORY':
          case 'BANNER':
            return BannerSection(section: section);
          case 'PRODUCT_LIST':
            return _buildProductListSection(data);
          case 'PRODUCT_GRID':
            return _buildProductGridSection(data);
          case 'SPONSORED':
          case 'BRAND':
            return _buildSponsoredSection(data);
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _buildBannerSection(List<dynamic> data) {
    return Container(
      height: 150,
      color: Colors.orange,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(child: Text('Banner Section - ${data.length} items')),
    );
  }

  Widget _buildProductListSection(List<dynamic> data) {
    return Column(
      children: data.map((item) {
        return ListTile(
          title: Text(item['name'] ?? ''),
        );
      }).toList(),
    );
  }

  Widget _buildProductGridSection(List<dynamic> data) {
    return GridView.builder(
      shrinkWrap: true, // important: lets it take only the needed height
      physics:
          const NeverScrollableScrollPhysics(), // important: disables inner scrolling
      itemCount: data.length,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          child: Center(child: Text(item['name'] ?? '')),
        );
      },
    );
  }

  Widget _buildSponsoredSection(List<dynamic> data) {
    return Container(
      height: 400,
      color: Colors.green,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(child: Text('Sponsored Section')),
    );
  }
}
