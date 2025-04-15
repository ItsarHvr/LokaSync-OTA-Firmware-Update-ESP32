import 'package:firebase_auth/firebase_auth.dart';
import 'package:lokasync/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lokasync/features/auth/domain/entities/user_entity.dart';


class AuthController {
  final AuthRepositoriesImpl _authRepository;
  
  AuthController({AuthRepositoriesImpl? authRepository}) 
      : _authRepository = authRepository ?? AuthRepositoriesImpl();
  
  // ----------------------
  // Metode Status Login
  // ----------------------
  
  /// Memeriksa apakah pengguna sedang login
  Future<bool> isUserLoggedIn() async {
    return await _authRepository.isUserLoggedIn();
  }
  
  /// Mendapatkan data pengguna yang sedang login
  FirebaseUserEntity? getCurrentUser() {
    return _authRepository.getCurrentUser();
  }
  
  // ----------------------
  // Metode Autentikasi
  // ----------------------
  
  /// Login dengan email dan password
  Future<FirebaseUserEntity?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _authRepository.signInWithEmailAndPassword(email, password);
    } on FirebaseAuthException {
      rethrow; // Re-throw to be caught by the UI
    } catch (e) {
      rethrow; // Re-throw to be caught by the UI
    }
  }

  /// Login dengan Google
  Future<FirebaseUserEntity?> signInWithGoogle() async {
    try {
      return await _authRepository.signInWithGoogle();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Logout dari semua provider
  Future<void> signOut() async {
    await _authRepository.signOut();
  }
  
  // ----------------------
  // Metode Registrasi
  // ----------------------
  
  /// Mendaftarkan pengguna baru dengan email dan password
  Future<FirebaseUserEntity?> registerWithEmailAndPassword(
      String email, String password, String fullName) async {
    try {
      return await _authRepository.registerWithEmailAndPassword(
        email, password, fullName);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  // ----------------------
  // Metode Manajemen Akun
  // ----------------------
  
  /// Mengirim email untuk reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Menghapus akun pengguna
  Future<void> deleteAccount() async {
    try {
      await _authRepository.deleteAccount();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Re-autentikasi pengguna (diperlukan untuk operasi sensitif)
  Future<bool> reauthenticateUser(String password) async {
    try {
      return await _authRepository.reauthenticateUser(password);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  // ----------------------
  // Metode Manajemen Profil
  // ----------------------
  
  /// Memperbarui profil pengguna (nama dan foto)
  Future<FirebaseUserEntity?> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      return await _authRepository.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Mengubah password pengguna
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authRepository.updatePassword(newPassword);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Mengubah email pengguna
  Future<void> updateEmail(String newEmail, {required String password}) async {
    try {
      await _authRepository.updateEmail(newEmail, password: password);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  // ----------------------
  // Metode Verifikasi Email
  // ----------------------
  
  /// Mengirim email verifikasi
  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Memeriksa status verifikasi email
  Future<bool> isEmailVerified() async {
    try {
      return await _authRepository.isEmailVerified();
    } catch (e) {
      rethrow;
    }
  }
  
  // ----------------------
  // Metode Biometric Auth
  // ----------------------
  
  /// Memeriksa ketersediaan biometrik pada perangkat
  Future<bool> isBiometricAvailable() async {
    try {
      return await _authRepository.isBiometricAvailable();
    } catch (e) {
      return false; // Asumsikan tidak tersedia jika ada error
    }
  }
  
  /// Melakukan autentikasi biometrik
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _authRepository.authenticateWithBiometrics();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Mengaktifkan login biometrik
  Future<void> enableBiometricLogin(String email, String password) async {
    try {
      await _authRepository.enableBiometricLogin(email, password);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Menonaktifkan login biometrik
  Future<void> disableBiometricLogin() async {
    try {
      await _authRepository.disableBiometricLogin();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Login dengan biometrik
  Future<FirebaseUserEntity?> signInWithBiometrics() async {
    try {
      return await _authRepository.signInWithBiometrics();
    } catch (e) {
      rethrow;
    }
  }

  /// Cek apakah login biometrik sudah diaktifkan
  Future<bool> isBiometricLoginEnabled() async {
    try {
      return await _authRepository.isBiometricLoginEnabled();
    } catch (e) {
      return false;
    }
  }
  
  // ----------------------
  // Utility Methods
  // ----------------------
  
  /// Memeriksa apakah string adalah email valid
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Memeriksa kekuatan password
  Map<String, dynamic> checkPasswordStrength(String password) {
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;
    
    // Perubahan: menghapus perhitungan skor dan level kekuatan password
    // Hanya memeriksa apakah password memenuhi semua kriteria
    bool isStrongPassword = hasMinLength && 
                            hasUppercase && 
                            hasLowercase && 
                            hasDigits && 
                            hasSpecialCharacters;
    
    // Perubahan: buat pesan yang lebih spesifik tentang apa yang masih kurang
    String message = '';
    if (!isStrongPassword) {
      List<String> missingRequirements = [];
      
      if (!hasMinLength) {
        missingRequirements.add("minimal 8 karakter");
      }
      if (!hasUppercase) {
        missingRequirements.add("huruf besar");
      }
      if (!hasLowercase) {
        missingRequirements.add("huruf kecil");
      }
      if (!hasDigits) {
        missingRequirements.add("angka");
      }
      if (!hasSpecialCharacters) {
        missingRequirements.add("simbol");
      }
      
      if (missingRequirements.isNotEmpty) {
        message = "Password butuh kombinasi ${missingRequirements.join(', ')}";
      }
    }
    
    return {
      'isStrong': isStrongPassword,
      'message': message,
      'hasUppercase': hasUppercase,
      'hasLowercase': hasLowercase,
      'hasDigits': hasDigits,
      'hasSpecialCharacters': hasSpecialCharacters,
      'hasMinLength': hasMinLength,
    };
  }
}