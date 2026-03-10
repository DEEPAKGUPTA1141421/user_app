import 'package:flutter/material.dart';
import './models.dart';
import './app_theme.dart';

class FilterDrawer extends StatefulWidget {
  final FilterOptions filters;
  final Function(FilterOptions) onApplyFilters;

  const FilterDrawer({
    super.key,
    required this.filters,
    required this.onApplyFilters,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late FilterOptions _selectedFilters;

  final distanceOptions = ['< 1 km', '< 2 km', '< 5 km', '< 10 km'];
  final brandOptions = ['Apple', 'Samsung', 'Nike', 'Adidas', 'Zara', 'LEGO', 'Dell', 'Sony'];
  final categoryOptions = ['Electronics', 'Fashion', 'Home & Kitchen', 'Beauty', 'Sports', 'Books', 'Toys', 'Grocery'];
  final ratingOptions = ['4.5+', '4.0+', '3.5+', '3.0+'];
  final deliveryOptionsList = ['Same Day', '1-2 Days', 'Express Delivery', 'Free Delivery'];
  final offersList = ['Has Offers', 'Free Shipping', 'Discounted', 'Buy 1 Get 1'];

  @override
  void initState() {
    super.initState();
    _selectedFilters = widget.filters;
  }

  void _toggleFilter(String category, String value) {
    setState(() {
      switch (category) {
        case 'distance':
          final list = List<String>.from(_selectedFilters.distance);
          list.contains(value) ? list.remove(value) : list.add(value);
          _selectedFilters = _selectedFilters.copyWith(distance: list);
          break;
        case 'brands':
          final list = List<String>.from(_selectedFilters.brands);
          list.contains(value) ? list.remove(value) : list.add(value);
          _selectedFilters = _selectedFilters.copyWith(brands: list);
          break;
        case 'categories':
          final list = List<String>.from(_selectedFilters.categories);
          list.contains(value) ? list.remove(value) : list.add(value);
          _selectedFilters = _selectedFilters.copyWith(categories: list);
          break;
        case 'rating':
          final list = List<String>.from(_selectedFilters.rating);
          list.contains(value) ? list.remove(value) : list.add(value);
          _selectedFilters = _selectedFilters.copyWith(rating: list);
          break;
        case 'deliveryOptions':
          final list = List<String>.from(_selectedFilters.deliveryOptions);
          list.contains(value) ? list.remove(value) : list.add(value);
          _selectedFilters = _selectedFilters.copyWith(deliveryOptions: list);
          break;
        case 'offers':
          final list = List<String>.from(_selectedFilters.offers);
          list.contains(value) ? list.remove(value) : list.add(value);
          _selectedFilters = _selectedFilters.copyWith(offers: list);
          break;
      }
    });
  }

  bool _isSelected(String category, String value) {
    switch (category) {
      case 'distance': return _selectedFilters.distance.contains(value);
      case 'brands': return _selectedFilters.brands.contains(value);
      case 'categories': return _selectedFilters.categories.contains(value);
      case 'rating': return _selectedFilters.rating.contains(value);
      case 'deliveryOptions': return _selectedFilters.deliveryOptions.contains(value);
      case 'offers': return _selectedFilters.offers.contains(value);
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        if (_selectedFilters.totalSelected > 0)
                          Text(
                            '${_selectedFilters.totalSelected} filter${_selectedFilters.totalSelected > 1 ? "s" : ""} applied',
                            style: const TextStyle(fontSize: 12, color: kPrimary),
                          ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Distance', 'distance', distanceOptions),
                      const Divider(height: 28),
                      _buildSection('Brand', 'brands', brandOptions),
                      const Divider(height: 28),
                      _buildSection('Categories', 'categories', categoryOptions),
                      const Divider(height: 28),
                      _buildSection('Rating', 'rating', ratingOptions),
                      const Divider(height: 28),
                      _buildSection('Delivery', 'deliveryOptions', deliveryOptionsList),
                      const Divider(height: 28),
                      _buildSection('Offers & Discounts', 'offers', offersList),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Footer buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilters = const FilterOptions();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Clear All', style: TextStyle(color: kTextPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApplyFilters(_selectedFilters);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _selectedFilters.totalSelected > 0
                              ? 'Apply (${_selectedFilters.totalSelected})'
                              : 'Apply',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String category, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = _isSelected(category, option);
            return GestureDetector(
              onTap: () => _toggleFilter(category, option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFF5ED) : Colors.white,
                  border: Border.all(
                    color: selected ? kPrimary : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? kPrimary : kTextSecondary,
                        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check, size: 14, color: kPrimary),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}