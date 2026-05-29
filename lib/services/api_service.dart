import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://foods-backend-5o8e.onrender.com/api';

  // OTP அனுப்பு
  static Future<bool> sendOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 60));
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // OTP verify பண்ணி token save பண்ணு
  static Future<bool> verifyOtp(String phone, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      ).timeout(const Duration(seconds: 60));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Bill save
  static Future<void> saveBill(Map<String, dynamic> billData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await http.post(
        Uri.parse('$baseUrl/bills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(billData),
      ).timeout(const Duration(seconds: 60));
    } catch (e) {}
  }

  // Menu fetch
  static Future<List<dynamic>> fetchMenu() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/menu'),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(res.body);
    } catch (e) {
      return [];
    }
  }
}