import 'package:flutter/material.dart';
import 'address_section.dart';
import 'search_section.dart';
import 'category_section.dart';
import 'show_address_modal.dart';

class CollapsibleHeader extends StatefulWidget {
  final Function(String) onCategorySelected;
  const CollapsibleHeader({super.key, required this.onCategorySelected});
  @override
  State<CollapsibleHeader> createState() => _CollapsibleHeaderState();
}

class _CollapsibleHeaderState extends State<CollapsibleHeader> {
  bool isCollapsed = false;
  double lastScrollY = 0;
  ScrollPosition? _scrollPosition;
  VoidCallback? _scrollListener;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScrollableState? scrollable = Scrollable.of(context);
      if (scrollable != null) {
        _scrollPosition = scrollable.position;

        _scrollListener = () {
          if (!mounted) return; // safety check
          double currentScrollY = _scrollPosition!.pixels;

          if (currentScrollY > 100 && currentScrollY > lastScrollY) {
            setState(() => isCollapsed = true);
          } else if (currentScrollY < lastScrollY) {
            setState(() => isCollapsed = false);
          }

          lastScrollY = currentScrollY;
        };

        _scrollPosition!.addListener(_scrollListener!);
      }
    });
  }

  @override
  void dispose() {
    if (_scrollListener != null && _scrollPosition != null) {
      _scrollPosition!.removeListener(_scrollListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(
              0, isCollapsed ? -100 : 0, 0), // collapse effect
          child: Container(
             color: Colors.black,
            child: SafeArea(
              top: false,
              child: AddressSection(
                showAddressModal: () {
                  showAddressModal(context);
                },
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              const SearchSection(),
              CategorySection(onCategorySelected: widget.onCategorySelected),
            ],
          ),
        )
      ],
    );
  }
}
