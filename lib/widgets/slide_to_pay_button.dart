import 'package:flutter/material.dart';

/// Swiggy-style "slide the card to pay" button.
///
/// Use [SlideToPayButtonState.reset] via a [GlobalKey] to snap the thumb
/// back to the start (e.g. when the user cancels payment or an order fails).
class SlideToPayButton extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool enabled;
  final bool loading;
  final String text;
  final double width;
  final double height;

  const SlideToPayButton({
    super.key,
    required this.onConfirm,
    this.enabled = true,
    this.loading = false,
    this.text = 'Pay',
    this.width = 220,
    this.height = 52,
  });

  @override
  State<SlideToPayButton> createState() => SlideToPayButtonState();
}

class SlideToPayButtonState extends State<SlideToPayButton>
    with TickerProviderStateMixin {
  late final AnimationController _snapController;
  late final AnimationController _shimmerController;
  double _dragX = 0;
  bool _locked = false; // thumb reached the end, awaiting parent action

  double get _thumbSize => widget.height - 8;
  double get _maxDrag => widget.width - _thumbSize - 8;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        setState(() => _dragX = _snapController.value * _maxDrag);
      });
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _snapController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// Snaps the thumb back to the start. Call this from the parent when the
  /// action tied to [onConfirm] is cancelled or fails.
  void reset() {
    if (!mounted) return;
    setState(() => _locked = false);
    _snapController.value = _dragX == 0 ? 0 : (_dragX / _maxDrag);
    _snapController.animateBack(0);
  }

  bool get _interactive =>
      widget.enabled && !widget.loading && !_locked;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_interactive) return;
    setState(() {
      _dragX = (_dragX + details.delta.dx).clamp(0.0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_interactive) return;
    if (_dragX >= _maxDrag * 0.7) {
      setState(() {
        _dragX = _maxDrag;
        _locked = true;
      });
      widget.onConfirm();
    } else {
      _snapController.value = _maxDrag == 0 ? 0 : _dragX / _maxDrag;
      _snapController.animateBack(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _maxDrag <= 0 ? 0.0 : (_dragX / _maxDrag).clamp(0.0, 1.0);
    final disabled = !widget.enabled;
    final busy = widget.loading || _locked;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(widget.height / 2),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // progress fill behind the thumb
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              width: (_dragX + _thumbSize + 8).clamp(_thumbSize + 8, widget.width),
              height: widget.height,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20)
                    .withOpacity(0.12 + 0.16 * progress),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),

            // shimmering label + chevrons
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (1 - progress * 1.4).clamp(0.0, 1.0),
                  child: Padding(
                    padding: EdgeInsets.only(left: _thumbSize * 0.6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(2, (i) {
                                // Staggered pulse per chevron for a "flowing" hint.
                                final phase =
                                    (_shimmerController.value + i * 0.3) % 1.0;
                                final opacity =
                                    0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2);
                                return Opacity(
                                  opacity: opacity.clamp(0.35, 1.0),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xFF1B5E20),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // draggable thumb (payment card)
            Positioned(
              left: 4 + _dragX,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF1B5E20),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded,
                          color: Color(0xFF1B5E20), size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
