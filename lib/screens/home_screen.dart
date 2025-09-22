import 'package:flutter/material.dart';

import '../utils/StorageService.dart';
import '../widgets/address_section.dart';
import '../widgets/search_section.dart';
import '../widgets/banner_section.dart';
import '../widgets/category_section.dart';
import '../widgets/product_list.dart';
import '../widgets/product_grid.dart';
import '../widgets/title_row.dart';
import '../widgets/sponsored_section.dart';
import './auth/login_screen.dart'; // your login page
import '../widgets/collapsible_header.dart';
import '../widgets/Home/category_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? jwtToken;
  bool isLoading = false;
  String? selectedCategoryId;
  int reloadKey = 0;
  @override
  void initState() {
    print("Init the Rendering from Home Page");
    super.initState();
    Future.microtask(() => checkAuth(context));
    // default to null → CategoryPage can handle empty state
    selectedCategoryId = null;
    isLoading = false;
  }

  void reloadPage() {
    setState(() {
      reloadKey++; // change key to rebuild
    });
  }

  Future<void> checkAuth(BuildContext context) async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      // Token not found → go to Login
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _onProductTap(String product) {
    // Navigate to product details page
    print("Tapped product: $product");
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
  }

  void _onMicTap() {
    // Handle mic logic (speech recognition)
    print("Mic tapped!");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(255, 82, 0, 1),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              reloadKey++; // triggers rebuild of everything inside KeyedSubtree
            });
          },
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: KeyedSubtree(
                key: ValueKey(reloadKey), // <-- everything inside rebuilds
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collapsible header
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: CollapsibleHeader(
                        onCategorySelected: (id) {
                          setState(() => selectedCategoryId = id);
                        },
                      ),
                    ),
                    // Category page
                    CategoryPage(categoryId: selectedCategoryId),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to apply horizontal margin to all sections
class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: child,
    );
  }
}
