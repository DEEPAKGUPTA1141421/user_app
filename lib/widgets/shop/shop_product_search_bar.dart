import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Reusable search bar for in-shop product search.
///
/// Manages its own listener on [controller] so the clear button
/// appears and disappears reactively on every keystroke.
class ShopProductSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;

  const ShopProductSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hint = 'Search products in this shop…',
  });

  @override
  State<ShopProductSearchBar> createState() => _ShopProductSearchBarState();
}

class _ShopProductSearchBarState extends State<ShopProductSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(ShopProductSearchBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: const TextStyle(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.greyDark, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.greyDark, size: 18),
          suffixIcon: hasText
              ? GestureDetector(
                  onTap: widget.onClear,
                  child: const Icon(Icons.close,
                      color: AppColors.grey, size: 16),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        cursorColor: AppColors.white,
      ),
    );
  }
}
