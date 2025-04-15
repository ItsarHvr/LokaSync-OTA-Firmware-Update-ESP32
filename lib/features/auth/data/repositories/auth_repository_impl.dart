import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lokasync/features/auth/data/models/user_model.dart';
import 'package:lokasync/features/auth/domain/entities/user_entity.dart';
import 'package:lokasync/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoriesImpl implements AuthRepositories {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoriesImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) 
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ----------------------
  // Metode Status Login
  // ----------------------

  @override
  Future<bool> isUserLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  FirebaseUserEntity? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  // ----------------------
  // Metode Autentikasi
  // ----------------------

  @override
  Future<FirebaseUserEntity?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Opsional: Check if email is verified
        if (!userCredential.user!.emailVerified) {
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Silakan verifikasi email Anda sebelum login.',
          );
        }
        
        return UserModel.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<FirebaseUserEntity?> signInWithCredential(AuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return UserModel.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<FirebaseUserEntity?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Jika user membatalkan proses signin
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return signInWithCredential(credential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Google Sign In failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    // Sign out dari Firebase
    await _firebaseAuth.signOut();
    
    // Sign out dari Google jika sedang login
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
  }

  // ----------------------
  // Metode Registrasi
  // ----------------------

  @override
  Future<FirebaseUserEntity?> registerWithEmailAndPassword(
      String email, String password, String fullName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update nama pengguna
        await userCredential.user!.updateDisplayName(fullName);
        
        // Reload user untuk mendapatkan data yang sudah diupdate
        await userCredential.user!.reload();
        
        // Ambil user baru dengan data yang sudah diupdate
        final updatedUser = _firebaseAuth.currentUser;
        
        // Kirim email verifikasi
        await sendEmailVerification();
        
        return UserModel.fromFirebaseUser(updatedUser!);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ----------------------
  // Metode Manajemen Akun
  // ----------------------

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Tidak ada pengguna yang sedang login.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<bool> reauthenticateUser(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && user.email != null) {
        // Buat credential baru
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        
        // Reautentikasi
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } on FirebaseAuthException {
      return false;
    }
  }

  // ----------------------
  // Metode Manajemen Profil
  // ----------------------

  @override
  Future<FirebaseUserEntity?> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        
        // Reload user untuk mendapatkan data baru
        await user.reload();
        
        // Ambil user yang sudah diupdate
        final updatedUser = _firebaseAuth.currentUser;
        return UserModel.fromFirebaseUser(updatedUser!);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Tidak ada pengguna yang sedang login.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> updateEmail(String newEmail, {required String password}) async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user != null && user.email != null) {
        // Create credential and re-authenticate first (always required for email change)
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        
        // Re-authenticate
        await user.reauthenticateWithCredential(credential);
        
        // Use verifyBeforeUpdateEmail instead of deprecated updateEmail
        await user.verifyBeforeUpdateEmail(newEmail);
        
        // Reload user to get updated data
        await user.reload();
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Tidak ada pengguna yang sedang login.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ----------------------
  // Metode Verifikasi Email
  // ----------------------

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Tidak ada pengguna yang sedang login.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Reload user untuk mendapatkan status verifikasi terbaru
      await user.reload();
      return _firebaseAuth.currentUser!.emailVerified;
    }
    return false;
  }

  // ----------------------
  // Metode Biometric Auth
  // ----------------------

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      // Cek apakah hardware mendukung biometrik
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }
      
      // Cek apakah ada biometrik yang terdaftar
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Autentikasi untuk mengakses LokaSync',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      if (e.toString().contains(auth_error.notAvailable)) {
        throw Exception('Autentikasi biometrik tidak tersedia pada perangkat ini');
      } else if (e.toString().contains(auth_error.notEnrolled)) {
        throw Exception('Tidak ada biometrik yang terdaftar pada perangkat ini');
      }
      throw Exception('Autentikasi gagal: ${e.toString()}');
    }
  }
  
  @override
  Future<void> enableBiometricLogin(String email, String password) async {
    // Verifikasi kredensial terlebih dahulu
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Simpan kredensial secara aman
      await _secureStorage.write(key: 'biometric_email', value: email);
      await _secureStorage.write(key: 'biometric_password', value: password);
    } catch (e) {
      throw Exception('Gagal mengaktifkan login biometrik: ${e.toString()}');
    }
  }
  
  @override
  Future<FirebaseUserEntity?> signInWithBiometrics() async {
    try {
      // Autentikasi dengan biometrik
      final authenticated = await authenticateWithBiometrics();
      
      if (!authenticated) {
        return null;
      }
      
      // Ambil kredensial tersimpan
      final email = await _secureStorage.read(key: 'biometric_email');
      final password = await _secureStorage.read(key: 'biometric_password');
      
      if (email == null || password == null) {
        throw Exception('Login biometrik belum diatur');
      }
      
      // Login dengan kredensial tersimpan
      return await signInWithEmailAndPassword(email, password);
    } catch (e) {
      throw Exception('Sign in biometrik gagal: ${e.toString()}');
    }
  }

  @override
  Future<bool> isBiometricLoginEnabled() async {
    try {
      // Check if biometric credentials are stored
      final hasEmail = await _secureStorage.read(key: 'biometric_email') != null;
      final hasPassword = await _secureStorage.read(key: 'biometric_password') != null;
      
      // Only return true if both email and password are stored
      return hasEmail && hasPassword;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> disableBiometricLogin() async {
    try {
      // Delete all stored biometric credentials
      await _secureStorage.delete(key: 'biometric_email');
      await _secureStorage.delete(key: 'biometric_password');
    } catch (e) {
      throw Exception('Gagal menonaktifkan login biometrik: ${e.toString()}');
    }
  }

  // ----------------------
  // Helper Methods
  // ----------------------

  // Metode helper untuk memetakan Firebase User ke Entity kita
  // FirebaseUserEntity _mapFirebaseUserToEntity(User user) {
  //   return UserModel.fromFirebaseUser(user);
  // }
}