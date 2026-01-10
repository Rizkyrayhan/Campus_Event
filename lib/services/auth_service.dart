import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  late SharedPreferences _prefs;
  User? _currentUser;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> login(String email, String password) async {
    try {
      if (email.isEmpty || password.length < 6) return false;

      // Simulasi login - ganti dengan API call sebenarnya
      await Future.delayed(const Duration(milliseconds: 1000));

      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: email.split('@')[0],
        nim: '12345678',
        phoneNumber: '08123456789',
        faculty: 'Teknik Informatika',
        photoUrl: '',
        createdAt: DateTime.now(),
        isEmailVerified: true,
      );

      await _saveUserData(_currentUser!);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String nim,
    required String phoneNumber,
    required String faculty,
  }) async {
    try {
      if (email.isEmpty || password.length < 6 || fullName.isEmpty) {
        return false;
      }

      // Simulasi registrasi - ganti dengan API call sebenarnya
      await Future.delayed(const Duration(milliseconds: 1000));

      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        nim: nim,
        phoneNumber: phoneNumber,
        faculty: faculty,
        photoUrl: '',
        createdAt: DateTime.now(),
        isEmailVerified: false,
      );

      await _saveUserData(_currentUser!);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs.clear();
  }

  Future<void> _saveUserData(User user) async {
    await _prefs.setString(AppConstants.userIdKey, user.id);
    await _prefs.setString(AppConstants.userEmailKey, user.email);
    await _prefs.setString(AppConstants.userNameKey, user.fullName);
    await _prefs.setString(AppConstants.userPhoneKey, user.phoneNumber);
    await _prefs.setString(AppConstants.userFacultyKey, user.faculty);
    await _prefs.setString(AppConstants.userNimKey, user.nim);
    await _prefs.setBool(AppConstants.isLoggedInKey, true);
  }

  User? getCurrentUser() {
    if (_currentUser == null) {
      final userId = _prefs.getString(AppConstants.userIdKey);
      if (userId != null) {
        _currentUser = User(
          id: userId,
          email: _prefs.getString(AppConstants.userEmailKey) ?? '',
          fullName: _prefs.getString(AppConstants.userNameKey) ?? '',
          nim: _prefs.getString(AppConstants.userNimKey) ?? '',
          phoneNumber: _prefs.getString(AppConstants.userPhoneKey) ?? '',
          faculty: _prefs.getString(AppConstants.userFacultyKey) ?? '',
          photoUrl: '',
          createdAt: DateTime.now(),
        );
      }
    }
    return _currentUser;
  }

  bool isLoggedIn() {
    return _prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  Future<bool> updateProfile(User user) async {
    try {
      _currentUser = user;
      await _saveUserData(user);
      return true;
    } catch (e) {
      return false;
    }
  }
}