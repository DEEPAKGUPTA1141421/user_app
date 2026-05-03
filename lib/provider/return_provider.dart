import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class ReturnItem {
  final String id;
  final String bookingId;
  final String reason;
  final String reasonLabel;
  final String? description;
  final String status;
  final String statusLabel;
  final String? adminNote;
  final List<String> evidenceImages;
  final String? createdAt;
  final String? updatedAt;

  const ReturnItem({
    required this.id,
    required this.bookingId,
    required this.reason,
    required this.reasonLabel,
    this.description,
    required this.status,
    required this.statusLabel,
    this.adminNote,
    required this.evidenceImages,
    this.createdAt,
    this.updatedAt,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) => ReturnItem(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        reason: json['reason'] as String,
        reasonLabel: json['reasonLabel'] as String,
        description: json['description'] as String?,
        status: json['status'] as String,
        statusLabel: json['statusLabel'] as String,
        adminNote: json['adminNote'] as String?,
        evidenceImages: (json['evidenceImages'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );
}

// ─── State ─────────────────────────────────────────────────────────────────────

class ReturnState {
  final bool isSubmitting;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<ReturnItem> returns;
  final ReturnItem? selectedReturn;
  final bool hasMore;
  final int page;

  const ReturnState({
    this.isSubmitting = false,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.returns = const [],
    this.selectedReturn,
    this.hasMore = false,
    this.page = 0,
  });

  ReturnState copyWith({
    bool? isSubmitting,
    bool? isLoading,
    String? error,
    String? successMessage,
    List<ReturnItem>? returns,
    ReturnItem? selectedReturn,
    bool? hasMore,
    int? page,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelected = false,
  }) =>
      ReturnState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        successMessage:
            clearSuccess ? null : successMessage ?? this.successMessage,
        returns: returns ?? this.returns,
        selectedReturn:
            clearSelected ? null : selectedReturn ?? this.selectedReturn,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class ReturnNotifier extends StateNotifier<ReturnState> {
  ReturnNotifier() : super(const ReturnState());

  Dio get _client => ApiClient.instance.productClient;

  Future<bool> submitReturn({
    required String bookingId,
    required String reason,
    String? description,
    List<String>? imagePaths,
  }) async {
    state = state.copyWith(
        isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final formFields = <String, dynamic>{
        'bookingId': bookingId,
        'reason': reason,
      };
      if (description != null && description.isNotEmpty) {
        formFields['description'] = description;
      }
      if (imagePaths != null && imagePaths.isNotEmpty) {
        formFields['images'] = await Future.wait(
          imagePaths.map((p) => MultipartFile.fromFile(p)),
        );
      }

      final response = await _client.post(
        ApiEndpoints.returns,
        data: FormData.fromMap(formFields),
      );

      final bool success = response.data['success'] as bool? ?? false;
      if (success) {
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Return request submitted successfully.',
        );
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error:
              response.data['message'] as String? ?? 'Submission failed.',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Submission failed. Please try again.';
      state = state.copyWith(isSubmitting: false, error: msg);
      return false;
    } catch (_) {
      state = state.copyWith(
          isSubmitting: false,
          error: 'Something went wrong. Please try again.');
      return false;
    }
  }

  Future<void> loadReturns({bool refresh = false}) async {
    if (state.isLoading) return;
    final nextPage = refresh ? 0 : state.page;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.get(
        ApiEndpoints.returns,
        queryParameters: {'page': nextPage, 'size': 10},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final items = (data['returns'] as List<dynamic>)
          .map((e) => ReturnItem.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        returns: refresh ? items : [...state.returns, ...items],
        hasMore: data['hasMore'] as bool? ?? false,
        page: nextPage + 1,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to load returns.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load returns.');
    }
  }

  Future<void> loadReturnDetail(String id) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSelected: true);
    try {
      final response =
          await _client.get(ApiEndpoints.returnDetail(id));
      final item = ReturnItem.fromJson(
          response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, selectedReturn: item);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to load return details.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load return details.');
    }
  }

  void clearMessages() =>
      state = state.copyWith(clearError: true, clearSuccess: true);
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final returnProvider =
    StateNotifierProvider<ReturnNotifier, ReturnState>(
  (ref) => ReturnNotifier(),
);
