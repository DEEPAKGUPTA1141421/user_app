import 'package:flutter/material.dart';

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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Ensures 5 items show
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color.fromRGBO(255, 82, 0, 1), // Active
      unselectedItemColor: Colors.grey, // Inactive icon color
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Accounts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
      ],
    );
  }
}
