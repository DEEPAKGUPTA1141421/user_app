import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:user_app/utils/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/people_screen.dart';
import 'screens/cart_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/bottom_navbar.dart';
import './utils/StorageService.dart'; // <-- import your storage service
import './main_layout.dart';
import 'screens/cart/order_summary_page.dart';
import 'screens/cart/payment_page.dart';
import 'screens/accounts/customer_support_page.dart';
import 'screens/accounts/my_orders_page.dart';
import 'screens/accounts/order_details_page.dart';
import 'unknown_page.dart';
import 'widgets/product/product_details_page.dart';
import 'firebase_options.dart';
import 'screens/accounts/wishlist_screen.dart'; // replace the old one with new file
import 'screens/accounts/addresses_screen.dart';
import 'screens/accounts/saved_cards_upi_screen.dart';
import 'screens/accounts/notification_settings_screen.dart';
import 'screens/accounts/edit_profile_page.dart';
import 'widgets/product_search_results_page.dart'; // ← your new file
Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
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
      home: const SplashScreen(),

      // Static routes
      routes: {
        "/home": (context) => const MainLayout(),
        "/login": (context) => const LoginScreen(),
        '/order-summary': (context) => OrderSummaryPage(),
        '/payment': (context) => PaymentPage(),
        '/account/orders': (context) => MyOrdersPage(),
        '/account/wishlist': (context) => WishlistScreen(),
        '/account/support': (context) => CustomerSupportPage(),  
        '/account/addresses': (context) => const AddressesScreen(),
        '/account/cards': (context) => const SavedCardsUpiScreen(),
        '/account/notifications': (context) => const NotificationSettingsScreen(),
        '/account/profile': (context) => const EditProfilePage(),
      },

      // Dynamic routes
      onGenerateRoute: (settings) {
        if (settings.name != null) {
          final uri = Uri.parse(settings.name!);

          // Example: /order/1
          if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'order') {
            final orderId = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (context) => OrderDetailsPage(orderId: orderId),
            );
          } // Dynamic shop route: /shop/<id>
          

          // Dynamic product detail route: /productDetail/<id>
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments[0] == 'productDetail') {
            final productId = uri.pathSegments[1]; // from URL path
            final args = settings.arguments as Map<String, dynamic>? ?? {};

            return MaterialPageRoute(
              builder: (context) => ProductDetailsPage(
                productId: productId,
                // Optionally, pass args to the constructor if you modify it:
                // itemType: args['itemType'] ?? "Product",
                // title: args['title'] ?? "Unnamed Product",
                // imageUrl: args['imageUrl'] ?? "https://via.placeholder.com/150",
                // itemId: args['itemId'] ?? productId,
              ),
              settings: settings, // Keep arguments available via ModalRoute
            );
          }
          if (uri.pathSegments[0] == 'search') {
  final q = settings.arguments as String? ?? '';
  return MaterialPageRoute(builder: (_) => ProductSearchResultsPage(query: q));
}
        }

        // Unknown route fallback
        print("⚠️ Unknown route: ${settings.name}");
        return MaterialPageRoute(
          builder: (context) => const UnknownPage(),
        );
      },
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
  late FirebaseMessaging messaging;
  @override
  void initState() {
    messaging = FirebaseMessaging.instance;
    messaging.requestPermission();
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
          color: AppColors.bg,
        ),
      ),
    );
  }
}

