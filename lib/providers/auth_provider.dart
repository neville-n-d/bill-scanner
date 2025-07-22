import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../providers/bill_provider.dart'; // Added import for BillProvider

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _authService.isLoggedIn;

  // Initialize auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      _user = _authService.currentUser;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize authentication';
      print('Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required bool hasTerahiveEss,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        hasTerahiveEss: hasTerahiveEss,
        phone: phone,
      );

      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        if (result['errors'] != null) {
          _error = _formatErrors(result['errors']);
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        
        // Notify that login was successful (for other providers to react)
        _onLoginSuccess();
        
        // Call auth state change callback
        _onAuthStateChanged?.call(true);
        
        return true;
      } else {
        _error = result['message'];
        if (result['errors'] != null) {
          _error = _formatErrors(result['errors']);
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Callback for successful login (can be overridden by other providers)
  void _onLoginSuccess() {
    // This method can be extended to notify other providers
    print('✅ Login successful for user: ${_user?.email}');
  }

  // Set callback for auth state changes
  Function(bool)? _onAuthStateChanged;
  
  void setAuthStateCallback(Function(bool) callback) {
    _onAuthStateChanged = callback;
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
      // Call auth state change callback
      _onAuthStateChanged?.call(false);
    }
  }

  // Refresh user profile
  Future<bool> refreshProfile() async {
    if (!isLoggedIn) return false;

    try {
      final result = await _authService.getProfile();
      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to refresh profile: $e';
      notifyListeners();
      return false;
    }
  }

  // Update TeraHive ESS installation status
  Future<bool> updateHasTerahiveEss(bool value) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      // Call backend to update user profile
      final result = await _authService.updateTerahiveEssStatus(value);
      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update TeraHive status: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Format validation errors
  String _formatErrors(List<dynamic> errors) {
    if (errors.isEmpty) return 'Validation failed';
    
    return errors.map((error) {
      if (error is Map<String, dynamic>) {
        return error['msg'] ?? 'Invalid input';
      }
      return error.toString();
    }).join(', ');
  }
} 