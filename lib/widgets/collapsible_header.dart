import 'package:flutter/material.dart';
import 'address_section.dart';
import 'search_section.dart';
import 'category_section.dart';
import 'show_address_modal.dart';

class CollapsibleHeader extends StatefulWidget {
  const CollapsibleHeader({super.key});

  @override
  State<CollapsibleHeader> createState() => _CollapsibleHeaderState();
}

class _CollapsibleHeaderState extends State<CollapsibleHeader> {
  bool isCollapsed = false;
  double lastScrollY = 0;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScrollableState? scrollable = Scrollable.of(context);
      scrollable?.position.addListener(() {
        double currentScrollY = scrollable.position.pixels;

        if (currentScrollY > 100 && currentScrollY > lastScrollY) {
          setState(() => isCollapsed = true);
        } else if (currentScrollY < lastScrollY) {
          setState(() => isCollapsed = false);
        }

        lastScrollY = currentScrollY;
      });
    });
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
            child: SafeArea(child: AddressSection(
              showAddressModal: () {
                showAddressModal(context); // your pre-defined function
              },
            )),
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
          child: const Column(
            children: [
              SearchSection(),
              CategorySection(),
            ],
          ),
        )
      ],
    );
  }
}
