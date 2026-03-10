import 'package:flutter/material.dart';

class ServerApi {
  // Base URL for Product Client Service
  static const String productClientService = "http://localhost:8080";
  //"https://productclientservice-549653694225.asia-south1.run.app";

  // Example endpoints (you can add more here)
  static const String login = "$productClientService/api/v1/auth/login";
  static const String verifyOtp = "$productClientService/api/v1/auth/verify";
  static const String GetUserDetails =
      "$productClientService/api/v1/user/get-user";
  static const String GetCategory =
      '$productClientService/api/v1/product/category';
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
}
