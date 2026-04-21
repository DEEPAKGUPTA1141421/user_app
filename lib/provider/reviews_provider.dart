import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

class ReviewState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<dynamic> reviews;
  final int totalElements;
  final bool hasMore;
  final int page;
  final String sortBy;
  final bool isSubmitting;
  final String? submitError;
  final String? submitSuccess;

  const ReviewState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.reviews = const [],
    this.totalElements = 0,
    this.hasMore = false,
    this.page = 0,
    this.sortBy = 'newest',
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess,
  });

  ReviewState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<dynamic>? reviews,
    int? totalElements,
    bool? hasMore,
    int? page,
    String? sortBy,
    bool? isSubmitting,
    String? submitError,
    String? submitSuccess,
  }) =>
      ReviewState(
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        reviews: reviews ?? this.reviews,
        totalElements: totalElements ?? this.totalElements,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        sortBy: sortBy ?? this.sortBy,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submitError: submitError,
        submitSuccess: submitSuccess,
      );
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final String productId;
  ReviewNotifier(this.productId) : super(const ReviewState());

  Dio get _client => ApiClient.instance.productClient;

  Future<void> fetchReviews({String? sort}) async {
    final sortBy = sort ?? state.sortBy;
    state = state.copyWith(isLoading: true, error: null, sortBy: sortBy, page: 0);
    try {
      final res = await _client.get(
        ApiEndpoints.reviews(productId),
        queryParameters: {'page': 0, 'size': 10, 'sort': sortBy},
      );
      final data =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        reviews: (data['reviews'] as List?) ?? [],
        totalElements: (data['totalElements'] as int?) ?? 0,
        hasMore: (data['hasMore'] as bool?) ?? false,
        page: 0,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _client.get(
        ApiEndpoints.reviews(productId),
        queryParameters: {
          'page': nextPage,
          'size': 10,
          'sort': state.sortBy,
        },
      );
      final data =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoadingMore: false,
        reviews: [
          ...state.reviews,
          ...((data['reviews'] as List?) ?? []),
        ],
        hasMore: (data['hasMore'] as bool?) ?? false,
        page: nextPage,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> toggleHelpful(String reviewId) async {
    try {
      final res = await _client.post(ApiEndpoints.reviewHelpful(reviewId));
      final action =
          (res.data as Map<String, dynamic>)['data']?['action'] as String?;
      final updated = state.reviews.map((r) {
        final review = Map<String, dynamic>.from(r as Map);
        if (review['id'] == reviewId) {
          final current = (review['helpfulCount'] as int?) ?? 0;
          return {
            ...review,
            'helpfulCount': action == 'ADDED'
                ? current + 1
                : (current - 1).clamp(0, current),
          };
        }
        return review;
      }).toList();
      state = state.copyWith(reviews: updated);
    } catch (_) {}
  }

  // Returns the success message from the API, or null on failure.
  Future<String?> submitReview({
    required int rating,
    String? title,
    String? review,
    List<XFile>? images,
  }) async {
    state = state.copyWith(
        isSubmitting: true, submitError: null, submitSuccess: null);
    try {
      final imageFiles = images != null && images.isNotEmpty
          ? await Future.wait(
              images.map((f) async {
                final bytes = await f.readAsBytes();
                final name = f.name.isNotEmpty
                    ? f.name
                    : f.path.split('/').last;
                return MultipartFile.fromBytes(bytes, filename: name);
              }),
            )
          : <MultipartFile>[];

      final formData = FormData.fromMap({
        'rating': rating.toString(),
        if (title != null && title.isNotEmpty) 'title': title,
        if (review != null && review.isNotEmpty) 'review': review,
        if (imageFiles.isNotEmpty) 'images': imageFiles,
      });
      final res = await _client.post(
        ApiEndpoints.reviews(productId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final apiMessage = (res.data as Map<String, dynamic>?)?['message']
              as String? ??
          'Review submitted successfully';
      state = state.copyWith(
          isSubmitting: false, submitSuccess: apiMessage);
      await fetchReviews();
      return apiMessage;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isSubmitting: false, submitError: msg);
      return null;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
      return null;
    }
  }
}

final reviewPod =
    StateNotifierProvider.family<ReviewNotifier, ReviewState, String>(
  (ref, productId) => ReviewNotifier(productId),
);
