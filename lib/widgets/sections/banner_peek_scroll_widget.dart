import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';
import '../product_search_results_page.dart';
import 'section_shell.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

/// banner_peek_scroll_v1
///
/// Single-row horizontal scroll where the first card takes ~75% of screen
/// width and the next card peeks at ~25%, hinting at scrollability.
/// Image-only — no title, price, or description rendered.
/// Card height matches product_highlight_v1 (childAspectRatio 0.55 → ~4:5).
class BannerPeekScrollWidget extends StatefulWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;

  const BannerPeekScrollWidget({
    super.key,
    required this.section,
    this.onNavigate,
  });

  @override
  State<BannerPeekScrollWidget> createState() => _BannerPeekScrollWidgetState();
}

class _BannerPeekScrollWidgetState extends State<BannerPeekScrollWidget> {
  late final PageController _pageController;
  int _currentPage = 0;

  // Config read from backend JSONB — falls back to sensible defaults.
  double get _firstCardWidthPct =>
      (widget.section.config['firstCardWidthPercent'] as num?)?.toDouble() ??
      75.0;

  double get _cardSpacing =>
      (widget.section.config['cardSpacing'] as num?)?.toDouble() ?? 6.0;

  static const double _cardAspectRatio = 0.55;

  List<SectionItemV2> get _items => widget.section.cappedItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _firstCardWidthPct / 100,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTap(SectionItemV2 item) {
    final fp = item.filterPayload;
    if (fp != null) {
      final rawKeyword = fp['keyword'] as String? ?? '';
      final keyword =
          Uri.decodeQueryComponent(rawKeyword.replaceAll('+', ' '));
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductSearchResultsPage(
          query: keyword,
          filterPayload: fp,
        ),
      ));
      return;
    }

    // Fallback: tapAction routing (same pattern as BannerWidget)
    final ta = item.tapAction;
    if (ta == null) return;
    switch (ta.kind) {
      case 'PRODUCT':
        widget.onNavigate?.call('/productDetail/${ta.value}', {});
      case 'CATEGORY':
        widget.onNavigate?.call('/category/${ta.value}', {});
      case 'SEARCH':
        widget.onNavigate?.call('/search', {'q': ta.value});
      default:
        widget.onNavigate?.call(ta.value, {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * (_firstCardWidthPct / 100);
    final cardHeight = (cardWidth / _cardAspectRatio) * 0.75 * 0.9 * 0.8;

    return SectionShell(
      section: widget.section,
      child: Column(
        children: [
          SizedBox(
            height: cardHeight,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, index) {
                final item = _items[index];
                final isActive = index == _currentPage;
                return _PeekCard(
                  item: item,
                  spacing: _cardSpacing,
                  isFirst: index == 0,
                  isActive: isActive,
                  onTap: () => _handleTap(item),
                );
              },
            ),
          ),
          if (_items.length > 1) ...[
            const SizedBox(height: 8),
            _DotIndicator(count: _items.length, current: _currentPage),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Single card ───────────────────────────────────────────────────────────────

class _PeekCard extends StatelessWidget {
  final SectionItemV2 item;
  final double spacing;
  final bool isFirst;
  final bool isActive;
  final VoidCallback onTap;

  const _PeekCard({
    required this.item,
    required this.spacing,
    required this.isFirst,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.bannerImageUrl?.isNotEmpty == true)
        ? item.bannerImageUrl!
        : (item.imageUrl ?? '');

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: isFirst ? 0 : spacing / 2,
        right: spacing / 2,
        top: isActive ? 0 : 10,
        bottom: isActive ? 0 : 10,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background fills card edges
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Container(color: Colors.black.withOpacity(0.35)),
                      // Full image, no cropping
                      Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _Placeholder(),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: AppColors.surface2,
                                child: const Center(child: AppSpinner()),
                              ),
                      ),
                    ],
                  )
                : _Placeholder(),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface2,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.grey,
          size: 40,
        ),
      );
}

// ── Dot indicator ─────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.white : AppColors.grey,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
