import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class NotificationPreferencesNotifier
    extends StateNotifier<Map<String, dynamic>> {
  NotificationPreferencesNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'preferences': {},
          'totalCategories': 0,
          'totalChannels': 0,
        });

  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/v1/users/notification-preferences
  Future<void> fetchAll() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};
      final headers = await _headers();
      final res = await http.get(
        Uri.parse(
            '${ServerApi.OrderPaymentNotificationService}/api/v1/users/notification-preferences'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'] ?? {};
        state = {
          ...state,
          'isLoading': false,
          'success': body['success'] ?? false,
          'preferences': data['preferences'] ?? {},
          'totalCategories': data['totalCategories'] ?? 0,
          'totalChannels': data['totalChannels'] ?? 0,
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to load preferences',
        };
      }
    } catch (e) {
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// PATCH /api/v1/users/notification-preferences/{type}
  /// Update a single category+channel
  Future<Map<String, dynamic>> updateCategory({
    required String category,
    required String channel,
    required bool enabled,
    String? quietStart,
    String? quietEnd,
    int? dailyCap,
  }) async {
    // Optimistic update
    _optimisticUpdate(category, channel, enabled);

    try {
      final headers = await _headers();
      final body = <String, dynamic>{
        'channel': channel,
        'enabled': enabled,
      };
      if (quietStart != null) body['quietStart'] = quietStart;
      if (quietEnd != null) body['quietEnd'] = quietEnd;
      if (dailyCap != null) body['dailyCap'] = dailyCap;

      final res = await http.patch(
        Uri.parse(
            '${ServerApi.OrderPaymentNotificationService}/api/v1/users/notification-preferences/$category'),
        headers: headers,
        body: json.encode(body),
      );
      final resBody = json.decode(res.body);
      if (res.statusCode != 200) {
        // Revert optimistic update on failure
        _optimisticUpdate(category, channel, !enabled);
      }
      return resBody;
    } catch (e) {
      // Revert
      _optimisticUpdate(category, channel, !enabled);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// PUT /api/v1/users/notification-preferences
  /// Bulk update multiple preferences
  Future<Map<String, dynamic>> bulkUpdate(
      List<Map<String, dynamic>> preferences) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _headers();
      final res = await http.put(
        Uri.parse(
            '${ServerApi.OrderPaymentNotificationService}/api/v1/users/notification-preferences'),
        headers: headers,
        body: json.encode({'preferences': preferences}),
      );
      final body = json.decode(res.body);
      state = {...state, 'isLoading': false};
      if (res.statusCode == 200) {
        await fetchAll();
      }
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  void _optimisticUpdate(String category, String channel, bool enabled) {
    final prefs =
        Map<String, dynamic>.from(state['preferences'] as Map? ?? {});
    final categoryList = List<dynamic>.from(prefs[category] ?? []);
    final idx = categoryList.indexWhere((p) => p['channel'] == channel);
    if (idx >= 0) {
      categoryList[idx] = {
        ...Map<String, dynamic>.from(categoryList[idx]),
        'enabled': enabled,
      };
    } else {
      categoryList.add({'channel': channel, 'enabled': enabled});
    }
    prefs[category] = categoryList;
    state = {...state, 'preferences': prefs};
  }
}

final notificationPrefsProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, Map<String, dynamic>>(
  (ref) => NotificationPreferencesNotifier(),
);