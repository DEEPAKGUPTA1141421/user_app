import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

/// RiderNotifier manages API calls for login and OTP verification
class RiderNotifier extends StateNotifier<Map<String, dynamic>> {
  RiderNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'user_detail': {},
          'recent_search': [],
          'trending_search': []
        });

  /// Getter for loading status
  bool get isLoading => state['isLoading'] ?? false;

  /// Login API
  Future<Map<String, dynamic>> login(String phone, String userType) async {
    state = {...state, 'isLoading': true, 'success': false, 'message': ''};

    try {
      final res = await http.post(
        Uri.parse(ServerApi.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "typeOfUser": userType}),
      );

      final Map<String, dynamic> jsonBody = jsonDecode(res.body);

      // Update state with API response and stop loading
      state = {...jsonBody, 'isLoading': false};
      return jsonBody;
    } catch (e) {
      state = {'success': false, 'message': e.toString(), 'isLoading': false};
      return state;
    }
  }

  /// OTP Verification API
  Future<Map<String, dynamic>> verifyOtp(
      String phone, String userType, String otp) async {
    state = {...state, 'isLoading': true};

    try {
      final res = await http.post(
        Uri.parse(ServerApi.verifyOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"phone": phone, "typeOfUser": userType, "otp_code": otp}),
      );

      final Map<String, dynamic> jsonBody = jsonDecode(res.body);

      // Update state with API response and stop loading
      state = {...jsonBody, 'isLoading': false};
      return jsonBody;
    } catch (e) {
      state = {'success': false, 'message': e.toString(), 'isLoading': false};
      return state;
    }
  }

  Future<Map<String, dynamic>> getUserDetail() async {
    state = {...state, 'isLoading': true};
    final token = await StorageService.getToken();

    try {
      final res = await http.get(
        Uri.parse(ServerApi.GetUserDetails),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final Map<String, dynamic> jsonBody = jsonDecode(res.body);
      state = {
        ...state,
        'isLoading': false,
        'success': jsonBody['success'] ?? false,
        'message': jsonBody['message'] ?? '',
        'user_detail': jsonBody['data'] ?? {},
      };

      return jsonBody;
    } catch (e) {
      state = {
        ...state,
        'success': false,
        'message': e.toString(),
        'isLoading': false,
      };
      return state;
    }
  }
}

/// Global Riverpod provider for RiderNotifier
final riderPod = StateNotifierProvider<RiderNotifier, Map<String, dynamic>>(
  (ref) => RiderNotifier(),
);
