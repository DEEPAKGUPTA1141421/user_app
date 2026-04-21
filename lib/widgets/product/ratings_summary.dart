import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/reviews_provider.dart';
import '../../provider/rider_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/real_search_page.dart';
import 'best_review.dart';

class RatingsSummary extends ConsumerStatefulWidget {
  final String productId;
  const RatingsSummary({super.key, required this.productId});

  @override
  ConsumerState<RatingsSummary> createState() => _RatingsSummaryState();
}

class _RatingsSummaryState extends ConsumerState<RatingsSummary>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  final ScrollController _scrollCtrl = ScrollController();

  static const _sortOptions = [
    {'label': 'Most Recent', 'value': 'newest'},
    {'label': 'Most Helpful', 'value': 'helpful'},
    {'label': 'Highest First', 'value': 'highest'},
    {'label': 'Lowest First', 'value': 'lowest'},
  ];

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    Future.microtask(() {
      ref.read(reviewPod(widget.productId).notifier).fetchReviews();
      _barCtrl.forward();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(reviewPod(widget.productId).notifier).fetchMore();
    }
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewPod(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.white, size: 15),
          ),
        ),
        title: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RealSearchPage())),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Icon(CupertinoIcons.search, color: AppColors.grey, size: 15),
                SizedBox(width: 8),
                Text('Search for products',
                    style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.green))
          : state.error != null
              ? _buildError(state.error!)
              : CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryHeader(state),
                            const SizedBox(height: 20),
                            _buildSortTabs(state.sortBy),
                          ],
                        ),
                      ),
                    ),
                    if (state.reviews.isEmpty && !state.isLoading)
                      SliverFillRemaining(child: _buildEmpty())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            if (i == state.reviews.length) {
                              return state.isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.green)),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _ReviewTile(
                              review: Map<String, dynamic>.from(
                                  state.reviews[i] as Map),
                              productId: widget.productId,
                            );
                          },
                          childCount: state.reviews.length + 1,
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildSummaryHeader(ReviewState state) {
    // If no reviews yet, show placeholder
    if (state.totalElements == 0 && !state.isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ratings & Reviews',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          Text('No reviews yet. Be the first!',
              style: TextStyle(color: AppColors.grey, fontSize: 14)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ratings & Reviews',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('${_fmtK(state.totalElements)} ratings',
            style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSortTabs(String current) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sortOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = _sortOptions[i];
          final isSelected = opt['value'] == current;
          return GestureDetector(
            onTap: () => ref
                .read(reviewPod(widget.productId).notifier)
                .fetchReviews(sort: opt['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isSelected ? AppColors.white : AppColors.border),
              ),
              child: Text(opt['label']!,
                  style: TextStyle(
                      color: isSelected ? AppColors.bg : AppColors.grey,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.greyDark, size: 40),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref
                  .read(reviewPod(widget.productId).notifier)
                  .fetchReviews(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined,
              color: AppColors.greyDark, size: 48),
          SizedBox(height: 12),
          Text('No reviews yet',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Be the first to share your thoughts!',
              style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  String _fmtK(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ─── Review tile ───────────────────────────────────────────────────────────────
class _ReviewTile extends ConsumerWidget {
  final Map<String, dynamic> review;
  final String productId;
  const _ReviewTile({required this.review, required this.productId});

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
    final images = review['reviewImages'] as List? ?? [];
    final createdAt = review['createdAt'] as String? ?? '';

    final currentUserId =
        (ref.watch(riderPod).user['id'] ?? '').toString();
    final isOwn = currentUserId.isNotEmpty && user['id'] == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 17,
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
                  onTap: () => showReviewSheet(
                    context,
                    productId: productId,
                    initialRating: rating,
                    initialTitle: title,
                    initialReview: text,
                  ),
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
                Text(_timeAgo(createdAt),
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 11)),
            ],
          ),
          if (isOwn) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(_timeAgo(createdAt),
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11)),
            ),
          ],
          const SizedBox(height: 10),

          // Stars + title
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      color: i < rating
                          ? AppColors.green
                          : AppColors.surface2,
                      size: 14)),
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
            ],
          ),

          // Review text
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.5)),
          ],

          // Review images
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, idx) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[idx].toString(),
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 80,
                      color: AppColors.surface2,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.grey, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Helpful row
          GestureDetector(
            onTap: () => ref
                .read(reviewPod(productId).notifier)
                .toggleHelpful(reviewId),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thumb_up_outlined,
                    color: AppColors.grey, size: 14),
                const SizedBox(width: 6),
                Text('Helpful ($helpful)',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
