import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _authError;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'ADMIN';
  String? get authError => _authError;

  Future<void> checkLoginStatus() async {
    final token = await _apiService.getAccessToken();

    if (token != null) {
      await _decodeAndSetUser(token);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    bool success = await _apiService.login(email, password);

    if (success) {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        await _decodeAndSetUser(token);
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      await _apiService.register(name: name, email: email, password: password);
      return true;
    } catch (e) {
      _authError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _decodeAndSetUser(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;

      final payload = parts[1];
      final String decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);
      final savedName = await _apiService.getSavedUserName();

      _currentUser = User(
        id: payloadMap['id'] ?? payloadMap['userId'] ?? 0, 
        name: payloadMap['name'] ?? savedName ?? 'Anggota LibraSys',
        email: payloadMap['email'] ?? 'email@tidak.disertakan.di.token',
        role: payloadMap['role'] ?? 'USER',
      );
    } catch (e) {
      _currentUser = null;
    }
  }
}