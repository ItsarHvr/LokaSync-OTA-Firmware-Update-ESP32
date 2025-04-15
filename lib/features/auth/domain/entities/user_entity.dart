class FirebaseUserEntity {
  final String uid;
  final String email;
  final String fullName;
  final bool isEmailVerified;
  final String? photoURL;

  FirebaseUserEntity({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.isEmailVerified,
    this.photoURL,
  });
}