import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/people_screen.dart';
import 'screens/cart_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/bottom_navbar.dart';
import './utils/StorageService.dart'; // <-- import your storage service
import './main_layout.dart';

void main() {
  runApp(
    const ProviderScope(
      // ← This is required for Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/home": (context) => const MainLayout(),
        "/login": (context) => const LoginScreen(),
      },
      home: const SplashScreen(),
    );
  }
}

/// 🔹 SplashScreen handles the token check
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await StorageService.checkAuth();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(255, 82, 0, 1), // orange loader
        ),
      ),
    );
  }
}
