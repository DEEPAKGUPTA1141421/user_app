import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_loader.dart';
import '../../model/shop.dart';
import '../../provider/rider_provider.dart';
import '../../provider/shop_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/shops/shop_card.dart';
import '../../widgets/shops/shop_grid_card.dart';
import '../../widgets/shops/shop_filter_sheet.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final ScrollController _scroll   = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  Timer? _suggestDebounce;
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _gridView = true; // default to grid — shows more shops

  // User location — read from rider state (defaultAddress lat/lng)
  double _lat = 0.0;
  double _lng = 0.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _suggestDebounce?.cancel();
    _overlayEntry?.remove();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  void _init() {
    final addresses = ref.read(riderPod).addresses;
    final defaultAddr = _defaultAddress(addresses);

    if (defaultAddr != null) {
      _lat = double.tryParse(defaultAddr['latitude']?.toString() ?? '') ?? 0.0;
      _lng = double.tryParse(defaultAddr['longitude']?.toString() ?? '') ?? 0.0;
    }
    ref.read(shopPod.notifier).loadNearby(lat: _lat, lng: _lng);
  }

  Map<String, dynamic>? _defaultAddress(List<dynamic> addresses) {
    if (addresses.isEmpty) return null;
    try {
      return addresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => addresses.first,
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Scroll — load more ───────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final threshold = _scroll.position.maxScrollExtent - 200;
    if (_scroll.offset >= threshold) {
      ref.read(shopPod.notifier).loadMore(lat: _lat, lng: _lng);
    }
  }

  // ── Search + autocomplete ────────────────────────────────────────────────────

  void _onSearchChanged(String q) {
    // Full search debounce — replaces the shop list
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      ref.read(shopPod.notifier).search(q, lat: _lat, lng: _lng);
    });

    // Suggestion debounce — shorter so overlay appears quickly
    _suggestDebounce?.cancel();
    if (q.trim().isEmpty) {
      _hideSuggestions();
      return;
    }
    _suggestDebounce = Timer(const Duration(milliseconds: 280), () async {
      final results =
          await ref.read(shopPod.notifier).getSuggestions(q.trim());
      if (!mounted) return;
      if (results.isEmpty) {
        _hideSuggestions();
      } else {
        setState(() => _suggestions = results);
        _showSuggestionsOverlay();
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    _suggestDebounce?.cancel();
    _hideSuggestions();
    ref.read(shopPod.notifier).loadNearby(lat: _lat, lng: _lng);
  }

  void _onSuggestionSelected(String suggestion) {
    _searchCtrl.text = suggestion;
    _searchCtrl.selection =
        TextSelection.fromPosition(TextPosition(offset: suggestion.length));
    _debounce?.cancel();
    _suggestDebounce?.cancel();
    _hideSuggestions();
    ref.read(shopPod.notifier).search(suggestion, lat: _lat, lng: _lng);
  }

  void _showSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (_) => _SuggestionsOverlay(
        layerLink: _layerLink,
        suggestions: _suggestions,
        onSelect: _onSuggestionSelected,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _suggestions = []);
  }

  // ── Filter sheet ─────────────────────────────────────────────────────────────

  void _openFilter() => showShopFilterSheet(
        context,
        ref: ref,
        userLat: _lat,
        userLng: _lng,
      );

  // ── Navigate to shop detail ───────────────────────────────────────────────────

  void _openShop(Shop shop) {
    Navigator.pushNamed(
      context,
      '/shop/${shop.id}',
      arguments: {'shop': shop, 'userLat': _lat, 'userLng': _lng},
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(shopPod);
    final filterActive = state.filter.isActive;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Shops',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              // Grid / List toggle
              GestureDetector(
                onTap: () => setState(() => _gridView = !_gridView),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    size: 18,
                    color: AppColors.grey,
                  ),
                ),
              ),
              // Filter icon with active dot badge
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: _openFilter,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: filterActive ? AppColors.white : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: filterActive ? AppColors.white : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: filterActive ? AppColors.bg : AppColors.grey,
                        ),
                      ),
                      if (filterActive)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.divider),
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: CompositedTransformTarget(
                link: _layerLink,
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ),
            ),
          ),

          // ── Active filter chips row ─────────────────────────────────────────
          if (filterActive)
            SliverToBoxAdapter(
              child: _ActiveFilterChips(
                filter: state.filter,
                onClear: () => ref
                    .read(shopPod.notifier)
                    .clearFilter(lat: _lat, lng: _lng),
              ),
            ),

          // ── Sort label row ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    state.query.isNotEmpty
                        ? 'Results for "${state.query}"'
                        : 'Nearby Shops',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (!state.isLoading && state.shops.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      '${state.shops.length} shops',
                      style: const TextStyle(
                        color: AppColors.greyDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          if (state.isLoading && state.shops.isEmpty)
            const SliverFillRemaining(
              child: Center(child: AppSpinner()),
            )
          else if (!state.isLoading && state.shops.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                isSearch: state.query.isNotEmpty,
                onReset: _clearSearch,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: state.shops.length,
                itemBuilder: (_, i) => _gridView
                    ? ShopGridCard(
                        shop: state.shops[i],
                        onTap: () => _openShop(state.shops[i]),
                      )
                    : ShopCard(
                        shop: state.shops[i],
                        onTap: () => _openShop(state.shops[i]),
                      ),
              ),
            ),

            // Load-more footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: state.isLoadingMore
                    ? const Center(child: AppSpinner(size: 20))
                    : state.hasMore
                        ? const SizedBox.shrink()
                        : const Center(
                            child: Text(
                              '— That\'s all —',
                              style: TextStyle(
                                color: AppColors.greyDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
              ),
            ),

            // Bottom safe area
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Suggestions overlay ───────────────────────────────────────────────────────

class _SuggestionsOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  const _SuggestionsOverlay({
    required this.layerLink,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.border,
                indent: 44,
              ),
              itemBuilder: (_, i) => InkWell(
                onTap: () => onSelect(suggestions[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: AppColors.greyDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestions[i],
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.north_west_rounded,
                        size: 14,
                        color: AppColors.greyDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search shops…',
          hintStyle: const TextStyle(color: AppColors.greyDark, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.greyDark, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close, color: AppColors.grey, size: 16),
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

// ── Active filter chips summary ───────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final ShopFilter filter;
  final VoidCallback onClear;

  const _ActiveFilterChips({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filter.sortBy != ShopSortBy.distance)
              _ActiveChip(label: filter.sortBy.label),
            if (filter.minRating != null)
              _ActiveChip(label: '${filter.minRating!.toStringAsFixed(1)}+ ★'),
            if (filter.maxDeliveryMinutes != null)
              _ActiveChip(
                label: filter.maxDeliveryMinutes == 60
                    ? '< 1 hr'
                    : filter.maxDeliveryMinutes == 120
                        ? '< 2 hrs'
                        : '< 1 day',
              ),
            _ClearChip(onTap: onClear),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  const _ActiveChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ClearChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 10, color: AppColors.grey),
            SizedBox(width: 3),
            Text(
              'Clear',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final VoidCallback onReset;

  const _EmptyState({required this.isSearch, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.storefront_outlined,
              color: AppColors.greyDark,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No shops found' : 'No shops nearby',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different search term or clear filters.'
                  : 'We\'re expanding. Check back soon.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (isSearch) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onReset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Clear Search',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
