import 'package:flutter/material.dart';

class ServerApi {
  // Base URL for Product Client Service
  static const String productClientService =
      "https://productclientservice-1083680567660.asia-south1.run.app";

  // Example endpoints (you can add more here)
  static const String login = "$productClientService/api/v1/auth/login";
  static const String verifyOtp = "$productClientService/api/v1/auth/verify";
  static const String GetUserDetails =
      "$productClientService/api/v1/user/get-user";
  static const String GetCategory =
      '$productClientService/api/v1/product/category';
  static const String GetSectionOfCategory =
      '$productClientService//api/v1/sections/For You';
}
