import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './filter_chip_widget.dart';
import './filter_modal .dart';
import './product_card_widget .dart';
import './sort_modal_widget.dart';
import './badge_widget.dart';
import '../../model/product.dart';
import '../../widgets/real_search_page.dart';

class ProductGrid extends StatefulWidget {
  final Map<String, dynamic>? section;
  const ProductGrid({super.key,this.section});

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  bool sortModalOpen = false;
  bool filterModalOpen = false;
  String selectedSort = "relevance";
  List<String> selectedFilters = [];
  int cartCount = 6;
  final Color brandColor = const Color(0xFFFF5200); // Your brand color

  final List<Product> products = [
    Product(
      id: 1,
      name: "GameSir Silver T80 Ultra Slim Smartwatch with Metal Strap",
      image: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400",
      originalPrice: 3999,
      salePrice: 793,
      discount: 80,
      rating: 4,
      deliveryDate: "Delivery by 25th Oct",
      isTopDiscount: true,
    ),
    Product(
      id: 2,
      name: "Noise Colorfit Icon 2 1.8\" Display Bluetooth Calling Smartwatch",
      image: "https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400",
      originalPrice: 5999,
      salePrice: 1199,
      discount: 80,
      rating: 4.5,
      deliveryDate: "Delivery tomorrow",
      isBestseller: true,
      hasComboOffer: true,
      comboSavings: 1055,
      isExpressDelivery: true,
    ),
    // Add other products...
  ];

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFFF5200);
    return Scaffold(
      backgroundColor: brandColor.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          readOnly: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RealSearchPage()),
          ),
          decoration: InputDecoration(
            hintText: "Search for products",
            filled: true,
            fillColor: Colors.grey[200],
            prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(CupertinoIcons.cart, color: brandColor),
                onPressed: () {},
              ),
              if (cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: BadgeWidget(
                    text: '$cartCount',
                    count: cartCount,
                    variant: BadgeVariant.destructive, // red cart badge
                    padding: const EdgeInsets.all(4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChipWidget(
                  label: "Sort",
                  onPressed: () => setState(() => sortModalOpen = true),
                ),
                FilterChipWidget(
                  label: "Filter",
                  icon: CupertinoIcons.slider_horizontal_3,
                  onPressed: () => setState(() => filterModalOpen = true),
                ),
                FilterChipWidget(
                  label: "Brand",
                  onPressed: () {},
                ),
                FilterChipWidget(
                  label: "Discount",
                  onPressed: () => setState(() => filterModalOpen = true),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  return ProductCardWidget(product: products[index]);
                },
              ),
            ),
          ),

          // Sort & Filter Modals
          if (sortModalOpen)
            SortModalWidget(
              open: sortModalOpen,
              onOpenChange: (isOpen) => setState(() => sortModalOpen = isOpen),
              selectedSort: selectedSort,
              onSortChange: (value) {
                setState(() {
                  selectedSort = value;
                  sortModalOpen = false;
                });
              },
            ),

          if (filterModalOpen)
            FilterModal(
              open: filterModalOpen,
              onOpenChange: (isOpen) => setState(() => filterModalOpen = isOpen),
              selectedFilters: selectedFilters,
              onFiltersChange: (filters) {
                setState(() => selectedFilters = filters);
              },
            ),
        ],
      ),
    );
  }
}
