import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'verify_otp_screen.dart';
import '../../constant/ServerApi.dart';
import '../../provider/rider_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  Future<void> handleContinue() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      showSnack("Invalid Phone Number", "Please enter a valid phone number");
      return;
    }

    final riderNotifier = ref.read(riderPod.notifier);
    final response = await riderNotifier.login(phone, "USER");

    if (true || response['success'] == true) {
      showSnack("Success", "OTP sent successfully");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(phone: phone, userType: "USER"),
        ),
      );
    } else {
      showSnack("Error", response['message'] ?? "Failed to send OTP");
    }
  }

  void showSnack(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title: $message")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderPod)['isLoading'] ?? false;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Log In For The Best Experience",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                "Enter your phone number to continue",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                cursorColor: Colors.black,
                style: const TextStyle(
                  color: Colors.black, // phone number text color
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: const TextStyle(
                    color: Color.fromRGBO(255, 82, 0, 1), // 🔥 label text color
                  ),
                  prefixText: "+91 ",
                  prefixStyle:
                      const TextStyle(color: Colors.black), // prefix color
                  filled: true,
                  fillColor:
                      Colors.white, // background stays white (change if needed)
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(255, 82, 0, 1), // outline color
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(
                          255, 82, 0, 1), // outline color when not focused
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(
                          255, 82, 0, 1), // outline color when focused
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Spacer(),
              ElevatedButton(
                onPressed: isLoading ? null : handleContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromRGBO(255, 82, 0, 1),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continue"),
              ),
              const SizedBox(height: 10),
              const Text(
                "By continuing, you confirm that you are above 18 years of age, and you agree to the Terms of Use and Privacy Policy",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }
}
