import 'package:flutter/material.dart';

class ServerApi {
  // Base URL for Product Client Service
  static const String productClientService = "http://192.168.1.105:8081";
  static const String OrderPaymentNotificationService = "http://192.168.1.105:8082";
  // Example endpoints (you can add more here)
  static const String login = "$productClientService/api/v1/auth/login";
  static const String verifyOtp = "$productClientService/api/v1/auth/verify";
  static const String GetUserDetails =
      "$productClientService/api/v1/user";
  static const String GetCategory =
      '$productClientService/api/v1/product/category';
  static const String GetCategoryByLevel =
      '$productClientService/api/v1/product/categorylevelwise';
  static const String GetSectionOfCategory =
      '$productClientService/api/v1/sections/For You';
      
  static const String getProducts = "$productClientService/products";
  static const String getProductDetail = "$productClientService/api/v1/product";
  static const String searchProduct =
      "$productClientService/api/v1/product/search";
  static const String saveSearch = "$productClientService/api/v1/user/save";
  static const String recentSearchOfUser =
      "$productClientService/api/v1/user/last";
  static const String TrendingSearch =
      "$productClientService/api/v1/product/trending";
  static const String getBrands =
      "$productClientService/api/v1/brands/category";
  static const String getCart = "$productClientService/api/v1/cart/get-cart";
  static const String addItemToCart = "$productClientService/api/v1/cart/items";
  static const String updateItemQtyToCart =
      "$productClientService/api/v1/cart/items";
  static const String removeItemFromCart =
      "$productClientService/api/v1/cart/items";
  static const String addAddress =
      "$productClientService/api/v1/user/add-address";
  static const String makeaddressdefault =
      "$productClientService/api/v1/user/set-default";
  static const String cartCoupon =
      "$productClientService/api/v1/cart/coupons";
  static const String ApplyCartCoupon =
      "$productClientService/api/v1/cart/coupons";
  static const String createPayment=     "$OrderPaymentNotificationService/api/v1/payment"; 
  static const String checkoutBooking = "$OrderPaymentNotificationService/api/v1/booking/checkout";
  static const String validatePayment = "$OrderPaymentNotificationService/api/v1/payment/validate-payment";
}
