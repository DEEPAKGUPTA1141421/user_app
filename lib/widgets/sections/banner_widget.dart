import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: PageView.builder(
              controller: _page,
              itemCount: _items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) => _BannerSlide(
                item: _items[i],
                onTap: () => _handleTap(_items[i]),
              ),
            ),
          ),
          if (_items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 14, right: 14),
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
        ],
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
    final imageUrl = item.imageUrl ?? '';
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
    return Container(
      color: AppColors.surface2,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white)),
          if ((item.subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.subtitle!,
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
    const h = 3.0;
    const radius = BorderRadius.all(Radius.circular(2));
    const track = AppColors.greyDark;
    const fill = AppColors.white;

    if (isPast) {
      return Container(
          height: h,
          decoration: const BoxDecoration(color: fill, borderRadius: radius));
    }
    if (!isActive) {
      return Container(
          height: h,
          decoration: const BoxDecoration(color: track, borderRadius: radius));
    }
    return AnimatedBuilder(
      animation: progress!,
      builder: (_, __) => Stack(
        children: [
          Container(
              height: h,
              decoration:
                  const BoxDecoration(color: track, borderRadius: radius)),
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
