import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MpesaService {
  // Use your backend URL. If testing on Android emulator, use 10.0.2.2 instead of localhost.
  static const String _baseUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

  Future<Map<String, dynamic>> initiateStkPush({
    required String phone,
    required double amount,
  }) async {
    final url = Uri.parse('$_baseUrl/stkpush');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'amount': amount.toInt(), // M-Pesa expects integers for STK Push in sandbox sometimes
        }),
      );

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
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
