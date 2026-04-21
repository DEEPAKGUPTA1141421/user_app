import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../provider/reviews_provider.dart';
import '../../provider/rider_provider.dart';
import '../../utils/app_colors.dart';
import 'ratings_summary.dart';

class BestReview extends ConsumerStatefulWidget {
  final String productId;
  final Map<String, dynamic> ratingSummary;

  const BestReview({
    super.key,
    required this.productId,
    required this.ratingSummary,
  });

  @override
  ConsumerState<BestReview> createState() => _BestReviewState();
}

class _BestReviewState extends ConsumerState<BestReview>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    Future.microtask(() {
      ref.read(reviewPod(widget.productId).notifier).fetchReviews();
      _barCtrl.forward();
    });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.ratingSummary;
    final avg = (rs['averageRating'] as num?)?.toDouble() ?? 0.0;
    final total = (rs['totalRatings'] as num?)?.toInt() ?? 0;
    final dist = rs['distribution'] as Map<String, dynamic>? ?? {};

    final reviewState = ref.watch(reviewPod(widget.productId));
    final topReview = reviewState.reviews.isNotEmpty
        ? reviewState.reviews.first as Map<String, dynamic>
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ratings & Reviews',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RatingsSummary(productId: widget.productId),
                  ),
                ),
                child: const Text('See All',
                    style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (total == 0)
            _NoRatingsYet(productId: widget.productId)
          else ...[
            // ── Average Rating + Histogram ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big rating number
                Column(
                  children: [
                    Text(avg.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2)),
                    const SizedBox(height: 4),
                    _StarRow(rating: avg, size: 14),
                    const SizedBox(height: 4),
                    Text('${_fmtK(total)} ratings',
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 11)),
                  ],
                ),

                const SizedBox(width: 20),

                // Distribution bars
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count =
                          (dist[star.toString()] as num?)?.toInt() ?? 0;
                      final fraction =
                          total > 0 ? count / total : 0.0;
                      return _AnimatedBar(
                        star: star,
                        fraction: fraction,
                        animation: _barCtrl,
                        color: _barColor(star),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),

            // ── Top Review ─────────────────────────────────────────────
            if (topReview != null) _ReviewCard(review: topReview, productId: widget.productId),

            const SizedBox(height: 12),

            // ── Write a Review CTA ──────────────────────────────────────
            GestureDetector(
              onTap: () => _showWriteReviewSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text('Write a Review',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _barColor(int star) {
    if (star >= 4) return AppColors.green;
    if (star == 3) return Colors.orange;
    return Colors.redAccent;
  }

  Future<void> _showWriteReviewSheet(
    BuildContext context, {
    int initialRating = 0,
    String initialTitle = '',
    String initialReview = '',
  }) =>
      showReviewSheet(
        context,
        productId: widget.productId,
        initialRating: initialRating,
        initialTitle: initialTitle,
        initialReview: initialReview,
      );

  String _fmtK(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ─── Animated bar row ──────────────────────────────────────────────────────────
class _AnimatedBar extends StatelessWidget {
  final int star;
  final double fraction;
  final Animation<double> animation;
  final Color color;

  const _AnimatedBar({
    required this.star,
    required this.fraction,
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$star',
              style: const TextStyle(color: AppColors.grey, fontSize: 11)),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, color: AppColors.grey, size: 11),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction *
                        Curves.easeOut.transform(animation.value),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text('${(fraction * 100).round()}%',
                textAlign: TextAlign.end,
                style:
                    const TextStyle(color: AppColors.grey, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ─── Star row ──────────────────────────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (i < rating);
        return Icon(
          half ? Icons.star_half_rounded : Icons.star_rounded,
          color: filled || half ? AppColors.green : AppColors.surface2,
          size: size,
        );
      }),
    );
  }
}

// ─── Review card (top review) ──────────────────────────────────────────────────
class _ReviewCard extends ConsumerWidget {
  final Map<String, dynamic> review;
  final String productId;
  const _ReviewCard({required this.review, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] as String? ?? 'Anonymous';
    final userImg = user['image'] as String?;
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final title = review['title'] as String? ?? '';
    final text = review['review'] as String? ?? '';
    final verified = review['verifiedPurchase'] as bool? ?? false;
    final helpful = (review['helpfulCount'] as num?)?.toInt() ?? 0;
    final reviewId = review['id'] as String? ?? '';
    final createdAt = review['createdAt'] as String? ?? '';
    final ago = _timeAgo(createdAt);

    final currentUserId =
        (ref.watch(riderPod).user['id'] ?? '').toString();
    final isOwn = currentUserId.isNotEmpty && user['id'] == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author row
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface2,
              backgroundImage:
                  userImg != null ? NetworkImage(userImg) : null,
              child: userImg == null
                  ? Text(name[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  if (verified)
                    const Text('Verified Purchase',
                        style: TextStyle(
                            color: AppColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (isOwn)
              GestureDetector(
                onTap: () => _openEdit(context, ref, rating, title, text),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: AppColors.grey, size: 12),
                      SizedBox(width: 4),
                      Text('Edit',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else
              Text(ago,
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11)),
          ],
        ),
        if (isOwn) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(ago,
                style:
                    const TextStyle(color: AppColors.grey, fontSize: 11)),
          ),
        ],
        const SizedBox(height: 10),

        // Stars + title
        Row(children: [
          ...List.generate(
              5,
              (i) => Icon(Icons.star_rounded,
                  color: i < rating ? AppColors.green : AppColors.surface2,
                  size: 13)),
          if (title.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.grey, fontSize: 12, height: 1.5)),
        ],
        const SizedBox(height: 10),

        // Helpful
        GestureDetector(
          onTap: () =>
              ref.read(reviewPod(productId).notifier).toggleHelpful(reviewId),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.thumb_up_outlined,
                  color: AppColors.grey, size: 13),
              const SizedBox(width: 5),
              Text('Helpful ($helpful)',
                  style:
                      const TextStyle(color: AppColors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref,
          int rating, String title, String text) =>
      showReviewSheet(
        context,
        productId: productId,
        initialRating: rating,
        initialTitle: title,
        initialReview: text,
      );

  String _timeAgo(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}

// ─── Public helper — open review sheet and show SnackBar with result ──────────
Future<void> showReviewSheet(
  BuildContext context, {
  required String productId,
  int initialRating = 0,
  String initialTitle = '',
  String initialReview = '',
}) async {
  final msg = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _WriteReviewSheet(
      productId: productId,
      initialRating: initialRating,
      initialTitle: initialTitle,
      initialReview: initialReview,
    ),
  );
  if (msg != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.white, fontSize: 13)),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── No ratings yet placeholder ────────────────────────────────────────────────
class _NoRatingsYet extends StatelessWidget {
  final String productId;
  const _NoRatingsYet({required this.productId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.star_border_rounded,
            color: AppColors.greyDark, size: 40),
        const SizedBox(height: 8),
        const Text('No ratings yet',
            style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text('Be the first to review this product',
            style: TextStyle(color: AppColors.greyDark, fontSize: 12)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => showReviewSheet(context, productId: productId),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('Write a Review',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Write Review Bottom Sheet ─────────────────────────────────────────────────
class _WriteReviewSheet extends ConsumerStatefulWidget {
  final String productId;
  final int initialRating;
  final String initialTitle;
  final String initialReview;

  const _WriteReviewSheet({
    required this.productId,
    this.initialRating = 0,
    this.initialTitle = '',
    this.initialReview = '',
  });

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  static const int _maxImages = 5;

  late int _rating;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _reviewCtrl;
  final List<XFile> _images = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _reviewCtrl = TextEditingController(text: widget.initialReview);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= _maxImages) return;
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _images.add(picked));
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.white),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: AppColors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.white),
                title: const Text('Take a Photo',
                    style: TextStyle(color: AppColors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewPod(widget.productId));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            widget.initialRating > 0 ? 'Edit Your Review' : 'Write a Review',
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // ── Star selector ────────────────────────────────────────────
          const Text('Your Rating',
              style: TextStyle(color: AppColors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: i < _rating ? AppColors.green : AppColors.grey,
                    size: 34,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── Title ────────────────────────────────────────────────────
          _DarkTextField(
              controller: _titleCtrl,
              hint: 'Title (optional)',
              maxLines: 1),
          const SizedBox(height: 10),

          // ── Review body ──────────────────────────────────────────────
          _DarkTextField(
              controller: _reviewCtrl,
              hint: 'Your review (optional)',
              maxLines: 4),
          const SizedBox(height: 14),

          // ── Photo section ────────────────────────────────────────────
          Row(
            children: [
              const Text('Photos',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
              const SizedBox(width: 6),
              Text('(${_images.length}/$_maxImages)',
                  style: const TextStyle(
                      color: AppColors.greyDark, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add button (visible while under limit)
                if (_images.length < _maxImages)
                  GestureDetector(
                    onTap: _showPickerOptions,
                    child: Container(
                      width: 72,
                      height: 72,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
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
                          SizedBox(height: 4),
                          Text('Add',
                              style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),

                // Selected image previews
                ..._images.asMap().entries.map((e) {
                  final idx = e.key;
                  final file = e.value;
                  return Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (_, snap) => snap.hasData
                                ? Image.memory(snap.data!,
                                    fit: BoxFit.cover)
                                : const ColoredBox(
                                    color: AppColors.surface2),
                          ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(idx)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: AppColors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Submit ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: state.isSubmitting || _rating == 0
                  ? null
                  : () async {
                      final msg = await ref
                          .read(reviewPod(widget.productId).notifier)
                          .submitReview(
                            rating: _rating,
                            title: _titleCtrl.text.trim(),
                            review: _reviewCtrl.text.trim(),
                            images: _images.isEmpty ? null : _images,
                          );
                      if (msg != null && context.mounted) {
                        Navigator.pop(context, msg);
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:
                      _rating == 0 ? AppColors.surface2 : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bg))
                      : Text(
                          'Submit Review',
                          style: TextStyle(
                            color: _rating == 0
                                ? AppColors.greyDark
                                : AppColors.bg,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (state.submitError != null) ...[
            const SizedBox(height: 8),
            Text(state.submitError!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _DarkTextField(
      {required this.controller,
      required this.hint,
      required this.maxLines});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.grey, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: AppColors.grey),
        ),
      ),
    );
  }
}
