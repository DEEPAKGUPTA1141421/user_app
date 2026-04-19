import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/category_sections.dart';
import '../provider/banner_provider.dart';
import '../provider/infinite_product_Provider.dart';
import '../widgets/collapsible_header.dart';
import '../widgets/Home/category_page.dart';
import '../components/product/infinite_product_section.dart';
import '../core/widgets/app_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedCategoryId;

  // Incrementing this key remounts CategoryPage + InfiniteProductSection,
  // resetting their dedup guards and triggering a fresh API fetch.
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    // 1. Reset provider state so children re-fetch from scratch
    ref.invalidate(categorySectionsProvider);
    ref.invalidate(bannerProvider);
    ref.invalidate(InfiniteproductProvider);

    // 2. Remount children by changing their ValueKey
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppRefreshIndicator(
        onRefresh: _onRefresh,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CollapsibleHeader(
                  onCategorySelected: (id) {
                    setState(() => selectedCategoryId = id);
                  },
                ),

                  // ValueKey forces remount on refresh so _lastKey resets
                  CategoryPage(
                    key: ValueKey('category_$_refreshKey'),
                    categoryId: selectedCategoryId,
                  ),

                  InfiniteProductSection(
                    key: ValueKey('infinite_$_refreshKey'),
                  ),
                ],
            ),
          ),
        ),
      ),
    );
  }
}
