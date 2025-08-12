import 'package:flutter/material.dart';
import '../widgets/address_section.dart';
import '../widgets/search_section.dart';
import '../widgets/banner_section.dart';
import '../widgets/category_scroll.dart';
import '../widgets/product_list.dart';
import '../widgets/product_grid.dart';
import '../widgets/title_row.dart';
import '../widgets/sponsored_section.dart';
import '../widgets/sell_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Section(child: SellSection()),
              _Section(child: AddressSection()),
              _Section(child: SearchSection()),
              _Section(child: BannerSection()),
              _Section(child: TitleRow(title: "Shop by Category")),
              _Section(child: CategoryScroll()),
              _Section(child: TitleRow(title: "Popular Products")),
              _Section(child: ProductList(itemCount: 3)),
              _Section(child: TitleRow(title: "Upcoming Top Deals")),
              _Section(child: ProductList(itemCount: 3)),
              _Section(child: TitleRow(title: "Suggested For You")),
              _Section(child: ProductList(itemCount: 3)),
              _Section(child: TitleRow(title: "Continue Your Search")),
              _Section(child: ProductGrid(itemCount: 6)),
              _Section(child: TitleRow(title: "Upcoming Festival Products")),
              _Section(child: ProductList(itemCount: 3)),
              _Section(child: TitleRow(title: "Super Hot Trends")),
              _Section(child: ProductList(itemCount: 3)),
              _Section(child: TitleRow(title: "Sponsored")),
              _Section(child: SponsoredSection()),
            ],
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
