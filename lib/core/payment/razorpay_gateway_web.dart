// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'razorpay_gateway.dart';

RazorpayGateway createRazorpayGateway() => _WebRazorpayGateway();

/// Talks to the `checkout.js` script (loaded in web/index.html) via JS
/// interop, since `razorpay_flutter` has no web implementation.
///
/// Uses `dart:js_util` exclusively — mixing it with `dart:js`'s `JsObject`
/// wrapper (e.g. passing `js.context['Razorpay']` into
/// `js_util.callConstructor`) throws at runtime because `js_util` expects
/// raw JS values, not the `dart:js` wrapper type.
class _WebRazorpayGateway implements RazorpayGateway {
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
    final razorpayCtor =
        js_util.getProperty(js_util.globalThis, 'Razorpay');
    if (razorpayCtor == null) {
      onError(
          'Payment gateway failed to load. Please check your connection and try again.');
      return;
    }

    final prefill = js_util.newObject();
    js_util.setProperty(prefill, 'contact', contact);
    js_util.setProperty(prefill, 'email', email);

    final theme = js_util.newObject();
    js_util.setProperty(theme, 'color', '#000000');

    final modal = js_util.newObject();
    js_util.setProperty(modal, 'ondismiss', js_util.allowInterop(() {
      onError('Payment cancelled');
    }));

    final options = js_util.newObject();
    js_util.setProperty(options, 'key', keyId);
    js_util.setProperty(options, 'order_id', orderId);
    if (amountPaise != null) {
      js_util.setProperty(options, 'amount', amountPaise);
    }
    js_util.setProperty(options, 'currency', currency);
    js_util.setProperty(options, 'name', name);
    js_util.setProperty(options, 'description', description);
    js_util.setProperty(options, 'prefill', prefill);
    js_util.setProperty(options, 'theme', theme);
    js_util.setProperty(options, 'modal', modal);
    js_util.setProperty(
        options, 'handler', js_util.allowInterop((dynamic response) {
      final paymentId =
          js_util.getProperty(response, 'razorpay_payment_id')?.toString() ??
              '';
      final respOrderId =
          js_util.getProperty(response, 'razorpay_order_id')?.toString() ??
              orderId;
      final signature =
          js_util.getProperty(response, 'razorpay_signature')?.toString() ??
              '';
      onSuccess(paymentId, respOrderId, signature);
    }));

    final rzp = js_util.callConstructor(razorpayCtor, [options]);
    js_util.callMethod(rzp, 'open', []);
  }

  @override
  void dispose() {}
}
