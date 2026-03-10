import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

class PhonePePg {
  int amount;
  BuildContext context;

  PhonePePg({required this.context, required this.amount});

  String merchantId = "PGTESTPAYUAT";
  String salt = "099eb0cd-02cf-4e2a-8aca-3e6c6aff0399";
  int saltIndex = 1;
  String callbackURL = "https://www.webhook.site/callback-url";
  String apiEndPoint = "/pg/v1/pay";

  void init() {
    // PhonePePaymentSdk.init("SANDBOX", null, merchantId, true).then((val) {
    //   debugPrint('PhonePe SDK Initialized - $val');
    //   startTransaction();
    // }).catchError((error) {
    //   debugPrint('PhonePe SDK error - $error');
    // });
  }

  void startTransaction() async {
    try {
      String body = getCheckSum().toString();
      var response =
          await PhonePePaymentSdk.startTransaction(body, "com.phonepe.app");
      if (response != null) {
        String status = response['status'].toString();
        String error = response['error'].toString();
        if (status == "SUCCESS") {
          debugPrint("Payment Done");
        } else {
          debugPrint("Payment Failed - Status: $status, Error: $error");
        }
      } else {
        debugPrint("Flow Incompleted");
      }
    } catch (error) {
      debugPrint('Error initiating payment: $error');
    }
  }

  getCheckSum() {
    final requestData = {
      "merchantId": merchantId,
      "merchantTransactionId": "MT7850590068188104",
      "merchantUserId": "MUID123",
      "amount": amount,
      "mobileNumber": "9999999999",
      "callbackUrl": callbackURL,
      "paymentInstrument": {"type": "PAY_PAGE"}
    };

    String jsonString = json.encode(requestData);
    String checkSum = generateChecksum(jsonString);
    requestData["checkSum"] = checkSum;
    return requestData;
  }

  String generateChecksum(String data) {
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
