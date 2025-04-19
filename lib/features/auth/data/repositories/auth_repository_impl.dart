import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lokasync/features/auth/data/models/user_model.dart';
import 'package:lokasync/features/auth/domain/entities/user_entity.dart';
import 'package:lokasync/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoriesImpl implements AuthRepositories {
  final FirebaseAuth _firebaseAuth;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoriesImpl({
    FirebaseAuth? firebaseAuth,
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) 
      : _firebaseAuth = firebaseAuth ?? (
          () {
            // Create FirebaseAuth instance with non-persistent session
            FirebaseAuth instance = FirebaseAuth.instance;
            // Set persistence to NONE to require login after app restart
            instance.setPersistence(Persistence.NONE);
            return instance;
          }()
        ),
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
        
        // Update stored credentials if biometric login is enabled
        final isBiometricEnabled = await isBiometricLoginEnabled();
        if (isBiometricEnabled) {
          await _secureStorage.write(key: 'auth_email', value: email);
          await _secureStorage.write(key: 'auth_password', value: password);
          debugPrint('Stored credentials refreshed after successful login');
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
  Future<void> signOut() async {
    // Sign out dari Firebase
    await _firebaseAuth.signOut();
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
        
        // Check if biometric login is enabled
        final isBiometricEnabled = await isBiometricLoginEnabled();
        
        // If biometric login is enabled, update the stored password
        if (isBiometricEnabled && user.email != null) {
          debugPrint('BIOMETRIC DEBUG: Updating stored credentials after password change');
          await _secureStorage.write(key: 'auth_password', value: newPassword);
        }
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
        
        // Check if biometric login is enabled
        final isBiometricEnabled = await isBiometricLoginEnabled();
        
        // If biometric login is enabled, update the stored email
        if (isBiometricEnabled) {
          debugPrint('BIOMETRIC DEBUG: Updating stored email after email change');
          await _secureStorage.write(key: 'auth_email', value: newEmail);
          await _secureStorage.write(key: 'auth_password', value: password);
        }
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
      // Check if device supports biometrics
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      // Check if device supports PIN/Pattern/Password authentication
      final canAuthenticate = await _localAuth.isDeviceSupported();
      
      return canAuthenticateWithBiometrics && canAuthenticate;
    } catch (e) {
      debugPrint('Error checking biometric availability: ${e.toString()}');
      return false;
    }
  }
  
  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      // Authenticate with biometrics
      return await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        debugPrint('Biometric authentication is not available on this device.');
        throw Exception('Biometric authentication is not available on this device.');
      } else if (e.code == auth_error.notEnrolled) {
        debugPrint('No biometric enrolled on this device.');
        throw Exception('No biometric enrolled on this device.');
      } else {
        debugPrint('Error during biometric authentication: ${e.toString()}');
        throw Exception('Biometric authentication failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error during biometric authentication: ${e.toString()}');
      throw Exception('Biometric authentication failed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> enableBiometricLogin(String email, String password) async {
    try {
      debugPrint('BIOMETRIC DEBUG: Starting enableBiometricLogin with email: $email');
      
      // First verify biometric is available
      final biometricsAvailable = await isBiometricAvailable();
      debugPrint('BIOMETRIC DEBUG: Biometric available: $biometricsAvailable');
      
      if (!biometricsAvailable) {
        throw Exception('Biometric authentication is not available on this device.');
      }
      
      // Try to validate credentials before storing them
      try {
        debugPrint('BIOMETRIC DEBUG: Validating credentials before storing');
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user == null) {
          throw Exception('Failed to validate credentials');
        }
        debugPrint('BIOMETRIC DEBUG: Credentials validated successfully');
      } catch (e) {
        debugPrint('BIOMETRIC DEBUG: Credential validation error: ${e.toString()}');
        throw Exception('Invalid credentials provided for biometric login. Please try again with correct password.');
      }
      
      // Store credentials directly without biometric authentication
      await _secureStorage.write(key: 'auth_email', value: email);
      await _secureStorage.write(key: 'auth_password', value: password);
      await _secureStorage.write(key: 'biometric_login_enabled', value: 'true');
      
      debugPrint('BIOMETRIC DEBUG: Biometric login enabled successfully.');
    } catch (e) {
      debugPrint('BIOMETRIC DEBUG: Error enabling biometric login: ${e.toString()}');
      throw Exception('Failed to enable biometric login: ${e.toString()}');
    }
  }
  
  @override
  Future<void> disableBiometricLogin() async {
    try {
      debugPrint('BIOMETRIC DEBUG: Disabling biometric login');
      // Remove credentials from secure storage
      await _secureStorage.delete(key: 'auth_email');
      await _secureStorage.delete(key: 'auth_password');
      await _secureStorage.delete(key: 'biometric_login_enabled');
      
      debugPrint('BIOMETRIC DEBUG: Biometric login disabled successfully.');
    } catch (e) {
      debugPrint('BIOMETRIC DEBUG: Error disabling biometric login: ${e.toString()}');
      throw Exception('Failed to disable biometric login: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: 'biometric_login_enabled');
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error checking if biometric login is enabled: ${e.toString()}');
      return false;
    }
  }
  
  @override
  Future<FirebaseUserEntity?> signInWithBiometrics() async {
    try {
      // First authenticate with biometrics
      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        throw Exception('Biometric authentication failed or was canceled by the user.');
      }
      
      // Then retrieve stored credentials
      final email = await _secureStorage.read(key: 'auth_email');
      final password = await _secureStorage.read(key: 'auth_password');
      
      if (email == null || password == null) {
        throw Exception('No stored credentials found. Please login with email and password first.');
      }
      
      // Login with credentials
      final user = await signInWithEmailAndPassword(email, password);
      return user;
    } catch (e) {
      debugPrint('Error signing in with biometrics: ${e.toString()}');
      throw Exception('Failed to sign in with biometrics: ${e.toString()}');
    }
  }

  @override
  Future<FirebaseUserEntity?> signInWithStoredCredentials() async {
    try {
      // Retrieve stored credentials without biometric verification
      final email = await _secureStorage.read(key: 'auth_email');
      final password = await _secureStorage.read(key: 'auth_password');
      
      if (email == null || password == null) {
        throw Exception('No stored credentials found. Please login with email and password first.');
      }
      
      // Login with credentials
      try {
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user != null) {
          return UserModel.fromFirebaseUser(userCredential.user!);
        }
        return null;
      } on FirebaseAuthException catch (e) {
        // Handle invalid-credential specifically
        if (e.code == 'invalid-credential' || 
            e.code == 'user-not-found' ||
            e.code == 'wrong-password') {
          // Clear invalid credentials
          await disableBiometricLogin();
          throw Exception('Stored credentials are no longer valid. Please login again with email and password.');
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error signing in with stored credentials: ${e.toString()}');
      throw Exception('Failed to sign in with stored credentials: ${e.toString()}');
    }
  }
}