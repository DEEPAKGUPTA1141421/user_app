import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_gateway.dart';

RazorpayGateway createRazorpayGateway() => _MobileRazorpayGateway();

class _MobileRazorpayGateway implements RazorpayGateway {
  late final Razorpay _razorpay;
  void Function(String paymentId, String orderId, String signature)?
      _onSuccess;
  void Function(String message)? _onError;

  _MobileRazorpayGateway() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse r) {
      _onSuccess?.call(
          r.paymentId ?? '', r.orderId ?? '', r.signature ?? '');
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      _onError?.call(r.message ?? 'Payment failed or cancelled');
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse r) {});
  }

  @override
  void open({
    required String keyId,
    required String orderId,
    required String currency,
    int? amountPaise,
    required String name,
    required String description,
    required String contact,
    required String email,
    required void Function(String, String, String) onSuccess,
    required void Function(String) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _razorpay.open({
      'key': keyId,
      'order_id': orderId,
      if (amountPaise != null) 'amount': amountPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#000000'},
    });
  }

  @override
  void dispose() => _razorpay.clear();
}
