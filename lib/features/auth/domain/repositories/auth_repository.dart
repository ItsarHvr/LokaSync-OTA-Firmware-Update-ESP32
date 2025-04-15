import 'package:firebase_auth/firebase_auth.dart';
import 'package:lokasync/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepositories {
  // Metode cek status login
  Future<bool> isUserLoggedIn();
  
  // Metode autentikasi
  Future<FirebaseUserEntity?> signInWithEmailAndPassword(String email, String password);
  Future<FirebaseUserEntity?> signInWithCredential(AuthCredential credential);
  
  // Metode autentikasi sosial media
  Future<FirebaseUserEntity?> signInWithGoogle();
  
  // Metode registrasi
  Future<FirebaseUserEntity?> registerWithEmailAndPassword(String email, String password, String fullName);
  
  // Metode manajemen akun
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  
  // Metode manajemen profil
  Future<FirebaseUserEntity?> updateUserProfile({String? displayName, String? photoURL});
  Future<void> updatePassword(String newPassword);
  Future<void> updateEmail(String newEmail, {required String password});
  
  // Metode mendapatkan data pengguna
  FirebaseUserEntity? getCurrentUser();
  
  // Metode verifikasi email
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  
  // Metode hapus akun
  Future<void> deleteAccount();
  
  // Metode reauthentication (diperlukan untuk operasi sensitif)
  Future<bool> reauthenticateUser(String password);

  // Metode untuk autentikasi biometrik
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometrics();
  Future<void> enableBiometricLogin(String email, String password);
  Future<FirebaseUserEntity?> signInWithBiometrics();
  Future<bool> isBiometricLoginEnabled();
  Future<void> disableBiometricLogin();
}