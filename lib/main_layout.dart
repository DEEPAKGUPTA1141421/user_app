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

  // Tracks which tabs have been visited so we only mount each screen once.
  // Home (index 0) is visited by default.
  final Set<int> _visitedTabs = {0};

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
      // IndexedStack keeps every mounted screen alive in the widget tree.
      // Tab screens are only mounted the first time they are visited, preventing
      // repeated initState / API calls on every tab switch.
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screens.length, (i) {
          if (!_visitedTabs.contains(i)) return const SizedBox.shrink();
          return _screens[i];
        }),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _visitedTabs.add(index); // mark tab as visited → mounts it once
            _currentIndex = index;
          });
        },
      ),
    );
  }
}