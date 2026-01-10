import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Domain email yang diizinkan untuk registrasi
  static const List<String> allowedEmailDomains = [
    'gmail.com',
    'yahoo.com',
    'yahoo.co.id',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'icloud.com',
    // Tambahkan domain universitas jika perlu
  ];

  /// Validasi format email dengan regex pattern yang ketat
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    return emailRegex.hasMatch(email);
  }

  /// Validasi domain email yang diizinkan
  bool isAllowedEmailDomain(String email) {
    if (!email.contains('@')) return false;
    final domain = email.split('@').last.toLowerCase();
    return allowedEmailDomains.contains(domain);
  }

  /// Mendapatkan list domain yang diizinkan sebagai string
  String getAllowedDomainsString() {
    return allowedEmailDomains.map((d) => '@$d').join(', ');
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  // Check if current user email is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  // Stream auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Register user dengan email dan password
  /// Email verification akan dikirim otomatis setelah registrasi
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String nim,
    required String phoneNumber,
    required String faculty,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        return {
          'success': false,
          'message': 'Email, password, dan nama tidak boleh kosong',
        };
      }

      // Validasi format email
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message':
              'Format email tidak valid. Gunakan email yang benar (contoh: nama@gmail.com)',
        };
      }

      // Validasi domain email
      if (!isAllowedEmailDomain(email)) {
        return {
          'success': false,
          'message':
              'Gunakan email dari provider yang valid (Gmail, Yahoo, Outlook, dll). Domain yang didukung: ${getAllowedDomainsString()}',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password minimal 6 karakter',
        };
      }

      print('Starting registration for email: $email');

      // Create user di Firebase Auth
      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        return {
          'success': false,
          'message': _getErrorMessage(e.code),
        };
      }

      User? firebaseUser = userCredential.user;
      print('User created: ${firebaseUser?.uid}');

      if (firebaseUser != null) {
        // Update display name
        await firebaseUser.updateDisplayName(fullName);

        // Simpan data user ke Firestore
        Map<String, dynamic> userData = {
          'id': firebaseUser.uid,
          'email': email,
          'fullName': fullName,
          'nim': nim,
          'phoneNumber': phoneNumber,
          'faculty': faculty,
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
        };

        try {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(userData);
          print('User data saved to Firestore successfully');
        } catch (e) {
          print('Error saving to Firestore: $e');
          // Continue anyway - data bisa disimpan nanti
        }

        // Kirim email verification
        try {
          await firebaseUser.sendEmailVerification();
          print('Verification email sent to: $email');
        } catch (e) {
          print('Error sending verification email: $e');
          return {
            'success': false,
            'message': 'Gagal mengirim email verifikasi. Coba lagi nanti.',
          };
        }

        // Logout setelah registrasi - user harus verifikasi dulu baru bisa login
        await _firebaseAuth.signOut();

        return {
          'success': true,
          'message':
              'Registrasi berhasil! Email verifikasi telah dikirim ke $email. Silakan cek inbox Gmail Anda (termasuk folder Spam).',
          'email': email,
        };
      }

      return {
        'success': false,
        'message': 'Gagal membuat akun. Silakan coba lagi.',
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      print('Register error: $e');
      return {
        'success': false,
        'message': 'Registrasi gagal: ${e.toString()}',
      };
    }
  }

  /// Login dengan email dan password
  /// HANYA bisa login jika email sudah diverifikasi
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email dan password tidak boleh kosong',
          'needsVerification': false,
        };
      }

      // Validasi format email
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Format email tidak valid',
          'needsVerification': false,
        };
      }

      print('Starting login for email: $email');

      // Sign in ke Firebase
      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        return {
          'success': false,
          'message': _getErrorMessage(e.code),
          'needsVerification': false,
        };
      }

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Reload user untuk mendapatkan status verifikasi terbaru
        await firebaseUser.reload();
        firebaseUser = _firebaseAuth.currentUser;

        // CEK WAJIB: Email harus sudah diverifikasi
        if (firebaseUser != null && !firebaseUser.emailVerified) {
          print('Email belum diverifikasi: ${firebaseUser.email}');

          // LOGOUT - tidak boleh login jika belum verifikasi
          await _firebaseAuth.signOut();

          return {
            'success': false,
            'message':
                'Email Anda belum diverifikasi.\n\nSilakan cek inbox Gmail Anda (termasuk folder Spam) dan klik link verifikasi terlebih dahulu.',
            'needsVerification': true,
            'email': email,
          };
        }

        // Update status verifikasi di Firestore
        try {
          await _firestore.collection('users').doc(firebaseUser!.uid).update({
            'isEmailVerified': true,
          });
        } catch (e) {
          print('Error updating verification status: $e');
        }

        print('Login berhasil: ${firebaseUser?.email}');
        return {
          'success': true,
          'message': 'Login berhasil!',
          'needsVerification': false,
        };
      }

      return {
        'success': false,
        'message': 'Login gagal. Silakan coba lagi.',
        'needsVerification': false,
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
        'needsVerification': false,
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Login gagal: ${e.toString()}',
        'needsVerification': false,
      };
    }
  }

  /// Kirim ulang email verification
  Future<Map<String, dynamic>> resendVerificationEmail(String email, String password) async {
    try {
      // Login dulu untuk mendapatkan user
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _firebaseAuth.signOut(); // Logout lagi setelah kirim email
        
        return {
          'success': true,
          'message': 'Email verifikasi telah dikirim ulang ke $email. Silakan cek inbox Gmail Anda.',
        };
      } else if (user != null && user.emailVerified) {
        await _firebaseAuth.signOut();
        return {
          'success': true,
          'message': 'Email Anda sudah terverifikasi. Silakan login.',
        };
      }

      return {
        'success': false,
        'message': 'Gagal mengirim email verifikasi.',
      };
    } catch (e) {
      print('Error resending verification: $e');
      return {
        'success': false,
        'message': 'Gagal mengirim email: ${e.toString()}',
      };
    }
  }

  /// Check apakah email sudah diverifikasi (untuk polling)
  Future<bool> checkEmailVerified(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.reload();
        bool verified = _firebaseAuth.currentUser?.emailVerified ?? false;
        await _firebaseAuth.signOut();
        return verified;
      }
      return false;
    } catch (e) {
      print('Error checking verification: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Format email tidak valid',
        };
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Email reset password telah dikirim ke $email',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengirim email: ${e.toString()}',
      };
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (e) {
      print('Reload user error: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      print('User logged out');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }

  /// Get user data dari Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Cek jaringan Anda.';
      case 'user-disabled':
        return 'Akun Anda telah dinonaktifkan. Hubungi admin.';
      default:
        return 'Terjadi kesalahan: $errorCode';
    }
  }
}
