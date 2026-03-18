import 'package:flutter/material.dart';

import '../utils/StorageService.dart';
import '../widgets/collapsible_header.dart';
import '../widgets/Home/category_page.dart';
import '../components/product/infinite_product_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // null = "For You" default; set to a real category id on tap
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFF5200),
          onRefresh: () async {
            // Force a full rebuild by toggling state
            setState(() {
              selectedCategoryId = selectedCategoryId; // triggers didUpdateWidget in CategoryPage
            });
          },
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Collapsible header (address + search + category tabs) ──
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: CollapsibleHeader(
                      onCategorySelected: (id) {
                        // ✅ Update selected category → triggers didUpdateWidget
                        //    in CategoryPage → re-fetches all APIs
                        setState(() => selectedCategoryId = id);
                      },
                    ),
                  ),

                  // ── Dynamic sections for the selected category ──────────────
                  // CategoryPage reacts to categoryId changes via didUpdateWidget
                  CategoryPage(categoryId: selectedCategoryId),

                  // ── Infinite product scroll (always shown below) ────────────
                  const InfiniteProductSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}