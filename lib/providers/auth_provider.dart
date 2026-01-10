import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _successMessage;
  
  // Untuk menyimpan credentials saat perlu kirim ulang email
  String? _pendingEmail;
  String? _pendingPassword;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get pendingEmail => _pendingEmail;

  AuthProvider() {
    _initialize();
  }

  /// Initialize auth state
  Future<void> _initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      fb.User? firebaseUser = _authService.currentUser;
      if (firebaseUser != null && firebaseUser.emailVerified) {
        _currentUser = await _getUserData(firebaseUser);
      }
    } catch (e) {
      print('Error initializing: $e');
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((fb.User? user) async {
      if (user != null && user.emailVerified) {
        _currentUser = await _getUserData(user);
      } else {
        _currentUser = null;
      }
      _isInitializing = false;
      notifyListeners();
    });

    _isInitializing = false;
    notifyListeners();
  }

  /// Get user data dari Firebase Auth dan Firestore
  Future<User?> _getUserData(fb.User firebaseUser) async {
    try {
      Map<String, dynamic>? userData = await _authService.getUserData(
        firebaseUser.uid,
      );

      if (userData != null) {
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          fullName: userData['fullName'] ?? firebaseUser.displayName ?? 'User',
          nim: userData['nim'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? firebaseUser.phoneNumber ?? '',
          faculty: userData['faculty'] ?? '',
          photoUrl: firebaseUser.photoURL ?? userData['photoUrl'] ?? '',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
        );
      } else {
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          fullName: firebaseUser.displayName ?? 'User',
          nim: '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          faculty: '',
          photoUrl: firebaseUser.photoURL ?? '',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
        );
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Login - hanya bisa jika email sudah diverifikasi
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        fb.User? firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          _currentUser = await _getUserData(firebaseUser);
        }
        _successMessage = result['message'];
      } else {
        _errorMessage = result['message'];
        
        // Simpan email untuk keperluan resend verification
        if (result['needsVerification'] == true) {
          _pendingEmail = email;
          _pendingPassword = password;
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
        'needsVerification': false,
      };
    }
  }

  /// Register - akan mengirim email verifikasi
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String nim,
    required String phoneNumber,
    required String faculty,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        nim: nim,
        phoneNumber: phoneNumber,
        faculty: faculty,
      );

      if (result['success'] == true) {
        _successMessage = result['message'];
        _pendingEmail = email;
        _pendingPassword = password;
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  /// Kirim ulang email verifikasi
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    if (_pendingEmail == null || _pendingPassword == null) {
      return {
        'success': false,
        'message': 'Tidak ada email yang pending. Silakan login ulang.',
      };
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.resendVerificationEmail(
        _pendingEmail!,
        _pendingPassword!,
      );

      if (result['success'] == true) {
        _successMessage = result['message'];
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  /// Check status verifikasi email
  Future<bool> checkEmailVerification() async {
    if (_pendingEmail == null || _pendingPassword == null) {
      return false;
    }

    try {
      return await _authService.checkEmailVerified(
        _pendingEmail!,
        _pendingPassword!,
      );
    } catch (e) {
      print('Error checking verification: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _errorMessage = null;
      _successMessage = null;
      _pendingEmail = null;
      _pendingPassword = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendPasswordResetEmail(email);
      
      if (result['success'] == true) {
        _successMessage = result['message'];
      } else {
        _errorMessage = result['message'];
      }
      
      _isLoading = false;
      notifyListeners();
      return result['success'] == true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear error message (deprecated - use clearMessages)
  void clearErrorMessage() {
    clearMessages();
  }

  /// Store pending credentials for verification
  void setPendingCredentials(String email, String password) {
    _pendingEmail = email;
    _pendingPassword = password;
  }

  /// Clear pending credentials
  void clearPendingCredentials() {
    _pendingEmail = null;
    _pendingPassword = null;
  }
}
