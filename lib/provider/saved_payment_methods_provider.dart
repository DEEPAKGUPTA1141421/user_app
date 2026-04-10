import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class SavedPaymentMethodsNotifier
    extends StateNotifier<Map<String, dynamic>> {
  SavedPaymentMethodsNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'methods': [],
        });

  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/v1/users/payment-methods
  Future<void> fetchAll() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};
      final headers = await _headers();
      final res = await http.get(
        Uri.parse('${ServerApi.OrderPaymentNotificationService}/api/v1/users/payment-methods'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        state = {
          ...state,
          'isLoading': false,
          'success': body['success'] ?? false,
          'methods': body['data'] ?? [],
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to load payment methods',
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

  /// POST /api/v1/users/payment-methods/card
  Future<Map<String, dynamic>> saveCard({
    required String gatewayToken,
    required String cardLast4,
    required String cardBrand,
    required String cardHolderName,
    required String cardExpiry,
    required String cardType,
    required String gateway,
    String? nickname,
    bool makeDefault = false,
  }) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _headers();
      final res = await http.post(
        Uri.parse(
            '${ServerApi.OrderPaymentNotificationService}/api/v1/users/payment-methods/card'),
        headers: headers,
        body: json.encode({
          'gatewayToken': gatewayToken,
          'cardLast4': cardLast4,
          'cardBrand': cardBrand,
          'cardHolderName': cardHolderName,
          'cardExpiry': cardExpiry,
          'cardType': cardType,
          'gateway': gateway,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          'makeDefault': makeDefault,
        }),
      );
      final body = json.decode(res.body);
      state = {...state, 'isLoading': false};
      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchAll();
      }
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /api/v1/users/payment-methods/upi
  Future<Map<String, dynamic>> saveUpi({
    required String upiId,
    String? upiDisplayName,
    String? nickname,
    bool makeDefault = false,
  }) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _headers();
      final res = await http.post(
        Uri.parse(
            '${ServerApi.OrderPaymentNotificationService}/api/v1/users/payment-methods/upi'),
        headers: headers,
        body: json.encode({
          'upiId': upiId,
          if (upiDisplayName != null && upiDisplayName.isNotEmpty)
            'upiDisplayName': upiDisplayName,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          'makeDefault': makeDefault,
        }),
      );
      final body = json.decode(res.body);
      state = {...state, 'isLoading': false};
      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchAll();
      }
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  /// DELETE /api/v1/users/payment-methods/{id}
  Future<Map<String, dynamic>> delete(String id) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _headers();
      final res = await http.delete(
        Uri.parse(
            '${ServerApi.OrderPaymentNotificationService}/api/v1/users/payment-methods/$id'),
        headers: headers,
      );
      final body = json.decode(res.body);
      state = {...state, 'isLoading': false};
      if (res.statusCode == 200) {
        // Optimistic removal
        final current = List<dynamic>.from(state['methods']);
        current.removeWhere((m) => m['id']?.toString() == id);
        state = {...state, 'methods': current};
      }
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }
}

final savedPaymentMethodsProvider =
    StateNotifierProvider<SavedPaymentMethodsNotifier, Map<String, dynamic>>(
  (ref) => SavedPaymentMethodsNotifier(),
);