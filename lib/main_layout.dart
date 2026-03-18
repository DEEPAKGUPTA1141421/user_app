import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/people_screen.dart';
import 'screens/cart_screen.dart';
import 'widgets/bottom_navbar.dart';
import 'widgets/shop/shops_page.dart';
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ShopsPage(),
    const CategoriesScreen(),
    const PeopleScreen(),
    const CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // ✅ ONLY ACTIVE SCREEN BUILDS
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}