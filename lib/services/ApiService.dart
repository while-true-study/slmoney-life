import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class ApiService {
  static const String baseUrl = 'https://your-api.com';

  static Future<Transaction> analyzeText(String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (res.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('AI 분석 실패');
    }
  }
}
