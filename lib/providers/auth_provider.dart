import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _userId;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  String? get token => _token;

  Future<void> login(String user, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.login(user, password);
      _isAuthenticated = true;
      _token = _apiService.token;
      _userId = _apiService.userId;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Intenta recuperar una sesión guardada en el dispositivo sin red.
  /// Devuelve true si había una sesión válida y quedó restaurada.
  Future<bool> tryRestoreSession() async {
    final restored = await _apiService.tryRestoreSession();
    if (restored) {
      _isAuthenticated = true;
      _token = _apiService.token;
      _userId = _apiService.userId;
      notifyListeners();
    }
    return restored;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _userId = null;
    _token = null;
    _error = null;
    notifyListeners();
  }
}
