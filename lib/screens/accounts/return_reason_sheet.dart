import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../provider/return_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';

// Reason option definition
class _ReasonOption {
  final String value;
  final String label;
  final IconData icon;
  const _ReasonOption(this.value, this.label, this.icon);
}

const _reasons = [
  _ReasonOption('DEFECTIVE', 'Defective / Not Working', Icons.build_circle_outlined),
  _ReasonOption('WRONG_ITEM', 'Wrong Item Received', Icons.swap_horiz_rounded),
  _ReasonOption('CHANGED_MIND', 'Changed My Mind', Icons.undo_rounded),
  _ReasonOption('SIZE_ISSUE', 'Size / Fit Issue', Icons.straighten_outlined),
  _ReasonOption('DAMAGED_IN_TRANSIT', 'Damaged in Transit', Icons.warning_amber_rounded),
  _ReasonOption('NOT_AS_DESCRIBED', 'Not as Described', Icons.description_outlined),
  _ReasonOption('MISSING_PARTS', 'Missing Parts', Icons.inventory_2_outlined),
  _ReasonOption('OTHER', 'Other', Icons.help_outline_rounded),
];

class ReturnReasonSheet extends ConsumerStatefulWidget {
  final String bookingId;
  const ReturnReasonSheet({super.key, required this.bookingId});

  @override
  ConsumerState<ReturnReasonSheet> createState() => _ReturnReasonSheetState();
}

class _ReturnReasonSheetState extends ConsumerState<ReturnReasonSheet> {
  String? _selectedReason;
  final _descController = TextEditingController();
  final List<String> _imagePaths = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 5) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      setState(() => _imagePaths.add(file.path));
    }
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a return reason.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final success = await ref.read(returnProvider.notifier).submitReturn(
          bookingId: widget.bookingId,
          reason: _selectedReason!,
          description: _descController.text.trim(),
          imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Return request submitted.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1A3A1A),
      ));
    } else {
      final error = ref.read(returnProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Submission failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(returnProvider).isSubmitting;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Why are you returning this?',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a reason to help us process your return faster.',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Reason grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final selected = _selectedReason == r.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReason = r.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.white.withOpacity(0.08)
                          : AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.white : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(r.icon,
                            size: 15,
                            color: selected
                                ? AppColors.white
                                : AppColors.grey),
                        const SizedBox(width: 6),
                        Text(
                          r.label,
                          style: TextStyle(
                            color:
                                selected ? AppColors.white : AppColors.grey,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Description
            const Text('Additional Details (optional)',
                style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle:
                    const TextStyle(color: AppColors.greyDark, fontSize: 14),
                filled: true,
                fillColor: AppColors.bg,
                counterStyle:
                    const TextStyle(color: AppColors.greyDark, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Photo evidence
            Row(
              children: [
                const Text('Evidence Photos (optional)',
                    style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const Spacer(),
                Text('${_imagePaths.length}/5',
                    style: const TextStyle(
                        color: AppColors.greyDark, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  if (_imagePaths.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.grey, size: 22),
                            SizedBox(height: 3),
                            Text('Add',
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  // Picked images
                  ..._imagePaths.asMap().entries.map((e) => Stack(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                              image: DecorationImage(
                                image: FileImage(File(e.value)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _imagePaths.removeAt(e.key)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.bg,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const AppSpinner(size: 20, color: AppColors.bg)
                    : const Text('Submit Return Request',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
