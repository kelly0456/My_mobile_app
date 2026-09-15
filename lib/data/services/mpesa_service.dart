import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MpesaService {
  // IMPORTANT: Replace this with your actual Render URL
  // Example: 'https://my-mpesa-backend.onrender.com'
  static const String _renderUrl = 'https://my-mobile-app-ebv6.onrender.com';

  Future<Map<String, dynamic>> initiateStkPush({
    required String phone,
    required double amount,
  }) async {
    // If we are in local development, use localhost/10.0.2.2, otherwise use Render
    String baseUrl = kDebugMode 
        ? (kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000')
        : _renderUrl;

    // Use Render URL if local testing is not possible
    final url = Uri.parse('$baseUrl/stkpush');

    debugPrint('M-Pesa: Initiating STK Push to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'amount': amount.toInt(),
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('M-Pesa: Status Code ${response.statusCode}');
      debugPrint('M-Pesa: Response ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'STK Push initiated successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'STK Push failed',
        };
      }
    } catch (e) {
      debugPrint('M-Pesa Error: $e');
      return {
        'success': false,
        'message': 'Unable to connect to payment server. Please ensure your backend is live.',
      };
    }
  }
}
