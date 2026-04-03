import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,

        // 🎨 Theme (matching EditProfile)
        backgroundColor: AppColors.bg,
        elevation: 0,

        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.grey,

        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
