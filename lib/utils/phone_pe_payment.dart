import 'package:flutter/services.dart';

class PhonePePayment {
  static const MethodChannel _channel = MethodChannel('phonepe_sdk');

  static Future<Map<String, dynamic>> pay({
    required String merchantId,
    required String upiId,
    required String name,
    required String amount,
    required String txnId,
    required String callbackUrl,
  }) async {
    final result = await _channel.invokeMethod('startPayment', {
      'merchantId': merchantId,
      'upiId': upiId,
      'name': name,
      'amount': amount,
      'txnId': txnId,
      'callbackUrl': callbackUrl,
    });

    return Map<String, dynamic>.from(result);
  }
}
