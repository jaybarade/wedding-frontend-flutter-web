import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  bool get isAuthenticated =>
      _user != null && _user!.token!.isNotEmpty;

  AuthProvider() {
    _loadUser();
  }

  /// 🔥 LOAD USER FROM STORAGE
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (userStr != null) {
      _user = User.fromJson(jsonDecode(userStr));
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 🔥 LOGIN
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService();

      final response = await api.post(ApiConfig.loginUrl, {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _user = User(
          email: email,
          token: data['token'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed';
      }
    } catch (e) {
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 🔥 LOGOUT
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }
}