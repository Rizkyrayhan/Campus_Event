# Email Verification Setup - Campus Event

## Overview
Sistem ini sekarang mengharuskan user untuk:
1. ✅ **Mendaftar dengan email yang valid** - Format email divalidasi dengan ketat
2. ✅ **Menerima email verifikasi** - Email otomatis dikirim setelah registrasi
3. ✅ **Memverifikasi email terlebih dahulu** - User harus klik link verifikasi sebelum bisa login
4. ✅ **Melakukan login dengan email terverifikasi** - Sistem mengecek status verifikasi saat login

---

## Perubahan yang Dilakukan

### 1. **Email Format Validation** 
**File:** `lib/services/firebase_auth_service.dart`

Ditambahkan method `isValidEmail()` yang menggunakan regex pattern untuk validasi email:
```dart
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );
  return emailRegex.hasMatch(email);
}
```

Validasi ini dijalankan di:
- **Register**: Memastikan email format valid sebelum mendaftar
- **Login**: Memastikan email format valid sebelum login

### 2. **Registration Email Validation**
**File:** `lib/screens/auth/register_screen.dart`

Updated email validator di form dengan regex pattern yang sama untuk konsistensi.

**Error Message yang muncul jika email tidak valid:**
- "Gunakan email yang valid (contoh: nama@domain.com)"

### 3. **Email Verification Required for Login**
**File:** `lib/services/firebase_auth_service.dart` - `login()` method

Ditambahkan pengecekan email verification status:
```dart
if (!firebaseUser.emailVerified) {
  print('⚠️ WARNING: Email belum diverifikasi');
  // Sign out karena email belum verified
  await _firebaseAuth.signOut();
  throw Exception('Email Anda belum diverifikasi. Silakan cek email dan klik link verifikasi terlebih dahulu.');
}
```

**Behavior:**
- Jika user login dengan email yang belum diverifikasi → sign out otomatis
- Error message: "Email Anda belum diverifikasi. Silakan cek email dan klik link verifikasi terlebih dahulu."
- User dipaksa kembali ke login screen dan diminta untuk verifikasi email

### 4. **Email Verification Screen - Enhanced UX**
**File:** `lib/screens/auth/verify_email_screen.dart`

Ditambahkan:
- ⚠️ **Important Notice** box - Menekankan bahwa email harus diverifikasi sebelum login
- Instruksi yang lebih jelas: "✉️ Silakan cek inbox email Anda dan klik link verifikasi untuk mengaktifkan akun"
- Visual indicator yang lebih baik

---

## User Flow

### Registrasi Baru:
1. User mengisi form dengan email yang valid
2. Sistem validasi format email (regex)
3. Jika format valid → Lanjut ke registrasi
4. Jika format tidak valid → Tampilkan error "Gunakan email yang valid"
5. User membuat akun di Firebase Auth
6. Email verifikasi otomatis dikirim
7. **Redirect ke VerifyEmailScreen**
8. User diminta cek email dan klik link verifikasi
9. Sistem auto-check setiap 3 detik apakah email sudah diverifikasi
10. Ketika verified → Redirect ke Login Screen

### Login:
1. User input email dan password
2. Sistem validasi format email
3. User login ke Firebase
4. **Sistem cek: apakah email sudah diverifikasi?**
   - ✅ Jika SUDAH verified → Login berhasil
   - ❌ Jika BELUM verified → Sign out otomatis + Error message → Kembali ke login
5. User harus verifikasi email dulu

---

## Email Validation Pattern

Format email yang VALID:
- ✅ user@domain.com
- ✅ john.doe@company.co.uk
- ✅ first+last@example.org
- ✅ user123@test-domain.com

Format email yang TIDAK VALID:
- ❌ user@
- ❌ @domain.com
- ❌ user @domain.com
- ❌ user@domain
- ❌ userdomain.com (tanpa @)

---

## Testing

### Test Case 1: Register dengan Email Tidak Valid
1. Buka app → Register
2. Input email: `invalid-email`
3. Error: "Gunakan email yang valid (contoh: nama@domain.com)"
4. ❌ Tombol Daftar tidak bisa diklik sampai email valid

### Test Case 2: Register dengan Email Valid
1. Buka app → Register
2. Input email: `user@gmail.com` (dan data lainnya)
3. ✅ Tombol Daftar bisa diklik
4. Redirect ke VerifyEmailScreen
5. Email verifikasi dikirim ke `user@gmail.com`
6. User harus cek email dan klik link verifikasi

### Test Case 3: Login Sebelum Email Diverifikasi
1. Coba login dengan akun yang baru registered (belum verifikasi email)
2. Input email dan password dengan benar
3. Error: "Email Anda belum diverifikasi. Silakan cek email dan klik link verifikasi terlebih dahulu."
4. ❌ Login gagal, user tetap di login screen

### Test Case 4: Login Setelah Email Diverifikasi
1. Verifikasi email (klik link di email)
2. Login dengan email dan password yang sama
3. ✅ Login berhasil
4. Redirect ke Home Screen

---

## Important Notes

1. **Email verifikasi harus melalui Gmail** - User akan menerima email dari Firebase
2. **Link verifikasi berlaku 24 jam** - Jika user tidak klik dalam 24 jam, perlu request ulang
3. **Tombol "Kirim Ulang Email"** tersedia di VerifyEmailScreen dengan countdown 60 detik
4. **Auto-check verification** - Setiap 3 detik app cek apakah email sudah verified
5. **Security** - User tidak bisa login tanpa email verified, maka data lebih aman

---

## Troubleshooting

### Problem: Email tidak diterima
**Solusi:**
1. Tunggu beberapa menit
2. Cek folder Spam/Junk di Gmail
3. Klik "Kirim Ulang Email" di VerifyEmailScreen
4. Pastikan email address benar

### Problem: Link verifikasi sudah expired
**Solusi:**
1. Buka VerifyEmailScreen
2. Klik "Kirim Ulang Email" untuk mendapatkan link baru
3. Klik link baru di email

### Problem: Sudah klik link tapi app masih bilang belum verified
**Solusi:**
1. Tutup app sepenuhnya
2. Buka app lagi
3. App akan auto-check dan menemukan email sudah verified

