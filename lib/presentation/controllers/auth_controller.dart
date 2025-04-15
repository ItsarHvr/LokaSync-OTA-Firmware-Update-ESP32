import 'package:flutter/material.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';
import 'package:lokasync/features/home/presentation/pages/home_page.dart';
import 'package:lokasync/presentation/screens/splash_screen.dart';

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final AuthController _authController = AuthController();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authController.isUserLoggedIn();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isLoggedIn;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menampilkan spinner loading saat memeriksa status autentikasi
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Jika pengguna sudah terautentikasi, langsung ke Home
    // Jika belum, tampilkan login screen
    return _isAuthenticated ? const Home() : const Splash();
  }
}