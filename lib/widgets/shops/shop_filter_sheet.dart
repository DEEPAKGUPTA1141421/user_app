import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/shop.dart';
import '../../provider/shop_provider.dart';
import '../../utils/app_colors.dart';


/// Dark bottom sheet for shop filters.
/// Matches the buy_now_address_sheet.dart pattern exactly:
///   handle → title → sections → AppButton CTA.
///
/// Sections: Sort By · Category · Min Rating · Max Delivery Time
/// (No brand / no offer / no coupon — per spec)
Future<void> showShopFilterSheet(
  BuildContext context, {
  required WidgetRef ref,
  required double userLat,
  required double userLng,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShopFilterSheet(
      ref: ref,
      userLat: userLat,
      userLng: userLng,
    ),
  );
}

class _ShopFilterSheet extends StatefulWidget {
  final WidgetRef ref;
  final double userLat;
  final double userLng;

  const _ShopFilterSheet({
    required this.ref,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<_ShopFilterSheet> createState() => _ShopFilterSheetState();
}

class _ShopFilterSheetState extends State<_ShopFilterSheet> {
  late ShopFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.ref.read(shopPod).filter;
  }

  void _apply() {
    widget.ref.read(shopPod.notifier).applyFilter(
          _draft,
          lat: widget.userLat,
          lng: widget.userLng,
        );
    Navigator.pop(context);
  }

  void _clear() => setState(() => _draft = const ShopFilter.empty());

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Shops',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: _clear,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Sort By ─────────────────────────────────────────────────────
            const _SectionLabel('Sort By'),
            const SizedBox(height: 10),
            _SortChips(
              current: _draft.sortBy,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(sortBy: v)),
            ),
            const SizedBox(height: 22),

            // ── Minimum Rating ───────────────────────────────────────────────
            const _SectionLabel('Minimum Rating'),
            const SizedBox(height: 10),
            _RatingChips(
              current: _draft.minRating,
              onChanged: (v) => setState(
                () => _draft = v == null
                    ? _draft.copyWith(clearRating: true)
                    : _draft.copyWith(minRating: v),
              ),
            ),
            const SizedBox(height: 22),

            // ── Max Delivery Time ─────────────────────────────────────────────
            const _SectionLabel('Delivery Time'),
            const SizedBox(height: 10),
            _DeliveryChips(
              current: _draft.maxDeliveryMinutes,
              onChanged: (v) => setState(
                () => _draft = v == null
                    ? _draft.copyWith(clearDelivery: true)
                    : _draft.copyWith(maxDeliveryMinutes: v),
              ),
            ),
            const SizedBox(height: 28),

            // ── Apply CTA ────────────────────────────────────────────────────
            _ApplyButton(onTap: _apply),
          ],
        ),
      ),
    );
  }
}

// ── Sort chips ─────────────────────────────────────────────────────────────────

class _SortChips extends StatelessWidget {
  final ShopSortBy current;
  final ValueChanged<ShopSortBy> onChanged;
  const _SortChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShopSortBy.values
          .map((v) => _FilterChip(
                label: v.label,
                active: current == v,
                onTap: () => onChanged(v),
              ))
          .toList(),
    );
  }
}

// ── Rating chips ───────────────────────────────────────────────────────────────

class _RatingChips extends StatelessWidget {
  final double? current;
  final ValueChanged<double?> onChanged;
  const _RatingChips({required this.current, required this.onChanged});

  static const _options = <double?>[null, 3.0, 4.0, 4.5];

  String _label(double? v) => v == null ? 'Any' : '${v.toStringAsFixed(1)}+ ★';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options
          .map((v) => _FilterChip(
                label: _label(v),
                active: current == v,
                onTap: () => onChanged(v),
              ))
          .toList(),
    );
  }
}

// ── Delivery time chips ────────────────────────────────────────────────────────

class _DeliveryChips extends StatelessWidget {
  final int? current;
  final ValueChanged<int?> onChanged;
  const _DeliveryChips({required this.current, required this.onChanged});

  static const _options = <int?>[null, 60, 120, 1440];

  String _label(int? v) => switch (v) {
        null => 'Any',
        60   => '< 1 hr',
        120  => '< 2 hrs',
        1440 => '< 1 day',
        _    => '< ${v}m',
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options
          .map((v) => _FilterChip(
                label: _label(v),
                active: current == v,
                onTap: () => onChanged(v),
              ))
          .toList(),
    );
  }
}

// ── Shared filter chip ─────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.white : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.white : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.bg : AppColors.grey,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Apply CTA ─────────────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ApplyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'Apply Filters',
            style: TextStyle(
              color: AppColors.bg,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.grey,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
