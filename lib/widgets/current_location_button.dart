import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import '../utils/app_colors.dart'; // ✅ USE YOUR COLOR FILE

class CurrentLocationButton extends ConsumerStatefulWidget {
  const CurrentLocationButton({super.key});

  @override
  ConsumerState<CurrentLocationButton> createState() =>
      _CurrentLocationButtonState();
}

class _CurrentLocationButtonState
    extends ConsumerState<CurrentLocationButton> {
  bool isLoading = false;

  Future<void> handleUseCurrentLocation() async {
    setState(() => isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final riderNotifier = ref.read(riderPod.notifier);

      final res = await riderNotifier.addAddress(
        position.latitude.toString(),
        position.longitude.toString(),
        true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['success'] == true
                ? "Location saved successfully"
                : res['message'] ?? "Failed to save",
            style: const TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e",
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.surface2,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: isLoading ? null : handleUseCurrentLocation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.location_fill,
                      color: AppColors.white,
                      size: 18,
                    ),
              const SizedBox(width: 10),
              Text(
                isLoading
                    ? "Fetching your location..."
                    : "Use current location",
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}