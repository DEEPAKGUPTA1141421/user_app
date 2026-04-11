import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class NotificationPreferencesState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> preferences;
  final int totalCategories;
  final int totalChannels;

  const NotificationPreferencesState({
    this.isLoading = false,
    this.error,
    this.preferences     = const {},
    this.totalCategories = 0,
    this.totalChannels   = 0,
  });

  NotificationPreferencesState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? preferences,
    int? totalCategories,
    int? totalChannels,
  }) {
    return NotificationPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      preferences:     preferences     ?? this.preferences,
      totalCategories: totalCategories ?? this.totalCategories,
      totalChannels:   totalChannels   ?? this.totalChannels,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  NotificationPreferencesNotifier()
      : super(const NotificationPreferencesState());

  Dio get _client => ApiClient.instance.orderClient;

  // ── Fetch all preferences ─────────────────────────────────────────────────

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.notificationPrefs);
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        isLoading: false,
        preferences:     data['preferences'] as Map<String, dynamic>? ?? {},
        totalCategories: data['totalCategories'] as int? ?? 0,
        totalChannels:   data['totalChannels']   as int? ?? 0,
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

  // ── Update a single category + channel (with optimistic update) ───────────

  Future<Map<String, dynamic>> updateCategory({
    required String category,
    required String channel,
    required bool enabled,
    String? quietStart,
    String? quietEnd,
    int? dailyCap,
  }) async {
    _applyOptimistic(category, channel, enabled);
    try {
      final body = <String, dynamic>{'channel': channel, 'enabled': enabled};
      if (quietStart != null) body['quietStart'] = quietStart;
      if (quietEnd   != null) body['quietEnd']   = quietEnd;
      if (dailyCap   != null) body['dailyCap']   = dailyCap;

      final res = await _client.patch(
        ApiEndpoints.notificationPrefCategory(category),
        data: body,
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _applyOptimistic(category, channel, !enabled); // revert
      return {'success': false, 'message': AppException.fromDioError(e).message};
    } catch (e) {
      _applyOptimistic(category, channel, !enabled);
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Bulk update ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> bulkUpdate(
    List<Map<String, dynamic>> preferences,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.put(
        ApiEndpoints.notificationPrefs,
        data: {'preferences': preferences},
      );
      state = state.copyWith(isLoading: false);
      await fetchAll();
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = AppException.fromDioError(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _applyOptimistic(String category, String channel, bool enabled) {
    final prefs = Map<String, dynamic>.from(state.preferences);
    final categoryList = List<dynamic>.from(prefs[category] ?? []);
    final idx = categoryList.indexWhere((p) => p['channel'] == channel);
    if (idx >= 0) {
      categoryList[idx] = {
        ...Map<String, dynamic>.from(categoryList[idx] as Map),
        'enabled': enabled,
      };
    } else {
      categoryList.add({'channel': channel, 'enabled': enabled});
    }
    prefs[category] = categoryList;
    state = state.copyWith(preferences: prefs);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final notificationPrefsProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>(
  (ref) => NotificationPreferencesNotifier(),
);
