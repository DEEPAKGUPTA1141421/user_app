import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPayment = "";
  bool showPriceDetails = true;
  int donationAmount = 0;

  final int totalAmount = 638;
  static const brandColor = Color(0xFFFF5200);
  Future<void> initiateUPIPayment({
    required String upiId,
    required String name,
    required String amount,
  }) async {
    final Uri upiUri = Uri.parse(
      'upi://pay?pa=$upiId&pn=$name&am=$amount&cu=INR',
    );

    try {
      bool launched =
          await launchUrl(upiUri, mode: LaunchMode.externalApplication);

      if (!launched) {
        throw 'Could not launch UPI app';
      }
    } catch (e) {
      debugPrint('Error launching UPI app: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Correct SDK initialization with positional arguments
    // init(String environment, String merchantUpiId, String merchantId, bool isAutoSelectApp)
    PhonePePaymentSdk.init(
      "SANDBOX", // environment
      "merchant@upi", // your UPI ID (can use test UPI)
      "TEST-M2361NIBCR3FS_25101", // your merchant ID from dashboard
      true, // auto-select PhonePe app if installed
    ).then((val) {
      debugPrint('PhonePe SDK Initialized: $val');
    }).catchError((error) {
      debugPrint('PhonePe SDK init error: $error');
    });
  }

  void payWithPhonePe() async {
    try {
      Map<String, dynamic> bodyMap = {
        "merchantId": "YOUR_MERCHANT_ID",
        "merchantTransactionId": "txn123",
        "merchantUserId": "user123",
        "amount": 63800, // in paise, 638.00 INR = 63800 paise
        "mobileNumber": "9999999999",
        "callbackUrl": "https://yourcallback.url",
        "paymentInstrument": {"type": "PAY_PAGE"}
      };

      String body = jsonEncode(bodyMap);
      print("now calling the api of phonesdk");
      var response = await PhonePePaymentSdk.startTransaction(
        body,
        "com.phonepe.app", // the app schema
      );

      print("Payment Response: $response");
    } catch (e) {
      print("Error initiating payment: $e");
    }
  }

  void handlePlaceOrder() {
    if (selectedPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select payment method to continue"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // initiateUPIPayment(
    //   upiId: 'merchant@upi', // Your or test UPI ID
    //   name: 'D2D',
    //   amount: '638',
    // );
    payWithPhonePe();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Order placed successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int finalAmount = totalAmount + donationAmount;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: const Text("Payments"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.lock, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  "100% Secure",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Warning Banner
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                color: Colors.amber[50],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📦", style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Rest assured with Open Box Delivery",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.amber),
                              children: [
                                const TextSpan(
                                    text:
                                        "Delivery agent will open the package so you can check for correct product, damage or missing items. Share OTP to accept the delivery. "),
                                TextSpan(
                                  text: "Why?",
                                  style: const TextStyle(
                                      color: brandColor,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Total Amount Display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          showPriceDetails = !showPriceDetails;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Total Amount",
                                style: TextStyle(
                                    color: brandColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                showPriceDetails
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: brandColor,
                              ),
                            ],
                          ),
                          Text(
                            "₹$finalAmount",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (showPriceDetails)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          buildPriceRow("Price (1 item)", 1097),
                          buildPriceRow("Discount", -316, isGreen: true),
                          buildPriceRow("Coupons for you", -150, isGreen: true),
                          buildPriceRow("Platform Fee", 7),
                          if (donationAmount > 0)
                            buildPriceRow("Donation", donationAmount),
                        ],
                      )
                  ],
                ),
              ),

              // Donation Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text("❤️", style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Donate to Flipkart Foundation",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Support transformative social work in India",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=100&h=100&fit=crop",
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [10, 20, 50, 100].map((amount) {
                          bool isSelected = donationAmount == amount;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.white,
                                  side: BorderSide(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade400,
                                      width: 2),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    donationAmount =
                                        donationAmount == amount ? 0 : amount;
                                  });
                                },
                                child: Text("₹$amount",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Note: GST and No cost EMI will not be applicable",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Payment Methods Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: [
                    buildPaymentMethod(
                        title: "PhonePe",
                        icon: Icons.phone_iphone,
                        value: "phonepe"),
                    buildPaymentMethod(
                        title: "Google Pay",
                        icon: Icons.phone_iphone,
                        value: "Google Pay"),
                    buildPaymentMethod(
                        title: "Add new UPI ID",
                        icon: Icons.upcoming,
                        value: "upi"),
                    buildPaymentMethod(
                        title: "Credit / Debit / ATM Card",
                        icon: Icons.credit_card,
                        value: "card"),
                    buildPaymentMethod(
                        title: "Net Banking",
                        icon: Icons.account_balance,
                        value: "netbanking"),
                    buildPaymentMethod(
                        title: "Have a Flipkart Gift Card?",
                        icon: Icons.card_giftcard,
                        value: "gift"),
                    buildPaymentMethod(
                        title: "Cash on Delivery",
                        icon: Icons.account_balance_wallet,
                        value: "cod",
                        enabled: false),
                    buildPaymentMethod(
                        title: "EMI",
                        icon: Icons.percent,
                        value: "emi",
                        enabled: false),
                  ],
                ),
              ),

              // Happy Customers
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: const [
                    Text("thousands of happy customers",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("and counting!",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 4),
                    Text("😊", style: TextStyle(fontSize: 32)),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("₹$finalAmount",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text("View details",
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: handlePlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor, // Set your brand color here
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPriceRow(String title, int amount, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            (amount >= 0 ? "₹$amount" : "-₹${-amount}"),
            style: TextStyle(
                fontSize: 12,
                color: isGreen ? Colors.green : Colors.black,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget buildPaymentMethod(
      {required String title,
      required IconData icon,
      required String value,
      bool enabled = true}) {
    bool isSelected = selectedPayment == value;

    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                selectedPayment = value;
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          border: const Border(
              bottom: BorderSide(color: Color.fromARGB(255, 8, 5, 5))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      color: enabled ? Colors.black : Colors.grey)),
            ),
            if (!enabled)
              const Text("Unavailable",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (enabled)
              Radio<String>(
                value: value,
                groupValue: selectedPayment,
                activeColor: brandColor,
                onChanged: (val) {
                  setState(() {
                    selectedPayment = val!;
                  });
                },
              )
          ],
        ),
      ),
    );
  }
}
