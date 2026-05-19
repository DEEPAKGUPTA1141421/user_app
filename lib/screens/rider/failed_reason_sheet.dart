import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Bottom sheet for selecting a failure reason when a delivery cannot be completed.
/// Returns the selected reason string on confirm, null on dismiss.
class FailedReasonSheet extends StatefulWidget {
  final String address;
  final int stopNumber;

  const FailedReasonSheet({
    super.key,
    required this.address,
    required this.stopNumber,
  });

  static Future<String?> show(
    BuildContext context, {
    required String address,
    required int stopNumber,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FailedReasonSheet(address: address, stopNumber: stopNumber),
      );

  @override
  State<FailedReasonSheet> createState() => _FailedReasonSheetState();
}

class _FailedReasonSheetState extends State<FailedReasonSheet> {
  static const _presets = [
    'Customer not available',
    'Wrong address',
    'Customer refused delivery',
    'Access denied / gated area',
    'Other',
  ];

  String? _selected;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == null) return;
    final reason =
        _selected == 'Other' ? _otherCtrl.text.trim() : _selected!;
    if (reason.isEmpty) return;
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ──────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stop #${widget.stopNumber} — Report Failed',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(widget.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12)),
              ]),
            ),
          ]),

          const SizedBox(height: 20),
          const Text('SELECT REASON',
              style: TextStyle(color: AppColors.grey, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          // ── Reason options ───────────────────────────────────────────────
          ..._presets.map((reason) => _ReasonTile(
                label: reason,
                selected: _selected == reason,
                onTap: () => setState(() => _selected = reason),
              )),

          // ── Free-text for "Other" ────────────────────────────────────────
          if (_selected == 'Other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Describe the issue…',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: AppColors.surface2,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Submit button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected != null ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surface2,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Report',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? Colors.redAccent.withOpacity(0.08)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.redAccent : AppColors.border,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.redAccent : AppColors.white,
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400)),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                color: Colors.redAccent, size: 18),
        ]),
      ),
    );
  }
}
