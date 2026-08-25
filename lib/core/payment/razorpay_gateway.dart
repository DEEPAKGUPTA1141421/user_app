import 'razorpay_gateway_mobile.dart'
    if (dart.library.html) 'razorpay_gateway_web.dart' as impl;

/// Platform-agnostic wrapper around the Razorpay checkout.
///
/// `razorpay_flutter` only ships native Android/iOS implementations — on
/// Flutter Web calling it throws a `MissingPluginException`. This interface
/// is backed by [impl.createRazorpayGateway], which resolves at compile
/// time to the native plugin on mobile/desktop and to a `checkout.js` JS
/// interop wrapper on web.
abstract class RazorpayGateway {
  void open({
    required String keyId,
    required String orderId,
    required String currency,
    int? amountPaise,
    required String name,
    required String description,
    required String contact,
    required String email,
    required void Function(
            String paymentId, String orderId, String signature)
        onSuccess,
    required void Function(String message) onError,
  });

  void dispose();
}

RazorpayGateway createRazorpayGateway() => impl.createRazorpayGateway();
