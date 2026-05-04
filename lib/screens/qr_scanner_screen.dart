import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _torchOn = false;
  bool _processed = false;
  MobileScannerException? _cameraError;

  late AnimationController _lineCtrl;
  late Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  // ── Retry camera after error / permission grant ───────────────────────────

  void _retry() {
    _scanner.dispose();
    setState(() {
      _cameraError = null;
      _processed = false;
      _torchOn = false;
      _scanner = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      );
    });
  }

  // ── QR detection ─────────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .where((v) => v != null && v.isNotEmpty)
        .firstOrNull;
    if (raw == null) return;

    final shopId = _extractShopId(raw);
    if (shopId == null) {
      _showSnack('QR code not recognized as a shop link.');
      return;
    }

    _processed = true;
    _scanner.stop();

    Navigator.of(context).pop();
    Navigator.of(context).pushNamed('/shop/$shopId');
  }

  // Handles full URLs and app-relative paths
  String? _extractShopId(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final segs = uri.pathSegments;
    for (int i = 0; i < segs.length - 1; i++) {
      if (segs[i] == 'shop' && segs[i + 1].isNotEmpty) return segs[i + 1];
    }
    return null;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _processed = false);
    });
  }

  void _toggleTorch() {
    _scanner.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  // ── Error message helper ──────────────────────────────────────────────────

  String _errorMessage(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied.\nGo to Settings → App → Camera and allow access.';
      case MobileScannerErrorCode.unsupported:
        return 'QR scanning is not supported on this device.';
      default:
        return 'Could not start the camera.\nTap "Try again" to retry.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutout = (size.width * 0.72).clamp(220.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera feed (or error state) ──────────────────────────────────────
          MobileScanner(
            key: ValueKey(_scanner.hashCode),
            controller: _scanner,
            onDetect: _onDetect,
            errorBuilder: (context, error, _) {
              // Store and show the error overlay
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _cameraError == null) {
                  setState(() => _cameraError = error);
                }
              });
              return const SizedBox.expand(
                child: ColoredBox(color: Colors.black),
              );
            },
          ),

          // ── Camera error overlay ──────────────────────────────────────────────
          if (_cameraError != null)
            _CameraErrorOverlay(
              message: _errorMessage(_cameraError!),
              onRetry: _retry,
              onClose: () => Navigator.of(context).pop(),
            )
          else ...[
            // ── Dark overlay with cutout ────────────────────────────────────────
            CustomPaint(
              painter: _OverlayPainter(cutoutSize: cutout),
            ),

            // ── Animated scan line ──────────────────────────────────────────────
            Center(
              child: SizedBox(
                width: cutout,
                height: cutout,
                child: AnimatedBuilder(
                  animation: _lineAnim,
                  builder: (_, __) => Align(
                    alignment: Alignment(0, _lineAnim.value * 2 - 1),
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFFFF5200).withOpacity(0.9),
                          const Color(0xFFFF5200),
                          const Color(0xFFFF5200).withOpacity(0.9),
                          Colors.transparent,
                        ]),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Corner brackets ─────────────────────────────────────────────────
            Center(
              child: CustomPaint(
                size: Size(cutout, cutout),
                painter: const _CornerPainter(),
              ),
            ),

            // ── Hint label ──────────────────────────────────────────────────────
            Align(
              alignment: const Alignment(0, 0.62),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point at a shop QR code to open its page',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],

          // ── Top bar (always shown) ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: CupertinoIcons.xmark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Scan Shop QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  _CircleButton(
                    icon: _torchOn
                        ? CupertinoIcons.bolt_fill
                        : CupertinoIcons.bolt,
                    onTap: _cameraError == null ? _toggleTorch : () {},
                    active: _torchOn,
                    disabled: _cameraError != null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Camera error overlay ──────────────────────────────────────────────────────

class _CameraErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _CameraErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              CupertinoIcons.camera_fill,
              color: Colors.white54,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Camera Access Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Go back',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay painter ───────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final double cutoutSize;
  const _OverlayPainter({required this.cutoutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final center = Offset(size.width / 2, size.height / 2);
    final cutout = Rect.fromCenter(
        center: center, width: cutoutSize, height: cutoutSize);
    final full = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(16)));
    canvas.drawPath(
        Path.combine(PathOperation.difference, full, hole), paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.cutoutSize != cutoutSize;
}

// ── Corner brackets ───────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFFF5200);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const radius = 12.0;
    const arm = 26.0;

    final corners = [
      (Offset.zero, 1.0, 1.0, false),
      (Offset(size.width, 0), -1.0, 1.0, true),
      (Offset(size.width, size.height), -1.0, -1.0, false),
      (Offset(0, size.height), 1.0, -1.0, true),
    ];

    for (final (c, xd, yd, cw) in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + xd * arm, c.dy)
          ..lineTo(c.dx + xd * radius, c.dy)
          ..arcToPoint(
            Offset(c.dx, c.dy + yd * radius),
            radius: const Radius.circular(radius),
            clockwise: cw,
          )
          ..lineTo(c.dx, c.dy + yd * arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter _) => false;
}

// ── Circle icon button ────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool disabled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFF5200).withOpacity(0.25)
              : Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? const Color(0xFFFF5200)
                : Colors.white.withOpacity(disabled ? 0.08 : 0.18),
          ),
        ),
        child: Icon(
          icon,
          color: disabled
              ? Colors.white24
              : active
                  ? const Color(0xFFFF5200)
                  : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
