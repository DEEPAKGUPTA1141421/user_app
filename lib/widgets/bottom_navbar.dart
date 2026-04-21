import 'package:flutter/cupertino.dart';
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

  static const _items = [
    _NavItem(icon: CupertinoIcons.house,          activeIcon: CupertinoIcons.house_fill,          label: 'Home'),
    _NavItem(icon: CupertinoIcons.tag,             activeIcon: CupertinoIcons.tag_fill,             label: 'Shop'),
    _NavItem(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: 'Categories'),
    _NavItem(icon: CupertinoIcons.person,          activeIcon: CupertinoIcons.person_fill,          label: 'Account'),
    _NavItem(icon: CupertinoIcons.bag,             activeIcon: CupertinoIcons.bag_fill,             label: 'Cart'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.only(top: 10, bottom: bottomPad > 0 ? bottomPad : 12),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.surface2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      active ? _items[i].activeIcon : _items[i].icon,
                      color: active ? AppColors.white : AppColors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _items[i].label,
                    style: TextStyle(
                      color: active ? AppColors.white : AppColors.grey,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
