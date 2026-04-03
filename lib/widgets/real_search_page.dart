import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/product_provider.dart';
import 'default_sections.dart';
import 'search_results.dart';
import '../utils/app_colors.dart';

class RealSearchPage extends ConsumerStatefulWidget {
  const RealSearchPage({super.key});

  @override
  ConsumerState<RealSearchPage> createState() => _RealSearchPageState();
}

class _RealSearchPageState extends ConsumerState<RealSearchPage> {
  String searchQuery = "";
  Timer? _debounce;

  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> popularProducts = [
    {
      "id": 1,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "brand": "Samsung",
      "category": "Mobiles"
    },
    {
      "id": 2,
      "image":
          "https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg",
      "brand": "JBL",
      "category": "Speakers"
    },
  ];

  final List<String> categories = [
    "Mobiles",
    "Shoes",
    "Laptops",
    "Watches",
  ];

  /// 🔍 Debounced Search (like Amazon)
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchProducts(value);
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty || query.length < 2) return;

    await ref.read(productPod.notifier).searchProduct(query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productPod);
    final isLoading = productState['isLoading'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER (Premium E-commerce Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  /// Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: AppColors.white),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// 🔍 Search Field
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _controller,
                        cursorColor: AppColors.white,
                        style: const TextStyle(color: AppColors.white, fontSize: 14),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                          _onSearchChanged(value);
                        },
                        decoration: const InputDecoration(
                          hintText: "Search for products, brands...",
                          hintStyle: TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          suffixIcon: Icon(
                            CupertinoIcons.mic,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// QR Scanner (like Flipkart)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      CupertinoIcons.qrcode_viewfinder,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔽 CONTENT
            Expanded(
              child: searchQuery.isEmpty
                  ? DefaultSections(
                      popularProducts: popularProducts,
                      categories: categories,
                      onCategoryTap: (val) {
                        setState(() {
                          searchQuery = val;
                          _controller.text = val;
                        });
                        _searchProducts(val);
                      },
                    )
                  : isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.white),
                        )
                      : SearchResults(query: searchQuery),
            ),
          ],
        ),
      ),
    );
  }
}