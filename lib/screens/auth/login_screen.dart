import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'verify_otp_screen.dart';
import '../../provider/rider_provider.dart';
import '../../utils/app_colors.dart';

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
      _showSnack("Please enter a valid 10-digit phone number");
      return;
    }

    final riderNotifier = ref.read(riderPod.notifier);
    final response = await riderNotifier.login(phone, "USER");

    if (true || response['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(phone: phone, userType: "USER"),
        ),
      );
    } else {
      _showSnack(response['message'] ?? "Failed to send OTP");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white, fontSize: 14)),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderPod).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ── Logo / Brand mark ──────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Icon(Icons.shopping_bag_outlined, color: AppColors.white, size: 28),
                ),
              ),

              const SizedBox(height: 32),

              // ── Heading ────────────────────────────────────────────
              const Text(
                "Welcome back",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your phone number to continue",
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 40),

              // ── Phone label ────────────────────────────────────────
              const Text(
                "PHONE NUMBER",
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),

              // ── Phone input ────────────────────────────────────────
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                cursorColor: AppColors.white,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "10-digit mobile number",
                  hintStyle: const TextStyle(color: AppColors.greyDark, fontSize: 15),
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: const Text(
                      "+91",
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.white, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 32),

              // ── Continue button ────────────────────────────────────
              GestureDetector(
                onTap: isLoading ? null : handleContinue,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isLoading ? AppColors.surface2 : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              color: AppColors.bg,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Disclaimer ─────────────────────────────────────────
              const Text(
                "By continuing, you confirm that you are above 18 years of age, and you agree to the Terms of Use and Privacy Policy",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greyDark,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // ── Divider ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: AppColors.border)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("secure login", style: TextStyle(color: AppColors.greyDark, fontSize: 12)),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 24),

              // ── Security note ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.greyDark),
                  SizedBox(width: 6),
                  Text(
                    "Your data is encrypted and secure",
                    style: TextStyle(color: AppColors.greyDark, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}