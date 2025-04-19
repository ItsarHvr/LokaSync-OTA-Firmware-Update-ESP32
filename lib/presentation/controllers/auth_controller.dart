import 'package:flutter/material.dart';
import 'package:lokasync/features/auth/presentation/controllers/auth_controller.dart';
import 'package:lokasync/features/auth/presentation/pages/login_page.dart';
import 'package:lokasync/features/home/presentation/pages/home_page.dart';
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}
class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final AuthController _authController = AuthController();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isBiometricEnabled = false;
  bool _shouldShowBiometricPrompt = false;
  
  // Add precaching of screens for smoother transitions
  late Widget _homeScreen;

  @override
  void initState() {
    super.initState();
    _precacheWidgets();
    _checkAuthStatus();
  }
  
  // Precache widgets to avoid jank when transitioning
  void _precacheWidgets() {
    // Create instances but don't build them yet
    _homeScreen = const Home();
  }

  Future<void> _checkAuthStatus() async {
    try {
      debugPrint('AUTH_WRAPPER: Checking authentication status');
      
      // First quickly check if user is logged in
      final isLoggedIn = await _authController.isUserLoggedIn();
      debugPrint('AUTH_WRAPPER: isLoggedIn = $isLoggedIn');
      
      // Only check for biometric if not logged in
      if (!isLoggedIn) {
        debugPrint('AUTH_WRAPPER: Checking biometric status');
        
        // Run biometric checks in parallel
        final results = await Future.wait([
          _authController.isBiometricAvailable(),
          _authController.isBiometricLoginEnabled(),
        ]);
        
        final biometricAvailable = results[0];
        final biometricEnabled = results[1];
        debugPrint('AUTH_WRAPPER: biometricAvailable = $biometricAvailable, biometricEnabled = $biometricEnabled');
        
        if (mounted) {
          setState(() {
            _isBiometricEnabled = biometricAvailable && biometricEnabled;
            // Show biometric prompt if available and enabled
            _shouldShowBiometricPrompt = _isBiometricEnabled;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _isAuthenticated = isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AUTH_WRAPPER: Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while checking auth status
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF014331),
          ),
        ),
      );
    }
    
    // If authenticated, go to Home
    if (_isAuthenticated) {
      return _homeScreen;
    }
    
    // Show login screen with biometric flag
    return Login(showBiometricPrompt: _shouldShowBiometricPrompt);
  }
}