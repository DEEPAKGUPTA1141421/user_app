// Forwarding shim — all endpoints now live in core/api/api_endpoints.dart.
// Keep this file so any widget/screen that still imports it compiles without changes.
import '../core/api/api_endpoints.dart';

@Deprecated('Import ApiEndpoints from core/api/api_endpoints.dart instead.')
class ServerApi {
  ServerApi._();

  static const String productClientService = ApiEndpoints.productServiceBase;
  static const String OrderPaymentNotificationService = ApiEndpoints.orderServiceBase;

  static const String login       = ApiEndpoints.login;
  static const String verifyOtp   = ApiEndpoints.verifyOtp;
  static const String GetUserDetails   = ApiEndpoints.userDetails;
  static const String GetCategoryByLevel = ApiEndpoints.categoryByLevel;
  static String GetSectionOfCategory = ApiEndpoints.sectionsForCategory('For You');
  static const String getProductDetail = ApiEndpoints.productDetail;
  static const String searchProduct    = ApiEndpoints.searchProducts;
  static const String saveSearch       = ApiEndpoints.saveSearchItem;
  static const String recentSearchOfUser = ApiEndpoints.recentSearches;
  static const String TrendingSearch   = ApiEndpoints.trendingSearch;
  static const String getBrands        = '/api/v1/brands/category';
  static const String getCart          = ApiEndpoints.cart;
  static const String addItemToCart    = ApiEndpoints.cartItems;
  static const String updateItemQtyToCart = ApiEndpoints.cartItems;
  static const String removeItemFromCart  = ApiEndpoints.cartItems;
  static const String addAddress       = ApiEndpoints.addAddress;
  static const String makeaddressdefault = ApiEndpoints.setDefaultAddr;
  static const String cartCoupon       = ApiEndpoints.cartCoupons;
  static const String ApplyCartCoupon  = ApiEndpoints.cartCoupons;
  static const String createPayment    = ApiEndpoints.createPayment;
  static const String checkoutBooking  = ApiEndpoints.checkoutBooking;
  static const String validatePayment  = ApiEndpoints.validatePayment;
}
