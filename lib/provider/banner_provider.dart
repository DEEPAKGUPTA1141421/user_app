import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class BannerState {
  final bool isLoading;
  final String? error;
  final List<dynamic> banners;
  final String? currentCategoryId;

  const BannerState({
    this.isLoading = false,
    this.error,
    this.banners = const [],
    this.currentCategoryId,
  });

  bool get isEmpty => banners.isEmpty;

  BannerState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? banners,
    String? currentCategoryId,
  }) {
    return BannerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      banners: banners ?? this.banners,
      currentCategoryId: currentCategoryId ?? this.currentCategoryId,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BannerNotifier extends StateNotifier<BannerState> {
  BannerNotifier() : super(const BannerState());

  Dio get _client => ApiClient.instance.productClient;

  Future<void> fetchBannersByCategory(String categoryId) async {
    // Skip if same category is already loaded
    if (state.currentCategoryId == categoryId && state.banners.isNotEmpty) {
      return;
    }

    state = BannerState(isLoading: true, currentCategoryId: categoryId);

    try {
      final res = await _client.get(
        ApiEndpoints.banners,
        queryParameters: {'categoryId': categoryId},
      );
      final body = res.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        banners: (body['data'] as List<dynamic>?) ?? const [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        banners: const [],
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        banners: const [],
        error: e.toString(),
      );
    }
  }

  /// Safely clear banner state, deferring if called mid-frame.
  void clearBanners() {
    if (state.banners.isEmpty && state.currentCategoryId == null) return;

    void doReset() {
      state = const BannerState();
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => doReset());
    } else {
      doReset();
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final bannerProvider =
    StateNotifierProvider<BannerNotifier, BannerState>((ref) => BannerNotifier());
