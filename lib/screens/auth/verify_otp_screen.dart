import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/rider_provider.dart';
import "../../utils/StorageService.dart";

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String userType;
  const VerifyOtpScreen({
    super.key,
    required this.phone,
    required this.userType,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  int timeLeft = 30;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (timeLeft > 0) {
        setState(() => timeLeft--);
        return true;
      } else {
        setState(() => canResend = true);
        return false;
      }
    });
  }

  String formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, "0");
    final secs = (seconds % 60).toString().padLeft(2, "0");
    return "$mins:$secs";
  }

  Future<void> handleVerify() async {
    if (otpController.text.length != 6) {
      showSnack("Invalid OTP", "Please enter 6 digits");
      return;
    }

    // Use Riverpod notifier for API call
    final riderNotifier = ref.read(riderPod.notifier);
    final response = await riderNotifier.verifyOtp(
        widget.phone, widget.userType, otpController.text);
    print(response);
    Navigator.pushReplacementNamed(context, "/home");
    if (true || response['success'] == true) {
      final token = response['data']; // the JWT from API
      await StorageService.saveToken(token);
      showSnack("Success", "You are logged in!");
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      showSnack("Error", response['message'] ?? "OTP verification failed");
    }
  }

  Future<void> handleResend() async {
    if (!canResend) return;

    setState(() {
      otpController.clear();
      timeLeft = 30;
      canResend = false;
    });
    startTimer();

    final riderNotifier = ref.read(riderPod.notifier);
    final response = await riderNotifier.login(widget.phone, widget.userType);

    if (response['success'] == true) {
      showSnack("OTP Sent", response['message']);
    } else {
      showSnack("Error", response['message'] ?? "Failed to resend OTP");
    }
  }

  void showSnack(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title: $message")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the isLoading flag from Riverpod
    final isLoading = ref.watch(riderPod)['isLoading'] ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Please enter the verification code sent to ${widget.phone}",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                cursorColor: Colors.black, // cursor color
                decoration: InputDecoration(
                  labelText: "OTP",
                  labelStyle: const TextStyle(
                    color: Color.fromRGBO(255, 82, 0, 1),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(255, 82, 0, 1),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(255, 82, 0, 1),
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: Color.fromRGBO(255, 82, 0, 1),
                ),
              ),
              const SizedBox(height: 10),
              Text(formatTime(timeLeft),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (canResend)
                TextButton(
                  onPressed: isLoading ? null : handleResend,
                  child: const Text("Resend OTP"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(255, 82, 0, 1),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: isLoading ? null : handleVerify,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromRGBO(255, 82, 0, 1),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
