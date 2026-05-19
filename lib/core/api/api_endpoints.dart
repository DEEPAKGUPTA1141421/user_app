/// Central registry of all API endpoints.
///
/// Base URLs are kept here as the single source of truth.
/// TODO: Replace hardcoded IPs with environment-specific config before production.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base URLs ──────────────────────────────────────────────────────────────
  static const String productServiceBase  = 'http://192.168.1.116:8081';
  static const String orderServiceBase    = 'http://192.168.1.116:8082';
  static const String chatServiceBase     = 'http://192.168.1.116:8082';
  static const String deliveryServiceBase = 'http://192.168.1.116:8083';

  // ── SendBird App ID (set to your SendBird Application ID) ─────────────────
  static const String sendbirdAppId = 'F125EC09-A15E-4141-9C1F-3B1BD2A8A309';

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
  static String categoryBrowse(String superCategoryId) =>
      '/api/v1/product/category/browse?superCategoryId=$superCategoryId';
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
  static const String buyNow           = '/api/v1/buy-now';
  static const String checkoutBooking  = '/api/v1/booking/checkout';
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

  // ── Reco / Similarity / Tracking ──────────────────────────────────────────
  static const String trackInteraction = '/api/v1/track/interaction';
  static const String recoForYou       = '/api/v1/reco/for-you';
  static const String recoFeedback     = '/api/v1/reco/feedback';

  static String similarProducts(String productId) =>
      '/api/v1/product/$productId/similar';

  // ── Shops ─────────────────────────────────────────────────────────────────
  // Nearby shop listing  → GET /api/v1/shops/nearby?userLat=&userLng=&...
  static const String shopsNearby  = '/api/v1/shops/nearby';
  // Text search          → GET /api/v1/shops/search?q=&userLat=&userLng=&...
  static const String shopsSearch  = '/api/v1/shops/search';
  // Autocomplete         → GET /api/v1/shops/suggestions?q=<prefix>
  static const String shopsSuggest = '/api/v1/shops/suggestions';
  // Shop detail          → GET /api/v1/shops/{id}?userLat=&userLng=
  static String shopDetail(String id) => '/api/v1/shops/$id';
  // Storefront sections  → GET /api/v1/shops/{id}/storefront
  // Returns backend-ordered sections: BUY_AGAIN first, then CATEGORY groups
  static String shopStorefront(String id) => '/api/v1/shops/$id/storefront';
  // Products inside shop → GET /api/v1/search/results?sellerId=<id>&keyword=&...
  // Reuses the existing ES search endpoint — sellerId param scopes to one shop.
  static const String searchResults = '/api/v1/search/results';
  // Follow / Unfollow a shop → POST/DELETE /api/v1/shops/{id}/follow
  static String shopFollow(String id)   => '/api/v1/shops/$id/follow';
  static String shopUnfollow(String id) => '/api/v1/shops/$id/follow';

  // ── Returns & Refunds ─────────────────────────────────────────────────────
  static const String returns = '/api/v1/returns';
  static String returnDetail(String id) => '/api/v1/returns/$id';

  // ── Wallet ────────────────────────────────────────────────────────────────
  static const String wallet             = '/api/v1/wallet';
  static const String walletTransactions = '/api/v1/wallet/transactions';
  static String walletPay(String bookingId) => '/api/v1/wallet/pay/$bookingId';

  // ── Chat / Support ────────────────────────────────────────────────────────
  // POST /api/chat/token → { sendbirdUserId, sessionToken, expiresAt }
  static const String chatToken = '/api/chat/token';
  // POST /api/chat/support/ticket → { channelUrl, ticketId }
  static const String chatSupportTicket = '/api/chat/support/ticket';

  // ── Rider Route & Location (DeliveryInventoryService :8083) ──────────────
  static String riderTodayRoute(String riderId) =>
      '/api/v1/riders/$riderId/route/today';

  static String riderAssignmentStatus(String riderId, String assignmentId) =>
      '/api/v1/riders/$riderId/assignments/$assignmentId/status';

  static String riderLocation(String riderId) =>
      '/api/v1/riders/$riderId/location';

  // ── Zone Eligibility (DeliveryInventoryService :8083) ─────────────────────
  static String zoneCheck(double lat, double lng, {String type = 'USER'}) =>
      '/api/v1/zones/check?lat=$lat&lng=$lng&type=$type';

  // ── FCM Device Token ──────────────────────────────────────────────────────
  static const String fcmToken = '/api/v1/user/fcm-token';

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
