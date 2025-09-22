import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CurrentLocationButton extends StatefulWidget {
  const CurrentLocationButton({super.key});

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  bool isLoading = false;

  Future<void> handleUseCurrentLocation() async {
    setState(() => isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions are denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
          "Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    } catch (e) {
      debugPrint("Error fetching location: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : handleUseCurrentLocation,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.location_on, color: Colors.white),
        label: Text(
            isLoading ? "Fetching location..." : "Use my current location"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5200),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
