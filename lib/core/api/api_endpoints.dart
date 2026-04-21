/// Central registry of all API endpoints.
///
/// Base URLs are kept here as the single source of truth.
/// TODO: Replace hardcoded IPs with environment-specific config before production.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base URLs ──────────────────────────────────────────────────────────────
  static const String productServiceBase = 'http://localhost:8081';
  static const String orderServiceBase   = 'http://localhost:8082';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String login     = '/api/v1/auth/login';
  static const String verifyOtp = '/api/v1/auth/verify';
  static const String refresh   = '/api/v1/auth/refresh';

  // ── User ───────────────────────────────────────────────────────────────────
  static const String userDetails    = '/api/v1/user';
  static const String addAddress     = '/api/v1/user/add-address';
  static const String setDefaultAddr = '/api/v1/user/set-default';
  static const String saveSearchItem = '/api/v1/user/save';
  static const String recentSearches = '/api/v1/user/last';

  // ── Products ───────────────────────────────────────────────────────────────
  static const String categoryByLevel  = '/api/v1/product/categorylevelwise';
  static const String categoryList     = '/api/v1/product/category';
  static const String productDetail    = '/api/v1/product';
  static const String searchSuggestions   = '/api/v1/product/search';
  static const String productSearch    = '/api/v1/product/products/search';
  static const String trendingSearch  = '/api/v1/product/trending';
  static const String popularProducts = '/api/v1/product/popular';

  static String sectionsForCategory(String categoryId) =>
      '/api/v1/sections/$categoryId';

  static String categoryFilters(String categoryId) =>
      '/api/v1/categories/$categoryId/filters';

  // ── Brands ─────────────────────────────────────────────────────────────────
  static String brandsForCategory(String categoryId) =>
      '/api/v1/brands/category/$categoryId';

  // ── Cart ───────────────────────────────────────────────────────────────────
  static const String cart              = '/api/v1/cart/get-cart';
  static const String cartItems         = '/api/v1/cart/items';
  static const String cartCoupons       = '/api/v1/cart/coupons';
  static const String removeCartCoupon  = '/api/v1/cart/coupons/remove';

  static String applyCartCoupon(String code) => '/api/v1/cart/coupons/$code';
  static String cartItem(String id) => '/api/v1/cart/items/$id';

  // ── Wishlist ────────────────────────────────────────────────────────────────
  static const String wishlist           = '/api/v1/wishlist';
  static const String wishlistPriceDrops = '/api/v1/wishlist/price-drops';
  static const String wishlistShare      = '/api/v1/wishlist/share';

  static String wishlistItem(String productId) =>
      '/api/v1/wishlist/items/$productId';
  static String wishlistMoveToCart(String productId) =>
      '/api/v1/wishlist/$productId/move-to-cart';

  // ── Banners ─────────────────────────────────────────────────────────────────
  static const String banners = '/api/v1/banners';

  // ── Order / Payment ─────────────────────────────────────────────────────────
  static const String checkoutBooking = '/api/v1/booking/checkout';
  static const String createPayment   = '/api/v1/payment';
  static const String validatePayment = '/api/v1/payment/validate-payment';
  static const String codGenerateOtp  = '/api/v1/payment/cod/generate-otp';

  // Order history list (GET /api/v1/booking?page=0&size=10)
  static const String orders = '/api/v1/booking';
  // Single order detail (GET /api/v1/booking/{bookingId})
  static String orderDetail(String bookingId) => '/api/v1/booking/$bookingId';
  // Receipt PDF download — 404 means not ready yet, retry after 2–3 s
  static String receiptDownload(String bookingId) =>
      '/api/v1/receipt/$bookingId/download';

  static String orderTracking(String bookingId) =>
      '/api/v1/booking/$bookingId/tracking';

  // ── Reviews ───────────────────────────────────────────────────────────────
  static String reviews(String productId) => '/api/v1/reviews/$productId';
  static String reviewSummary(String productId) =>
      '/api/v1/reviews/$productId/summary';
  static String reviewHelpful(String reviewId) =>
      '/api/v1/reviews/$reviewId/helpful';

  // ── Notification Preferences ─────────────────────────────────────────────
  static const String notificationPrefs = '/api/v1/users/notification-preferences';

  static String notificationPrefCategory(String category) =>
      '/api/v1/users/notification-preferences/$category';

  // ── Payment Methods ───────────────────────────────────────────────────────
  static const String paymentMethods = '/api/v1/users/payment-methods';
  static const String saveCard       = '/api/v1/users/payment-methods/card';
  static const String saveUpi        = '/api/v1/users/payment-methods/upi';

  static String deletePaymentMethod(String id) =>
      '/api/v1/users/payment-methods/$id';
}
