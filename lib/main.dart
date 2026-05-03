import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:user_app/utils/app_colors.dart';
import 'core/api/api_client.dart';
import 'core/api/api_endpoints.dart';
import 'core/widgets/app_loader.dart';
import 'core/api/auth_interceptor.dart';
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
import 'screens/accounts/my_returns_page.dart';
import 'screens/accounts/wallet_page.dart';
import 'widgets/product_search_results_page.dart'; // ← your new file
import 'screens/order_success_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/shops/shop_detail_screen.dart';
import 'screens/payment_page.dart';

Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
  AuthInterceptor.navigatorKey = _navigatorKey;
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  OverlayEntry? _banner;

  @override
  void initState() {
    super.initState();
    // Foreground message → in-app notification banner
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    // Background/terminated tap → navigate to the right screen
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
  }

  void _onForegroundMessage(RemoteMessage msg) {
    final title = msg.notification?.title ?? '';
    final body  = msg.notification?.body  ?? '';
    if (title.isEmpty && body.isEmpty) return;
    _showBanner(title, body, msg.data);
  }

  void _onNotificationTap(RemoteMessage msg) {
    final type = msg.data['type'] as String?;
    if (type == 'ORDER_STATUS') {
      _navigatorKey.currentState?.pushNamed('/order-tracking');
    }
  }

  void _showBanner(String title, String body, Map<String, dynamic> data) {
    _banner?.remove();
    _banner = OverlayEntry(
      builder: (_) => _NotificationBanner(
        title: title,
        body: body,
        onTap: () {
          _banner?.remove();
          _banner = null;
          if (data['type'] == 'ORDER_STATUS') {
            _navigatorKey.currentState?.pushNamed('/order-tracking');
          }
        },
        onDismiss: () {
          _banner?.remove();
          _banner = null;
        },
      ),
    );
    _navigatorKey.currentState?.overlay?.insert(_banner!);
    // Auto-dismiss after 4 s
    Future.delayed(const Duration(seconds: 4), () {
      _banner?.remove();
      _banner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

      // Static routes
      routes: {
        '/home':                   (context) => const MainLayout(),
        '/login':                  (context) => const LoginScreen(),
        '/order-summary':          (context) => const OrderSummaryPage(),
        '/payment':                (context) => const PaymentPage(),
        '/order-success':          (context) => const OrderSuccessScreen(),
        '/order-tracking':         (context) => const OrderTrackingScreen(),
        '/account/orders':         (context) => const MyOrdersPage(),
        '/account/returns':        (context) => const MyReturnsPage(),
        '/account/wallet':         (context) => const WalletPage(),
        '/account/wishlist':       (context) => const WishlistScreen(),
        '/account/support':        (context) => const CustomerSupportPage(),
        '/account/addresses':      (context) => const AddressesScreen(),
        '/account/cards':          (context) => const SavedCardsUpiScreen(),
        '/account/notifications':  (context) => const NotificationSettingsScreen(),
        '/account/profile':        (context) => const EditProfilePage(),
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
          }

          // Dynamic shop route: /shop/<id>
          if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'shop') {
            return MaterialPageRoute(
              builder: (_) => const ShopDetailScreen(),
              settings: settings,
            );
          }

          // Dynamic product detail route: /productDetail/<id>
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments[0] == 'productDetail') {
            final productId = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (context) => ProductDetailsPage(productId: productId),
              settings: settings,
            );
          }

          if (uri.pathSegments[0] == 'search') {
            final q = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => ProductSearchResultsPage(query: q),
            );
          }
        }

        // Unknown route fallback
        assert(() {
          debugPrint('⚠️ Unknown route: ${settings.name}');
          return true;
        }());
        return MaterialPageRoute(
          builder: (context) => const UnknownPage(),
        );
      },
    );
  }
}

// ── In-app notification banner ────────────────────────────────────────────────

class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: AppColors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (widget.body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(widget.body,
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(Icons.close,
                        color: AppColors.greyDark, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── FCM token registration ────────────────────────────────────────────────────

Future<void> _registerFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await ApiClient.instance.productClient.post(
      ApiEndpoints.fcmToken,
      data: {'token': token},
    );
  } catch (_) {
    // Non-critical — silently ignore registration failures
  }
}

// ── SplashScreen — auth check + FCM token registration ───────────────────────

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
    final isLoggedIn = await StorageService.isLoggedIn();
    final initialRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final isShopDeepLink = initialRoute.startsWith('/shop/');

    if (!mounted) return;

    if (isShopDeepLink) {
      Navigator.pushReplacementNamed(context, initialRoute);
      return;
    }

    if (isLoggedIn) {
      // Register FCM token now that auth tokens are available
      _registerFcmToken();
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: AppSpinner(color: AppColors.bg)),
    );
  }
}

