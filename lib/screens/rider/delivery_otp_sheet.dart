import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';

/// Bottom sheet that collects a 4-digit confirmation OTP before marking
/// a stop as DELIVERED. Returns the entered OTP string on success.
class DeliveryOtpSheet extends StatefulWidget {
  final String address;
  final int stopNumber;

  const DeliveryOtpSheet({
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
        builder: (_) => DeliveryOtpSheet(address: address, stopNumber: stopNumber),
      );

  @override
  State<DeliveryOtpSheet> createState() => _DeliveryOtpSheetState();
}

class _DeliveryOtpSheetState extends State<DeliveryOtpSheet> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes  = List.generate(4, (_) => FocusNode());
  bool _hasError = false;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigit(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() => _hasError = false);
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _confirm() {
    if (_otp.length < 4) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.pop(context, _otp);
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
                color: Colors.greenAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.greenAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stop #${widget.stopNumber} — Confirm Delivery',
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

          const SizedBox(height: 24),
          const Text('Enter customer OTP',
              style: TextStyle(color: AppColors.grey, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 12),

          // ── OTP boxes ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                width: 58, height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasError
                        ? Colors.redAccent
                        : _focusNodes[i].hasFocus
                            ? Colors.greenAccent
                            : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 22,
                      fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (v) => _onDigit(i, v),
                  onTap: () => setState(() {}),
                ),
              );
            }),
          ),

          if (_hasError) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text('Please enter all 4 digits',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ],

          const SizedBox(height: 28),

          // ── Confirm button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Delivery',
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
