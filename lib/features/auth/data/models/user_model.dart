import 'package:firebase_auth/firebase_auth.dart';
import 'package:lokasync/features/auth/domain/entities/user_entity.dart';

class UserModel extends FirebaseUserEntity {
  // Menggunakan super parameters untuk lebih singkat
  UserModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.isEmailVerified,
    super.photoURL,
  });

  // Konversi dari Firebase User ke UserModel
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? '',
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  // Method untuk mengkonversi UserModel ke Map (untuk penyimpanan di database)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
    };
  }

  // Factory constructor untuk membuat UserModel dari Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      photoURL: map['photoURL'],
      isEmailVerified: map['isEmailVerified'] ?? false,
    );
  }

  // Method untuk menyalin UserModel dengan beberapa perubahan
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? photoURL,
    bool? isEmailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}