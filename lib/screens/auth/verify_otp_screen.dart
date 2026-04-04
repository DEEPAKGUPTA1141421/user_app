import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/rider_provider.dart';
import '../../utils/StorageService.dart';
import '../../utils/app_colors.dart';

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
  // 6 controllers + focus nodes for the OTP boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int timeLeft = 30;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (timeLeft > 0) {
        setState(() => timeLeft--);
        return true;
      } else {
        setState(() => canResend = true);
        return false;
      }
    });
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, "0");
    final secs = (seconds % 60).toString().padLeft(2, "0");
    return "$mins:$secs";
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next box
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty) {
      // Move to previous box on backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  Future<void> handleVerify() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      _showSnack("Please enter the complete 6-digit OTP");
      return;
    }

    final riderNotifier = ref.read(riderPod.notifier);
    final response =
        await riderNotifier.verifyOtp(widget.phone, widget.userType, otp);

    if (!mounted) return;

    if (response['success'] == true) {
      final dynamic rawData = response['data'];
      String? token;

      if (rawData is String && rawData.isNotEmpty) {
        token = rawData;
      } else if (rawData is Map) {
        token = rawData['token']?.toString() ??
            rawData['accessToken']?.toString() ??
            rawData['jwt']?.toString();
      }

      if (token != null && token.isNotEmpty) {
        await StorageService.saveToken(token);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      _showSnack(response['message']?.toString() ?? "OTP verification failed");
    }
  }

  Future<void> handleResend() async {
    if (!canResend) return;

    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) {
      setState(() {
        timeLeft = 30;
        canResend = false;
      });
    }
    _startTimer();

    final riderNotifier = ref.read(riderPod.notifier);
    final response = await riderNotifier.login(widget.phone, widget.userType);

    if (!mounted) return;

    if (response['success'] == true) {
      _showSnack("OTP resent successfully");
    } else {
      _showSnack(response['message']?.toString() ?? "Failed to resend OTP");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: AppColors.white, fontSize: 14)),
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
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderPod)['isLoading'] ?? false;
    final isOtpComplete = _otpValue.length == 6;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ── Back button ────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Heading ────────────────────────────────────────────
              const Text(
                "Verify your number",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "We sent a 6-digit code to "),
                    TextSpan(
                      text: "+91 ${widget.phone}",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── OTP label ──────────────────────────────────────────
              const Text(
                "ENTER OTP",
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // ── 6-box OTP input ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFocused = _focusNodes[index].hasFocus;
                  final hasValue = _controllers[index].text.isNotEmpty;

                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      cursorColor: AppColors.white,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: hasValue
                            ? AppColors.surface2
                            : AppColors.surface,
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
                          borderSide: const BorderSide(
                              color: AppColors.white, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) => _onOtpDigitChanged(index, value),
                      // Handle backspace on empty field
                      onEditingComplete: () {
                        if (_controllers[index].text.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // ── Timer / Resend ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!canResend)
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Resend in ${_formatTime(timeLeft)}",
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: isLoading ? null : handleResend,
                      child: const Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
                        ),
                      ),
                    ),
                  // Change number
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Change number",
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Verify button ──────────────────────────────────────
              GestureDetector(
                onTap: (isLoading || !isOtpComplete) ? null : handleVerify,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isOtpComplete && !isLoading
                        ? AppColors.white
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOtpComplete && !isLoading
                          ? AppColors.white
                          : AppColors.border,
                    ),
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
                        : Text(
                            "Verify & Continue",
                            style: TextStyle(
                              color: isOtpComplete
                                  ? AppColors.bg
                                  : AppColors.greyDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                ),
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
                    style:
                        TextStyle(color: AppColors.greyDark, fontSize: 12),
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