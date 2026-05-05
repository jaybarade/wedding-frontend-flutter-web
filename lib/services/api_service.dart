import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    print('GET Request: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    print('Response [${response.statusCode}]: ${response.body}');
    return response;
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    print('POST Request: $url');
    print('Body: ${jsonEncode(body)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );
      print('Response [${response.statusCode}]: ${response.body}');
      return response;
    } catch (e) {
      print('POST Exception: $e');
      rethrow;
    }
  }

  // Generic Multipart request helper
  Future<http.MultipartRequest> createMultipartRequest(String method, String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    final request = http.MultipartRequest(
      method,
      Uri.parse(url),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }
}
