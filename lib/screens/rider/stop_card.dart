import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/route_stop.dart';
import '../../provider/route_provider.dart';
import '../../utils/app_colors.dart';
import 'delivery_otp_sheet.dart';
import 'failed_reason_sheet.dart';

class StopCard extends ConsumerStatefulWidget {
  final RouteStop stop;

  const StopCard({super.key, required this.stop});

  @override
  ConsumerState<StopCard> createState() => _StopCardState();
}

class _StopCardState extends ConsumerState<StopCard> {
  bool _working = false;

  RouteStop get stop => widget.stop;

  // ── Status presentation ───────────────────────────────────────────────────

  Color get _statusColor => switch (stop.status) {
        'DELIVERED' => Colors.greenAccent,
        'FAILED'    => Colors.redAccent,
        'PICKED'    => Colors.lightBlueAccent,
        _           => Colors.amberAccent,
      };

  String get _statusLabel => switch (stop.status) {
        'DELIVERED' => 'Delivered',
        'FAILED'    => 'Failed',
        'PICKED'    => 'Picked Up',
        _           => 'Pending',
      };

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _navigateToStop() async {
    final uri = Uri.parse(
        'https://maps.google.com/?daddr=${stop.destLat},${stop.destLng}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markPickedUp() async {
    setState(() => _working = true);
    await ref.read(routePod.notifier).updateStatus(stop.assignmentId, 'PICKED');
    if (mounted) setState(() => _working = false);
  }

  Future<void> _confirmDelivery() async {
    final otp = await DeliveryOtpSheet.show(
      context,
      address: stop.destAddress,
      stopNumber: stop.sequenceNumber,
    );
    if (otp == null || !mounted) return;

    setState(() => _working = true);
    await ref.read(routePod.notifier).updateStatus(stop.assignmentId, 'DELIVERED');
    if (mounted) setState(() => _working = false);
  }

  Future<void> _reportFailed() async {
    final reason = await FailedReasonSheet.show(
      context,
      address: stop.destAddress,
      stopNumber: stop.sequenceNumber,
    );
    if (reason == null || !mounted) return;

    setState(() => _working = true);
    await ref
        .read(routePod.notifier)
        .updateStatus(stop.assignmentId, 'FAILED', failureReason: reason);
    if (mounted) setState(() => _working = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: stop.isDone ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stop.isDone ? AppColors.border : _statusColor.withOpacity(0.35),
          ),
        ),
        child: Column(
          children: [
            // ── Header row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sequence badge
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: stop.isDone
                          ? AppColors.surface2
                          : _statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${stop.sequenceNumber}',
                      style: TextStyle(
                        color: stop.isDone ? AppColors.grey : _statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Address + order number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.destAddress,
                          style: TextStyle(
                            color: stop.isDone
                                ? AppColors.grey
                                : AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: stop.status == 'DELIVERED'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stop.orderNo,
                          style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // ── ETA row ─────────────────────────────────────────────────
            if (stop.estimatedArrivalAt != null && stop.isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(children: [
                  const SizedBox(width: 44),
                  const Icon(Icons.schedule_rounded,
                      size: 13, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'ETA ${_formatEta(stop.estimatedArrivalAt!)}',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 11),
                  ),
                ]),
              ),

            // ── Action bar ───────────────────────────────────────────────
            if (stop.isActive) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: _working
                    ? const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.greenAccent),
                        ),
                      )
                    : Row(children: [
                        // Navigate
                        _ActionBtn(
                          icon: Icons.navigation_rounded,
                          label: 'Navigate',
                          color: Colors.lightBlueAccent,
                          onTap: _navigateToStop,
                        ),
                        const SizedBox(width: 8),

                        if (stop.status == 'ASSIGNED') ...[
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.inventory_2_rounded,
                              label: 'Picked Up',
                              color: Colors.amberAccent,
                              filled: true,
                              onTap: _markPickedUp,
                            ),
                          ),
                        ] else ...[
                          // PICKED state — deliver or fail
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.check_circle_rounded,
                              label: 'Deliver',
                              color: Colors.greenAccent,
                              filled: true,
                              onTap: _confirmDelivery,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            icon: Icons.cancel_rounded,
                            label: 'Failed',
                            color: Colors.redAccent,
                            onTap: _reportFailed,
                          ),
                        ],
                      ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatEta(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h  = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m  = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ap';
    } catch (_) {
      return '';
    }
  }
}

// ── Small action button ───────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.15) : AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: filled ? color.withOpacity(0.4) : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
