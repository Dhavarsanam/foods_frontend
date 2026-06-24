import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://foods-backend-5o8e.onrender.com/api';
  static const String _rootUrl = 'https://foods-backend-5o8e.onrender.com';

  // ─── Wake up server (call this in main.dart or splash screen) ──────────────
  static Future<void> warmUp() async {
    try {
      print('⏳ Waking up server...');
      await http
          .get(Uri.parse(_rootUrl))
          .timeout(const Duration(seconds: 60)); // cold start = 60s வரை எடுக்கும்
      print('✅ Server is awake!');
    } catch (_) {}
  }

  // ─── Send OTP ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await http
          .post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      )
          .timeout(const Duration(seconds: 60)); // ✅ 60s — cold start handle

      if (res.body.trim().startsWith('<')) {
        return {'success': false, 'message': 'Server error. Try again.'};
      }

      final data = jsonDecode(res.body);
      return data['success'] == true
          ? {'success': true}
          : {'success': false, 'message': data['message'] ?? 'OTP அனுப்ப முடியவில்லை'};

    } on TimeoutException {
      return {
        'success': false,
        'message': 'Server தூங்குது 😴 10 seconds கழித்து மீண்டும் try பண்ணவும்',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─── Verify OTP ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final res = await http
          .post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      )
          .timeout(const Duration(seconds: 60));

      if (res.body.trim().startsWith('<')) {
        return {'success': false, 'message': 'Server error. Try again.'};
      }

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'தவறான OTP'};

    } on TimeoutException {
      return {'success': false, 'message': 'Server timeout. மீண்டும் try பண்ணவும்.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─── Auth headers ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Save bill ──────────────────────────────────────────────────────────────
  static Future<bool> saveBill(Map<String, dynamic> billData) async {
    try {
      final headers = await _authHeaders;
      final res = await http
          .post(
        Uri.parse('$baseUrl/bills'),
        headers: headers,
        body: jsonEncode(billData),
      )
          .timeout(const Duration(seconds: 30));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('saveBill error: $e');
      return false;
    }
  }

  // ─── Fetch menu ─────────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchMenu() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/menu'))
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } catch (e) {
      print('fetchMenu error: $e');
      return [];
    }
  }
}