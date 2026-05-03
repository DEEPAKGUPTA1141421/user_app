import 'dart:io';
import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';
import '../product_search_results_page.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);

class BannerWidget extends StatefulWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;
  const BannerWidget({super.key, required this.section, this.onNavigate});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget>
    with SingleTickerProviderStateMixin {
  late final PageController _page;
  late final AnimationController _prog;
  int _current = 0;

  List<SectionItemV2> get _items => widget.section.cappedItems;
  Duration get _holdDuration =>
      Duration(milliseconds: widget.section.loopMs);
  static const Duration _pageDuration = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _prog = AnimationController(vsync: this, duration: _holdDuration);
    if (_items.length > 1 && widget.section.autoplay) {
      _prog.addStatusListener((s) {
        if (s == AnimationStatus.completed) _advance();
      });
      _prog.forward();
    }
    _fireImpressionPixels();
  }

  void _fireImpressionPixels() {
    for (final item in _items) {
      final url = item.impressionPixel;
      if (url != null && url.isNotEmpty) {
        _firePixel(url);
      }
    }
  }

  static void _firePixel(String url) {
    HttpClient()
        .getUrl(Uri.parse(url))
        .then((req) => req.close())
        .ignore();
  }

  void _advance() {
    if (!mounted || _items.length <= 1) return;
    _page.animateToPage(
      (_current + 1) % _items.length,
      duration: _pageDuration,
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    _prog.forward(from: 0);
  }

  @override
  void dispose() {
    _prog.dispose();
    _page.dispose();
    super.dispose();
  }

  void _handleTap(SectionItemV2 item) {
    final clickUrl = item.clickPixel;
    if (clickUrl != null && clickUrl.isNotEmpty) {
      _firePixel(clickUrl);
    }

    // filterPayload takes priority — navigate to product results page
    final fp = item.filterPayload;
    if (fp != null) {
      final rawKeyword = fp['keyword'] as String? ?? '';
      final keyword = Uri.decodeQueryComponent(rawKeyword.replaceAll('+', ' '));
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductSearchResultsPage(
          query: keyword,
          filterPayload: fp,
        ),
      ));
      return;
    }

    // Fallback: tapAction routing
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
    final screenW = MediaQuery.of(context).size.width;
    final height = widget.section.bannerHeight > 0
        ? widget.section.bannerHeight
        : (screenW * 0.44).clamp(155.0, 210.0);

    // Each segment ~20dp wide + 4dp gap; total capped at 45% screen width
    final barTotalWidth = (_items.length * 20.0 + (_items.length - 1) * 4.0)
        .clamp(0.0, screenW * 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _page,
              itemCount: _items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) => _BannerSlide(
                item: _items[i],
                onTap: () => _handleTap(_items[i]),
              ),
            ),
            if (_items.length > 1) ...[
              // Dark gradient at bottom for bar visibility
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                      ],
                    ),
                  ),
                ),
              ),
              // Progress bars centered inside banner
              Positioned(
                bottom: 9,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: barTotalWidth,
                    child: Row(
                      children: List.generate(_items.length, (i) {
                        final isActive = i == _current;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: i == 0 ? 0 : 4,
                                right: i == _items.length - 1 ? 0 : 4),
                            child: _ProgressBar(
                              isActive: isActive,
                              isPast: i < _current,
                              progress: isActive ? _prog : null,
                            ),
                          ),
                        );
                      }),
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

class _BannerSlide extends StatelessWidget {
  final SectionItemV2 item;
  final VoidCallback onTap;
  const _BannerSlide({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Prefer banner-specific imageUrl from metadata; fall back to generic imageUrl
    final imageUrl = (item.bannerImageUrl?.isNotEmpty == true)
        ? item.bannerImageUrl!
        : (item.imageUrl ?? '');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
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
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    final displayTitle = item.bannerAltText ?? item.title ?? '';
    final displaySub = item.subtitle ?? '';
    return Container(
      color: AppColors.surface2,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayTitle.isNotEmpty)
            Text(displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
          if (displaySub.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(displaySub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.grey)),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final bool isActive;
  final bool isPast;
  final AnimationController? progress;
  const _ProgressBar(
      {required this.isActive, required this.isPast, this.progress});

  @override
  Widget build(BuildContext context) {
    const h = 2.0;
    const radius = BorderRadius.all(Radius.circular(1));
    final track = Colors.white.withOpacity(0.35);
    const fill = Colors.white;

    if (isPast) {
      return Container(
          height: h,
          decoration: const BoxDecoration(color: fill, borderRadius: radius));
    }
    if (!isActive) {
      return Container(
          height: h,
          decoration: BoxDecoration(color: track, borderRadius: radius));
    }
    return AnimatedBuilder(
      animation: progress!,
      builder: (_, __) => Stack(
        children: [
          Container(
              height: h,
              decoration: BoxDecoration(color: track, borderRadius: radius)),
          FractionallySizedBox(
            widthFactor: progress!.value,
            child: Container(
                height: h,
                decoration:
                    const BoxDecoration(color: fill, borderRadius: radius)),
          ),
        ],
      ),
    );
  }
}
