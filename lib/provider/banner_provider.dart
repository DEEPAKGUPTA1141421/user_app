import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BannerNotifier extends StateNotifier<Map<String, dynamic>> {
  BannerNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'banners': [],
          'currentCategoryId': null,
        });

  Future<void> fetchBannersByCategory(String categoryId) async {
    try {
      // Skip if same category already loaded
      if (state['currentCategoryId'] == categoryId &&
          (state['banners'] as List).isNotEmpty) {
        return;
      }

      state = {
        ...state,
        'isLoading': true,
        'message': '',
        'banners': [],
        'currentCategoryId': categoryId,
      };

      final uri = Uri.parse('http://localhost:8081/api/v1/banners').replace(
        queryParameters: {'categoryId': categoryId},
      );

      final res = await http.get(
          uri, headers: {'Content-Type': 'application/json'});

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true) {
          state = {
            ...state,
            'isLoading': false,
            'success': true,
            'message': body['message'] ?? '',
            'banners': body['data'] as List? ?? [],
          };
        } else {
          state = {
            ...state,
            'isLoading': false,
            'success': false,
            'message': body['message'] ?? 'Failed to fetch banners',
            'banners': [],
          };
        }
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Error: ${res.statusCode}',
          'banners': [],
        };
      }
    } catch (e) {
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'message': 'Exception: ${e.toString()}',
        'banners': [],
      };
    }
  }

  /// Clears banner state safely.
  ///
  /// If called during a build frame (which happens when category tabs are
  /// tapped and didUpdateWidget fires), we defer the mutation to the next
  /// post-frame so Riverpod never sees "provider modified while building".
  void clearBanners() {
    // Already clear — nothing to do.
    if ((state['banners'] as List).isEmpty &&
        state['currentCategoryId'] == null) {
      return;
    }

    void doReset() {
      // Check mounted-equivalent: StateNotifier disposes itself; if already
      // disposed the assignment is a no-op, so this is safe.
      state = {
        ...state,
        'isLoading': false,
        'banners': [],
        'currentCategoryId': null,
      };
    }

    // If we are currently in the middle of a frame, defer to post-frame.
    // SchedulerBinding.instance.schedulerPhase covers build, layout & paint.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => doReset());
    } else {
      doReset();
    }
  }
}

final bannerProvider =
    StateNotifierProvider<BannerNotifier, Map<String, dynamic>>(
  (ref) => BannerNotifier(),
);